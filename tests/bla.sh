#!/bin/bash

#./docker.sh
#./core.sh


while getopts 'ab:c' opt ; do
  case "${opt}" in
    a ) temp='' ;;
    b ) [ -z "${OPTARG}" ] ;;
    c ) temp='' ;;
#    * ) echo "Unknown option -${opt}" >&2 ;;
  esac
done

