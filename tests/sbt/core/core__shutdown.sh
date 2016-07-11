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
  new_test "Processing the default registry, this should clear it out: "
  [ -d "${__SBT_TMP_DIR}" ]                                          || fail 1
  [ "${__SBT_SHUTDOWN_REGISTRY[0]}" == "rm -r '${__SBT_TMP_DIR}'" ]  || fail 2
  core__shutdown                                                     || fail 3
  [ "${__SBT_SHUTDOWN_REGISTRY[*]}" == '' ]                          || fail 4
  [ ${#__SBT_SHUTDOWN_REGISTRY[@]} -eq 0 ]                           || fail 5
  pass

  # -- 2 --  Load several events, in order.
  new_test "We should be able to load several events in order: "
  core__register_shutdown_event "touch /tmp/core__shutdown_1.tmp"                || fail 1
  core__register_shutdown_event "rm    /tmp/core__shutdown_1.tmp"                || fail 2
  core__register_shutdown_event "echo 'data' > /tmp/core__shutdown_2.tmp"        || fail 3
  core__register_shutdown_event "echo 'more data' >> /tmp/core__shutdown_2.tmp"  || fail 4
  core__register_shutdown_event "rm /tmp/core__shutdown_2.tmp"                   || fail 5
  core__shutdown                                                                 || fail 6
  pass

  # -- 3 -- Multiple invocations should still be ordered.
  new_test "Multiple invocations should produce ordered results: "
  core__register_shutdown_event "touch /tmp/core__shutdown_1.tmp"                || fail 1
  core__shutdown                                                                 || fail 2
  [ -f '/tmp/core__shutdown_1.tmp' ]                                             || fail 3
  core__register_shutdown_event "rm    /tmp/core__shutdown_1.tmp"                || fail 4
  core__shutdown                                                                 || fail 5
  [ -f '/tmp/core__shutdown_1.tmp' ]                                             && fail 6
  core__register_shutdown_event "echo 'data' > /tmp/core__shutdown_2.tmp"        || fail 7
  core__shutdown                                                                 || fail 8
  [ -f '/tmp/core__shutdown_2.tmp' ]                                             || fail 9
  grep -q -P '^data$' /tmp/core__shutdown_2.tmp                                  || fail 10
  [ $(wc -l </tmp/core__shutdown_2.tmp) -eq 1 ]                                  || fail 11
  core__register_shutdown_event "echo 'more data' >> /tmp/core__shutdown_2.tmp"  || fail 12
  core__shutdown                                                                 || fail 13
  [ -f '/tmp/core__shutdown_2.tmp' ]                                             || fail 14
  grep -q -P '^more data$' /tmp/core__shutdown_2.tmp                             || fail 15
  [ $(wc -l </tmp/core__shutdown_2.tmp) -eq 2 ]                                  || fail 16
  core__register_shutdown_event "rm /tmp/core__shutdown_2.tmp"                   || fail 17
  core__shutdown                                                                 || fail 18
  [ -f '/tmp/core__shutdown_2.tmp' ]                                             && fail 19
  pass

  # -- 4 --  True/false options
  new_test "Options -a/--abort-on-error and -e/--empty-ok require 'true' or 'false': "
  core__shutdown -a 'nope' 2>/dev/null  && fail 1
  [ $? -eq 1 ]                          || fail 2
  core__shutdown -e 'nope' 2>/dev/null  && fail 3
  [ $? -eq 1 ]                          || fail 4
  pass

  # -- 5 --  Empty commands should be OK by default.
  new_test "Empty commands shouldn't be considered an error by default: "
  core__register_shutdown_event "touch /tmp/core__shutdown_3.tmp"    || fail 1
  core__register_shutdown_event "rm /tmp/core__shutdown_3.tmp"       || fail 2
  __SBT_SHUTDOWN_REGISTRY[2]=""                                      || fail 3
  core__shutdown                                                     || fail 4
  pass

  # -- 6 --  If empty commands aren't allowed, error.
  new_test "Empty commands with -e/--empty-ok=false should error out: "
  core__register_shutdown_event "touch /tmp/core__shutdown_3.tmp"    || fail 1
  core__register_shutdown_event "rm /tmp/core__shutdown_3.tmp"       || fail 2
  __SBT_SHUTDOWN_REGISTRY[2]=""                                      || fail 3
  core__shutdown -e false                                            && fail 4
  pass

  # -- 7 -- Failed commands.
  new_test "A failed command should return non-zero but still clear the registry by default: "
  core__register_shutdown_event "touch /tmp/core__shutdown_3.tmp"    || fail 1
  core__register_shutdown_event "rm /tmp/core__shutdown_3.tmp"       || fail 2
  core__register_shutdown_event "rm /tmp/not_a_real_file"            || fail 3
  core__shutdown 2>/dev/null                                         && fail 4
  [ $? -eq 15 ]                                                      || fail 5
  [ ${#__SBT_SHUTDOWN_REGISTRY[@]} -eq 0 ]                           || fail 6
  pass

  # -- 8 -- Failed commands.
  new_test "With -a/--abort-on-error, a failed command should bail early and leave the registry untouched: "
  core__register_shutdown_event "touch /tmp/core__shutdown_3.tmp"    || fail 1
  core__register_shutdown_event "rm /tmp/core__shutdown_3.tmp"       || fail 2
  core__register_shutdown_event "rm /tmp/not_a_real_file"            || fail 3
  core__shutdown --abort-on-error true 2>/dev/null                   && fail 4
  [ $? -eq 14 ]                                                      || fail 5
  [ ${#__SBT_SHUTDOWN_REGISTRY[@]} -eq 3 ]                           || fail 6
  unset __SBT_SHUTDOWN_REGISTRY
  declare -a __SBT_SHUTDOWN_REGISTRY="rm -r '${__SBT_TMP_DIR}'"
  pass

  # -- 9 -- Empty commands with abort enabled should short-circuit.
  new_test "With -a/--abort-on-error true and -e/--empty-ok true, empty commands should bail early and leave the registry untouched: "
  core__register_shutdown_event "touch /tmp/core__shutdown_3.tmp"    || fail 1
  core__register_shutdown_event "rm /tmp/core__shutdown_3.tmp"       || fail 2
  __SBT_SHUTDOWN_REGISTRY[2]=""                                      || fail 3
  core__shutdown --abort-on-error true --empty-ok false 2>/dev/null  && fail 4
  [ $? -eq 14 ]                                                      || fail 5
  [ ${#__SBT_SHUTDOWN_REGISTRY[@]} -eq 3 ]                           || fail 6
  unset __SBT_SHUTDOWN_REGISTRY
  declare -a __SBT_SHUTDOWN_REGISTRY="rm -r '${__SBT_TMP_DIR}'"
  pass


  # Clean up / Reset.
  unset __SBT_SHUTDOWN_REGISTRY
  declare -a __SBT_SHUTDOWN_REGISTRY="rm -r '${__SBT_TMP_DIR}'"
  mkdir "${__SBT_TMP_DIR}"
  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

