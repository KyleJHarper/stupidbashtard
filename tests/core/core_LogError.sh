#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"


[ "${1}" == 'performance' ] && iteration=1
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- Can we send a message (redirected to dev null) without getting a non-zero code?
  new_test "Sending a message to std err.  This should result in 1 line: "
  [ $( core_LogError 'rawr' 2>&1 | wc -l ) -eq 1 ]   || fail 1
  pass


  # -- The -n switch should change the output
  new_test "Sending the '-n' switch, preventing a newline.  This should result in 0 lines: "
  [ $( core_LogError -n 'rawr' 2>&1 | wc -l ) -eq 0 ]  || fail 1
  pass


  # -- The -e switch will allow interpretation of escapes.  Going to put several lines in
  new_test "Sending the '-e' switch, adding newlines.  This will result in 4 lines: "
  [ $( core_LogError -e 'rawr\n\n\n' 2>&1 | wc -l ) -eq 4 ]  || fail 1
  pass


  # -- The -n and -e switches combined should work.  Going to put one line in to match MD5 from test 1
  new_test "Sending the '-e' to send newline and '-n' to remove one.  Should mimic test 1: "
  [ $( core_LogError -n -e 'rawr\n' 2>&1 | wc -l ) -eq 1 ]  || fail 1
  pass


  # -- The -n and -e switches combined should work.  Going to put 5 lines in this time to match MD5 from test 3
  new_test "Sending the '-e' to send 4 newlines and '-n' to remove auto-newline.  Should match test 3: "
  [ $( core_LogError -n -e 'rawr\n\n\n\n' 2>&1 | wc -l ) -eq 4 ]  || fail 1
  pass


  # -- Multiple strings to the function should work because of internally handled __SBT_NONOPT_ARGS
  new_test "Sending 3 different arguments and newlines.  Should be combined into 4 lines: "
  [ $( core_LogError -n -e 'rawr\n' 'hello\n' 'whee\n\n' 2>&1 | wc -l ) -eq 4 ]  || fail 1
  pass

  let iteration++
done
