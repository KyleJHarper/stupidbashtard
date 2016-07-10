#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

#./docker.sh
#./core.sh

T=0
ITERATIONS=100000


echo "-- True & False  --"
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


echo "-- Number vs Number (test syntax: [ # -eq # ] ) --"
i=0
time (for x in $(seq 1 1 ${ITERATIONS}) ; do
  if [ ${T} -eq 0 ] ; then let i++ ; fi
done)
echo ${i}


echo "-- 0 & 1 (test syntax: [ # ] ) --"
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
