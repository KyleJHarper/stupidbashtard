#!/bin/bash

#@Author    Kyle Harper
#@Date      2013.07.07
#@Version   0.1-beta
#@Namespace core

#@Description  These functions serve as some of the primative tools and requirements for all of SBT.  This will likely become a large namespace.


function core_getopts {
  #@Description  Largely backward compatible replacement for the built-in getopts routine in Bash.  It allows long options, that's the only change.  Long and short options can use a-z A-Z and 0-9 (and hyphens for long opts).
  #@Description  Long options are comma separated.  Adding a colon after an option (but before the comma) implies an argument should follow; same as the built-in getopts.
  #@Description  -
  #@Description  We will use positional numeric parameters because BASH_ARGV only exists when extdebug is on and it pushes/pops up to $9.  Positionals go up to ${10}+ if you use braces for proper interpolation.
  #@Description  -
  #@Description  This breaks the typical naming convention (upper/proper-casing  latter segement of function name) on purpose.

  #@$1  The list short options, same as bash built-in getopts.
  #@$2  Textual name of the variable to send back to the caller, same as built-in getopts.
  #@$3  The list of long options, optional.

  # Clean out OPTARG
  OPTARG=''                                  #@$ Stores the value for any options require an additional argument.
  NONOPT_ARGS=()                             #@$ An array to hold arguments found which aren't tied to options.
  local OPT=''                               #@$ Holds the positional argument based on OPTIND.
  eval OPT="\${${OPTIND}}"
  local temp_opt                             #@$ Used for parsing against OPT to find a match.
  local i=0                                  #@$ Loop control, that's it.

  # If we're on the first index, turn off OPTERR if our prescribed opts start with a colon.
  if [ ${OPTIND} -eq 1 ] ; then
    if [ "${1:0:1}" == ':' ] || [ "${3:0:1}" == ':' ] ; then
      OPTERR=0
    fi
  fi

  # Move OPTIND
  let OPTIND++

  # If the option we tried to store in OPT is blank, we're done.
  [ -z "${OPT}" ] && return 1

  # If the OPT has an equal sign, we need to place the right-hand contents in value and trim OPT.
  if [[ "${OPT}" =~ ^--[a-zA-Z0-9][a-zA-Z0-9-]*= ]] ; then
    OPTARG="${OPT##*=}"
    OPT="${OPT%%=*}"
  fi
  if [[ "${OPT}" =~ ^-[a-zA-Z0-9][a-zA-Z0-9]+ ]] ; then
    OPTARG="${OPT:2}"
    OPT="${OPT:0:2}"
  fi

  # Try to match $OPT against a long option.
  if [ "${OPT:0:2}" == '--' ] ; then
    OPT="${OPT:2}"
    if [ ${#OPT} -lt 1 ] ; then
      core_Error "Long option attempted (--) but no name found."
      return 1
    fi
    for temp_opt in ${3//,/ } ; do
      if [ "${temp_opt%:}" = "${OPT}" ] ; then
        eval $2="${temp_opt%:}"
        if [ "${temp_opt:0:-1}" == ':' ] && [ -z "${OPTARG}" ] ; then
          eval OPTARG="\${${OPTIND}}"
          let OPTIND++
          if [ ${OPTERR} -ne 0 ] && [ -z "${OPTARG}" ] ; then
            core_Error "Option specified (--${OPT}) requires a value."
FINISH ME            return 1
          fi
        fi
        return 0
      fi
    done
    # No options were found in the allowed list.  Send a warning, if necessary, and return failure.
    [ ${OPTERR} -ne 0 ] && core_Error "Invalid argument: --${OPT}"
    return 1
  fi

  # Try to match $OPT against a short option
  if [ "${OPT:0:1}" == '-' ] ; then
    OPT="${OPT:1}"
    if [ ${#OPT} -lt 1 ] ; then
      core_Error "Short option attempted (-) but no name found."
      return 1
    fi
    while [ $i -lt ${#1} ] ; do
      temp_opt="${1:${i}:1}"
      if [ "${temp_opt}" = "${OPT}" ] ; then
        eval $2="${temp_opt}"
        let i++
        if [ "${1:${i}:1}" == ':' ] && [ -z "${OPTARG}" ] ; then
          eval OPTARG="\${${OPTIND}}"
          let OPTIND++
          if [ ${OPTERR} -ne 0 ] && [ -z "${OPTARG}" ] ; then
            core_Error "Option specified (-${OPT}) requires a value."
            return 1
          fi
        fi
        return 0
      fi
      let i++
    done
    # No options were found in the allowed list.  Send a warning, if necessary, and return failure.
    [ ${OPTERR} -ne 0 ] && core_Error "Invalid argument: -${OPT}"
    return 1
  fi

  # If we're here, then the positional item exists, is non-blank, and is not an option.
  # This means it's a non-option param (file, etc) and we need to keep processing.
  NONOPT_ARGS+=( "${OPT}" )
  return 0
}
