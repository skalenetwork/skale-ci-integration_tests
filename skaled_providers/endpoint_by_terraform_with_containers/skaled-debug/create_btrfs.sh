#!/bin/bash

# Instructions:
# 1 provide external env var BTRFS_FILE_PATH to costomize place where BTRFS data will be physically stored (file will be created automatically)
# 2 provide BTRFS_DIR_PATH - directory where BTRFS will be mounted
# 3 #1-#2 have default values (see below)
# 4 By default, volume size is 200M (customize it below)

BTRFS_FILE_PATH=${BTRFS_FILE_PATH:-./btrfs.file}
BTRFS_DIR_PATH=${BTRFS_DIR_PATH:-./btrfs}

umount $BTRFS_DIR_PATH
mkdir $BTRFS_DIR_PATH

dd if=/dev/zero of=$BTRFS_FILE_PATH bs=1M count=300
mkfs.btrfs $BTRFS_FILE_PATH

mount -o user_subvol_rm_allowed $BTRFS_FILE_PATH $BTRFS_DIR_PATH
chown 1000:1001 $BTRFS_DIR_PATH
