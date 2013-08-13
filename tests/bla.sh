#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

#./docker.sh
#./core.sh

. ../sbt/core.sh
. ../sbt/string.sh
__SBT_VERBOSE=true

#echo "$(string_FormatCase -u 'hello world')"
#string=$'a\tfew words'
#string=($string)
#string=${string[@]^}
#echo $string

bob=('whee' 'yay' 'i Am fUN')

echo "${bob[@]~~}"
