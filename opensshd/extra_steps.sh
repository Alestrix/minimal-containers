#!/bin/bash
set -euo pipefail

# Make users root, user, and sshd known
mkdir -p rootfs/etc
grep "^root" /etc/passwd > ./rootfs/etc/passwd
echo "user:x:1000:1000::/home/user:/usr/sbin/nologin" >> ./rootfs/etc/passwd
grep "^sshd" /etc/passwd >> ./rootfs/etc/passwd
chmod 644 ./rootfs/etc/passwd

# user homedir
mkdir -p rootfs/home/user

# Privilege separation directory
mkdir -p rootfs/run/sshd

# C code for startup binary to start hostkey-generation if needed before sshd is started
#mkdir -p rootfs/usr/sbin
cat > ./sshd-start.c <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <glob.h>
#include <string.h>

int main(int argc, char *argv[]) {
    glob_t g;

    // 1. Check for hostkey existance
    int r = glob("/etc/ssh/ssh_host_*_key", 0, NULL, &g);

    if (r == GLOB_NOMATCH || g.gl_pathc == 0) {
        printf("No SSH-Host-Keys found – generating...\n");
        globfree(&g);

        // exec ssh-keygen -A to generate hostkeys
        pid_t pid = fork();
        if (pid == 0) {
            execl("/usr/bin/ssh-keygen", "ssh-keygen", "-A", (char *)NULL);
            perror("exec ssh-keygen");
            _exit(1);
        } else if (pid < 0) {
            perror("fork");
            exit(1);
        }

        // wait for ssh-keygen
        int status;
        waitpid(pid, &status, 0);

        if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
            fprintf(stderr, "ssh-keygen -A failed\n");
            exit(1);
        }

    } else if (r == 0) {
        printf("SSH-Host-Keys present.\n");
        globfree(&g);
    } else {
        perror("glob");
        exit(1);
    }

    // 2. Show parameters
    printf("Starting sshd with parameters:");
    for (int i = 1; i < argc; i++) {
        printf(" %s", argv[i]);
    }
    printf("\n");

    // 3. Build args (has one item more than argc)
    char **args = malloc((argc + 1) * sizeof(char*));
    if (!args) {
        perror("malloc");
        exit(1);
    }

    args[0] = "/usr/sbin/sshd";
    for (int i = 1; i < argc; i++)
        args[i] = argv[i];
    args[argc] = NULL;

    // start sshd replacing current process
    execv("/usr/sbin/sshd", args);

    // in case of error
    perror("execv sshd");
    return 1;
}
EOF

# Compile C code
gcc -o /usr/sbin/sshd-start sshd-start.c

# ...and collect libraries
./collect.sh /usr/sbin/sshd-start

# prepare sshd config
mkdir -p rootfs/etc/ssh/sshd_config.d
mkdir -p rootfs/etc/ssh/authorized_keys

cat > ./rootfs/etc/ssh/sshd_config <<'EOF'
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

EOF

echo "ChrootDirectory /home/%u" > ./rootfs/etc/ssh/sshd_config.d/10_chroot.conf

# Add nologin to valid shells
echo "/usr/sbin/nologin" > ./rootfs/etc/shells
