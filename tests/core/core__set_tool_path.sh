#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"


# Special variable to reset PATH for multiple iterations
ORIGINAL_PATH="${PATH}"


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 --  Sending nothing to the command should fail.
  new_test "Calling function without any path info, this should an error message and return non-zero: "
  [ $( core__set_tool_path 2>&1 | wc -l ) -gt 0 ]  ||  fail 1
  core__set_tool_path 2>/dev/null                  &&  fail 2
  pass

  # -- 2 -- Sending a directory that doesn't exist should fail
  new_test "Sending a non-existent directory, this should return non-zero: "
  [ $( core__set_tool_path '/this/no/exists' 2>&1 | wc -l ) -gt 0 ]  ||  fail 1
  core__set_tool_path '/this/no/exists' 2>/dev/null                  &&  fail 2
  pass

  # -- 3 -- Sending a valid directory
  new_test "Sending a valid directory, this should prepend to PATH and work: "
  core__set_tool_path "/tmp"                   || fail 1
  [[ "/tmp:${ORIGINAL_PATH}" == "${PATH}" ]]   || fail 2
  PATH="${ORIGINAL_PATH}"
  pass

  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

