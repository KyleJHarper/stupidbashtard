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
  [ "$(string_CountOf -a '123456789')" -eq 9 ] || fail 1
  pass

  # -- 2 -- Make sure a regex pattern works
  new_test "Using a custom regex pattern to ensure it passes correctly: "
  [ "$(string_CountOf -p '[\s\S]' '123456789')" -eq 9 ] || fail 1
  pass

  # -- 3 -- Reading files should work
  myuuid="/tmp/$(uuidgen)"
  myuuid2="/tmp/$(uuidgen)"
  echo -n '123456789' > "${myuuid}"
  echo -n '123456789' > "${myuuid2}"
  new_test "Reading a file (or files, or files + STDIN) should work: "
  [ "$(string_CountOf -a -f "${myuuid}")" -eq 9 ]                               || fail 1
  [ "$(string_CountOf -a -f "${myuuid}" -f "${myuuid2}")" -eq 18 ]              || fail 2
  [ "$(string_CountOf -a -f "${myuuid}" '123456789')" -eq 18 ]                  || fail 3
  [ "$(string_CountOf -a -f "${myuuid}" -f "${myuuid2}" '1234567890')" -eq 28 ] || fail 4
  pass

  # -- 4 -- Long options should work
  new_test "Long options should work: "
  [ "$(string_CountOf --all '123456789')" -eq 9 ]                                          || fail 1
  [ "$(string_CountOf --pattern '[\s\S]' '123456789')" -eq 9 ]                             || fail 2
  [ "$(string_CountOf --all --file "${myuuid}" --file "${myuuid2}" '1234567890')" -eq 28 ] || fail 3
  pass

  # -- 5 -- ByRef storage
  new_test "Storing byref should work (-R): "
  myvar=1
  string_CountOf --all --file "${myuuid}" --file "${myuuid2}" '1234567890' -R 'myvar'
  [ ${myvar} -eq 28 ] || fail 1
  pass


  # -- 6 -- Make sure searching for a different regex pattern will work.
  new_test "Searching for a different regex pattern instead of all chars: "
  myvar=1
  string_CountOf --pattern '[0-9]{3}' --file "${myuuid}" --file "${myuuid2}" '123456' -R 'myvar'
  [ ${myvar} -eq 8 ] || fail 1
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

