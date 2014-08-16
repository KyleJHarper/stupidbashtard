#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared, core, and namespace.
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/string.sh"
core_SetToolPath "$(here)/../lib/tools"


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Use it as expected
  new_test "Sending all arguments as required, to simulate a good test: "
  [ "$(string_Substring -i '4' -l '11' 'The_best_chance_is_now')" == 'best_chance' ] || fail 1
  pass

  # -- 2 -- Don't send a length
  new_test "Not specifying a length, should return the remainder after index: "
  [ "$(string_Substring -i '4' 'The_best_chance_is_now')" == 'best_chance_is_now' ] || fail 1
  pass

  # -- 3 -- Long options
  new_test "Making sure long options work properly: "
  [ "$(string_Substring --index '4' --length '11' 'The_best_chance_is_now')" == 'best_chance' ] || fail 1
  pass

  # -- 4 -- Negative index
  new_test "Sending a negative index, should start from the end of the string and NOT wrap forward: "
  [ "$(string_Substring -i '-4' 'The_best_chance_is_now')" == '_now' ] || fail 1
  pass

  # -- 5 -- Negative length
  new_test "Sending a negative length should work, but has repercussions if boundaries are overflown: "
  [ "$(string_Substring -l '-4' 'The_best_chance_is_now')" == 'The_best_chance_is' ]    || fail 1
  string_Substring -l '-44' 'The_best_chance_is_now' 2>/dev/null 1>/dev/null            && fail 2
  [ "$(string_Substring -i '4' -l '-4' 'The_best_chance_is_now')" == 'best_chance_is' ] || fail 3
  string_Substring -i '20' -l '-4' 'The_best_chance_is_now' 2>/dev/null 1>/dev/null     && fail 4
  string_Substring -i '-3' -l '-4' 'The_best_chance_is_now' 2>/dev/null 1>/dev/null     && fail 5
  [ "$(string_Substring -i '-5' -l '-4' 'The_best_chance_is_now')" == 's' ]             || fail 6
  pass

  # -- 6 -- No options should send a warning, but work
  new_test "Sending no options should work, but give a warning: "
  __SBT_VERBOSE=true
  string_Substring 'The_best_chance_is_now' 2>&1 | grep -q 'Both index and length are zero' || fail 1
  __SBT_VERBOSE=false
  pass

  # -- 7 -- Multiple strings should combine
  new_test "Multiple strings should be 'mashed' together: "
  [ "$(string_Substring -i '4' 'The_best_chance_is_now' '_not_later')" == 'best_chance_is_now_not_later' ] || fail 1
  pass

  # -- 8 -- ByRef should be supported
  new_test "Storing value byref instead of stdout: "
  rawr=''
  string_Substring -R 'rawr' -i '4' 'The_best_chance_is_now' '_not_later' || fail 1
  [ "${rawr}" == 'best_chance_is_now_not_later' ]                         || fail 2
  pass

  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

