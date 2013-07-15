#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Run an entire namespace's worth of tests
ns="${1}"
if [ -z "${ns}" ] ; then echo "You have to specify a namespace to test." >&2 ; exit 1 ; fi
if [ ! -d ${ns} ] ; then echo "Namespace specified doesn't exist."       >&2 ; exit 1 ; fi
shift

# Run each test.
for file in ${ns}/* ; do
  ./${file} ${1}
done
