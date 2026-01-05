name = Logs archiver

NO_COLOR=\033[0m	# Color Reset
COLOR_OFF='\e[0m'       # Color Off
OK_COLOR=\033[32;01m	# Green Ok
ERROR_COLOR=\033[31;01m	# Error red
WARN_COLOR=\033[33;01m	# Warning yellow
RED='\e[1;31m'          # Red
GREEN='\e[1;32m'        # Green
YELLOW='\e[1;33m'       # Yellow
BLUE='\e[1;34m'         # Blue
PURPLE='\e[1;35m'       # Purple
CYAN='\e[1;36m'         # Cyan
WHITE='\e[1;37m'        # White
UCYAN='\e[4;36m'        # Cyan
ifneq (,$(wildcard .env))
    include .env
    export $(shell sed 's/=.*//' .env)
endif
USER_ID = $(shell id -u)

all:
	@printf "Launch configuration ${name}...\n"
	@./scripts/01_get_global_list.sh ${FOLDER_PATH} | ./scripts/02_send_dirs_to_remover.sh

env:
	@printf "$(ERROR_COLOR)==== Create environment file for ${name}... ====$(NO_COLOR)\n"
	@if [ -f .env ]; then \
		echo "$(ERROR_COLOR).env file already exists!$(NO_COLOR)"; \
	else \
		cp .env.example .env; \
		echo "$(GREEN).env file successfully created!$(NO_COLOR)"; \
	fi

git:
	@printf "$(YELLOW)==== Set user name and email to git for ${name} repo... ====$(NO_COLOR)\n"
	@bash scripts/gituser.sh

push:
	@bash scripts/push.sh

service:
	@bash scripts/create_service.sh

timer:
	@bash scripts/create_timer.sh