#!/bin/bash
tar -czf /tmp/world-backup.tar.gz -C /opt/minecraft/data world
aws s3 cp /tmp/world-backup.tar.gz s3://minecraft-backups-238039006137/backups/world-backup-$(date +%Y%m%d).tar.gz