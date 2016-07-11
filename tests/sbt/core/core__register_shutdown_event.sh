#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.
# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../sbt/core.sh"


# Special variable to reset PATH for multiple iterations
ORIGINAL_PATH="${PATH}"


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 --  Existing registry entries.
  new_test "Core should have already loaded the removal of the sbt dir: "
  [ -d "${__SBT_TMP_DIR}" ]                                          || fail 1
  [ "${__SBT_SHUTDOWN_REGISTRY[0]}" == "rm -r '${__SBT_TMP_DIR}'" ]  || fail 2
  pass

  # -- 2 --  Nesting double quotes.
  new_test "Double quotes should be nest-able when sent properly: "
  touch /tmp/core__register_shutdown_event_1.tmp                                          || fail 1
  core__register_shutdown_event "rm \"/tmp/core__register_shutdown_event_1.tmp\""         || fail 2
  [ "${__SBT_SHUTDOWN_REGISTRY[1]}" == 'rm "/tmp/core__register_shutdown_event_1.tmp"' ]  || fail 3
  pass

  # -- 3 --  Duplicates shouldn't be allowed by default.
  new_test "Duplicates are disallowed by default, but don't throw errors: "
  core__register_shutdown_event "rm \"/tmp/core__register_shutdown_event_1.tmp\""  || fail 1
  [ ${#__SBT_SHUTDOWN_REGISTRY[@]} -eq 2 ]                                         || fail 2
  [ -z "${__SBT_SHUTDOWN_REGISTRY[2]}" ]                                           || fail 3
  pass

  # -- 4 -- The -e switch should throw an error.
  new_test "Duplicates should throw an error if -e or --error-on-duplicates: "
  core__register_shutdown_event -e "rm \"/tmp/core__register_shutdown_event_1.tmp\""                    && fail 1
  core__register_shutdown_event --error-on-duplicate "rm \"/tmp/core__register_shutdown_event_1.tmp\""  && fail 2
  [ ${#__SBT_SHUTDOWN_REGISTRY[@]} -eq 2 ]                                                              || fail 3
  [ -z "${__SBT_SHUTDOWN_REGISTRY[2]}" ]                                                                || fail 4
  [ -z "${__SBT_SHUTDOWN_REGISTRY[3]}" ]                                                                || fail 5
  pass

  # -- 5 --  Using -d should allow duplicates
  new_test "Duplicates are allowed if -d or --duplicates is sent: "
  core__register_shutdown_event -d "rm \"/tmp/core__register_shutdown_event_1.tmp\""            || fail 1
  core__register_shutdown_event --duplicates "rm \"/tmp/core__register_shutdown_event_1.tmp\""  || fail 2
  [ ${#__SBT_SHUTDOWN_REGISTRY[@]} -eq 4 ]                                                      || fail 3
  [ "${__SBT_SHUTDOWN_REGISTRY[2]}" == 'rm "/tmp/core__register_shutdown_event_1.tmp"' ]        || fail 4
  [ "${__SBT_SHUTDOWN_REGISTRY[3]}" == 'rm "/tmp/core__register_shutdown_event_1.tmp"' ]        || fail 5
  pass

  # -- 6 --  Bad options should fail.
  new_test "Bad options should result in an error: "
  core__register_shutdown_event -x "nope" 2>/dev/null                                     && fail 1
  [ ${#__SBT_SHUTDOWN_REGISTRY[@]} -eq 4 ]                                                || fail 2
  [ "${__SBT_SHUTDOWN_REGISTRY[2]}" == 'rm "/tmp/core__register_shutdown_event_1.tmp"' ]  || fail 3
  [ "${__SBT_SHUTDOWN_REGISTRY[3]}" == 'rm "/tmp/core__register_shutdown_event_1.tmp"' ]  || fail 4
  [ -z "${__SBT_SHUTDOWN_REGISTRY[4]}" ]                                                  || fail 5
  pass

  # -- 7 -- Blank commands shouldn't be allowed.
  new_test "Blank commands shouldn't be allowed to be entered: "
  core__register_shutdown_event '' 'rm /tmp/not_real' '' 2>/dev/null  && fail 1
  pass

  # -- 8 -- Multiple commands are OK.
  new_test "Multiple commands should be storeable and in order: "
  unset __SBT_SHUTDOWN_REGISTRY
  declare -a __SBT_SHUTDOWN_REGISTRY=("rm -r '${__SBT_TMP_DIR}'")
  core__register_shutdown_event 'touch "/tmp/core__register_shutdown_event_1.tmp"' 'rm "/tmp/core__register_shutdown_event_1.tmp"'  || fail 1
  [ ${#__SBT_SHUTDOWN_REGISTRY[@]} -eq 3 ]                                                                                          || fail 2
  [ "${__SBT_SHUTDOWN_REGISTRY[1]}" == 'touch "/tmp/core__register_shutdown_event_1.tmp"' ]                                         || fail 3
  [ "${__SBT_SHUTDOWN_REGISTRY[2]}" == 'rm "/tmp/core__register_shutdown_event_1.tmp"' ]                                            || fail 4
  pass


  # Clean up.
  [ -f /tmp/core__register_shutdown_event_1.tmp ] && rm /tmp/core__register_shutdown_event_1.tmp
  unset __SBT_SHUTDOWN_REGISTRY
  declare -a __SBT_SHUTDOWN_REGISTRY=("rm -r '${__SBT_TMP_DIR}'")
  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

