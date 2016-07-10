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
  new_test "Trying to find 'bash', any version. (0.0.0): "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists 'bash'  || fail 1
  pass

  # -- 2 -- Try the short options, all of them!!!
  new_test 'Sending all short switches to ensure they work.  First without exact, then with: '
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists 'bash' -1 4 -2 0 -3 0    -r '\d+\.\d+([.]\d+)?' -v '--version'              || fail 1
  core__tool_exists 'bash' -1 4 -2 0 -3 0 -e -r '\d+\.\d+([.]\d+)?' -v '--version' 2>/dev/null  && fail 2
  pass

  # -- 3 -- Now try long options.
  new_test 'Sending all long switches to ensure they work.  First without exact, then with: '
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists 'bash' --major 4 --medium 0 --minor 0         --regex-pattern '\d+\.\d+([.]\d+)?' --version-switch '--version'              || fail 1
  core__tool_exists 'bash' --major 4 --medium 0 --minor 0 --exact --regex-pattern '\d+\.\d+([.]\d+)?' --version-switch '--version' 2>/dev/null  && fail 2
  pass

  # -- 4 -- Find bash again, but with too high a version.
  new_test "Trying to find 'bash', a version we know is too high. (9.6.2): "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists 'bash' --major=9 --medium=6 --minor=2 2>/dev/null  && fail 1
  pass

  # -- 5 -- Coreutils programs often just announce the coreutils version (eg. 8.13).
  new_test "Checking the 'cut' program output.  Should be corutils and only have x.yy: "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists 'cut' --major=7 || fail 1
  pass

  # -- 6 -- Some programs use special version checking switches, like mawk
  new_test "Overriding --version-switch argument to '-W version' to get awk/nawk/mawk version string: "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists 'awk' --major=1 -v '-W version' || fail 1
  pass

  # -- 7 -- Variable should have tools... otherwise we're missing out on caching.
  new_test "Checking for bash again, to make sure __SBT_TOOL_LIST actually populates: "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists 'bash' --major=4 --medium=0 --minor=0 || fail 1
  [ "${!__SBT_TOOL_LIST[@]}" == 'bash' ]                  || fail 2
  [ ! -z "${__SBT_TOOL_LIST['bash']}" ]                   || fail 3
  core__tool_exists 'perl' --major=4 --medium=0 --minor=0 || fail 4
  core__tool_exists 'cut'  --major=7 --medium=0 --minor=0 || fail 5
  [ ${#__SBT_TOOL_LIST[@]} -eq 3 ]                        || fail 6
  pass

  # -- 8 -- Multiple programs and we need them all.
  new_test "Requiring multiple tools at once: "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists 'bash' 'cut'         || fail 1
  [ ! -z "${__SBT_TOOL_LIST['bash']}" ]  || fail 2
  [ ! -z "${__SBT_TOOL_LIST['cut']}" ]   || fail 3
  [ ${#__SBT_TOOL_LIST[@]} -eq 2 ]       || fail 4
  pass

  # -- 9 -- Multiple programs but only need one
  new_test "Requiring one tool but checking multiple options: "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists --any 'ruroh' 'cut'  1>/dev/null   || fail 1
  [ ! -z "${__SBT_TOOL_LIST['cut']}" ]                 || fail 2
  [ ${#__SBT_TOOL_LIST[@]} -eq 1 ]                     || fail 3
  pass

  # -- 10 -- Multiple programs and none will be found.
  new_test "Checking for multiple tools, with --any, knowing it won't be found: "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists --any 'ruroh' 'raggy'  1>/dev/null && fail 1
  [ $? -eq 10 ] || fail 2
  pass

  # -- 11 -- Unable to find tool should report E_CMD_NOT_FOUND (code 10)
  new_test "Testing a tool known to be missing, code should be 10: "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core__tool_exists 'ruroh' 'raggy' 1>/dev/null 2>/dev/null
  [ $? -eq 10 ] || fail 1
  pass


  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

