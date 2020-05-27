# Building Dockerfiles at Scale

A key component of this work will be collecting a lot of (failing) Docker image build logs. This means building lots of Docker images. To do this, my plan is roughly this:

1. Collect a set of candidate repositories. (This is `data/repo-metadata/goldilocks-repos.csv`)

2. Create a tool that takes a repository URL and commit SHA and clones the repo, finds the Dockerfile, and attempts a `docker build ... ` while saving the log for our use.

This is simple enough, but to do this for _as many repos as possible_ it would be nice to run step 2 in a massively parallel fashion. Luckily, I have access to a "High Throughput Computing (HTC) Cluster". The only difficulty is, ideally, I'd need step 2 to run in a Docker container. (As it's easy to submit Docker containers to the HTC cluster.)

Therefore, what I need to develop is a "docker-in-docker" image that can take a URL and commit SHA and do the `git clone`, `docker build`, and log extraction. I'm played around with `DooD`: Docker outside of Docker before, and it's not to hard to get working. But, in this scenario, I need `DioD`: Docker _inside_ of Docker. I haven't tried `DioD`-style containers before, so it may be a bit tricky.
