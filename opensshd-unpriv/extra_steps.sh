#!/bin/bash
set -euo pipefail

# Make users root, user, sshd and nobody known
mkdir -p rootfs/etc
echo "user:x:1000:1000::/home/user:/usr/lib/openssh/sftp-server" > ./rootfs/etc/passwd
#chmod 644 ./rootfs/etc/passwd

# user homedir
mkdir -p rootfs/home/user
chown 1000 ./rootfs/home/user

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

    // 1. Hostkeys prüfen
    int r = glob("/etc/ssh/ssh_host_*_key", 0, NULL, &g);

    if (r == GLOB_NOMATCH || g.gl_pathc == 0) {
        printf("No SSH-Host-Keys found – generating...\n");
        globfree(&g);

        // ssh-keygen -A ausführen
        pid_t pid = fork();
        if (pid == 0) {
            execl("/usr/bin/ssh-keygen", "ssh-keygen", "-A", (char *)NULL);
            perror("exec ssh-keygen");
            _exit(1);
        } else if (pid < 0) {
            perror("fork");
            exit(1);
        }

        // Auf ssh-keygen warten
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

    // 2. Startparameter anzeigen
    printf("Starting sshd with parameters:");
    for (int i = 1; i < argc; i++) {
        printf(" %s", argv[i]);
    }
    printf("\n");

    // 3. Argumentliste für execv bauen
    char **args = malloc((argc + 1) * sizeof(char*));
    if (!args) {
        perror("malloc");
        exit(1);
    }

    args[0] = "/usr/sbin/sshd";
    for (int i = 1; i < argc; i++)
        args[i] = argv[i];
    args[argc] = NULL;

    // sshd starten (ersetzt aktuellen Prozess)
    execv("/usr/sbin/sshd", args);

    // nur bei Fehler:
    perror("execv sshd");
    return 1;
}
EOF

# Compile C code
gcc -o /usr/sbin/sshd-start sshd-start.c

# ...and collect libraries
./collect.sh /usr/sbin/sshd-start

# Prepare /tmp - pidfile is written there (we don't need it, but sshd will complain otherwise)
mkdir rootfs/tmp
chmod go+wx ./rootfs/tmp

# prepare sshd config
mkdir -p rootfs/etc/ssh/sshd_config.d
mkdir -p rootfs/etc/ssh/authorized_keys

# Needed so that ssh-keygen (which is run at startup as non-root user) can write the host keys
chown -R 1000 ./rootfs/etc/ssh
#chmod -R a+r ./rootfs/etc/ssh

cat > ./rootfs/etc/ssh/sshd_config <<'EOF'
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

#Subsystem       sftp    /usr/lib/openssh/sftp-server
Subsystem       sftp    internal-server

Include /etc/ssh/sshd_config.d/*.conf

EOF

# Add sftp-server to valid shells
echo "/usr/lib/openssh/sftp-server" > ./rootfs/etc/shells
