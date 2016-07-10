#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../sbt/core.sh"


__SBT_VERBOSE=true
# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Can we send a message (redirected to dev null) without getting a non-zero code?
  new_test "Sending a message to std err.  This should result in 1 line: "
  [ $( core__log_verbose 'rawr' 2>&1 | wc -l ) -eq 1 ]   || fail 1
  pass

  # -- 2 -- The -n switch should change the output
  new_test "Sending the '-n' switch, preventing a newline.  This should result in 0 lines: "
  [ $( core__log_verbose -n 'rawr' 2>&1 | wc -l ) -eq 0 ]  || fail 1
  pass

  # -- 3 -- The -e switch will allow interpretation of escapes.  Going to put several lines in
  new_test "Sending the '-e' switch, adding newlines.  This will result in 4 lines: "
  [ $( core__log_verbose -e 'rawr\n\n\n' 2>&1 | wc -l ) -eq 4 ]  || fail 1
  pass

  # -- 4 -- The -n and -e switches combined should work.  Going to put one line in to match MD5 from test 1
  new_test "Sending the '-e' to send newline and '-n' to remove one.  Should mimic test 1: "
  [ $( core__log_verbose -n -e 'rawr\n' 2>&1 | wc -l ) -eq 1 ]  || fail 1
  pass

  # -- 5 -- The -n and -e switches combined should work.  Going to put 5 lines in this time to match MD5 from test 3
  new_test "Sending the '-e' to send 4 newlines and '-n' to remove auto-newline.  Should match test 3: "
  [ $( core__log_verbose -n -e 'rawr\n\n\n\n' 2>&1 | wc -l ) -eq 4 ]  || fail 1
  pass

  # -- 6 -- Multiple strings to the function should work because of internally handled __SBT_NONOPT_ARGS
  new_test "Sending 3 different arguments and newlines.  Should be combined into 4 lines: "
  [ $( core__log_verbose -n -e 'rawr\n' 'hello\n' 'whee\n\n' 2>&1 | wc -l ) -eq 4 ]  || fail 1
  pass

  # -- 7 -- The function should support -W to signify error event.
  new_test "Sending the -W switch which should make it report as an error: "
  [[ "$(core__log_verbose -W -n -e $'rawr\n' 2>&1)" =~ 'error in main:' ]] || fail 1
  pass

  # -- 8 -- Log file writing must be a real path.
  new_test "Specifying a log file with a bad path should result in an error (code 12): "
  __SBT_LOG_FILE='/this/is/not/real'
  core__log_verbose "Wheeeee data" 2>/dev/null && fail 1
  [ $? -eq 12 ]                                || fail 2
  pass

  # -- 9 -- Log file writing can't use a relative path.
  new_test "Log file must be a fully qualified path, not relative: "
  __SBT_LOG_FILE='relative.log'
  core__log_verbose "Wheeeee data" 2>/dev/null && fail 1
  [ $? -eq 12 ]                                || fail 2

  # -- 10 -- Log file should write properly.
  __SBT_LOG_FILE='/tmp/core__log_verbose__test_8.tmp'
  [ -f "${__SBT_LOG_FILE}" ] && rm "${__SBT_LOG_FILE}"
  core__log_verbose "Wheeeee data"  2>/dev/null                          || fail 1
  core__log_verbose -W "Error data" 2>/dev/null                          || fail 2
  grep -qP '^\(main: [0-9]+\)  Wheeeee data$' "${__SBT_LOG_FILE}"        || fail 3
  grep -qP '^\(error in main: [0-9]+\)  Error data$' "${__SBT_LOG_FILE}" || fail 4
  pass

  let iteration++
done
__SBT_VERBOSE=false


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

