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
  # -- 1 -- Find a known program, bash!
  new_test "Trying to find 'bash', any version: "
  core__tool_exists 'bash' || fail 1
  pass

  # -- 2 -- Fail for a program that doesn't exist.
  new_test "Looking for a tool that doesn't exist, should be code 10: "
  core__tool_exists 'not_a_real_tool'  2>/dev/null  && fail 1
  [ $? -eq 10 ]                                     || fail 2
  pass

  # -- 3 -- Minimum version.
  new_test "Specifying a minimum version should work: "
  core__tool_exists -n '3.0'            -r '\d+[.]\d+([.]\d+)?' 'bash'              || fail 1
  core__tool_exists -n '9.0'            -r '\d+[.]\d+([.]\d+)?' 'bash' 2>/dev/null  && fail 2
  [ $? -eq 10 ]                                                                     || fail 3
  core__tool_exists --min-version '3.0' -r '\d+[.]\d+([.]\d+)?' 'bash'              || fail 4
  core__tool_exists --min-version '9.0' -r '\d+[.]\d+([.]\d+)?' 'bash' 2>/dev/null  && fail 5
  [ $? -eq 10 ]                                                                     || fail 6
  pass

  # -- 4 -- Maximum version.
  new_test "Specifying a maximum version should work: "
  core__tool_exists -m '3.0'            -r '\d+[.]\d+([.]\d+)?' 'bash' 2>/dev/null  && fail 1
  [ $? -eq 10 ]                                                                     || fail 2
  core__tool_exists -m '9.0'            -r '\d+[.]\d+([.]\d+)?' 'bash'              || fail 3
  core__tool_exists --max-version '3.0' -r '\d+[.]\d+([.]\d+)?' 'bash' 2>/dev/null  && fail 4
  [ $? -eq 10 ]                                                                     || fail 5
  core__tool_exists --max-version '9.0' -r '\d+[.]\d+([.]\d+)?' 'bash'              || fail 6
  pass

  # -- 5 -- Any Switch
  new_test "The any switch should work if any tools are found (in any order): "
  core__tool_exists 'not_a_real_tool' 'bash' --any >/dev/null   || fail 1
  core__tool_exists 'not_a_real_tool' 'bash' -a    >/dev/null   || fail 2
  core__tool_exists 'bash' 'not_a_real_tool' --any >/dev/null   || fail 3
  core__tool_exists 'bash' 'not_a_real_tool' -a    >/dev/null   || fail 4
  pass

  # -- 6 -- Any should fail if all missing
  new_test "We should still fail with --any if all are missing: "
  core__tool_exists 'not_a_real_tool' 'also_not_real' --any 2>/dev/null   && fail 1
  core__tool_exists 'not_a_real_tool' 'also_not_real' -a    2>/dev/null   && fail 2
  pass

  # -- 7 -- Any should send the first discovered tool.
  new_test "We should get the first matching tool with --any: "
  [ "$(core__tool_exists -a 'bash' 'sort' 'cut')" == 'bash' ]           || fail 1
  [ "$(core__tool_exists -a 'not_real' 'sort' 'cut')" == 'sort' ]       || fail 2
  [ "$(core__tool_exists -a 'not_real' 'still_nope' 'cut')" == 'cut' ]  || fail 3
  pass

  # -- 8 -- Any Switch with Quiet
  new_test "The any switch should suppress output if quiet is flagged: "
  [ "$(core__tool_exists -a -q      'bash' 'sort' 'cut')" == '' ]      || fail 1
  [ "$(core__tool_exists -a --quiet 'not_real' 'sort' 'cut')" == '' ]  || fail 2
  pass

  # -- 9 -- Exact matching should work.
  new_test "Using min and max versions of the same string should be an exact match formula: "
  core__tool_exists -n "${BASH_VERSION}" -m "${BASH_VERSION}" --regex-pattern '\d+[.]\d+[.]\d+\S*-release' 'bash'  || fail 1
  pass

  # -- 10 -- Without any switch we must match all
  new_test "If the --any switch is NOT set, we must match all tools: "
  core__tool_exists 'bash' 'sort' 'cut'             || fail 1
  core__tool_exists 'bash' 'not_real' 2>/dev/null   && fail 2
  pass

  # -- 11 -- The version switch should be selectable.
  new_test "We should be able to specify any type of version switch: "
  core__tool_exists 'awk' -v '-W version'                 || fail 1
  core__tool_exists 'awk' --version-switch '-W version'   || fail 2
  pass

  # -- 12 -- Bad options should return code 2
  new_test "Bad options should result in E_BAD_CLI (code 2): "
  core__tool_exists --bad-switch 2>/dev/null   && fail 1
  [ $? -eq 2 ]                                 || fail 2
  core__tool_exists -b           2>/dev/null   && fail 3
  [ $? -eq 2 ]                                 || fail 4
  core__tool_exists --min-version 2>/dev/null  && fail 5
  [ $? -eq 2 ]                                 || fail 6
  core__tool_exists --any 2>/dev/null          && fail 7
  [ $? -eq 2 ]                                 || fail 8
  pass

  # -- 13 -- LOTS of tools
  new_test "Sending LOTS of tools shouldn't be a problem: "
  core__tool_exists 'bash' 'sort' 'cut' 'shuf' 'head' 'tail' 'uniq'                        || fail 1
  core__tool_exists 'not_real_bash' 'sort' 'cut' 'shuf' 'head' 'tail' 'uniq' 2>/dev/null   && fail 2
  pass

  # -- 14 -- Blank tools should be an error.
  new_test "Sending a blank tool name like '' should fail: "
  core__tool_exists 'bash' '' 2>/dev/null      && fail 1
  [ $? -eq 2 ]                                 || fail 2
  core__tool_exists '' 'bash' '' 2>/dev/null   && fail 3
  [ $? -eq 2 ]                                 || fail 4
  core__tool_exists '' '' 2>/dev/null          && fail 5
  [ $? -eq 2 ]                                 || fail 6
  core__tool_exists '' 2>/dev/null             && fail 7
  [ $? -eq 2 ]                                 || fail 8
  pass


  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

