#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"


[ "${1}" == 'performance' ] && iteration=1
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
#__SBT_VERBOSE=true

  # -- Find a known program, bash!
  new_test "Trying to find 'bash', any version. (0.0.0): "
  core_ToolExists 'bash'  || fail 1
  pass

  # -- Try the short options, all of them!!!
  new_test 'Sending all short switches to ensure they work.  First without exact, then with: '
  core_ToolExists 'bash' -1 4 -2 0 -3 0    -r '\d+\.\d+([.]\d+)?' -v '--version'              || fail 1
  core_ToolExists 'bash' -1 4 -2 0 -3 0 -e -r '\d+\.\d+([.]\d+)?' -v '--version' 2>/dev/null  && fail 2
  pass

  # -- Now try long options.
  new_test 'Sending all long switches to ensure they work.  First without exact, then with: '
  core_ToolExists 'bash' --major 4 --medium 0 --minor 0         --regex-pattern '\d+\.\d+([.]\d+)?' --version-switch '--version'              || fail 1
  core_ToolExists 'bash' --major 4 --medium 0 --minor 0 --exact --regex-pattern '\d+\.\d+([.]\d+)?' --version-switch '--version' 2>/dev/null  && fail 2
  pass

  # -- Find bash again, but with too high a version.
  new_test "Trying to find 'bash', a version we know is too high. (9.6.2): "
  core_ToolExists 'bash' --major=9 --medium=6 --minor=2 2>/dev/null  && fail 1
  pass

  # -- Coreutils programs often just announce the coreutils version (eg. 8.13).
  new_test "Checking the 'cut' program output.  Should be corutils and only have x.yy: "
  core_ToolExists 'cut' --major=7 || fail 1
  pass

  # -- Some programs use special version checking switches, like mawk
  new_test "Overriding --version-switch argument to '-W version' to get awk/nawk/mawk version string: "
  core_ToolExists 'awk' --major=1 -v '-W version' || fail 1
  pass

  let iteration++
done
