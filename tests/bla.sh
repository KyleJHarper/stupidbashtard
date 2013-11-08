#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

#./docker.sh
#./core.sh


declare -r -A hash=(['key1']='value1'
                    ['key2']='value2'
)
echo "${hash['key1']}"
hash['key1']='no work'
echo "${hash['key1']}"
echo "${!hash[@]}"
echo "${hash[@]}"

exit
bob="${1:-default}"
echo "$bob"

exit
bla="$(false)"
echo $?

exit
function bla {
  echo '  <here>   '
}

bob="$(bla)"
echo "${bob}was here"
exit
function one {
  local bob=''
  two
  echo "${bob}"
}
function two {
  bob='i am not global from 1'
}

bob='i am global'
echo "${bob}"
one
echo "${bob}"

exit
function rawr {
  local -a ary=("$@")
  asdf="$(cat "${ary[@]}")"
  echo "$?"
}

declare -a bob
bob+=('one')
bob+=('two has a space')
bob+=('three_does_not')
bob+=('four also has a space, woohoo')

rawr "${bob[@]}"
#for item in "${bob[@]}" ; do
#  echo "${item}"
#done

exit
function rawr {
  while read -r ; do echo -e "${REPLY}" ; done
}

rawr < bla.sh

exit
function core_ReadSTDIN {
  #read -t 0 && while IFS= read -r ; do STDIN+="${REPLY}" ; done
  while IFS= read -r ; do STDIN+="${REPLY}\n" ; done
  STDIN="${STDIN: 0: -2}"
}

function log {
  echo -e "$@"
}
function one {
  log 'Entering one'
  #local STDIN=''
  two "$@"
  return 0
}
function two {
  log 'Entering two'
  local STDIN=''
  local haystack="$@"
  core_ReadSTDIN
  haystack+="${STDIN}"
  echo -e "${haystack}"
  return 0
}
function three {
  log 'Entering three'
  local STDIN=''
  core_ReadSTDIN
  echo -e "${STDIN}"
  return 0
}

one <<<'from stdin' | three | one | three | one | three | one | three | one | three | one | three | one | three
echo "${PIPESTATUS[@]}"

exit
declare -a files
files+=("/some/file")
files+=("/some/file2")
files+=("/some/file3")
echo "${files[@]}"
echo ${#files[@]}
echo ${files[0]}
echo ${files[1]}
echo ${files[2]}
echo ${files[3]}
for temp in $(seq 0 1 $((${#files[@]} - 1)) ) ; do files[${temp}]="\"${files[${temp}]}\"" ; done

echo "${files[@]}"
echo ${#files[@]}
echo ${files[0]}
echo ${files[1]}
echo ${files[2]}
echo ${files[3]}

exit
all=false

${all}   && echo "I am true"
! ${all} && echo "I am false"


exit
var=false
if true && ! ${var} ; then
  echo 'hi'
fi

exit
i=3
j=-2
haystack="I am a big string."
echo ${#haystack}
echo ${haystack:${i}}
echo ${haystack: ${i}}
echo ${haystack: 0: ${j}}

exit
T=0
ITERATIONS=100000
i=0
time (for x in $(seq 1 1 ${ITERATIONS}) ; do
  if true ; then let i++ ; fi
done)
echo ${i}

i=0
time (for x in $(seq 1 1 ${ITERATIONS}) ; do
  if ! false ; then let i++ ; fi
done)
echo ${i}

i=0
time (for x in $(seq 1 1 ${ITERATIONS}) ; do
  if [ ${T} -eq 0 ] ; then let i++ ; fi
done)
echo ${i}

i=0
time (for x in $(seq 1 1 ${ITERATIONS}) ; do
  if [ ${T} ] ; then let i++ ; fi
done)
echo ${i}

i=0
time (for x in $(seq 1 1 ${ITERATIONS}) ; do
  if [ 1 ] ; then let i++ ; fi
done)
echo ${i}

exit
. ../sbt/core.sh
#. ../sbt/string.sh
gawk -V
core_SetToolPath "/home/kyle/stupidbashtard/lib/tools"
gawk -V

exit

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

