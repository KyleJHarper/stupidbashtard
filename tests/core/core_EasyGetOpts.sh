#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"


# Functions
function reset_vars {
  unset _option_a
  unset _option_b
  unset _option_c
  unset _option_longA
  unset _option_longB
  unset _option_longC
  unset _option_long_hyphenated
  return 0
}


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Short options with no parameters
  new_test "Sending only short options that do not take parameters: "
  reset_vars
  core_EasyGetOpts ':abc' '' -a -b -c  || fail 1
  [ "${option_a}" = 'true' ]           || fail 2
  [ "${option_b}" = 'true' ]           || fail 3
  [ "${option_c}" = 'true' ]           || fail 4
  pass

  # -- 2 -- Short options with parameters
  new_test "Sending only short options and one will take a parameter, sent through OPTARG: "
  reset_vars
  core_EasyGetOpts ':ab:c' '' -a -b 'b value stuff' -c || fail 1
  [ "${option_a}" = 'true' ]                           || fail 2
  [ "${option_b}" = 'b value stuff' ]                  || fail 3
  [ "${option_c}" = 'true' ]                           || fail 4
  pass

  # -- 3 -- Short options with parameters that have a quote.
  new_test "Sending only short options and one will take a parameter with a double quote (eval should be escaped): "
  reset_vars
  core_EasyGetOpts ':ab:c' '' -a -b 'b "value" stuff' -c || fail 1
  [ "${option_a}" = 'true' ]                             || fail 2
  [ "${option_b}" = 'b "value" stuff' ]                  || fail 3
  [ "${option_c}" = 'true' ]                             || fail 4
  pass

  # -- 4 -- Long options with no parameters
  new_test "Sending only long options that do not take parameters: "
  reset_vars
  core_EasyGetOpts '' ':longA,longB,longC' --longA --longB --longC || fail 1
  [ "${option_longA}" = 'true' ]                                   || fail 2
  [ "${option_longB}" = 'true' ]                                   || fail 3
  [ "${option_longC}" = 'true' ]                                   || fail 4
  pass

  # -- 5 -- Long options with parameters
  new_test "Sending only long options and one will take a parameter, sent through OPTARG: "
  reset_vars
  core_EasyGetOpts '' ':longA,longB:,longC' --longA --longB 'b value stuff' --longC || fail 1
  [ "${option_longA}" = 'true' ]                                                    || fail 2
  [ "${option_longB}" = 'b value stuff' ]                                           || fail 3
  [ "${option_longC}" = 'true' ]                                                    || fail 4
  pass

  # -- 6 -- Long options with parameters that have a quote.
  new_test "Sending only long options and one will take a parameter with a double quote (eval should be escaped): "
  reset_vars
  core_EasyGetOpts '' ':longA,longB:,longC' --longA --longB 'b "value" stuff' --longC || fail 1
  [ "${option_longA}" = 'true' ]                                                      || fail 2
  [ "${option_longB}" = 'b "value" stuff' ]                                           || fail 3
  [ "${option_longC}" = 'true' ]                                                      || fail 4
  pass

  # -- 7 -- Using a long option with a hyphen in the name
  new_test "Sending a long option with a hyphen in the name: "
  reset_vars
  core_EasyGetOpts '' ':longA,long-hyphenated:,longB:' --longA --long-hyphenated 'rawr' --longB 'hello' || fail 1
  [ "${option_longA}" = 'true' ]                                                                        || fail 2
  [ "${option_long_hyphenated}" = 'rawr' ]                                                              || fail 3
  [ "${option_longB}" = 'hello' ]                                                                       || fail 4
  pass

  # -- 8 -- Mixing long and short options with parameters and double quotes.
  new_test "Sending short options, long options, with parameters, and with double quotes for escaping: "
  reset_vars
  core_EasyGetOpts ':abc:' ':longA,longB:,longC,long-hyphenated:' -a -b -c 'rawr' --longA --longB 'hello' --longC --long-hyphenated 'this "is" fun' || fail 1
  [ "${option_a}" = 'true' ]                                                                                                                        || fail 2
  [ "${option_b}" = 'true' ]                                                                                                                        || fail 3
  [ "${option_c}" = 'rawr' ]                                                                                                                        || fail 4
  [ "${option_longA}" = 'true' ]                                                                                                                    || fail 5
  [ "${option_longB}" = 'hello' ]                                                                                                                   || fail 6
  [ "${option_longC}" = 'true' ]                                                                                                                    || fail 7
  [ "${option_long_hyphenated}" = 'this "is" fun' ]                                                                                                 || fail 8
  pass


  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

