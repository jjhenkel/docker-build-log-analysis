# docker-build-log-analysis
Experiments and notes related to analyzing Docker build logs and learning/associating search terms to failing logs.

## Preliminaries: Data

To me, one of the things that will be crucial for this line of work is having a large set of candidate `<repository, Dockerfile>` pairs against which we can run `docker build ...` commands and capture logs. It's likely that a good portion of build attempts will fail and we can use that data for this study.

One "missing piece" in this will be having a way to associate `<F(failing log), Good Search Terms>`. That is, we need both a "featurized" representation of failing logs (could be as simple as just test, or the last line, or a bag of words of the last 5 lines, etc.) and we need "Good Search Terms/Keywords". Once we have such a dataset, we can assess the feasibility of going from a failing build to "Good Search Terms" automatically via either neural or traditional methods.

