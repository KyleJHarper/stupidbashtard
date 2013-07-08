#!/bin/bash

# --
# -- Functions
# --
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
  echo -e "${RED_F}FAILURE:  ${cmd}${NORM}"
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
TMP_FILE='/tmp/test_docker_file'
cmd=''
d="${BIN_DIR}/docker.pl"
dt="${d} -t"
test_number=1

# -- TEST PARAMETERS -- #
# 1. A message to STDOUT
# 2. A message to STDOUT only when -v present


# No switches should give basic test output
cmd="${dt}"
echo -n "Test ${test_number}: no options:  "
$cmd >/dev/null 2>/dev/null || fail
pass

# Does verbose work?  Should always give 2 lines of output when verbose.
cmd="${dt} -v"
echo -n "Test ${test_number}: verbosity:  "
[ $($cmd | wc -l) -gt 2 ] || fail
pass

# Does quiet work?
cmd="${dt} -q"
echo -n "Test ${test_number}: quiet switch:  "
[[ "$($cmd)" == "" ]] || fail
pass

# Specifying verbose and quiet should give an error
cmd="${dt} -q -v"
echo -n "Test ${test_number}: conflicting switches -v and -q:  "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_BAD_SYNTAX} ] || fail
pass

# Testing with a non-existent file
cmd="${dt} Idonotexist"
echo -n "Test ${test_number}: non-existent file:  "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
pass

# Testing with a file I cannot read (unless this is running as root)
cmd="${dt} ${TMP_FILE}"
echo -n "Test ${test_number}: file I cannot read:  "
touch ${TMP_FILE}          || fail
chmod 0000 ${TMP_FILE}     || fail
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
chmod 0600 ${TMP_FILE}     || fail
rm ${TMP_FILE}             || fail
pass

# Specify a NAMESPACES dir that either doesn't exist or is unreadable
cmd="${dt} /I/do/not/exist"
echo -n "Test ${test_number}: non-existent NAMESPACES_DIR:  "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
pass

# Specify a document directory that I don't have write permission to.
cmd="${dt} /I/do/not/exist"
echo -n "Test ${test_number}: non-existent DOC_DIR:  "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
pass

# Generate the test_function yaml file and make sure the MD5 matches.
cmd="${d} ../sbt/test_function.sh"
KNOWN_SUM='d76063fc223de7f5aa549b14f672023e'
echo -n "Test ${test_number}: complete function output (YAML file):  "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_GOOD} ] || fail
[[ "$( grep -P '^[^#]' ../doc/test_function.yaml | md5sum | cut -d' ' -f1 )" == "${KNOWN_SUM}" ]] || fail
pass
