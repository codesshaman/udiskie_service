#!/bin/bash

sudo apt update
sudo apt install -y udiskie

CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn "$CURRENT_USER")

# Путь к файлу
SERVICE_PATH="/etc/systemd/system/udiskie.service"

# Проверяем, существует ли файл
if [ -f "$SERVICE_PATH" ]; then
    echo "Файл $SERVICE_PATH уже существует."
else
    echo "Файл $SERVICE_PATH отсутствует. Создаём файл..."

    # Содержимое для файла
    SERVICE_CONTENT="[Unit]
Description=Automount removable media
After=udisks2.service
Requires=udisks2.service

[Service]
Type=simple
ExecStart=/usr/bin/udiskie -s &
Restart=always
Group=$CURRENT_GROUP
User=$CURRENT_USER

[Install]
WantedBy=multi-user.target"

    # Создаём файл под sudo и записываем содержимое
    echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_PATH" > /dev/null
    
    # Устанавливаем корректные права доступа
    sudo chmod 644 "$SERVICE_PATH"
    echo "Файл $SERVICE_PATH успешно создан."

    # Перезапускаем systemd для применения изменений
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable --now udiskie
    sudo systemctl status udiskie
fi
