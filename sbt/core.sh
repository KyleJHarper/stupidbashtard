#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


#@Author    Kyle Harper
#@Date      2013.07.07
#@Version   0.1-beta
#@Namespace core

#@Description  These functions serve as some of the primative tools and requirements for all of SBT.  This will likely become a large namespace, but attempts should be made to keep it as small as possible.  ALL modules require this namespace.  No other namespace should be a wide-spread requirement like this.


#
# -- Initialize Globals for this Namespace
#
           __SBT_VERBOSE=false       #@$ Enable or disable verbose messages for debugging.
           __SBT_WARNING=true        #@$ Enable or disable warning messages.
declare -i __SBT_SHORT_OPTIND=1      #@$ Tracks the position of the short option if they're side by side -abcd etc.  Unique to SBT.
declare -a __SBT_NONOPT_ARGS         #@$ Holds all arguments sent to getopts that are not part of the switch syntax.  Unique to SBT.  Similar to BASH_ARGV, only better.  Can store unlimited options, BASH_ARGV stores a max of 10, and in reverse order which is unintuitive when processing as-passed-in.
declare -A __SBT_TOOL_LIST           #@$ List of all tools asked for by SBT.  Prevent expensive lookups with recurring calls.
OPTIND=1                             #@$ Tracks the position of the argument we're reading.  Bash internal.
OPTARG=''                            #@$ Holds either the switch active in getopts, or the value sent to the switch if it's compulsory.  Bash internal.
OPTERR=1                             #@$ Flag to determine if getopts should report invalid switches itself or rely in case statement in caller.  Bash internal.



