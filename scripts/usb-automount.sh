#!/bin/bash

ACTION=$1
DEVBASE=$2
DEVICE="/dev/${DEVBASE}"
CURRENT_USER=$(whoami)
CURRENT_USER_ID=$(id -u "$CURRENT_USER")
CURRENT_GROUP=$(id -gn "$CURRENT_USER")

# Пропускаем, если не блочное устройство с ФС
if [[ ! -b "$DEVICE" ]]; then
    exit 0
fi

MOUNTPOINT="/media/${DEVBASE}"
LOG_TAG="usb-automount"

case "$ACTION" in
    add)
        # Создаём точку монтирования, если нет
        mkdir -p "$MOUNTPOINT"
        
        # Определяем ФС (blkid или пробуем распространённые)
        FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)
        if [[ -z "$FS_TYPE" ]]; then
            FS_TYPE="auto"  # Автоопределение
        fi
        
        # Опции монтирования: для сервера — безопасные, с uid/gid для доступа
        MOUNT_OPTS="defaults,noexec,nodev,nosuid,uid=$CURRENT_USER_ID,gid=$CURRENT_GROUP,umask=002,noatime"
        
        # Специфично для ФС
        if [[ "$FS_TYPE" == "ntfs" ]]; then
            # Для NTFS нужен ntfs-3g (установите: apt install ntfs-3g)
            mount.ntfs-3g "$DEVICE" "$MOUNTPOINT" -o "$MOUNT_OPTS"
        elif [[ "$FS_TYPE" == "exfat" ]]; then
            # Для exFAT (apt install exfat-fuse или exfat-utils)
            mount.exfat "$DEVICE" "$MOUNTPOINT" -o "$MOUNT_OPTS"
        else
            mount -t "$FS_TYPE" -o "$MOUNT_OPTS" "$DEVICE" "$MOUNTPOINT"
        fi
        
        if [[ $? -eq 0 ]]; then
            logger -t "$LOG_TAG" "Mounted $DEVICE at $MOUNTPOINT"
        else
            logger -t "$LOG_TAG" "Failed to mount $DEVICE"
            rmdir "$MOUNTPOINT"
        fi
        ;;
    
    remove)
        # Размонтируем и удаляем точку
        umount -l "$MOUNTPOINT" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            logger -t "$LOG_TAG" "Unmounted $MOUNTPOINT"
            rmdir "$MOUNTPOINT"
        fi
        ;;
esac
