#!/bin/bash

#@Author    Kyle Harper
#@Date      2013.07.07
#@Version   0.1-beta
#@Namespace core

#@Description  These functions serve as some of the primative tools and requirements for all of SBT.  This will likely become a large namespace.


#
# -- Initialize Globals for this Namespace
#
__SBT_NONOPT_ARGS=()



function core_getopts {
  #@Description  Largely backward compatible replacement for the built-in getopts routine in Bash.  It allows long options, that's the only change.  Long and short options can use a-z A-Z and 0-9 (and hyphens for long opts).
  #@Description  Long options are comma separated.  Adding a colon after an option (but before the comma) implies an argument should follow; same as the built-in getopts.
  #@Description  -
  #@Description  We will use positional numeric parameters because BASH_ARGV only exists when extdebug is on and it pushes/pops up to $9.  Positionals go up to ${10}+ if you use braces for proper interpolation.
  #@Description  -
  #@Description  This breaks the typical naming convention (upper/proper-casing  latter segement of function name) on purpose.
  #@Description  -
  #@Description  A note about the OPTIND global.  Bash uses this and so do we.  But we have added a niceness feature.  This is it:
  #@Description  Ok... this will send OPTIND back to default when we're done.  The normal getopts doesn't do this niceness.  I deviate here because the only time it'll conflict is if getopts case statement in a caller hits a function which does its own getopts. BUT!!!  For this to work in normal bash getopts, you need:  local OPTIND=1 anyway.

  #@$1  The list short options, same as bash built-in getopts.
  #@$2  Textual name of the variable to send back to the caller, same as built-in getopts.
  #@$3  A list of the allowed long options.  Even if it's blank, it must be passed: ""
  #@$4  The arguments sent to the caller and now passed to us.  It should always be passed quoted, like so:  "$@"

  # Make sure we have positional arguments 1 2 3 and 4.
  if [ -z "${4}" ] || [ -z "${2}" ] || [ -z "${1}" ] ; then
    core_Error "Invalid invocation of core_getopts."
    return 1
  fi

  # Clean out OPTARG
  OPTARG=''             #@$ Stores the value for any options require an additional argument.
  local __OPT=''        #@$ Holds the positional argument based on OPTIND.
  local temp_opt        #@$ Used for parsing against __OPT to find a match.
  local -i i            #@$ Loop control, that's it.
  local MY_OPTIND       #@$ Holds the correctly offset OPTIND for grabbing arguments (because this function absorbs 1, 2, and 3 for control).
                        #@$SHORT_OPTIND Index of shortopts if multiple are passed in a single switch: -abc

  # If we're on the first index, turn off OPTERR if our prescribed opts start with a colon.
  if [ ${OPTIND} -eq 1 ] ; then
    OPTERR=1
    SHORT_OPTIND=1
    if [ "${1:0:1}" == ':' ] || [ "${3:0:1}" == ':' ] ; then
      OPTERR=0
    fi
  fi

  while true ; do
    # If the item was a non-switch item (__SBT_NONOPT_ARGS), we will loop multiple times.  Ergo, reset vars here.
    __OPT=''
    temp_opt=''
    MY_OPTIND=${OPTIND}
    let MY_OPTIND+=3
    let OPTIND++

    # Try to store positional argument in __OPT.  If the option we tried to store in __OPT is blank, we're done.
    eval __OPT="\"\${${MY_OPTIND}}\""
    if [ -z "${__OPT}" ] ; then OPTIND=1 ; return 1 ; fi

    # If the __OPT has an equal sign, we need to place the right-hand contents in value and trim __OPT.
    if [[ "${__OPT}" =~ ^--[a-zA-Z0-9][a-zA-Z0-9-]*= ]] || [[ "${__OPT}" =~ ^-[a-zA-Z0-9][a-zA-Z0-9-]*= ]] ; then
      OPTARG="${__OPT##*=}"
      __OPT="${__OPT%%=*}"
    fi

    # If __OPT is a short opt with muliple switches at once, read/modify the SHORT_OPTIND and __OPT.
    # Also need to decrement OPTIND, it can't have an optarg unless it's the last one.
    if [[ "${__OPT}" =~ ^-[a-zA-Z0-9][a-zA-Z0-9]+ ]] ; then
      if [ -z "${__OPT:${SHORT_OPTIND}:1}" ] ; then
        SHORT_OPTIND=1
        break
      fi
      __OPT="-${__OPT:${SHORT_OPTIND}:1}"
      let SHORT_OPTIND++
      [ ! -z "${__OPT:${SHORT_OPTIND}:1}" ] && let OPTIND--
    fi

    ##############################################
    #  Try to match__OPT against a long option.  #
    ##############################################
    if [ "${__OPT:0:2}" == '--' ] ; then
      __OPT="${__OPT:2}"
      if [ ${#__OPT} -lt 1 ] ; then
        core_Error "Long option attempted (--) but no name found."
        return 1
      fi
      for temp_opt in ${3//,/ } ; do
        if [ "${temp_opt%:}" = "${__OPT}" ] ; then
          eval $2="\"${temp_opt%:}\""
          if [ "${temp_opt: -1}" == ':' ] && [ -z "${OPTARG}" ] ; then
            let OPTIND++
            let MY_OPTIND++
            eval OPTARG="\"\${${MY_OPTIND}}\""
            if [ ${OPTERR} -ne 0 ] && [ -z "${OPTARG}" ] ; then
              core_Error "Option specified (--${__OPT}) requires a value."
              return 1
            fi
          fi
          return 0
        fi
      done
      # No options were found in the allowed list.  Send a warning, if necessary, and return failure.
      if [ ${OPTERR} -ne 0 ] ; then
        core_Error "Invalid argument: --${__OPT}"
        return 1
      fi
      # If we're not handling errors internally, set the return value and let the user handle it.  Set OPTARG too because bash does... odd.
      eval $2="\"${__OPT}\""
      eval OPTARG="\"${__OPT}\""
      return 0
    fi

    ###############################################
    #  Try to match __OPT against a short option  #
    ###############################################
    if [ "${__OPT:0:1}" == '-' ] ; then
      __OPT="${__OPT:1}"
      if [ ${#__OPT} -lt 1 ] ; then
        core_Error "Short option attempted (-) but no name found."
        return 1
      fi
      i=0
      while [ $i -lt ${#1} ] ; do
        temp_opt="${1:${i}:1}"
        if [ "${temp_opt}" = "${__OPT}" ] ; then
          eval $2="\"${temp_opt}\""
          let i++
          if [ "${1:${i}:1}" == ':' ] && [ -z "${OPTARG}" ] ; then
            let OPTIND++
            let MY_OPTIND++
            eval  OPTARG="\"\${${MY_OPTIND}}\""
            if [ ${OPTERR} -ne 0 ] && [ -z "${OPTARG}" ] ; then
              core_Error "Option specified (-${__OPT}) requires a value."
              return 1
            fi
          fi
          return 0
        fi
        let i++
      done
      # No options were found in the allowed list.  Send a warning, if necessary, and return failure.
      if [ ${OPTERR} -ne 0 ] ; then
        core_Error "Invalid argument: -${__OPT}"
        return 1
      fi
      # If we're not handling errors internally, set the return value and let the user handle it.  Set OPTARG too because bash does... odd.
      eval $2="\"${__OPT}\""
      eval OPTARG="\"${__OPT}\""
      return 0
    fi

    # If we're here, then the positional item exists, is non-blank, and is not an option.
    # This means it's a non-option param (file, etc) and we need to keep processing.
    __SBT_NONOPT_ARGS+=( "${__OPT}" )
  done
  return 1  # This should never be reached
}

function core_Error {
  #@Description  Mostly for internal use.  It allows SBT to present errors, warnings, and similar in a concise fashion.
  #@Description  -
  #@Description  Still under development, needs a lot of work.

  #@Date    2013.07.09
  #@Version alpha

  local opt=''                #@$ Temporary variable to hold option for getopts parsing.
  local switches=''           #@$ The switches to send to echo.
  local OPTIND=1              #@$ Resetting OPTIND for this scope to handle getopts properly.
  local __SBT_NONOPT_ARGS=()  #@$ Capture non-opt args for sending out with echo

  while core_getopts ':en' opt '' "$@" ; do
    case "${opt}" in
      'e' ) switches+=" -${opt}" ;;
      'n' ) switches+=" -${opt}" ;;
      *   ) echo "Invalid option sent to core_Error: ${opt}" >&2 ; return 1 ;;
    esac
  done
  shift $(( ${OPTIND} - 1 ))

  echo ${switches} "${__SBT_NONOPT_ARGS[@]}" >&2
}
