#!/bin/bash

# Установка udiskie, если он не установлен
sudo apt update
sudo apt install -y udiskie

# Получаем текущего пользователя и группу
CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn "$CURRENT_USER")

# Создаём директорию для пользовательских сервисов systemd, если её нет
mkdir -p ~/.config/systemd/user

# Путь к файлу сервиса
SERVICE_PATH="~/.config/systemd/user/udiskie.service"

# Проверяем, существует ли файл
if [ -f "$SERVICE_PATH" ]; then
    echo "Файл $SERVICE_PATH уже существует."
else
    echo "Файл $SERVICE_PATH отсутствует. Создаём файл..."

    # Содержимое для файла
    SERVICE_CONTENT="[Unit]
Description=udiskie automount daemon
After=graphical.target

[Service]
Type=simple
ExecStart=/usr/bin/udiskie -s
Restart=always
Environment=DISPLAY=:0

[Install]
WantedBy=default.target"

    # Создаём файл под sudo и записываем содержимое
    echo "$SERVICE_CONTENT" | tee "$SERVICE_PATH" > /dev/null
    
    # Устанавливаем корректные права доступа
    chmod 644 "$SERVICE_PATH"
    echo "Файл $SERVICE_PATH успешно создан."

    # Перезапускаем systemd для применения изменений
    systemctl --user daemon-reexec
    systemctl --user daemon-reload
    systemctl --user enable udiskie.service
    systemctl --user start udiskie.service
    systemctl --user status udiskie
fi
