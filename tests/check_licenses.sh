#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


STRING1="# Copyright 2013 Kyle Harper"
STRING2="# Licensed per the details in the LICENSE file in this package."

TEST_DIR='.'
BIN_DIR='../bin'
SBT_DIR='../sbt'

for file in $(find ${TEST_DIR} ${BIN_DIR} ${SBT_DIR} -type f) ; do
  if ! grep -q -F "${STRING1}" ${file} ; then echo "Missing string 1 in ${file}" >&2 ; fi
  if ! grep -q -F "${STRING2}" ${file} ; then echo "Missing string 2 in ${file}" >&2 ; fi
done

