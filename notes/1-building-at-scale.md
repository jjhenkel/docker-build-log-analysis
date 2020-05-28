# Building Dockerfiles at Scale

A key component of this work will be collecting a lot of (failing) Docker image build logs. This means building lots of Docker images. To do this, my plan is roughly this:

1. Collect a set of candidate repositories. (This is `data/repo-metadata/goldilocks-repos.csv`)

2. Create a tool that takes a repository URL and commit SHA and clones the repo, finds the Dockerfile, and attempts a `docker build ... ` while saving the log for our use.

This is simple enough, but to do this for _as many repos as possible_ it would be nice to run step 2 in a massively parallel fashion. Luckily, I have access to a "High Throughput Computing (HTC) Cluster". The only difficulty is, ideally, I'd need step 2 to run in a Docker container. (As it's easy to submit Docker containers to the HTC cluster.)

Therefore, what I need to develop is a "docker-in-docker" image that can take a URL and commit SHA and do the `git clone`, `docker build`, and log extraction. I'm played around with `DooD`: Docker outside of Docker before, and it's not to hard to get working. But, in this scenario, I need `DioD`: Docker _inside_ of Docker. I haven't tried `DioD`-style containers before, so it may be a bit tricky.

## Some Issues with DioD 

First, reading around, people seem to call this `DinD` and it's even officially supported! There's a `docker:dind` image. Second, it requires `--privileged` execution (which is _not_ something I can run on the HTC Cluster).

So, `DinD` is out. (I also looked into installing/running a `rootless` Docker daemon but that still seems a bit out of reach and might not even remove the need for that flag?)

Next, I found [kaniko](https://github.com/GoogleContainerTools/kaniko) which is a tool from Google for building Docker images in a rootless/clean environment (without the need for the Docker daemon). This works! But there are two problems:

1. It's a little buggy (which, is to be expected, we'd be running it against 10s of thousands of diverse Dockerfiles)

2. It doesn't produce logs in the same way that `docker build ... ` does. That's _especially_ unfortunate given our intention of log analysis.

Therefore, I've also canned this approach.

### What Now?

Well, for now, it looks like I either need to find something very clever or accept the fact that we might not be able to "scale out" this workload across something like the HTC cluster I have access too.

In `tools/dockerception` there's an image that will just use `DooD` to build an arbitrary Dockerfile from our dataset in its original context.


