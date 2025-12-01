# Unprivileged minimal-opensshd

This is a minimal OpenSSHd container that runs an SFTP server as non-root user.

## Caveats

***NOTE:*** The OpenSSHd server cannot switch "down" from a privileged account (that has access to host keys) to the account that the user actions will be
carried out as. Hence, the **logged-in user has full access to the server's private host keys**. Only use this image if you control both sides of the connection and
if you know that the user on client will not mess with the server's private ssh keys!

## Out-of-the-box usage

In its default run mode, `minimal-opensshd-unpriv` only allows a user `user` to start an sftp session and authenticate via ssh key. The corresponding `authorized_keys` file with
the public key needs to be mounted into to container at `/etc/ssh/authorized_keys/user` and the server will listen on TCP port 2222.

So if you want to allow a user sftp read-only access to `/data`, you can run

```
docker run -d -p 2222:2222 --name sshd-container -v /home/realuser/.ssh/authorized_keys:/etc/ssh/authorized_keys/user -v /data:/data:ro minimal-opensshd-unpriv

docker logs -f sshd-container
```

## Customizing

### Host keys

Every time a new container is created from the image, a new set of ssh host keys is created. The keys will survive a `docker stop sshd-container` and `docker start sshd-container`,
but if the container is re-created from scratch (e.g. if you use docker compose and run `docker compose down` and `docker compose up -d`), then the host keys will change and
clients will complain about changed keys.

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
PidFile /tmp/sshd.pid

AuthorizedKeysFile     /etc/ssh/authorized_keys/%u

AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
PrintMotd no

# Prevent "Attempt to write login records by non-root user (aborting)" message
PrintLastLog no
UseLogin no

AcceptEnv LANG LC_* COLORTERM NO_COLOR

Subsystem       sftp    /usr/lib/openssh/sftp-server

Include /etc/ssh/sshd_config.d/*.conf
```

If you want to add or override some settings, you can mount additional `*.conf` files into the container's `/etc/ssh/sshd_config.d/` directory. Please be aware that not
all setting from sshd_config can be overridden in sshd_config.d/*.conf.

If you want to change the user name for the login to the container, you need to mount a different `/etc/passwd` into the container. The current one looks like this:

```
user:x:1000:1000::/home/user:/usr/lib/openssh/sftp-server
```

### Chroot (untested)

Since the container only copies very few files from a build container into an empty scratch container, and copying does not preserve capabilities, the respective files
could not be `setcap`ed. You might be able to configure a `ChrootDirectory` statement into a dedicated `.conf` file inside `/etc/ssh/sshd_config.d/` and run the container
with `--cap-add=SYS_CHROOT`, but this might or might not work. I am also not sure whether the capability might get lost during `sshd-start`'s execve, so you might have to
change the entrypoint to `/usr/sbin/sshd` (which also means you need to mount ssh host keys into the container).

## How it works internally

The entrypoint of the container is a little `sshd-start` binary compiled during the build process. This binary checks whether ssh host keys are present and, if not,
calls `ssh-keygen` to create them. Next, it starts `sshd` with the same options as the ones provided to itself (i.e. to the container during startup). By default,
these are `-D -e`, i.e do not detatch from tty and output all messages, including errors, to stdout/stderr.

If you want to try some settings and want to have more thorough debug output, you can run

```
docker run -p 23456:2222 --rm -v /home/realuser/.ssh/authorized_keys:/etc/ssh/authorized_keys/user -v ./sshd_extra.conf:/etc/ssh/sshd_config.d/extra.conf:ro minimal-opensshd-unpriv -dd
```

## Todo

- Make startup binary smarter to allow parameters for username and UID/GID and update /etc/passwd before sshd is started
- ~~Test chroot~~ --> solved by privileged version `minimal-opensshd`.
- Try in kubernetes and add respective documentation
- ~~Somehow solve the issue of private `ssh_host_*_key`s being readable by user (as sshd runs under that same user!)~~ --> solved by privileged version `minimal-opensshd`.
