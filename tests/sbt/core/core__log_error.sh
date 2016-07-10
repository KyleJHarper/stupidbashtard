#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../sbt/core.sh"


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Can we send a message (redirected to dev null) without getting a non-zero code?
  new_test "Sending a message to std err.  This should result in 1 line: "
  [ $( core__log_error 'rawr' 2>&1 | wc -l ) -eq 1 ]   || fail 1
  pass

  # -- 2 -- The -n switch should change the output
  new_test "Sending the '-n' switch, preventing a newline.  This should result in 0 lines: "
  [ $( core__log_error -n 'rawr' 2>&1 | wc -l ) -eq 0 ]  || fail 1
  pass

  # -- 3 -- The -e switch will allow interpretation of escapes.  Going to put several lines in
  new_test "Sending the '-e' switch, adding newlines.  This will result in 4 lines: "
  [ $( core__log_error -e 'rawr\n\n\n' 2>&1 | wc -l ) -eq 4 ]  || fail 1
  pass

  # -- 4 -- The -n and -e switches combined should work.  Going to put one line in to match MD5 from test 1
  new_test "Sending the '-e' to send newline and '-n' to remove one.  Should mimic test 1: "
  [ $( core__log_error -n -e 'rawr\n' 2>&1 | wc -l ) -eq 1 ]  || fail 1
  pass

  # -- 5 -- The -n and -e switches combined should work.  Going to put 5 lines in this time to match MD5 from test 3
  new_test "Sending the '-e' to send 4 newlines and '-n' to remove auto-newline.  Should match test 3: "
  [ $( core__log_error -n -e 'rawr\n\n\n\n' 2>&1 | wc -l ) -eq 4 ]  || fail 1
  pass

  # -- 6 -- Multiple strings to the function should work because of internally handled __SBT_NONOPT_ARGS
  new_test "Sending 3 different arguments and newlines.  Should be combined into 4 lines: "
  [ $( core__log_error -n -e 'rawr\n' 'hello\n' 'whee\n\n' 2>&1 | wc -l ) -eq 4 ]  || fail 1
  pass

  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

