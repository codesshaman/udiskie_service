#!/bin/bash

NAME="$(grep "GIT_USER" .env | sed -r 's/.*=//')"
MAIL="$(grep "GIT_MAIL" .env | sed -r 's/.*=//')"

git config user.name "$NAME"

git config user.email "$MAIL"

git config --local --list
