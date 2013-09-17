#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"


# Special variable to reset PATH for multiple iterations
ORIGINAL_PATH="${PATH}"


[ "${1}" == 'performance' ] && iteration=1
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- Sending nothing to the command should fail.
  new_test "Calling function without any path info, this should an error message and return non-zero: "
  [ $( core_SetToolPath 2>&1 | wc -l ) -gt 0 ]  ||  fail 1
  core_SetToolPath 2>/dev/null                  &&  fail 2
  pass


  # -- Sending a directory that doesn't exist should fail
  new_test "Sending a non-existent directory, this should return non-zero: "
  [ $( core_SetToolPath '/this/no/exists' 2>&1 | wc -l ) -gt 0 ]  ||  fail 1
  core_SetToolPath '/this/no/exists' 2>/dev/null                  &&  fail 2
  pass


  # -- Sending a valid directory
  new_test "Sending a valid directory, this should prepend to PATH and work: "
  core_SetToolPath "/tmp"                      || fail 1
  [[ "/tmp:${ORIGINAL_PATH}" == "${PATH}" ]]   || fail 2
  PATH="${ORIGINAL_PATH}"
  pass


  let iteration++
done
