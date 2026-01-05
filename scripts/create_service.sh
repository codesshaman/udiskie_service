#!/bin/bash

source .env

# Сохраняем текущую директорию в переменную
CURRENT_DIR=$(pwd)

# Сохраняем текущего пользователя в переменную
CURRENT_USER=$(whoami)

# Путь к файлу
SERVICE_PATH="/etc/systemd/system/logs_archiver_$SERVICE_POSTFIX.service"

# Проверяем, существует ли файл
if [ -f "$SERVICE_PATH" ]; then
    echo "Файл $SERVICE_PATH уже существует."
else
    echo "Файл $SERVICE_PATH отсутствует. Создаём файл..."

    # Содержимое для файла
    SERVICE_CONTENT="[Unit]
Description=Token Update Service
After=network.target

[Service]
ExecStart=/bin/bash /usr/local/lib/logs_archiver_$SERVICE_POSTFIX/launcher.sh
StandardOutput=file:/usr/local/lib/logs_archiver_$SERVICE_POSTFIX/logfile.log
StandardError=file:/usr/local/lib/logs_archiver_$SERVICE_POSTFIX/logfile.log
Group=$CURRENT_USER
User=$CURRENT_USER
Restart=on-failure

[Install]
WantedBy=multi-user.target"

    # Создаём файл под sudo и записываем содержимое
    echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_PATH" > /dev/null
    
    # Устанавливаем корректные права доступа
    sudo chmod 644 "$SERVICE_PATH"
    echo "Файл $SERVICE_PATH успешно создан."

    # Создаём лог-файл
    sudo touch $CURRENT_DIR/logfile.log
    sudo chown $CURRENT_USER:$CURRENT_USER $CURRENT_DIR/logfile.log

    # Доставляем все скрипты
SCRIPTS_PATH=/usr/local/lib/logs_archiver_$SERVICE_POSTFIX
    sudo mkdir $SCRIPTS_PATH
    sudo cp -rf ./scripts/* $SCRIPTS_PATH
    sudo cp .env $SCRIPTS_PATH

    # Создаём файл для запуска
sudo tee "$SCRIPTS_PATH/launcher.sh" > /dev/null << EOF
#!/bin/bash
/usr/local/lib/logs_archiver_$SERVICE_POSTFIX/01_get_global_list.sh $FOLDER_PATH \
| /usr/local/lib/logs_archiver_$SERVICE_POSTFIX/02_send_dirs_to_remover.sh
EOF

   sudo chmod +x /usr/local/lib/logs_archiver_$SERVICE_POSTFIX/*.sh

    # Перезапускаем systemd для применения изменений
    sudo systemctl daemon-reload
    sudo systemctl enable logs_archiver_$SERVICE_POSTFIX.service
    sudo systemctl start logs_archiver_$SERVICE_POSTFIX.service
    sudo systemctl status logs_archiver_$SERVICE_POSTFIX.service
    echo "Systemd перезагружен."
fi
