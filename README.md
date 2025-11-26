# Minimal Containers

## About

This repo intents to provide a general way to create minimal docker containers. By reducing the amount of software included in a container image, the container is less susceptible to attacks. Plus, a small container requires less storage and downloads faster.

## How to use

There is a subdirectory for each minimal container image (thus far only one - mosquitto). Each subdirectory includes these files:

| File | Purpose |
| -- | -- |
| EXTRA_PACKAGES | List of extra packages to install |
| BINARIES | List of binaries to copy to final image |
| ENTRYPOINT_BIN | The path configured as entrypoint in the image |
| extra_steps.sh | Extra collection steps needed to make this container work |
| get_version.sh | A script that outputs the version of the created container image |

## How the image is built

- First, based on `debian:stable-slim` packages are updated to latest versions and `EXTRA_PACKAGES` (see table above) are installed.
- Then, based on the `BINARIES`, the needed libraries are (recursively) searched for and collected, including the dynamic loader library.
- As an optional step (using `extra_steps.sh`), some additional files are collected (in case of mosquitto, `/etc/passwd` and `/etc/group` are copied, because otherwise mosquitto complains about a missing mosquitto user).
- Finally, all collected files are copied into an empty (`scratch`) container and the entrypoint is set to `ENTRYPOINT_BIN`.

## Docker Hub

While I intent to upload the image(s) to `alestrix/minimal-<container>`, I haven't set up a pipeline that keeps the image updated and by the time you want to use it, I might have abadoned this whole idea and the image is probably completely outdated and full of vulnerabilities.

Therefore, I encourage everyone to build their own images. You shouldn't trust a random guy on the internet anyway!
