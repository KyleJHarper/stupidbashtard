#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared, core, and namespace.
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/string.sh"


[ "${1}" == 'performance' ] && iteration=1
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Support case toggling items
  new_test "Sending multiple items for toggling case (e.g.: I am FUn == i AM fuN): "
  [ "$( string_ToggleCase $'Hello\nthere ' $'Joe\tSchmoe '  'RAWR'  )" == $'hELLO\nTHERE jOE\tsCHMOE rawr' ]   || fail 1
  pass


  let iteration++
done
