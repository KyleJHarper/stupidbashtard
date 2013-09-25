#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

#./docker.sh
#./core.sh


var="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." ; pwd)"
echo "${var}"
. /tmp/source_me
. /tmp/source_me_2

. /tmp/stupidbashtard/sbt/bla.sh
exit
. ../sbt/core.sh
. ../sbt/string.sh
__SBT_VERBOSE=true




case "one" in
  'o' | 'one' ) echo 'woohoo' ;;
esac
exit




var=''
string_FormatCase -l 'HELlo there ' 'nom ' 'NoMMMMM' -R 'var'

echo "${var}"






exit
function rawr {
  echo "Printing args agin before making a local lexical:"
  echo ${__SBT_NONOPT_ARGS[@]}
  echo
  echo

  local -a __SBT_NONOPT_ARGS
  echo "Set the array locally, should be blank:"
  echo ${__SBT_NONOPT_ARGS[@]}
  echo "^^"
  while core_getopts ':abc:' opt '' "$@" ; do
    case "${opt}" in
      'a'  ) echo "At a" ;;
      'b'  ) echo "At b" ;;
      'c'  ) echo "At c with OPTARG of '${OPTARG}'" ;;
      *    ) echo "Not an option:   ${opt}" ;;
    esac
  done

  echo "Done processing getopts for function.  Array is:"
  echo ${__SBT_NONOPT_ARGS[@]}

  return 0
}

while core_getopts ':abc:' opt '' "$@" ; do
  case "${opt}" in
    'a'  ) echo "At a" ;;
    'b'  ) echo "At b" ;;
    'c'  ) echo "At c with OPTARG of '${OPTARG}'" ;;
    *    ) echo "Not an option:   ${opt}" ;;
  esac
done

echo "__SBT_NONOPT_ARGS is:"
echo ${__SBT_NONOPT_ARGS[@]}

echo
echo
echo "Calling function now"
rawr -a -b -c 'hi' 'one' 'two' 'three'


echo
echo
echo "Final print of it from main, this should be the same as the first print out in main:"
echo ${__SBT_NONOPT_ARGS[@]}

