#!/bin/bash

function pass {
  local ESC="\e["
  local GREEN_F="${ESC}1;32m"
  local NORM="${ESC}0m"
  echo -e "${GREEN_F}SUCCESS${NORM}"
  let test_number++
  return 0
}

function fail {
  local ESC="\e["
  local RED_F="${ESC}1;31m"
  local NORM="${ESC}0m"
  echo -e "${RED_F}FAILURE (item $1)${NORM}"
  exit 1
}

E_GOOD=0
E_GENERIC=1
E_IO_FAILURE=10
E_BAD_SYNTAX=20
E_BAD_INPUT=30
E_OH_SNAP=255

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN_DIR="${HERE}/../bin"
TMP_FILE="/tmp/$(uuidgen)"
test_number=1

echo
echo "$0"
