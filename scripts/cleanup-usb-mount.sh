#!/bin/bash

MOUNTPOINT="/media/usb-$1"

# Уже отмонтировано systemd-umount в udev-правиле
# Просто ждём и чистим

for i in {1..8}; do
    if rmdir "$MOUNTPOINT" 2>/dev/null; then
        exit 0
    fi
    sleep 0.3
done

# Если не получилось — принудительно lazy umount (на всякий случай)
umount -l "$MOUNTPOINT" 2>/dev/null
rmdir "$MOUNTPOINT" 2>/dev/null || true
