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
TEST_FILE="${1}"
RESULTS_FILE="performance_logs/$(basename ${TEST_FILE})_results.log"
time (while [ ${i} -lt ${ITERATIONS} ] ; do
        if ! ./${TEST_FILE} >/dev/null ; then
          echo "Test failed.  Fix test before trying to do a performance test." >&2
          exit 1
        fi
        let i++
        printf '\r%6s' "      " "${i}%" >&2
      done)
echo ''
