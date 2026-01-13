#!/bin/bash

# Путь (стандартный для user services)
mkdir -p ~/.config/systemd/user

CURRENT_PATH=$(pwd)
CURRENT_USER=$(whoami)
CURRENT_USER_ID=$(id -u "$CURRENT_USER")
CURRENT_GROUP=$(id -gn "$CURRENT_USER")
RULE_FILE="$CURRENT_PATH/99-usb-automount.rules"
SCRIPT_FILE="$CURRENT_PATH/scripts/usb-automount.sh"
UMOUNT_FILE="$CURRENT_PATH/scripts/cleanup-usb-mount.sh"
SERVICE_PATH="$HOME/.config/systemd/user/media-%i.mount"
SCRIPT_PATH="/usr/local/bin/usb-automount.sh"
UMOUNT_PATH="/usr/local/bin/cleanup-usb-mount.sh"
RULE_PATH="/etc/udev/rules.d/99-usb-automount.rules"

if [ -f "$SERVICE_PATH" ]; then
    echo "Сервис $SERVICE_PATH уже существует."
else
    echo "Создаём $SERVICE_PATH..."

    cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Automount USB device %i
After=local-fs.target

[Mount]
Where=/media/%i
Options=defaults,noexec,nodev,nosuid,uid=$CURRENT_USER_ID,gid=$CURRENT_USER_ID,umask=002,noatime

[Install]
WantedBy=multi-user.target
EOF
chmod 644 "$SERVICE_PATH"
echo "Файл создан успешно."
fi

if [ -f "$SCRIPT_PATH" ]; then
    echo "Скрипт $SCRIPT_PATH уже существует."
else
    sudo cp "$SCRIPT_FILE" "$SCRIPT_PATH"
    sudo chmod +x "$SCRIPT_PATH"
fi

if [ -f "$UMOUNT_PATH" ]; then
    echo "Скрипт $UMOUNT_PATH уже существует."
else
    sudo cp "$UMOUNT_FILE" "$UMOUNT_PATH"
    sudo chmod +x "$UMOUNT_PATH"
fi

if [ -f "$RULE_PATH" ]; then
    echo "Udev правило $RULE_PATH уже существует."
else
    echo "Создаём $RULE_PATH..."
    sudo cp "$RULE_FILE" "$RULE_PATH"
fi

    

# Перезагружаем user-daemon и управляем сервисом
systemctl --user daemon-reload
systemctl --user enable udiskie.service
systemctl --user restart udiskie.service
systemctl --user status udiskie.service
sudo loginctl enable-linger $CURRENT_USER
echo "Сервис udiskie настроен и запущен."
