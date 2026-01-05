#!/bin/bash

BASE_DIR="${1:-.}"

find "$BASE_DIR" -maxdepth 1 -mindepth 1 -type d -print
