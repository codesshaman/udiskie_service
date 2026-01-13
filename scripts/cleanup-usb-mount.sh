#!/bin/bash
MOUNTPOINT="/media/usb-$1"

umount -l "$MOUNTPOINT" 2>/dev/null
sleep 2
rmdir --ignore-fail-on-non-empty "$MOUNTPOINT"
