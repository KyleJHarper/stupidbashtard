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
  # -- 1 -- Support case toggling items
  new_test "Sending multiple items for toggling case (e.g.: I am FUn == i AM fuN): "
  [ "$( string_ToggleCase $'Hello\nthere ' $'Joe\tSchmoe '  'RAWR'  )" == $'hELLO\nTHERE jOE\tsCHMOE rawr' ]   || fail 1
  pass

  # -- 2 -- Options sent to this should go to string_FormatCase
  new_test "Sending options supported by the back-end function string_FormatCase (like -R): "
  rv=''
  string_ToggleCase -R rv 'RAwr' || fail 1
  [ "${rv}" == "raWR" ]          || fail 2
  pass

  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi
