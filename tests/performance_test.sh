#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

if [ -z "${1}" ] ; then
  echo "You didn't specify a test to do metrics on." >&2
  exit 1
fi

if [ ! -f "${1}" ] ; then
  echo "Cannot find file to test: ${1}" >&2
  exit 1
fi

i=0
ITERATIONS=100
time (while [ ${i} -lt ${ITERATIONS} ] ; do
        if ! ./${1} >/dev/null ; then
          echo "Test failed.  Fix test before trying to do a performance test." >&2
          exit 1
        fi
        let i++
        printf '\r%6s' "      " "${i}%"
      done)
echo ''
