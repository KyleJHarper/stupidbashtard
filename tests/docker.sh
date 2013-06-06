#!/bin/bash

# --
# -- Functions
# --
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
  echo -e "${RED_F}FAILURE:  ${cmd}${NORM}"
  exit 1
}

# Vars
E_GOOD=0
E_GENERIC=1
E_IO_FAILURE=10
E_BAD_SYNTAX=20

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN_DIR="${HERE}/../bin"
TMP_FILE='/tmp/test_docker_file'
cmd=''
dt="${BIN_DIR}/docker.pl -t"

# -- TEST PARAMETERS -- #
# 1. A message to STDOUT
# 2. A message to STDOUT only when -v present


# No switches should give basic test output
cmd="${dt}"
echo -n 'Testing no options:  '
$cmd >/dev/null 2>/dev/null || fail
pass

# Does verbose work?  Should always give 2 lines of output when verbose.
cmd="${dt} -v"
echo -n 'Testing verbosity:  '
[ $($cmd | wc -l) -eq 2 ] || fail
pass

# Does quiet work?
cmd="${dt} -q"
echo -n 'Testing the quiet switch:  '
[[ "$($cmd)" == "" ]] || fail
pass

# Specifying verbose and quiet should give an error
cmd="${dt} -q -v"
echo -n 'Testing conflicting switches -v and -q:  '
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_GENERIC} ] || fail
pass

# Testing with a non-existent file
cmd="${dt} Idonotexist"
echo -n 'Testing with a non-existent file:  '
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
pass

# Testing with a file I cannot read (unless this is running as root)
cmd="${dt} ${TMP_FILE}"
echo -n 'Testing with a file I cannot read:  '
touch ${TMP_FILE}          || fail
chmod 0000 ${TMP_FILE}     || fail
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
chmod 0600 ${TMP_FILE}     || fail
rm ${TMP_FILE}             || fail
pass

# Specify a LIB dir that either doesn't exist or is unreadable
cmd="${dt} /I/do/not/exist"
echo -n 'Testing with a non-existent LIB_DIR:  '
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
pass

# Specify a document directory that I don't have write permission to.
cmd="${dt} /I/do/not/exist"
echo -n 'Testing with a non-existent DOC_DIR:  '
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
pass

