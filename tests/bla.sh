#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

#./docker.sh
#./core.sh



function get_opts {
  logger "line ${LINENO}: (verbose) ${FUNCNAME}:"
}

function logger {
  echo "$@"
}


get_opts
