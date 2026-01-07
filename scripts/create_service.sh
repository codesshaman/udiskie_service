#!/bin/bash

# Установка udiskie
sudo apt update
sudo apt install -y udiskie

# Путь (стандартный для user services)
mkdir -p ~/.config/systemd/user

CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn "$CURRENT_USER")

SERVICE_PATH="$HOME/.config/systemd/user/udiskie.service"
RULE_PATH="/etc/polkit-1/rules.d/10-udiskie.rules"

if [ -f "$SERVICE_PATH" ]; then
    echo "Сервис $SERVICE_PATH уже существует."
else
    echo "Создаём $SERVICE_PATH..."

    cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=udiskie automount daemon

[Service]
Type=simple
ExecStart=/usr/bin/udiskie -s
Restart=always

[Install]
WantedBy=default.target
EOF

RULE_CONTENT="polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.udisks2.") === 0 && subject.user === "$CURRENT_USER") {
        return polkit.Result.YES;
    }
});"

    echo "$RULE_CONTENT" | sudo tee "$RULE_PATH" > /dev/null

    chmod 644 "$SERVICE_PATH"
    echo "Файл создан успешно."
fi

# Перезагружаем user-daemon и управляем сервисом
systemctl --user daemon-reload
systemctl --user enable udiskie.service
systemctl --user restart udiskie.service
systemctl --user status udiskie.service
sudo loginctl enable-linger $CURRENT_USER
echo "Сервис udiskie настроен и запущен."