function core_getopts {
  #@Description  Largely backward compatible replacement for the built-in getopts routine in Bash.  It allows long options, that's the only major change.  Long and short options can use a-z A-Z and 0-9 (and hyphens for long opts, but long opt names cannot start or end with a hyphen).  Long options are comma separated.  Adding a colon after an option (but before the comma) implies an argument should follow; same as the built-in getopts.
  #@Description  -
  #@Description  We will use positional numeric parameters because BASH_ARGV only exists when extdebug is on and it pushes/pops up to $9.  Positionals go up to ${10}+ if you use braces for proper interpolation.  Additional non-option arguments are stored in __SBT_NONOPT_ARGS to make life easier.  You're welcome.
  #@Description  -
  #@Description  This function breaks the typical naming convention (upper/proper-casing latter segement of function name) on purpose.  It makes it more in line with the internal getopts naming convention, plus it makes scanning with Docker easier.
  #@Description  -
  #@Description  A note about the OPTIND global.  Bash uses this and so do we.  But we have added a niceness feature.  This is it:
  #@Description  SBT's getopts will set OPTIND back to default when we're done.  The normal getopts doesn't do this niceness.  I deviate here because the only time it'll conflict is if a getopts case statement in a caller hits a function which does its own getopts. BUT!!!  For this to work in normal bash getopts, you need:  local OPTIND=1 anyway.  So we fix add one niceness without affecting anticipated logic.

  #@Date  2013.07.13

  #@$1  The list short options, same format as bash built-in getopts.
  #@$2  Textual name of the variable to send back to the caller, same as built-in getopts.
  #@$3  A list of the allowed long options.  Even if it's blank, it must be passed: "" or ''
  #@$4  The arguments sent to the caller and now passed to us.  It should always be passed quoted, like so:  "$@"  (NOT "$*").
  #@$4  You must use the 'at' symbol, not asterisk.  Otherwise the positionals will be merged into a single word.

  #Invocation and preflight checks.
  core_LogVerbose 'Entering function.'
  if [ -z "${4}" ] || [ -z "${2}" ] || [ -z "${1}" ] ; then
    core_LogError "Invalid invocation of core_getopts."
    return 1
  fi

  # Clean out OPTARG and setup variables
  core_LogVerbose 'Setting up variables.'
  OPTARG=''
  local __OPT=''        #@$ Holds the positional argument based on OPTIND.
  local temp_opt        #@$ Used for parsing against __OPT to find a match.
  local -i i            #@$ Loop control, that's it.
  local -i MY_OPTIND    #@$ Holds the correctly offset OPTIND for grabbing arguments (because this function shifts 1, 2, and 3 for control).

  # If we're on the first index, turn off OPTERR if our prescribed opts start with a colon.
  core_LogVerbose 'Checking to see if OPTIND is 1 so we can reset items.'
  if [ ${OPTIND} -eq 1 ] ; then
    core_LogVerbose 'OPTIND is 1.  Resetting OPTERR and __SBT_SHORT_OPTIND.'
    OPTERR=1
    __SBT_SHORT_OPTIND=1
    if [ "${1:0:1}" == ':' ] || [ "${3:0:1}" == ':' ] ; then
      core_LogVerbose 'Error handling overriden, to be handled by caller.  OPTERR disabled.'
      OPTERR=0
    fi
  fi

  core_LogVerbose 'Starting loop to find the option sent.'
  while true ; do
    # If the item was a non-switch item (__SBT_NONOPT_ARGS), we will loop multiple times.  Ergo, reset vars here.
    core_LogVerbose "Clearing variables for loop with OPTIND of ${OPTIND}"
    __OPT=''
    temp_opt=''
    MY_OPTIND=${OPTIND}
    let MY_OPTIND+=3
    let OPTIND++

    # Try to store positional argument in __OPT.  If the option we tried to store in __OPT is blank, we're done.
    core_LogVerbose 'Assigning value to __OPT and leaving if blank.'
    eval __OPT="\"\${${MY_OPTIND}}\""
    if [ -z "${__OPT}" ] ; then OPTIND=1 ; return 1 ; fi

    # If the __OPT has an equal sign, we need to place the right-hand contents in value and trim __OPT.
    if [[ "${__OPT}" =~ ^--[a-zA-Z0-9][a-zA-Z0-9-]*= ]] || [[ "${__OPT}" =~ ^-[a-zA-Z0-9][a-zA-Z0-9-]*= ]] ; then
      core_LogVerbose 'Option specified has a value via assignment operator (=).  Settint OPTARG and re-setting __OPT.'
      OPTARG="${__OPT##*=}"
      __OPT="${__OPT%%=*}"
    fi

    # If __OPT is a short opt with muliple switches at once, read/modify the __SBT_SHORT_OPTIND and __OPT.
    # Also need to decrement OPTIND, it can't have an optarg unless it's the last one.
    if [[ "${__OPT}" =~ ^-[a-zA-Z0-9][a-zA-Z0-9]+ ]] ; then
      core_LogVerbose "Option is short and compacted (-abc...).  Getting new __OPT with short index of ${__SBT_SHORT_OPTIND}"
      if [ -z "${__OPT:${__SBT_SHORT_OPTIND}:1}" ] ; then
        __SBT_SHORT_OPTIND=1
        break
      fi
      __OPT="-${__OPT:${__SBT_SHORT_OPTIND}:1}"
      let __SBT_SHORT_OPTIND++
      [ ! -z "${__OPT:${__SBT_SHORT_OPTIND}:1}" ] && let OPTIND--
    fi

    ###############################################
    #  Try to match __OPT against a long option.  #
    ###############################################
    if [ "${__OPT:0:2}" == '--' ] ; then
      core_LogVerbose 'Option is long format.  Processing as such.'
      __OPT="${__OPT:2}"
      if [ ${#__OPT} -lt 1 ] ; then
        core_LogError "Long option attempted (--) but no name found."
        return 1
      fi
      core_LogVerbose "Searching available options for option specified: ${__OPT}"
      for temp_opt in ${3//,/ } ; do
        if [ "${temp_opt%:}" = "${__OPT}" ] ; then
          core_LogVerbose "Found a matching option.  Assigning to: $2"
          eval $2="\"${temp_opt%:}\""
          if [ "${temp_opt: -1}" == ':' ] && [ -z "${OPTARG}" ] ; then
            core_LogVerbose "Option sent (${__OPT}) requires an argument; gathering now."
            let OPTIND++
            let MY_OPTIND++
            eval OPTARG="\"\${${MY_OPTIND}}\""
            if [ ${OPTERR} -ne 0 ] && [ -z "${OPTARG}" ] ; then
              core_LogError "Option specified (--${__OPT}) requires a value."
              return 1
            fi
          fi
          return 0
        fi
      done
      # No options were found in the allowed list.  Send a warning, if necessary, and return failure.
      if [ ${OPTERR} -ne 0 ] ; then
        core_LogError "Invalid argument: --${__OPT}"
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
      core_LogVerbose 'Option is short format.  Processing as such.'
      __OPT="${__OPT:1}"
      if [ ${#__OPT} -lt 1 ] ; then
        core_LogError "Short option attempted (-) but no name found."
        return 1
      fi
      core_LogVerbose "Searching available options for option specified: ${__OPT}"
      i=0
      while [ $i -lt ${#1} ] ; do
        temp_opt="${1:${i}:1}"
        if [ "${temp_opt}" = "${__OPT}" ] ; then
          core_LogVerbose "Found a matching option.  Assigning to: $2"
          eval $2="\"${temp_opt}\""
          let i++
          if [ "${1:${i}:1}" == ':' ] && [ -z "${OPTARG}" ] ; then
            core_LogVerbose "Option sent (${__OPT}) requires an argument; gathering now."
            let OPTIND++
            let MY_OPTIND++
            eval  OPTARG="\"\${${MY_OPTIND}}\""
            if [ ${OPTERR} -ne 0 ] && [ -z "${OPTARG}" ] ; then
              core_LogError "Option specified (-${__OPT}) requires a value."
              return 1
            fi
          fi
          return 0
        fi
        let i++
      done
      # No options were found in the allowed list.  Send a warning, if necessary, and return failure.
      if [ ${OPTERR} -ne 0 ] ; then
        core_LogError "Invalid argument: -${__OPT}"
        return 1
      fi
      # If we're not handling errors internally, set the return value and let the user handle it.  Set OPTARG too because bash does... odd.
      eval $2="\"${__OPT}\""
      eval OPTARG="\"${__OPT}\""
      return 0
    fi

    # If we're here, then the positional item exists, is non-blank, and is not an option.
    # This means it's a non-option param (file, etc) and we need to keep processing.
    core_LogVerbose 'Argument sent not actually an option, storing in __SBT_NONOPT_ARGS array.'
    __SBT_NONOPT_ARGS+=( "${__OPT}" )
  done
  return 1  # This should never be reached
}


function core_Initialize {
  #@Description  Placeholder for logic required to initialize all functions in this namespace.  Globals are still external, meh.  Not sure this will ever be used.
  return 0
}


function core_LogError {
  #@Description  Mostly for internal use.  Sends info to std err if warnings are enabled.  No calls to other SBT functions allowed.
  #@Date    2013.07.14

  # Check for __SBT_WARNING first.
  ${__SBT_WARNING} || return 1

  while true ; do
    if [ "${1:0:1}" == '-' ] ; then switches+=" ${1}" ; shift ; continue ; fi
    break
  done
  echo ${switches} "(error in ${FUNCNAME[1]}: line ${BASH_LINENO[0]})  $@" >&2
  return 0
}


function core_LogVerbose {
  #@Description  Mostly for internal use.  Sends info to std err if verbosity is enabled.  No calls to other SBT functions allowed.
  #@Date    2013.07.14

  # Check for __SBT_VERBOSE first.  Save a lot of time if verbosity isn't enabled.
  ${__SBT_VERBOSE} || return 1

  while true ; do
    if [ "${1:0:1}" == '-' ] ; then switches+=" ${1}" ; shift ; continue ; fi
    break
  done
  echo ${switches} "(${FUNCNAME[1]}: line ${BASH_LINENO[0]})  $@" >&2
  return 0
}


function core_ToolExists {
  #@Description  Uses various means such as 'which', $PATH searching, and so forth to try to find an executable program with the names given.
  local __SBT_NONOPT_ARGS=()   #@$ Capture a list of tools for use.  Localize array since we'll only use it here.

  # Get a list of options and commands to check for
  while getopts ':' opt '' "$@" ; do
    case "${opt}" in
      * ) echo "Invalid option for the core_ToolExists function:  ${opt}  (continuing)" >&2 ;;
    esac
  done

#FINISH ME
  # If we reach this point, we couldn't find one or more of the programs.
  return 1;
}
