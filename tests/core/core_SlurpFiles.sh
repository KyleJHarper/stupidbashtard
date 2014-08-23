#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"

function dummy {
  # Placeholder to ensure nested piping works
  local _DATA=''
  local -a files=("$@")
  core_SlurpFiles "${files[@]}" || return 1
  echo -e "${_DATA}"
  return 0
}


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
echo 'this is a test 1' > /tmp/core_SlurpFiles--test1
echo 'this is a test 2' > /tmp/core_SlurpFiles--test2
echo 'this is a test 3' > /tmp/core_SlurpFiles--test3
echo 'this is a test 4' > "/tmp/core SlurpFiles with spaces"
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Try reading a single file
  new_test 'Trying to read a single file: '
  [ "$(dummy '/tmp/core_SlurpFiles--test1')" == $'this is a test 1' ] || fail 1
  pass

  # -- 2 -- Sending multiple files should work
  new_test 'Reading from multiple files should "mash" them together: '
  [ "$(dummy '/tmp/core_SlurpFiles--test1' '/tmp/core_SlurpFiles--test2' '/tmp/core_SlurpFiles--test3')" == $'this is a test 1\nthis is a test 2\nthis is a test 3' ] || fail 1
  pass

  # -- 3 -- Files with spaces should be ok
  new_test "Files with spaces shouldn't be a problem: "
  [ "$(dummy '/tmp/core_SlurpFiles--test1' '/tmp/core SlurpFiles with spaces')" = $'this is a test 1\nthis is a test 4' ] || fail 1
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

