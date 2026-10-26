#!/bin/bash
# git-ssh-wrapper.sh — durable GitHub SSH for cron-driven git pushes.
# exec's shell sees HOME=/home/hatch, but ssh resolves home via getpwuid as
# /root, whose .ssh is wiped on VM restart. This wrapper re-copies the
# persistent key into /root/.ssh whenever it's missing, then execs ssh.
# Set once per repo: git config core.sshCommand <this file>
set -u
KEY_SRC="/home/hatch/.ssh/id_ed25519"
KNOWN_SRC="/home/hatch/.ssh/known_hosts"
SSH_DIR="/root/.ssh"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ ! -f "$SSH_DIR/id_ed25519" ] && [ -f "$KEY_SRC" ]; then
  cp "$KEY_SRC" "$SSH_DIR/id_ed25519"
  chmod 600 "$SSH_DIR/id_ed25519"
fi

if [ -f "$KNOWN_SRC" ] && ! grep -q "^github.com" "$SSH_DIR/known_hosts" 2>/dev/null; then
  grep "^github.com" "$KNOWN_SRC" >> "$SSH_DIR/known_hosts" 2>/dev/null || true
fi

exec ssh -o ProxyCommand=none -i "$SSH_DIR/id_ed25519" "$@"
