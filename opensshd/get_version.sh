echo -n v
docker run --rm --entrypoint /usr/sbin/sshd minimal-opensshd --blabla 2>&1 | grep -Po '(?<=OpenSSH_).*(?= Debian)'
