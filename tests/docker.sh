#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. __shared.inc.sh

# Variables
cmd=''
d="${BIN_DIR}/docker.pl"
dt="${d} -t"





###########
#  Tests  #
###########

# Table of Contents
#   1.  docker.pl


# +-------------------------#
# |  Section 1.  docker.pl  |
# +-------------------------#
#
# No switches should give basic test output
#
cmd="${dt}"
new_test "Invoking with no options: "
$cmd >/dev/null 2>/dev/null || fail 1
pass


#
# Does verbose work?  Should always give 2 lines of output when verbose.
#
cmd="${dt} -v"
new_test "Enabling verbosity: "
[ $($cmd | wc -l) -gt 2 ] || fail 1
pass


#
# Does quiet work?
#
cmd="${dt} -q"
new_test "Enabling the quiet switch: "
[[ "$($cmd)" == "" ]] || fail 1
pass


#
# Specifying verbose and quiet should give an error
#
cmd="${dt} -q -v"
new_test "Using conflicting switches -v and -q: "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_BAD_SYNTAX} ] || fail 1
pass


#
# Testing with a non-existent file
#
cmd="${dt} Idonotexist"
new_test "Running against a non-existent file: "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail 1
pass


#
# Testing with a file I cannot read (unless this is running as root)
#
cmd="${dt} ${TMP_FILE}"
new_test "Running against a file I cannot read: "
touch ${TMP_FILE}          || fail 1
chmod 0000 ${TMP_FILE}     || fail 2
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail 3
chmod 0600 ${TMP_FILE}     || fail 4
rm ${TMP_FILE}             || fail 5
pass


#
# Specify a NAMESPACES dir that either doesn't exist or is unreadable
#
cmd="${dt} /I/do/not/exist"
new_test "Using a non-existent NAMESPACES_DIR: "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail 1
pass


#
# Specify a document directory that I don't have write permission to.
#
cmd="${dt} /I/do/not/exist"
new_test "Using a  non-existent DOC_DIR: "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_IO_FAILURE} ] || fail 1
pass


#
# Generate the test_function yaml file and make sure the MD5 matches.
#
cmd="${d} ../sbt/test_function.sh"
KNOWN_SUM='bd34d83ef1f1ef55aa6aa4d3b789b5ea'
new_test "Analyzing a complete function and comparing known MD5 of YAML file.  Includes most features and edge cases: "
$cmd >/dev/null 2>/dev/null
[ $? -eq ${E_GOOD} ] || fail 1
[[ "$( grep -P '^[^#]' ../doc/test_function.yaml | md5sum | cut -d' ' -f1 )" == "${KNOWN_SUM}" ]] || fail 2
pass
