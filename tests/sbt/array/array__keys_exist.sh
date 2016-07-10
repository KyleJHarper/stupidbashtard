#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared, core, and namespace.
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../sbt/core.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../sbt/array.sh"


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
declare -a myArray=('one' 'two has spaces' 'three' 'four' 'five space' 'six' 'seven')
declare -A myAssoc=(['one']='orange' ['two']='apple seeds' ['three']='grapes' ['fourth element']='ok now')
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Simple test to find keys.
  new_test "Trying to find known (and known-absent) keys: "
  array__keys_exist -a 'myArray' '0'           || fail 1
  array__keys_exist -a 'myArray' '0' '1'       || fail 2
  array__keys_exist -a 'myArray' '8'           && fail 3
  [ $? -eq 2 ]                                 || fail 4
  array__keys_exist -a 'myArray' '0' '8'       && fail 5
  array__keys_exist -a 'myArray' --any '0' '8' || fail 6
  pass

  # -- 2 -- Long options should work.
  new_test "Long options should work: "
  array__keys_exist --array 'myArray' '0' || fail 1
  pass

  # -- 3 -- Associative arrays.
  new_test "Associative arrays should work fine too: "
  array__keys_exist -a 'myAssoc' 'one'               || fail 1
  array__keys_exist -a 'myAssoc' 'one' 'two'         || fail 2
  array__keys_exist -a 'myAssoc' 'eight'             && fail 3
  [ $? -eq 2 ]                                       || fail 4
  array__keys_exist -a 'myAssoc' 'one' 'eight'       && fail 5
  array__keys_exist -a 'myAssoc' --any 'one' 'eight' || fail 6
  pass

  # -- 4 -- Either -a or --array should be sent.
  new_test "Option -a or --array should be sent: "
  array__keys_exist 'one' 2>/dev/null  && fail 1
  [ $? -eq 1 ]                         || fail 2
  pass

  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

