#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Quick check to make sure you use this script correclty
if [ -z "$@" ] ; then
  echo -e "You didn't specify any namespaces to test.\n  Usage:  ./namespace.sh <namespace name>\n  Example:  ./namespace.sh core" >&2
  exit 1
fi
declare -a namespaces=("${@}")
if [ "${1}" == 'all' ] ; then
  unset namespaces
  declare -a namespaces=( $(find sbt/* -type d -printf '%f ') )
fi

# Run each test.
declare -i count=0
declare -i ns_count=0
declare -A ns_counts=()
for dir in "${namespaces[@]}" ; do
  if [ ! -d "sbt/${dir}" ] ; then echo "Namespace specified doesn't exist: ${dir}" >&2 ; exit 1 ; fi
  ns_count=0
  for file in sbt/${dir}/* ; do
    output="$(./${file} ${1} 2>&1)"
    [ $? -ne 0 ] && echo -e "${output}" && exit 1
    echo -e "${output}"
    let "count+=$(grep -c -P 'Test\s+[0-9]+' <<<"${output}")"
    let "ns_count+=$(grep -c -P 'Test\s+[0-9]+' <<<"${output}")"
  done
  ns_counts[$dir]=${ns_count}
done

printf "%40s\n" '+-----------------------------+--------+'
printf "%40s\n" '| Namespace                   |  Tests |'
printf "%40s\n" '+-----------------------------+--------+'
for ns in "${namespaces[@]}" ; do
  printf "%-2s%-28s%-2s%6d%2s\n" "|" "${ns}" "|" "${ns_counts[$ns]}" "|"
done
printf "%-2s%-28s%-2s%6d%2s\n" "|" "Total" "|" "${count}" "|"
printf "%40s\n" '+-----------------------------+--------+'


