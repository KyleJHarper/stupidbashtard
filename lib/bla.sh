#!/bin/bash


while getopts 'ab:_:$:' my_opt ; do
  case "$my_opt" in
    'a' ) #@opt_ When specified, turns on AWESOME mode... yea.
          AWESOME_MODE=true     ;;
    'b' ) #@opt_ Override the default book name to use.
          BOOK_NAME="${OPTARG}" ;;
    '_' ) echo "${OPTARG}" ;;
    '$' ) echo "${OPTARG}" ;;
    *   ) echo "Invalid option -${OPTARG}" >&2
          return 1
          ;;
  esac
done

exit
function fun

{
  echo 'bla'
}

fun

exit
which hi >/dev/null || declare -F | grep -F 'hi'
exit
test=('abc' 'adr' '34g')
echo "${test[@]}"

exit
declare -i i
typeset -i -r j=55

i=5
#j='hi'

echo $i $j

exit

function whe_there-bob01_hi () {
  echo 'boooooobs'
}

whe_there-bob01_hi

exit
one-hi() {
  echo 'hi'
}

two      ()
{
  echo 'me too'
}

one-hi
two

exit

bob1 = 'hi'
echo $bob1

exit

while getopts ":A" opt; do
  case $opt in
    A)
      echo "-A was triggered!" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

exit
function not_async {
  echo "not_async ${BASHPID}"
}

function async {
  echo "async ${BASHPID}"
}

echo "Main ${BASHPID}"
not_async
async &

wait
