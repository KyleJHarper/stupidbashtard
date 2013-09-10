#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Run each test.
for dir in $@ ; do
  if [ ! -d "${dir}" ] ; then echo "Namespace specified doesn't exist."       >&2 ; exit 1 ; fi
  for file in ${dir}/* ; do
    ./${file} ${1}
  done
done
