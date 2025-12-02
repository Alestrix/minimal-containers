# minimal-opensshd

## Out-of-the-box usage

In its default run mode, `minimal-opensshd` only allows a user `user` to start an sftp session and authenticate via ssh key. The corresponding `authorized_keys` file with
the public key needs to be mounted into the container at `/etc/ssh/authorized_keys/user` and the server will listen on TCP port 2222. Connections will be chrooted to the user's
home directory `/home/user` - you should mount whatever you want to make accessible there.

If you want to allow a user sftp read-only access to `/mydata`, you can run

```
docker run -d -p 2222:2222 --name sshd-container -v /home/realuser/.ssh/authorized_keys:/etc/ssh/authorized_keys/user -v /mydata:/home/user/mydata:ro minimal-opensshd

docker logs -f sshd-container
```

## Customizing

### Host keys

Every time a new container is created from the image, a new set of ssh host keys is created. The keys will survive a `docker stop sshd-container` (unless you ran
the container with `--rm`) and `docker start sshd-container`, but if the container is re-created from scratch (e.g. if you use docker compose and run
`docker compose down` and `docker compose up -d`), then the host keys will be recreated and clients will complain about changed keys.

In order to keep the host keys constant you need to create them outside of the container and mount them into

```
/etc/ssh/ssh_host_ecdsa_key
/etc/ssh/ssh_host_ecdsa_key.pub
/etc/ssh/ssh_host_ed25519_key
/etc/ssh/ssh_host_ed25519_key.pub
/etc/ssh/ssh_host_rsa_key
/etc/ssh/ssh_host_rsa_key.pub
```

### Additional configs

The default `sshd_config` in the container looks like this:

```
Port 2222
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no

UsePAM no

AuthorizedKeysFile     /etc/ssh/authorized_keys/%u

AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
PrintMotd no

#PrintLastLog no
#UseLogin no

AcceptEnv LANG LC_* COLORTERM NO_COLOR

Subsystem       sftp    internal-sftp

Include /etc/ssh/sshd_config.d/*.conf
```

And a configuration file with a single `ChrootDirectory /home/%u` line in `/etc/ssh/sshd_config.d/10_chroot.conf`. If you don't want to
chroot the user to their home directory, you can mount an empty file or one with a different `ChrootDirectory` setting into that location.

If you want to add or override other settings, you can mount additional `*.conf` files into the container's `/etc/ssh/sshd_config.d/` directory. Please be aware
that not all setting from sshd_config can be overridden in sshd_config.d/*.conf.

If you want to change the user name for the login to the container, you need to mount a different `/etc/passwd` into the container. The current one looks like this:

```
root:x:0:0:root:/root:/bin/bash
user:x:1000:1000::/home/user:/usr/sbin/nologin
sshd:x:997:65534:sshd user:/run/sshd:/usr/sbin/nologin
```

Since there is no `bash` present in this image (and since `PermitRootLogin` is set to no), the root user will not be able to log into this container, but
`sshd` needs the entry to be there.

## How it works internally

The entrypoint of the container is a little `sshd-start` binary compiled during the build process. This binary checks whether ssh host keys are present and, if not,
calls `ssh-keygen` to create them. Next, it starts `sshd` with the same options as the ones provided to itself (i.e. to the container during startup). By default,
these are `-D -e`, i.e do not detatch from tty and output all messages, including errors, to stdout/stderr.

If you want to try some settings and want to have more thorough debug output, you can run

```
docker run -p 23456:2222 --rm -v /home/realuser/.ssh/authorized_keys:/etc/ssh/authorized_keys/user -v ./sshd_extra.conf:/etc/ssh/sshd_config.d/extra.conf:ro minimal-opensshd -dd
```

## Todo

- Make startup binary smarter to allow parameters for username and UID/GID and update /etc/passwd before sshd is started
- Try in kubernetes and add respective documentation
