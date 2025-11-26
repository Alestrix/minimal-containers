#!/bin/bash
set -euo pipefail

mkdir -p rootfs/etc
cp /etc/group ./rootfs/etc
cp /etc/passwd ./rootfs/etc
