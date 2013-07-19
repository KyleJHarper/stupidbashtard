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
  new_test "Sending a single argument for upper casing: "
  [ "$( string_FormatCase -u 'rawr' )" == 'RAWR' ]   || fail 1
  pass

  # -- Multiple arguments
  new_test "Sending multiple arguments for upper casing: "
  [ "$( string_FormatCase -u 'rawr' 'baby' )" == 'RAWRBABY' ]   || fail 1
  pass

  # -- Argument with newline characters
  new_test "Arguments with newlines should preserve newlines: "
  [ "$( string_FormatCase -u $'hello\nthere' )" == $'HELLO\nTHERE' ]   || fail 1
  pass

  # -- Put info in named var instead
  new_test "Putting return value in a named variable rather than std out: "
  rv=''
  string_FormatCase -u $'hello\nthere' -R rv
  [ "${rv}" == $'HELLO\nTHERE' ] || fail 1
  pass

  # -- Argument with newline characters
  new_test "Arguments with tabs should preserve tabs: "
  [ "$( string_FormatCase -u $'hello\tthere' )" == $'HELLO\tTHERE' ]   || fail 1
  pass

  # -- Pass a lot of arguments and combine in rv
  new_test "Using several arguments to join together.  Storing in rv.  Includes newlines and tabs: "
  rv=''
  string_FormatCase -u $'hello\nthere ' $'joe\tschmoe ' -R rv 'rawr'
  [ "${rv}" == $'HELLO\nTHERE JOE\tSCHMOE RAWR' ] || fail 1
  pass

  # -- Should be able to swallow output and get the same result as test above.
  new_test "Same complex test as above, swallowing output with subshell into rv rather than using -R (by-ref): "
  rv=''
  rv="$(string_FormatCase -u $'hello\nthere ' $'joe\tschmoe '  'rawr')"
  [ "${rv}" == $'HELLO\nTHERE JOE\tSCHMOE RAWR' ] || fail 1
  pass


  let iteration++
done
