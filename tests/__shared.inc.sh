#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

function pass {
  local ESC="\e["
  local GREEN_F="${ESC}1;32m"
  local NORM="${ESC}0m"
  echo -e "${GREEN_F}SUCCESS${NORM}"
  return 0
}

function fail {
  local ESC="\e["
  local RED_F="${ESC}1;31m"
  local NORM="${ESC}0m"
  echo -e "${RED_F}FAILURE (item $1)${NORM}"
  exit 1
}

function new_test {
  let test_number++
  printf '%-11s%6s%-s' "    * (Test " "${function_number}.${test_number})" "  $1"
  return 0
}

function new_function {
  test_number=0
  let function_number++
  echo ''
  echo "  --- $1"
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
test_number=0
function_number=0

echo
echo "$0"
