# docker-alpine-android

push mirror lives in [this GitHub repo](https://github.com/wULLSnpAXbWZGYDYyhWTKKspEQoaYxXyhoisqHf/docker-alpine-android)<br />
development happens on [this Gitea instance](https://git.dotya.ml/wanderer/docker-alpine-android)

image contents:
* android build tools (sdk 30)
* platform tools (sdk 30)
* android 30 platform
* adoptopenjdk-11
* openjdk-8
* `{bash,curl,git,vim,xz}` from alpine `edge/testing` repo

## Purpose
* ❄️ alpine-based image to enable easily building android apps in CI

## License
see the [LICENSE](LICENSE) file for details
