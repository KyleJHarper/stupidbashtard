#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../sbt/core.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../sbt/string.sh"


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Loading should set a flag.
  new_test "Loading the same namespace twice should be an error: "
  [ "${__SBT_NAMESPACES_LOADED[string]}" == 'loaded' ] || fail 1
  pass


  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

