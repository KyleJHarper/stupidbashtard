#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"

# Variables
myA=''
myB=''
myC=''
myD=''
myLongA=''
myLongB=''
myLongC=''
myLongD=''
myLongE=''  # Only exists for testing --e
myLongH=''  # Only exists for testing hyphenated

A_TEXT='yay a'
B_TEXT='yay b'
C_TEXT='yay c'
D_TEXT='yay d'
E_TEXT='yay e'  # Only exists for testing --e
H_TEXT='yay h'  # Only exists for testing hyphenated

SHORT_OPTS='ab:cd:'
LONG_OPTS='longA,longB:,longC,longD:,e:,long-hyphen:'


# Functions for testing
function test_vars {
  local i=1
  local to_test=''
  eval to_test="\"\${${i}}\""
  while [ $i -lt $# ] ; do
    case "${to_test}" in
      a ) [ "${myA}" == "${A_TEXT}" ] || return 1 ;;
      b ) [ "${myB}" == "${B_TEXT}" ] || return 1 ;;
      c ) [ "${myC}" == "${C_TEXT}" ] || return 1 ;;
      d ) [ "${myD}" == "${D_TEXT}" ] || return 1 ;;
      * ) echo 'Unknown test item in test_vars' >&2 ; return 1 ;;
    esac
    let i++
  done
  reset_vars
  return 0
}

function test_long_vars {
  local i=1
  local to_test=''
  eval to_test="\"\${${i}}\""
  while [ $i -lt $# ] ; do
    case "${to_test}" in
      a ) [ "${myLongA}" == "${A_TEXT}" ] || return 1 ;;
      b ) [ "${myLongB}" == "${B_TEXT}" ] || return 1 ;;
      c ) [ "${myLongC}" == "${C_TEXT}" ] || return 1 ;;
      d ) [ "${myLongD}" == "${D_TEXT}" ] || return 1 ;;
      e ) [ "${myLongE}" == "${E_TEXT}" ] || return 1 ;;
      h ) [ "${myLongH}" == "${H_TEXT}" ] || return 1 ;;  # For hyphenated test only
      * ) echo 'Unknown test item in test_long_vars' >&2 ; return 1 ;;
    esac
    let i++
  done
  reset_vars
  return 0
}

function reset_vars {
  myA=''
  myB=''
  myC=''
  myD=''
  myE=''
  myLongA=''
  myLongB=''
  myLongC=''
  myLongD=''
  myLongE=''
  myLongH=''
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
      a            ) myA="${A_TEXT}" ;;
      longA       ) myLongA="${A_TEXT}" ;;
      b           ) [ -z "${OPTARG}" ] && echo 'grr' && return 1 ; myB="${OPTARG}" ;;
      longB       ) [ -z "${OPTARG}" ] && echo 'grr' && return 1 ; myLongB="${OPTARG}" ;;
      c           ) myC="${C_TEXT}" ;;
      longC       ) myLongC="${C_TEXT}" ;;
      d           ) [ -z "${OPTARG}" ] && echo 'grr' && return 1 ; myD="${OPTARG}" ;;
      longD       ) [ -z "${OPTARG}" ] && echo 'grr' && return 1 ; myLongD="${OPTARG}" ;;
      e           ) myLongE="${E_TEXT}" ;;  # Only exists for testing --e
      long-hyphen ) [ -z "${OPTARG}" ] && echo 'grr' && return 1 ; myLongH="${OPTARG}" ;;  # Only exists for testing hyphenated
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



