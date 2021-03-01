# Shipwright

This repository contains the tools for building, clustering, analyzing, and fixing broken Dockerfiles. 

## Setup / Environment

There are a few prerequisite tools Shipwright relies on:

- A recent version of `make`
- A recent version of `Docker`
- `git` and other simple utilities

## Building

One of the key usages of Shipwright involves running _in-context Dockerfile builds_. To facilitate this, Shipwright provides the following `make` target: `TARGET="${SHA}" make run-dockerception`. This command will build the Dockerfile in the target git repository (identified by the commit SHA---see `./data/repo-metadata/just-commit-shas.txt` for a listing of repositories in our dataset). As part of this process, Shipwright will spin up a "Docker-inside-of-Docker" container to both: (i) clone the repository matching the given `${SHA}`, and (ii) attempt an _in-context_ build (with a 30 minute timeout). Results are saved to the `./data/build-results/<repo-id>/<commit-sha>/...` directory.

## Clustering & Analyzing

We provide the following example notebook for these tasks: [link to Google Collaboratory notebook](https://colab.research.google.com/drive/1NxLMvrx8XKsIwRrbcqVgAqCm__R5NF1n?usp=sharing).

## Fixing

Coming soon (secondary repository with further tools/scripts --- currently undergoing cleanup).

## Pull Requests

Here's a listing of links to pull requests made with Shipwright:

### Accepted (19)

* https://github.com/AjuntamentdeBarcelona/decidim-barcelona/pull/321
* https://github.com/realpython/flask-image-search/pull/2
* https://github.com/LLNL/merlin/pull/254
* https://github.com/fisadev/zombsole/pull/11
* https://github.com/xlight/docker-php7-swoole/pull/2
* https://github.com/castlamp/zenbership/pull/226
* https://github.com/edwin-zvs/email-providers/pull/9
* https://github.com/ex0dus-0x/doxbox/pull/12
* https://github.com/zhihu/kids/pull/58
* https://github.com/cxmcc/webinspect/pull/1
* https://github.com/thegroovebox/groovebox.org/pull/10
* https://github.com/quasoft/backgammonjs/pull/26
* https://github.com/gitevents/core/pull/216
* https://github.com/htilly/zenmusic/pull/56
* https://github.com/freedomvote/freedomvote/pull/332
* https://github.com/enomotokenji/pytorch-Neural-Style-Transfer/pull/3
* https://github.com/yesodweb/yesodweb.com-content/pull/255
* https://github.com/anurag/fastai-course-1/pull/14
* https://github.com/gjovanov/facer/pull/18

### Rejected (3)

* https://github.com/voxpupuli/puppet-stash/pull/193
* https://github.com/voxpupuli/puppet-mrepo/pull/117
* https://github.com/voxpupuli/puppet-fail2ban/pull/156

### In Review (23)

* https://github.com/CubiCasa/CubiCasa5k/pull/22
* https://github.com/blueboxgroup/ursula/pull/3005
* https://github.com/morecobol/cobol.run/pull/2
* https://github.com/avilaton/gtfseditor/pull/222
* https://github.com/domcode/rafflers/pull/171
* https://github.com/ricktorzynski/ocr-tesseract-docker/pull/9
* https://github.com/danitome24/silex-ddd-skeleton/pull/4
* https://github.com/knjcode/pytorch-finetuner/pull/2
* https://github.com/nabu-catalog/nabu/pull/687
* https://github.com/voxpupuli/puppet-puppetboard/pull/289
* https://github.com/agermanidis/OpenGPT-2/pull/6
* https://github.com/airesis/airesis/pull/201
* https://github.com/ynnadkrap/balldontlie/pull/41
* https://github.com/symbiod/juniorjobs/pull/381
* https://github.com/ello/wtf/pull/125
* https://github.com/willywos/jobbyjobjob/pull/50
* https://github.com/grinnellplans/GrinnellPlans/pull/158
* https://github.com/yunalading/yuncms/pull/39
* https://github.com/JensErat/docker-selfoss/pull/14
* https://github.com/worknenjoy/truppie/pull/155
* https://github.com/gochain/rpc-proxy/pull/56
* https://github.com/holderdeord/hdo-site/pull/692
* https://github.com/capn-freako/PyAMI/pull/9
