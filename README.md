# logs_archiver

### Описание

Универсальный набор скриптов для очистки директорий логов, бэкапов и любых других типов артефактов приложений. Позволяет реализовать автоматическую архивацию и удаление старых артефактов по дате. Работает со всеми артефактами, в названии которых есть дата того или иного формата, но можно корректировать это поведение при помощи регулярных выражений.

### Требования

Система на базе ядра линукс либо любая юникс-система, содержащая bash, git, make и systemd.

Пользователь должен иметь права sudo.

### Предварительные настройки

Необходимо склонировать репозиторий, перейти в директорию программы и выполнить следующие действия:

```
make env
```

Необходимо для создания .env-файла.

```
nano .env
```

Далее необходимо отредактировать получившийся ``.env`` следующим образом:

```
GREP_REGEXP=<первое регулярное выражение>
SED1_REGEXP=<второе регулярное выражение>
SED2_REGEXP=<третье регулярное выражение>
FOLDER_PATH=<полный путь к директории, содержащей папки с артефактами>
SERVICE_POSTFIX=<любой уникальный постфикс для формирования разных версий демона>
NUM_LAST_DIRS=<количество сохраняемых артефактов (>=1)>
NUM_LAST_ARCS=<количество архивируемых артефактов (>=0)>
```

Регулярные выражения будут подставляться в конструкцию вида

```
KEEP_LIST=$(ls "$dir" \
  | grep -E "$GREP_REGEXP" \
  | sed -E "$SED1_REGEXP" \
  | sort -r \
  | sed -E "$SED2_REGEXP")
```

Где ``GREP_REGEXP`` - регулярка, формирующая строки общей выборки, ``SED1_REGEXP`` - регулярка, вычисляющая дату-время из строки, а ``SED2_REGEXP`` - регулярка, обратная ``SED1_REGEXP``, возвращающая строку к нормальному виду для корректного отображения.

Между ними команда ``sort -r``, производящая реверс дат чтобы удалялись и архивировались сначала старые.

Некоторые регулярки можно заменять на "заглушки", если их логика не нужна. На примере логов apache airflow настройка регулярок выглядит так:

```
# Airflow logs sort example:
GREP_REGEXP="^run_id=(manual|scheduled)__"
SED1_REGEXP="s/^run_id=([^_]+)__(.*)$/\2 \1/"
SED2_REGEXP="s/^([0-9].*) ([a-z]+)$/run_id=\2__\1/"
FOLDER_PATH=/full/path/to/dags/logs/folder
SERVICE_POSTFIX=prod
NUM_LAST_DIRS=3
NUM_LAST_ARCS=3
```

Перенастроив регулярки под свою логику можно настроить скрипты на работу с любыми иными типами строк артефактов.

В ``FOLDER_PATH`` обязателен полный путь до директории артефактов.

``SERVICE_POSTFIX`` нужен для запуска нескольких экземпляров демона и таймера (у каждого экземпляра он должен отличаться).

``NUM_LAST_DIRS`` - количество сохраняемых артефактов (не может быть менее одного, хотя бы один должен остаться).

``NUM_LAST_ARCS`` - количество архивируемых артефактов (не может быть отрицательным числом).

При

```
NUM_LAST_DIRS=1
NUM_LAST_ARCS=0
```

Сохраняется только один последний артефакт, ничего не архивируется.

При

```
NUM_LAST_DIRS=3
NUM_LAST_ARCS=3
```

Сохраняются 6 последних артефактов, из них три самых давних архивируются. Более давние артефакты удаляются.

### Тестирование

Чтобы протестировать настройки, после сохранения изменений в ``.env`` можно выполнить команду ``make`` и исследовать директорию с артефактами. При необходимости перенастроить регулярки или глубину сохранений.

### Развёртывание

После предварительных настроек приступаем к установке сервиса. Для установки демона (создания сервиса systemd) вводим

```
make service
```

Для установки таймера вызываем

```
make timer
```

Вводим желаемое время запуска. Далее таймер создаётся автоматически.

При доступе к root-правам по паролю необходимо так же ввести пароль пользователя.

### Дополнительные установки

Если необходим ещё один экземпляр сервиса, необходимо поменять в ``.env`` в первую очередь постфикс (без нового постфикса сломается старая установка!), а так же все другие необходимые пременные - 

### Проверка установки

По пути

```
ll /usr/local/lib/
```

Должна появиться директория ``logs_archiver_<постфикс>``.

Проверка лаунчера (на примере постфикса prod и логов airflow):

```
cat /usr/local/lib/logs_archiver_prod/launcher.sh
```

Вывод:

```
#!/bin/bash

/usr/local/lib/logs_archiver_prod/01_get_global_list.sh /home/user/airflow/logs | /usr/local/lib/logs_archiver_prod/02_send_dirs_to_remover.sh
```

Проверка демона:

```
cat /etc/systemd/system/logs_archiver_prod.service
```

Вывод:

```
[Unit]
Description=Token Update Service
After=network.target

[Service]
ExecStart=/usr/local/lib/logs_archiver_prod/launcher.sh
StandardOutput=file:/usr/local/lib/logs_archiver_prod/logfile.log
StandardError=file:/usr/local/lib/logs_archiver_prod/logfile.log
Group=yarogor
User=yarogor
Restart=on-failure

[Install]
```

Проверка работы таймера:

```
cat /etc/systemd/system/logs_archiver_prod.timer
```

Вывод:

```
● logs_archiver_prod.timer - Run English Bot Service Daily
     Loaded: loaded (/etc/systemd/system/logs_archiver_prod.timer; enabled; preset: enabled)
     Active: active (waiting) since Fri 2025-12-12 14:58:38 MSK; 20ms ago
 Invocation: bd6db8a123a142239eb911202fb7ff3c
    Trigger: Fri 2025-12-12 15:00:00 MSK; 1min 21s left
   Triggers: ● logs_archiver_prod.service
```

Проверка работы сервиса:

```
sudo systemctl status logs_archiver_prod
```

Вывод:

```
● logs_archiver_prod.service - Token Update Service
     Loaded: loaded (/etc/systemd/system/logs_archiver_prod.service; enabled; preset: enabled)
     Active: active (running) since Fri 2025-12-12 14:41:09 MSK; 59ms ago
 Invocation: 45a77fd85d224a6bb76bd83e5dc639fd
   Main PID: 197619 ((ncher.sh))
      Tasks: 1 (limit: 76743)
     Memory: 1.5M (peak: 1.8M)
        CPU: 7ms
     CGroup: /system.slice/logs_archiver_prod.service
             └─197619 "(ncher.sh)"
```# udiskie_service
