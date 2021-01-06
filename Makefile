dcmd = docker
dfile = Dockerfile
dtag = immawanderer/alpine-android:testbuild
dargs = build -t $(dtag) --no-cache --pull .
cleanargs = image rm -f $(dtag)
pruneargs = system prune -af
dargskaniko = run --rm -it -w=$(kanikowdir) -v $$PWD:$(kanikowdir)
kanikoexecutorimg = gcr.io/kaniko-project/executor
kanikowdir = /src
kanikocontext = .
kanikoargs = -f=$(dfile) -c=$(kanikocontext) --use-new-run --snapshotMode=redo --no-push

.PHONY: build kaniko clean test prune

kaniko:
	$(dcmd) $(dargskaniko) $(kanikoexecutorimg) $(kanikoargs)

build:
	$(dcmd) $(dargs)

clean:
	$(dcmd) $(cleanargs)

test: build kaniko

prune:
	$(dcmd) $(pruneargs)
