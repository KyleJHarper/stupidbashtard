#!/bin/bash

# Source shared
. __shared.inc.sh
. ../sbt/core.sh

# Variables
myA=''
myB=''
myC=''
myD=''
myLongA=''
myLongB=''
myLongC=''
myLongD=''

A_TEXT='yay a'
B_TEXT='yay b'
C_TEXT='yay c'
D_TEXT='yay d'

# Functions for testing
function test_vars {
  [ "${myA}" == "${A_TEXT}" ] || return 1
  [ "${myB}" == "${B_TEXT}" ] || return 1
  [ "${myC}" == "${C_TEXT}" ] || return 1
  [ "${myD}" == "${D_TEXT}" ] || return 1
  reset_vars
  return 0
}

function test_long_vars {
  [ "${myLongA}" == "${A_TEXT}" ] || return 1
  [ "${myLongB}" == "${B_TEXT}" ] || return 1
  [ "${myLongC}" == "${C_TEXT}" ] || return 1
  [ "${myLongD}" == "${D_TEXT}" ] || return 1
  reset_vars
  return 0
}

function reset_vars {
  myA=''
  myB=''
  myC=''
  myD=''
  myLongA=''
  myLongB=''
  myLongC=''
  myLongD=''
}

function opts_sbt {
  local OPTIND=1
  OPTERR=1
  local SHORT_OPTS="$1"
  local LONG_OPTS="$2"
  shift 2
  local opt
  while core_getopts "${SHORT_OPTS}" opt "${LONG_OPTS}" "$@" ; do
    case "${opt}" in
      a|longA ) myA="${A_TEXT}" ; myLongA="${A_TEXT}" ;;
      b|longB ) [ -z "${OPTARG}" ] && echo 'grr' && return 1 ; myB="${OPTARG}" ; myLongB="${OPTARG}" ;;
      c|longC ) myC="${C_TEXT}" ; myLongC="${C_TEXT}" ;;
      d|longD ) [ -z "${OPTARG}" ] && echo 'grr' && return 1 ; myD="${OPTARG}" ; myLongD="${OPTARG}" ;;
      * ) echo "Unknown option -${OPTARG} (${opt})" >&2 ;;
    esac
  done
  shift $(( ${OPTIND} - 1 ))
  return 0
}

function opts {
  local OPTIND=1
  OPTERR=1
  local SHORT_OPTS="$1"
  shift 1
  local opt
  while getopts "${SHORT_OPTS}" opt ; do
    case "${opt}" in
      a ) myA="${A_TEXT}" ;;
      b ) [ -z "${OPTARG}" ] && return 1 ; myB="${OPTARG}" ;;
      c ) myC="${C_TEXT}" ;;
      d ) [ -z "${OPTARG}" ] && return 1 ; myD="${OPTARG}" ;;
      * ) echo "Unknown option -${OPTARG} (${opt})" >&2 ;;
    esac
  done
  shift $(( ${OPTIND} - 1 ))
  return 0
}


###########
#  Tests  #
###########
#
# Can we use shortopts as intended with both systems?
#
echo -n "Test ${test_number}: Can we do a simple short options getopts with internal error handling:  "
opts     'ab:cd:'    -a -b "${B_TEXT}" -c -d "${D_TEXT}"  || fail 1
test_vars                                                 || fail 2
opts_sbt 'ab:cd:' '' -a -b "${B_TEXT}" -c -d "${D_TEXT}"  || fail 3
test_vars                                                 || fail 4
pass


#
# If we handle invalid options it shouldn't affect argument processing.
#
echo -n "Test ${test_number}: Handling errors manually shouldn't result in failure:  "
opts     ':ab:cd:'    -a -b "${B_TEXT}" -c -d "${D_TEXT}"  || fail 1
test_vars                                                  || fail 2
opts_sbt ':ab:cd:' '' -a -b "${B_TEXT}" -c -d "${D_TEXT}"  || fail 3
test_vars                                                  || fail 4
pass


#
# If we allow getopts to handle invalid options it should send a line and continue (non-fail)
#
echo -n "Test ${test_number}: Sending invalid arguments and allowing internal error processing, shouldn't abort:  "
opts     'ab:cd:'    -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>/dev/null  || fail 1
test_vars                                                                || fail 2
opts_sbt 'ab:cd:' '' -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>/dev/null  || fail 3
test_vars                                                                || fail 4
pass


#
# If we handle invalid options it should still shouldn't fail, but we should get a notice.
#
echo -n "Test ${test_number}: Sending invalid arguments and allowing internal error processing, still shouldn't abort:  "
opts     ':ab:cd:'    -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>/dev/null  || fail 1
test_vars                                                                 || fail 2
opts_sbt ':ab:cd:' '' -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>/dev/null  || fail 3
test_vars                                                                 || fail 4
pass


#
# We should get a line to STDERR when we allow internal error handling to handle a failed option.
#
echo -n "Test ${test_number}: Sending invalid arguments and allowing internal error processing, should send a line to std err:  "
[ $( opts     'ab:cd:'    -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>&1 | wc -l ) -gt 0 ] || fail 1
#test_vars                                                                               || fail 2
[ $( opts_sbt 'ab:cd:' '' -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>&1 | wc -l ) -gt 0 ] || fail 3
#test_vars                                                                               || fail 4
pass


#
# We should get a line to STDERR when we handle errors manually with a failed option.
#
echo -n "Test ${test_number}: Sending invalid arguments and allowing internal error processing, should send a line to std err:  "
[ $( opts     ':ab:cd:'    -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>&1 | wc -l ) -gt 0 ] || fail 1
#test_vars                                                                                || fail 2
[ $( opts_sbt ':ab:cd:' '' -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>&1 | wc -l ) -gt 0 ] || fail 3
#test_vars                                                                                || fail 4
pass


#
# Long Options, woohoo!  Testing with valid ones just to make sure it works.
#
echo -n "Test ${test_number}: Attempting to pass long opts in the way we expect, no args to switches:  "
opts_sbt ':ab:cd:' 'longA,longB:,longC,longD:' --longA --longC  || fail 1
[ "${myLongA}" = "${A_TEXT}" ]                                  || fail 2
[ "${myLongC}" = "${C_TEXT}" ]                                  || fail 3
pass


#
# Long Options.  Try a switch with an argument.
#
echo -n "Test ${test_number}: Attempting to pass long opts in the way we expect, longB and longD have an arg now, space separated:  "
opts_sbt ':ab:cd:' 'longA,longB:,longC,longD:' --longA --longB "${B_TEXT}" --longC --longD "${D_TEXT}"  || fail 1
test_long_vars                                                                                          || fail 2
pass


#
# Long Options.  Try a switch with an argument.  This time using --option=value
#
echo -n "Test ${test_number}: Attempting to pass long opts in the way we expect, using --longopt=value format:  "
opts_sbt ':ab:cd:' 'longA,longB:,longC,longD:' --longA --longB="${B_TEXT}" --longC --longD="${D_TEXT}" || fail 1
test_long_vars                                                                                         || fail 2
pass


#
# Sending an option with the wrong case sensitivity.  Should result in an error to stderr.
#
echo -n "Test ${test_number}: Attempting to pass a case-incorrect long option, also confirms invalid long opt will fail:  "
[ $( opts_sbt ':ab:cd:' 'longA,longB:,longC,longD:' --longA --longB="${B_TEXT}" --longc 2>&1 | wc -l ) -gt 0 ] || fail 1
#test_long_vars                                                                                                 || fail 2
pass


#
# Multiple long opts with args
