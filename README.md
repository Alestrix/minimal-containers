# Minimal Containers

## About

This repo intents to provide a general way to create minimal docker containers. By reducing the amount of software included in a container image, the container is less susceptible to attacks. Plus, a small container requires less storage and downloads faster.

## How to use

There is a subdirectory for each minimal container image. Each subdirectory includes these files:

| File | Purpose |
| -- | -- |
| `EXTRA_PACKAGES` | List of extra packages to install |
| `BINARIES` | List of binaries to copy to final image |
| `ENTRYPOINT` | The line (or lines) used as ENTRYPOINT (and optionally CMD) for the Dockerfile |
| `extra_steps.sh` | Extra collection steps needed to make the respective container work |
| `get_version.sh` | A script that outputs the version of the created container image |

So far there are directories for these containers:

| Directory | Purpose |
| -- | -- |
| [mosquitto](./mosquitto/README.md) | An MQTT server |
| [opensshd](./opensshd/README.md) | The OpenSSH ssh server (sftp-only, key-only, chroot to user's home) |
| [opensshd-unpriv](./opensshd-unpriv/README.md) | Like opensshd, but running unprivileged (beware of some [caveats](./opensshd-unpriv/README.md#caveats) ) |

## How the image is built

- First, based on `debian:stable-slim` packages are updated to latest versions and `EXTRA_PACKAGES` (see table above) are installed.
- Then, based on the `BINARIES`, the needed libraries are (recursively) searched for and collected, including the dynamic loader library.
- As an optional step (using `extra_steps.sh`), some additional files are collected (in case of mosquitto, `/etc/passwd` and `/etc/group` are copied, because otherwise mosquitto complains about a missing mosquitto user).
- Finally, all collected files are copied into an empty (`scratch`) container and the entrypoint and cmd are set according to `ENTRYPOINT`.
- Once the image is created (docker automatically tags it as `:latest`), the `get_version.sh` script is executed and the output is used to add another tag with the correct version number.

## Docker Hub

While I do upload the image(s) to `alestrix/minimal-<container>` ([link to docker hub](https://hub.docker.com/u/alestrix)), I haven't set up a pipeline that
keeps the image(s) updated and by the time you want to use it, I might have abandoned this whole idea and the image could be completely outdated and full of
vulnerabilities.

Therefore, I encourage everyone to build their own images. You shouldn't trust a random guy on the internet anyway!

## Caveats

The created images might not be able to be properly scanned by tools like trivy, grype, or xray as they do not include any package information.

## Todo

- create minimal `/etc/passwd` / `/etc/group`
- set GID/UID to 65534
- hope it still works then