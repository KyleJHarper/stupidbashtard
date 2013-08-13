#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared, core, and namespace.
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/string.sh"


[ "${1}" == 'performance' ] && iteration=1
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- Support Proper (Title) casing items
  new_test "Sending multiple items for proper (title) casing (e.g.: I Am Some Text): "
  [ "$( string_ProperCase $'heLlo\ntheRE ' $'Joe\tschmoe '  'RAWR'  )" == $'Hello\nThere Joe\tSchmoe Rawr' ]   || fail 1
  pass


  let iteration++
done
