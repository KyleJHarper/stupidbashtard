#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Try a normal byref assignment
  new_test "Storing the value 'whee' to the variable 'temp': "
  REF='temp'
  temp='nope'
  core_StoreByRef "${REF}" "whee" || fail 1
  [[ "${temp}" == "whee" ]] || fail 2
  pass

  # -- 2 -- Send something to byref, but we aren't doing byref so it should go to stdout
  new_test "Calling again, but not intending to store by-ref.  Should go to stdout: "
  REF=''
  temp='nope'
  [[ $(core_StoreByRef "${REF}" "whee" || echo "whee") == "whee" ]] || fail 1
  pass

  # -- 3 -- Calling it without any parameters should fail
  new_test "Calling without any parameters.  This should fail:  "
  core_StoreByRef 2>/dev/null && fail 1
  [ $(core_StoreByRef 2>&1 | wc -l) -gt 0 ] || fail 2
  pass

  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

