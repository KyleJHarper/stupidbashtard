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
  [ "$(string_TrimLeft -c '_' '_______some string')" == 'some string' ]  || fail 1
  pass

  # -- 2 -- Saving results in reference variable
  new_test "Storing results in reference variable: "
  rv=''
  string_TrimLeft -c '+' '++++some_string+++' -R 'rv'
  [ "${rv}" == 'some_string+++' ] || fail 1
  pass

  # -- 3 -- Reading from a file for kicks.
  new_test "Reading data from a file just because: "
  echo '++++some_string++++' >/tmp/string_TrimLeft.tmp
  [ "$(string_TrimLeft -c '+' -f '/tmp/string_TrimLeft.tmp')" == 'some_string++++' ]  || fail 1
  pass
  rm /tmp/string_TrimLeft.tmp

  # -- 4 -- Defaults shouldn't change
  new_test "Trim's character and direction have defaults, ensuring they persist: "
  [ "$(string_TrimLeft '   some_string   ')" == 'some_string   ' ]  || fail 1
  pass

  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  let "TPS   = ${test_number} / (${TOTAL} / 1000)"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi
