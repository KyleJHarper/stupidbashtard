#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"

function dummy {
  # Placeholder to ensure nested piping works
  local DATA=''
  local -a files=("$@")
  core_SlurpFiles "${files[@]}" || return 1
  echo -e "${DATA}"
  return 0
}


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
echo 'this is a test' > /tmp/core_SlurpFiles--test1
echo 'this is a test' > /tmp/core_SlurpFiles--test2
echo 'this is a test' > /tmp/core_SlurpFiles--test3
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Try reading a single file
  new_test 'Trying to read a single file: '
  [ "$(dummy '/tmp/core_SlurpFiles--test1')" == $'this is a test' ] || fail 1
  pass

  # -- 2 -- Sending multiple files should work
  new_test 'Reading from multiple files should "mash" them together: '
  [ "$(dummy '/tmp/core_SlurpFiles--test1' '/tmp/core_SlurpFiles--test2' '/tmp/core_SlurpFiles--test3')" == $'this is a test\nthis is a test\nthis is a test' ] || fail 1
  pass


  let iteration++
done
rm /tmp/core_SlurpFiles--test1
rm /tmp/core_SlurpFiles--test2
rm /tmp/core_SlurpFiles--test3


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

