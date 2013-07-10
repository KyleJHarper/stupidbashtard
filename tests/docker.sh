#!/bin/bash

# Source shared
. __shared.inc.sh

# Variables
cmd=''
d="${BIN_DIR}/docker.pl"
dt="${d} -t"


###########
#  Tests  #
###########
#
# No switches should give basic test output
#
cmd="${dt}"
echo -n "Test ${test_number}: no options:  "
$cmd >/dev/null 2>/dev/null || fail
pass


#
# Does verbose work?  Should always give 2 lines of output when verbose.
#
cmd="${dt} -v"
echo -n "Test ${test_number}: verbosity:  "
[ $($cmd | wc -l) -gt 2 ] || fail
pass


#
# Does quiet work?
#
cmd="${dt} -q"
echo -n "Test ${test_number}: quiet switch:  "
[[ "$($cmd)" == "" ]] || fail
pass


#
# Specifying verbose and quiet should give an error
#
cmd="${dt} -q -v"
echo -n "Test ${test_number}: conflicting switches -v and -q:  "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_BAD_SYNTAX} ] || fail
pass


#
# Testing with a non-existent file
#
cmd="${dt} Idonotexist"
echo -n "Test ${test_number}: non-existent file:  "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
pass


#
# Testing with a file I cannot read (unless this is running as root)
#
cmd="${dt} ${TMP_FILE}"
echo -n "Test ${test_number}: file I cannot read:  "
touch ${TMP_FILE}          || fail
chmod 0000 ${TMP_FILE}     || fail
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
chmod 0600 ${TMP_FILE}     || fail
rm ${TMP_FILE}             || fail
pass


#
# Specify a NAMESPACES dir that either doesn't exist or is unreadable
#
cmd="${dt} /I/do/not/exist"
echo -n "Test ${test_number}: non-existent NAMESPACES_DIR:  "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
pass


#
# Specify a document directory that I don't have write permission to.
#
cmd="${dt} /I/do/not/exist"
echo -n "Test ${test_number}: non-existent DOC_DIR:  "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail
pass


#
# Generate the test_function yaml file and make sure the MD5 matches.
#
cmd="${d} ../sbt/test_function.sh"
KNOWN_SUM='d76063fc223de7f5aa549b14f672023e'
echo -n "Test ${test_number}: complete function output (YAML file):  "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_GOOD} ] || fail
[[ "$( grep -P '^[^#]' ../doc/test_function.yaml | md5sum | cut -d' ' -f1 )" == "${KNOWN_SUM}" ]] || fail
pass
