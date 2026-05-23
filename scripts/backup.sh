#!/bin/bash
set -euo pipefail

# Find the local-path PVC mount on the host dynamically
PVC_PATH=$(kubectl get pvc minecraft-data -o jsonpath='{.spec.volumeName}' | \
  xargs -I{} find /var/lib/rancher/k3s/storage -maxdepth 1 -name "{}*" -type d)

if [ -z "$PVC_PATH" ]; then
  echo "ERROR: Could not find PVC path" >&2
  exit 1
fi

tar -czf /tmp/world-backup.tar.gz -C "$PVC_PATH" world
aws s3 cp /tmp/world-backup.tar.gz s3://minecraft-backups-238039006137/backups/world-backup-$(date +%Y%m%d).tar.gz
echo "Backup complete: world-backup-$(date +%Y%m%d).tar.gz"