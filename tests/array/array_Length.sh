#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared, core, and namespace.
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/array.sh"


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Simple test for the length calculation
  new_test "Sending the basics to get a length: "
  temp=('one' 'two' 'three' 'four elements' $'fifth\nelement')
  [ $( array_Length -a 'temp' ) -eq 5 ]   || fail 1
  pass

  # -- 2 -- Sending value back by reference instead
  new_test "Sending value back by reference: "
  temp=('one' 'two' 'three' 'four elements' $'fifth\nelement')
  count=0
  array_Length -a 'temp' -R 'count'       || fail 1
  [ ${count} -eq 5 ]                      || fail 2
  pass

  # -- 3 -- Purposely trying to fail
  new_test "Failing to send array name on purpose: "
  temp=('one' 'two' 'three' 'four elements' $'fifth\nelement')
  array_Length 2>/dev/null                && fail 1
  pass

  # -- 4 -- Specifying -R without a name
  new_test "Sending -R but leaving arguement blank, should fail: "
  temp=('one' 'two' 'three' 'four elements' $'fifth\nelement')
  array_Length -a 'temp' -R 2>/dev/null   && fail 1
  pass

  # -- 5 -- Long opts should work
  new_test "Using long option (--array) instead of -a: "
  temp=('one' 'two' 'three' 'four elements' $'fifth\nelement')
  [ $( array_Length --array 'temp' ) -eq 5 ]  || fail 1
  pass


  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

