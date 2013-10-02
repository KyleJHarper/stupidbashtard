#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared, core, and namespace.
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/string.sh"


[ "${1}" == 'performance' ] && iteration=1
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- Simple invocation with 1 argument
  new_test "Sending a single argument for lower casing: "
  [ "$( string_ToLower 'RAWR' )" == 'rawr' ]   || fail 1
  pass

  # -- Pass all arguments as expected
  new_test "Sending all arguments as required, to simulate a good test: "
  string_IndexOf -p

  let iteration++
done
