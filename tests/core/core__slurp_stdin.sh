#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"

function dummy {
  # Placeholder to ensure nested piping works
  local _data=''
  echo 'I am a dummy'
  core__slurp_stdin || return 1
  echo -e "${_data}"
  return 0
}


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Piping test.  Need a dummy function, because piping to core__slurp_stdin direclty puts it in a subshell.  sigh
  new_test 'Piping a command into a dummy function that uses core__slurp_stdin: '
  [ "$(echo 'this is a test' | dummy)" == $'I am a dummy\nthis is a test' ] || fail 1
  pass

  # -- 2 -- Chained pipes caused an issue.  Race conditions and sigpipes.  core__slurp_stdin should work.
  # Real world case from 2013.10.25
  new_test 'Piping a series together (chained piping) because improper handling will cause sigpipes and race conditions: '
  [ "$(echo 'this is a test' | dummy | dummy | dummy | dummy)" == $'I am a dummy\nI am a dummy\nI am a dummy\nI am a dummy\nthis is a test' ] || fail 1
  pass

  # -- 3 -- Herestrings should work, and might be preferred in many cases.
  new_test 'Here-strings should work just fine: '
  [ "$(dummy <<<'this is a test')" == $'I am a dummy\nthis is a test' ] || fail 1
  pass

  # -- 4 -- Herestring and subsequent piping should work.
  new_test 'Here-string followed by piping should work: '
  [ "$(dummy <<<'this is a test' | dummy | dummy )" == $'I am a dummy\nI am a dummy\nI am a dummy\nthis is a test' ] || fail 1
  pass

  # -- 5 -- Here-doc should work fine too.
  new_test 'Here-document should be connected to STDIN and read as expected: '
  echo 'this is a test' > /tmp/core__slurp_stdin--test
  [ "$(dummy < /tmp/core__slurp_stdin--test)" == $'I am a dummy\nthis is a test' ] || fail 1
  [ "$(dummy < /tmp/core__slurp_stdin--test | dummy | dummy )" == $'I am a dummy\nI am a dummy\nI am a dummy\nthis is a test' ] || fail 2
  rm /tmp/core__slurp_stdin--test
  pass


  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

