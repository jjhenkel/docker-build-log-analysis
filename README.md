# docker-build-log-analysis
Experiments and notes related to analyzing Docker build logs and learning/associating search terms to failing logs.

## Setup / Environment

I try and write all of my tools/experiments with Docker---this helps later when I want to share/reproduce things. Nevertheless, there are some prerequisite tools I rely on:

- A recent version of `make`
- A recent version of `Docker`
- `git` and other simple utilities

I develop on various `*nix` machines (most `Debian/Ubuntu/CentOS`). This should be portable to `macOS` without much trouble. Even `Windows` would work (although driver/glue scripts would need to be ported or something like `Windows Subsystem for Linux` would need to be used).

## Preliminaries: Data

To me, one of the things that will be crucial for this line of work is having a large set of candidate `<repository, Dockerfile>` pairs against which we can run `docker build ...` commands and capture logs. It's likely that a good portion of build attempts will fail and we can use that data for this study.

One "missing piece" in this will be having a way to associate `<F(failing log), Good Search Terms>`. That is, we need both a "featurized" representation of failing logs (could be as simple as just test, or the last line, or a bag of words of the last 5 lines, etc.) and we need "Good Search Terms/Keywords". Once we have such a dataset, we can assess the feasibility of going from a failing build to "Good Search Terms" automatically via either neural or traditional methods.

