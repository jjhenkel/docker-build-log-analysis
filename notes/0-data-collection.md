# Notes on Data Collection

This is where I'm going to note exactly what data I have and the steps I've used to get said data. First off, I should note that from prior work (the "Learning from, Understanding, and Supporting..." ICSE paper) I have a distributed "ecosystem" for capturing data and DevOps files from GitHub. I have this up and running on a university machine an recently used it to capture the following:

1. Metadata for all repositories that, currently, have 10 or more stars and that were created between January 1st 2007 to May 1st 2020.

2. A full file listing for all of those repositories (each file listing comes with associated metadata).

3. An analysis (crude: based on file names only) of the file-listings that attempts to identify various kinds of DevOps files.

That data is now all stored in a PostgreSQL database. Here are some examples of working with that data:

```sql
/* 'repositories' stores repository metadata */
SELECT COUNT(*) FROM repositories;
/* RESULT: 1,086,811 repository metadata entries */

/* 'repository_files' stores file listings */
SELECT COUNT(*) FROM repository_files;
/* RESULTS: 437,716,767 (REALLY big table---400 Million rows!) */

/* 'v_repository_files' includes classifications of files into:
     - DevOps files (~11 different sub-classes)
      - Docker (file/compose file)
      - Travis 
      - CircleCI
      - Jenkins
      - etc. 
   How many repositories in this set have *some* kind of DevOps file?
*/
SELECT 
  COUNT(DISTINCT repo_id)
FROM v_repository_files
WHERE maybe_devops = true;
/* RESULTS: 288,873 repositories (or ~ 1 in every 4). */
```

## Goldilocks Repositories

Many repositories that have Dockerfiles have either: (i) more than one Dockerfile or (ii) a Dockerfile in a non-root directory (in some sub-folder of the repository). These are complicating factors. To "build" a Dockerfile we need to know the build context (a path containing the Dockerfile). When there's a single Dockerfile in the root directory of a repository, it is likely that we can get away with trying to build that Dockerfile and use the root directory as the build context. But, in the other two situations I mentioned, the decision of context, and trying to understand whether or not this is really _the_ Dockerfile for a repository in the case of (i), is a lot less clear.

Therefore, I propose looking at `<repository, Dockerfile>` pairs where there is just _a single Dockerfile in the root directory_ of the target repository. These are in the "Goldilocks" zone---aka., these are "just right"!

To find a count of such repositories, we can run a more sophisticated query:

```sql
/* This finds out how many repos are in the "Golilocks" zone. */
SELECT 
  COUNT(1) 
OVER()
FROM v_repository_files
WHERE 
  maybe_docker_file = true AND
  file_directory = ''
GROUP BY repo_id
HAVING COUNT(repo_id) = 1
LIMIT 1;

/* RESULTS: 32,466 */
```

So, given the above, it appears that we have `32,466` such repositories in this dataset! That's a really nice amount! (For context, there are `65,105` repositories with at least one Dockerfile in this dataset.)

## Extracting Goldilocks Repositories

Now that we have a count and a rough idea of what we're looking for, let's extract it and save it to disk:

```sql
/* Grab all the metadata for repository 'IN' the Golidlocks set */
SELECT
  R.*
FROM repositories AS R
WHERE R.repo_id IN (
	SELECT 
	  DISTINCT VF.repo_id
	FROM v_repository_files AS VF
	WHERE 
	  VF.maybe_docker_file = true AND
	  VF.file_directory = ''
	GROUP BY VF.repo_id
	HAVING COUNT(VF.repo_id) = 1
)

/* RESULTS: were saved using pgAdmin's export CSV feature */
```

Next, I do a sanity check on the downloaded CSV:

```bash
cat ./data/repo-metadata/goldilocks-repos.csv | awk -F',' '{ print $1 }' | head -n-1  | wc -l
```

It happened that this returned `32,469` which is more than expected? Further investigation reveals that one GitHub repository in the dataset had line breaks in its description field that ended up in the CSV. I manually fixed this (although CSV allows for line breaks in double quoted fields, I don't trust every arbitrary CSV reader to support that).

Finally, we're in a place where we can interact with this data on the disk:

```bash
# Get into clean environment
./dbla.sh i

# Use 'mlr' utility in clean environment and interact with dataset
root@f220f5fd4f88:/mnt> cat data/repo-metadata/goldilocks-repos.csv \
  | mlr --csv cut -f repo_name then head -n 4

# Results:
repo_name
yard
aasm
spree
activegraph
```
