#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared, core, and namespace.
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/string.sh"


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Simple invocation with expected parameters
  new_test "Sending expected arguments for a normal usage: "
  [ "$(string__insert -s 'am a ' -i '2' 'I hero')" == 'I am a hero' ]  || fail 1
  pass

  # -- 2 -- Negative index should work as expected
  new_test "Sending expected arguments for a normal usage: "
  [ "$(string__insert -s 'am a ' -i '-2' 'I hero')" == 'I heam a ro' ]  || fail 1
  pass

  # -- 3 -- Saving results in reference variable
  new_test "Storing results in reference variable: "
  rv=''
  string__insert -s 'am a ' -i '2' 'I hero' -R 'rv'
  [ "${rv}" == 'I am a hero' ] || fail 1
  pass

  # -- 4 -- Reading from a file for kicks.
  new_test "Reading data from a file just because: "
  echo 'I hero' >/tmp/string__insert.tmp
  [ "$(string__insert -s 'am a ' -i '2' 'I hero' -f '/tmp/string__insert.tmp')" == 'I am a hero' ]  || fail 1
  pass
  rm /tmp/string__insert.tmp

  # -- 5 -- Defaults shouldn't change
  new_test "Trim's character and direction have defaults, ensuring they persist: "
  [ "$(string__insert -s 'am a ' 'I hero')" == 'am a I hero' ]  || fail 1
  pass

  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi
