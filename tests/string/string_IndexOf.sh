#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared, core, and namespace.
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/string.sh"
core_SetToolPath "$(here)/../lib/tools"


[ "${1}" == 'performance' ] && iteration=1
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do

  # -- Pass all arguments as expected
  new_test "Sending all arguments as required, to simulate a good test: "
  [ $(string_IndexOf -n 'apple' 'I ate an apple yesterday.') -eq 9 ] || fail 1
  pass

  # -- A -1 index doesn't mean a failed function.
  new_test "Making sure not-found items will result in -1, but NOT return code non-zero: "
  [ $(string_IndexOf -n 'orange' 'I ate an apple yesterday.') -eq -1 ] || fail 1
  string_IndexOf -n 'orange' 'I ate an apple yesterday.' 1>/dev/null 2>/dev/null
  [ $? -eq 0 ] || fail 2
  pass

  # -- Should be able to find the Nth occurrence
  new_test "Finding the Nth occurrence should work: "
  [ $(string_IndexOf -n 'apple' -o 2 'I ate an apple yesterday, yes an apple homie.') -eq 33 ] || fail 1
  pass

  # -- 

  let iteration++
done
