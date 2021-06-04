#!/bin/bash

BTRFS_FILE_PATH=${BTRFS_FILE_PATH:-btrfs.file}
BTRFS_DIR_PATH=${BTRFS_DIR_PATH:-btrfs}

umount $BTRFS_DIR_PATH
mkdir $BTRFS_DIR_PATH

dd if=/dev/zero of=$BTRFS_FILE_PATH bs=1M count=12000
mkfs.btrfs $BTRFS_FILE_PATH

mount -o user_subvol_rm_allowed $BTRFS_FILE_PATH $BTRFS_DIR_PATH
chown 1000:1001 $BTRFS_DIR_PATH
