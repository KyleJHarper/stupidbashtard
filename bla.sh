#!/bin/bash

function whe_there-bob01_hi {
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
