#!/bin/bash

# Script to determine what named images and containers are dependent on the specified image (or a containers image) from stdin or in the args
# An unmatchable input is ignored
# All of the following will be found:
#    Any image name / tag / name:tag / id that has a prefix in it that matches the input
#    Any other image that relies on the images specified
#    Any containers (running or not) that use any of these images

set -euf -o pipefail


specifiedParents=""
# Find all the parents
if [ "$#" -ge "1" ]; then
	# Parents are in args
	specifiedParents="$(printf " %s\n" "$@")"
else
	# Parents arrive via stdin
	while IFS= read -r inStr; do
		if [ -n "$inStr" ]; then
			inStr="${inStr#"${inStr%%[![:space:]]*}"}"
			specifiedParents="$(printf "%s\n %s" "$specifiedParents" "$inStr")"
		fi
	done
fi

# Check there is some input
if [ -z "$specifiedParents" ]; then
	printf "%s" "Nothing specified to search for; images/containers must be specified as either args or on the stdin" >&2 
	exit 1
fi

# Collect the container and image info
containersData="$(docker ps -a --format 'Container {{.ID}} {{.Image}} {{.Names}} {{.Labels}}' --no-trunc)"
allImagesData="$(docker images -a --format 'Image {{.ID}} {{.Repository}}:{{.Tag}} {{.Repository}} {{.Tag}}' --no-trunc | sed 's/ [^:]*:/ /')"
namedImagesData="$(docker images --format 'Image {{.ID}} {{.Repository}}:{{.Tag}}' --no-trunc | sed 's/ [^:]*:/ /')"

# Check to see if you can find a matching container
matchedContainerIds=""
parentImageIds=""
while IFS= read -r aParent; do
	if [ -z "$aParent" ]; then
		continue
	fi
	
	# Use space to ensure matching starts at the beginning of a field
	aContainerId=" $(printf "%s" "$containersData" | grep -F "$aParent" | awk '{print $3}' || true)"
	if [ "$aContainerId" != " " ]; then
		# A container matched so use the image ID
		matchedContainerIds="$(printf "%s\n%s" "$matchedContainerIds" "$aContainerId")"
	fi

	# Also check images
	while IFS= read -r parentImageId; do
		if [ -z "$parentImageId" ]; then
			continue
		fi
		# Add the full ID to the parentImageIds, including a space to assist matching later
		parentImageIds="$(printf "%s%s\n" "$parentImageIds" " $parentImageId")"
	done <<< "$(printf "%s" "$allImagesData" | grep -F "$aParent" | awk '{print $2}')"
done <<< "$(printf "%s\n" "$specifiedParents")"

# Stop if there are no parents or containers
if [ -z "$parentImageIds" ] && [ -z "$matchedContainerIds" ]; then
	exit 0
fi

# Deduplicate
parentImageIds="$(printf "%s" "$parentImageIds" | LC_ALL=C sort -u)"

# Find descendent images
descendentImages=""
while IFS= read -r imageData; do
	anImageId="$(printf "%s" "$imageData" | awk '{print $2}')"

	# Check to see if this ID is a descendent of parentImageIds by imageInfo by moving through it's lineage
	areDescendents=""
	imageIdsChecked=""
	while true; do
		# Record that anImageId is being checked; including the space at the start to assist matching later
		imageIdsChecked="$(printf "%s%s\n" "$imageIdsChecked" " $anImageId")"

		if printf "%s" "$descendentImages" | grep -q -F "$anImageId"; then
			# Already determined that anImageId is a descendent of parentImageIds so TheImage is too
			areDescendents="true"
			break;
		else
			if printf "%s" "$parentImageIds" | grep -q -F " $anImageId"; then
				# TheImage is a descendent of parentImageIds
				areDescendents="true"
				break;
			fi

			# Move onto the parent of anImageId
			anImageId="$(docker inspect --format '{{.Parent}}' "$anImageId" | sed 's/.*://')"
			if [ -z "$anImageId" ]; then
				# Reached the end of the line; abandon all hope ye who enter here
				break;
			fi
		fi
	done

	# Add descendents to the descendentImages
	if [ -n "$areDescendents" ]; then
		descendentImages="$(printf "%s%s\n" "$descendentImages" "$imageIdsChecked")"
	fi
done <<< "$(printf "%s" "$allImagesData")"

# Identify any named images that are descendents of the parentImageIds
printf "%s\n" "$namedImagesData" | while IFS= read -r imageData; do
	thisImageId="$(printf "%s" "$imageData" | awk '{print $2}')"
	if printf "%s" "$descendentImages" | grep -q -F " $thisImageId"; then
		# We've found a descendent
		printf "%s\n" "$imageData"
	fi
done

# Identify containers that rely on images that are descendents of the parentImageIds
printf "%s\n" "$containersData" || while IFS= read -r containerData; do
	# Check to see if this container is dependant on a dependant image
	thisImageId="$(printf "%s" "$containerData" | awk '{print $3}')"
	if printf "%s" "$descendentImages" | grep -q -F " $thisImageId"; then
		# We've found a descendent
		printf "%s\n" "$containerData"
		continue
	fi

	# Check to see if this container itself has been matched
	thisContainerId="$(printf "%s" "$containerData" | awk '{print $2}')"
	if printf "%s" "$matchedContainerIds" | grep -q -F " $thisContainerId"; then
		# We've matched a container
		printf "%s\n" "$containerData"
		continue
	fi	
done
