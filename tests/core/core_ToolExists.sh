#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"


[ "${1}" == 'performance' ] && iteration=1
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Find a known program, bash!
  new_test "Trying to find 'bash', any version. (0.0.0): "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core_ToolExists 'bash'  || fail 1
  pass


  # -- 2 -- Try the short options, all of them!!!
  new_test 'Sending all short switches to ensure they work.  First without exact, then with: '
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core_ToolExists 'bash' -1 4 -2 0 -3 0    -r '\d+\.\d+([.]\d+)?' -v '--version'              || fail 1
  core_ToolExists 'bash' -1 4 -2 0 -3 0 -e -r '\d+\.\d+([.]\d+)?' -v '--version' 2>/dev/null  && fail 2
  pass


  # -- 3 -- Now try long options.
  new_test 'Sending all long switches to ensure they work.  First without exact, then with: '
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core_ToolExists 'bash' --major 4 --medium 0 --minor 0         --regex-pattern '\d+\.\d+([.]\d+)?' --version-switch '--version'              || fail 1
  core_ToolExists 'bash' --major 4 --medium 0 --minor 0 --exact --regex-pattern '\d+\.\d+([.]\d+)?' --version-switch '--version' 2>/dev/null  && fail 2
  pass


  # -- 4 -- Find bash again, but with too high a version.
  new_test "Trying to find 'bash', a version we know is too high. (9.6.2): "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core_ToolExists 'bash' --major=9 --medium=6 --minor=2 2>/dev/null  && fail 1
  pass


  # -- 5 -- Coreutils programs often just announce the coreutils version (eg. 8.13).
  new_test "Checking the 'cut' program output.  Should be corutils and only have x.yy: "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core_ToolExists 'cut' --major=7 || fail 1
  pass


  # -- 6 -- Some programs use special version checking switches, like mawk
  new_test "Overriding --version-switch argument to '-W version' to get awk/nawk/mawk version string: "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core_ToolExists 'awk' --major=1 -v '-W version' || fail 1
  pass


  # -- 7 -- Variable should have tools... otherwise we're missing out on caching.
  new_test "Checking for bash again, to make sure __SBT_TOOL_LIST actually populates: "
  unset __SBT_TOOL_LIST ; declare -A __SBT_TOOL_LIST
  core_ToolExists 'bash' --major=4 --medium=0 --minor=0 || fail 1
  [ "${!__SBT_TOOL_LIST[@]}" == 'bash' ]                || fail 2
  [ ! -z "${__SBT_TOOL_LIST['bash']}" ]                 || fail 3
  core_ToolExists 'perl' --major=4 --medium=0 --minor=0 || fail 4
  core_ToolExists 'cut'  --major=7 --medium=0 --minor=0 || fail 5
  [ ${#__SBT_TOOL_LIST[@]} -eq 3 ]                      || fail 6
  pass


  let iteration++
done
