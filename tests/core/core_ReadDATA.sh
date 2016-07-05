#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"

function dummy {
  local _data=''
  if [ "${1}" == 'rawr' ] ; then _data='rawr from positional' ; shift ; fi
  core_ReadDATA "$@" || return 1
  echo -e "${_data}"
  return 0
}


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi

# Testing loop
echo 'this is a test' > /tmp/core_ReadDATA--test1
echo 'this is a test' > /tmp/core_ReadDATA--test2
echo 'this is a test' > /tmp/core_ReadDATA--test3
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Positionals
  new_test 'Sending only positionals: '
  [ "$(dummy 'rawr')" == $'rawr from positional' ] || fail 1
  pass

  # -- 2 -- Positionals sent along with STDIN and files should pull positionals first
  new_test 'Sending positionals, STDIN, and files.  Positionals should be read first: '
  [ "$(echo 'this is from stdin' | dummy 'rawr' '/tmp/core_ReadDATA--test3')" == $'rawr from positional' ] || fail 1
  pass

  # -- 3 -- Sending STDIN and files, should read files first
  new_test 'Sending STDIN and files.  Files should be read first: '
  [ "$(echo 'this is from stdin' | dummy '/tmp/core_ReadDATA--test3' '/tmp/core_ReadDATA--test2')" == $'this is a test\nthis is a test' ] || fail 1
  pass

  # -- 4 -- Piping test.  Need a dummy function, because piping to core_SlurpSTDIN direclty puts it in a subshell.  sigh
  new_test 'Piping a command into a dummy function that uses core_ReadDATA: '
  [ "$(echo 'this is a test' | dummy)" == $'this is a test' ] || fail 1
  pass

  # -- 5 -- Herestrings should work, and might be preferred in many cases.
  new_test 'Here-strings should work just fine for STDIN: '
  [ "$(dummy <<<'this is a test')" == $'this is a test' ] || fail 1
  pass

  # -- 6 -- Here-doc should work fine too.
  new_test 'Here-document should be connected to STDIN and read as expected: '
  [ "$(dummy < /tmp/core_ReadDATA--test1)" == $'this is a test' ] || fail 1
  pass

  # -- 7 -- Try reading a single file
  new_test 'Trying to read a single file: '
  [ "$(dummy '/tmp/core_ReadDATA--test1')" == $'this is a test' ] || fail 1
  pass

  # -- 8 -- Sending multiple files should work
  new_test 'Reading from multiple files should "mash" them together: '
  [ "$(dummy '/tmp/core_ReadDATA--test1' '/tmp/core_ReadDATA--test2' '/tmp/core_ReadDATA--test3')" == $'this is a test\nthis is a test\nthis is a test' ] || fail 1
  pass


  let iteration++
done
rm /tmp/core_ReadDATA--test1
rm /tmp/core_ReadDATA--test2
rm /tmp/core_ReadDATA--test3


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