# +-------------------------------------------+
# |  Test Time!  Setup Performance Loop Here  |
# +-------------------------------------------+
[ "${1}" == 'performance' ] && iteration=1
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- Can we use shortopts as intended with both systems?
  new_test "Can we do a simple short options getopts with internal error handling: "
  opts     "${SHORT_OPTS}"    -a -b "${B_TEXT}" -c -d "${D_TEXT}"  || fail 1
  test_vars a b c d                                                || fail 2
  opts_sbt "${SHORT_OPTS}" '' -a -b "${B_TEXT}" -c -d "${D_TEXT}"  || fail 3
  test_vars a b c d                                                || fail 4
  pass


  # -- If we handle invalid options it shouldn't affect argument processing.
  new_test "Handling errors manually shouldn't result in failure: "
  opts     ":${SHORT_OPTS}"    -a -b "${B_TEXT}" -c -d "${D_TEXT}"  || fail 1
  test_vars a b c d                                                 || fail 2
  opts_sbt ":${SHORT_OPTS}" '' -a -b "${B_TEXT}" -c -d "${D_TEXT}"  || fail 3
  test_vars a b c d                                                 || fail 4
  pass


  # -- If we allow getopts to handle invalid options it should send a line and continue (non-fail)
  new_test "Sending invalid arguments and allowing internal error processing, shouldn't abort: "
  opts     "${SHORT_OPTS}"    -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>/dev/null  || fail 1
  test_vars a b c d                                                               || fail 2
  opts_sbt "${SHORT_OPTS}" '' -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>/dev/null  || fail 3
  test_vars a b c d                                                               || fail 4
  pass


  # -- If we handle invalid options it should still shouldn't fail, but we should get a notice.
  new_test "Sending invalid arguments and allowing internal error processing, still shouldn't abort: "
  opts     ":${SHORT_OPTS}"    -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>/dev/null  || fail 1
  test_vars a b c d                                                                || fail 2
  opts_sbt ":${SHORT_OPTS}" '' -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>/dev/null  || fail 3
  test_vars a b c d                                                                || fail 4
  pass


  # -- We should get a line to STDERR when we allow internal error handling to handle a failed option.
  new_test "Sending invalid arguments and allowing internal error processing, should send a line to std err: "
  [ $( opts     "${SHORT_OPTS}"    -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>&1 | wc -l ) -gt 0 ] || fail 1
  [ $( opts_sbt "${SHORT_OPTS}" '' -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>&1 | wc -l ) -gt 0 ] || fail 2
  pass


  # -- We should get a line to STDERR when we handle errors manually with a failed option.
  new_test "Sending invalid arguments and handling error processing ourselves, should send a line to std err: "
  [ $( opts     ":${SHORT_OPTS}"    -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>&1 | wc -l ) -gt 0 ] || fail 1
  [ $( opts_sbt ":${SHORT_OPTS}" '' -a -b "${B_TEXT}" -c -d "${D_TEXT}" -z 2>&1 | wc -l ) -gt 0 ] || fail 2
  pass


  # -- Long Options, woohoo!  Testing with valid ones just to make sure it works.
  new_test "Attempting to pass long opts in the way we expect, no args to switches: "
  opts_sbt ":${SHORT_OPTS}" "${LONG_OPTS}" --longA --longC  || fail 1
  pass


  # -- Long Options.  Try a switch with an argument.
  new_test "Attempting to pass long opts in the way we expect, longB and longD have an arg now, space separated: "
  opts_sbt ":${SHORT_OPTS}" "${LONG_OPTS}" --longA --longB "${B_TEXT}" --longC --longD "${D_TEXT}"  || fail 1
  test_long_vars a b c d                                                                            || fail 2
  pass


  # -- Long Options.  Try a switch with an argument.  This time using --option=value
  new_test "Attempting to pass long opts in the way we expect, using --longopt=value format: "
  opts_sbt ":${SHORT_OPTS}" "${LONG_OPTS}" --longA --longB="${B_TEXT}" --longC --longD="${D_TEXT}" || fail 1
  test_long_vars a b c d                                                                           || fail 2
  pass


  # -- Short opts should also work with an equal sign -a=value
  new_test "Attempting to pass short opts using -a=value format: "
  opts_sbt ":${SHORT_OPTS}" "${LONG_OPTS}" -a -b="${B_TEXT}" -c -d="${D_TEXT}" || fail 1
  test_vars a b c d                                                            || fail 2
  pass


  # -- Sending an option with the wrong case sensitivity.  Should result in an error to stderr.
  new_test "Attempting to pass a case-incorrect long option, also confirms invalid long opt will fail: "
  [ $( opts_sbt ":${SHORT_OPTS}" "${LONG_OPTS}" --longA --longB="${B_TEXT}" --longc 2>&1 | wc -l ) -gt 0 ] || fail 1
  pass


  # -- Multiple long opts with args using spaces
  new_test "Attempting to pass long opts in the way we expect, using --longopt value format: "
  opts_sbt ":${SHORT_OPTS}" "${LONG_OPTS}" --longA --longB "${B_TEXT}" --longC --longD "${D_TEXT}" || fail 1
  test_long_vars a b c d                                                                           || fail 2
  pass


  # -- Clearing __SBT_NONOPT_ARGS should allow us to send switches and non-switch args
  __SBT_NONOPT_ARGS=()
  new_test "Sending all expected options and some extras on the end.  Should be captured in __SBT_NONOPT_ARGS: "
  opts_sbt ":${SHORT_OPTS}" "${LONG_OPTS}" --longA --longB "${B_TEXT}" --longC --longD "${D_TEXT}" 'nonopt 1' 'nonopt 2' || fail 1
  test_long_vars a b c d                                                                                                 || fail 2
  [ ${#__SBT_NONOPT_ARGS[@]} -eq 2 ]                                                                                     || fail 3
  [ "${__SBT_NONOPT_ARGS[0]}" == 'nonopt 1' ]                                                                            || fail 4
  [ "${__SBT_NONOPT_ARGS[1]}" == 'nonopt 2' ]                                                                            || fail 5
  pass


  # -- Clearing __SBT_NONOPT_ARGS should allow us to send switches and non-switch args, this time intermixed
  __SBT_NONOPT_ARGS=()
  new_test "Sending all expected options and some extras intermixed.  Should be captured in __SBT_NONOPT_ARGS: "
  opts_sbt ":${SHORT_OPTS}" "${LONG_OPTS}" --longA 'nonopt 1' --longB "${B_TEXT}" 'nonopt 2' --longC --longD "${D_TEXT}" || fail 1
  test_long_vars a b c d                                                                                                 || fail 2
  [ ${#__SBT_NONOPT_ARGS[@]} -eq 2 ]                                                                                     || fail 3
  [ "${__SBT_NONOPT_ARGS[0]}" == 'nonopt 1' ]                                                                            || fail 4
  [ "${__SBT_NONOPT_ARGS[1]}" == 'nonopt 2' ]                                                                            || fail 5
  pass


  # -- Shortopts side-by-side should work:  like so:  -abc == -a -b -c
  new_test "Using short options in succession in the same argument: ./script -ac -b someArg: "
  opts_sbt ":${SHORT_OPTS}" '' -ac -b "${B_TEXT}" -d "${D_TEXT}" || fail 1
  test_vars a b c d                                              || fail 2
  pass


  # -- Shortopts side-by-side, the last opt can require an arg in OPTIND++:  -acb == -a -c -b someArg
  new_test "Using short options in succession, last requires argument: ./script -acb someArg: "
  opts_sbt ":${SHORT_OPTS}" '' -acb "${B_TEXT}" -d "${D_TEXT}" || fail 1
  test_vars a b c d                                            || fail 2
  pass


  # -- Call same opt multiple times, should work.  Short opts this time.
  new_test "Sending the same option multiple times.  Shouldn't be a problem: "
  opts_sbt ":${SHORT_OPTS}" ":${LONG_OPTS}" -a -a -b "${B_TEXT}" -c -d "${D_TEXT}" -d "${D_TEXT}"                               || fail 1
  test_vars a b c d                                                                                                             || fail 2
  opts_sbt ":${SHORT_OPTS}" ":${LONG_OPTS}" --longA --longA --longB "${B_TEXT}" --longC --longD "${D_TEXT}" --longD "${D_TEXT}" || fail 3
  test_long_vars a b c d                                                                                                        || fail 4
  pass


  # -- Mixing long and short opts
  new_test "Mixing short and long options, should be fine: "
  opts_sbt ":${SHORT_OPTS}" ":${LONG_OPTS}" -a -b "${B_TEXT}" --longC --longD "${D_TEXT}" || fail 1
  test_vars a b                                                                           || fail 2
  opts_sbt ":${SHORT_OPTS}" ":${LONG_OPTS}" -a -b "${B_TEXT}" --longC --longD "${D_TEXT}" || fail 3
  test_long_vars c d                                                                      || fail 4
  pass


  # -- Long opts with a single character
  new_test "Sending long opts that only have a character (looks like a short): "
  opts_sbt ":${SHORT_OPTS}" ":${LONG_OPTS}" --e "${E_TEXT}" || fail 1
  test_long_vars e                                          || fail 2
  pass


  # -- Long option with a hyphen should work
  new_test "Using a hyphenated long option: ./script --long-hyphen=someArg: "
  opts_sbt ":${SHORT_OPTS}" ":${LONG_OPTS}" --long-hyphen "${H_TEXT}" || fail 1
  test_long_vars h                                                    || fail 2
  pass

  let iteration++
done

