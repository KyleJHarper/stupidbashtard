#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Quick check to make sure you use this script correclty
if [ -z "$@" ] ; then
  echo -e "You didn't specify any namespaces to test.\n  Usage:  ./namespace.sh <namespace name>\n  Example:  ./namespace.sh core" >&2
  exit 1
fi

# Run each test.
for dir in $@ ; do
  if [ ! -d "${dir}" ] ; then echo "Namespace specified doesn't exist." >&2 ; exit 1 ; fi
  for file in ${dir}/* ; do
    ./${file} ${1}
  done
done
