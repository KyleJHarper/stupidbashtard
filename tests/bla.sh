#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

#./docker.sh
#./core.sh


temp='5.6.15'
MAJOR="${temp%%.*}"   ; temp="${temp:${#MAJOR}+1}"
MEDIUM="${temp%%.*}"  ; temp="${temp:${#MEDIUM}+1}"
MINOR="${temp%%.*}"

echo "Major :  ${MAJOR}"
echo "Medium:  ${MEDIUM}"
echo "Minor :  ${MINOR}"
