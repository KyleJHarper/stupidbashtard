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
  [ "$(string_Reverse 'hello')" == 'olleh' ] || fail 1
  pass

  # -- 2 -- Multiple lines should be fine
  new_test "Sending a multi-line string and breaking into an array: "
  declare -a lines
  while IFS=$'\n' read -r line ; do lines+=("${line}") ; done < <(string_Reverse $'hello\nthere\nmommy')
  [ ${#lines[@]} -eq 3 ] || fail 1
  [ "${lines[0]}" == 'olleh' ] || fail 2
  [ "${lines[1]}" == 'ereht' ] || fail 3
  [ "${lines[2]}" == 'ymmom' ] || fail 4
  unset lines
  pass

  # -- 3 -- Storing by reference to ensure it works
  new_test "Storing output by reference: "
  rv=''
  string_Reverse -R 'rv' 'hello'
  [ "${rv}" == 'olleh' ] || fail 1
  rv=''
  string_Reverse $'hello\nthere\nmommy' -R 'rv'
  declare -a lines
  while IFS=$'\n' read -r line ; do lines+=("${line}") ; done <<< "${rv}"
  [ ${#lines[@]} -eq 3 ]       || fail 2
  [ "${lines[0]}" == 'olleh' ] || fail 3
  [ "${lines[1]}" == 'ereht' ] || fail 4
  [ "${lines[2]}" == 'ymmom' ] || fail 5
  unset lines
  pass

  # -- 4 -- Read from files, because we can.
  new_test "Reading from a file instead of parameters: "
  echo -e "hello\nthere\nmommy" >/tmp/string_Reverse
  rv=''
  string_Reverse -R 'rv' -f /tmp/string_Reverse
  declare -a lines
  while IFS=$'\n' read -r line ; do lines+=("${line}") ; done <<< "${rv}"
  [ ${#lines[@]} -eq 3 ]       || fail 1
  [ "${lines[0]}" == 'olleh' ] || fail 2
  [ "${lines[1]}" == 'ereht' ] || fail 3
  [ "${lines[2]}" == 'ymmom' ] || fail 4
  unset lines
  rm /tmp/string_Reverse
  pass


  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

