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

declare -a __SBT_NONOPT_ARGS         #@$ Holds all arguments sent to getopts that are not part of the switch syntax.  Unique to SBT.  Similar to BASH_ARGV, only better.  Can store unlimited options, BASH_ARGV stores a max of 10, and in reverse order which is unintuitive when processing as-passed-in.
declare -i __SBT_SHORT_OPTIND=1      #@$ Tracks the position of the short option if they're side by side -abcd etc.  Unique to SBT.
declare -A __SBT_TOOL_LIST           #@$ List of all tools asked for by SBT.  Prevent expensive lookups with recurring calls.
           __SBT_VERBOSE=false       #@$ Enable or disable verbose messages for debugging.
           __SBT_WARNING=true        #@$ Enable or disable warning messages.
declare -r __SBT_ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." ; pwd)"   #@$ Root directory for the SBT system when sourced properly
declare -r __SBT_EXT_DIR="${SBT_ROOT_DIR}/sbt/ext"                                             #@$ Extension directory for non-bash functions
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

  # Invocation and preflight checks.
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
          core_LogVerbose "Successfully captured a long option. Leaving returning 0."
          return 0
        fi
      done
      # No options were found in the allowed list.  Send a warning, if necessary, and return failure.
      if [ ${OPTERR} -ne 0 ] ; then
        core_LogError "Invalid argument: --${__OPT}"
        return 1
      fi
      # If we're not handling errors internally. Return success and let the user handle it.  Set OPTARG too because bash does... odd.
      core_LogVerbose "Found an option that isn't in the list but I was told to shut up about it:  --${__OPT}"
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
          core_LogVerbose "Successfully captured a short option. Leaving returning 0."
          return 0
        fi
        let i++
      done
      # No options were found in the allowed list.  Send a warning, if necessary, and return failure.
      if [ ${OPTERR} -ne 0 ] ; then
        core_LogError "Invalid argument: -${__OPT}"
        return 1
      fi
      # If we're not handling errors internally. Return success and let the user handle it.  Set OPTARG too because bash does... odd.
      core_LogVerbose "Found an option that isn't in the list but I was told to shut up about it:  -${__OPT}"
      eval $2="\"${__OPT}\""
      eval OPTARG="\"${__OPT}\""
      return 0
    fi

    # If we're here, then the positional item exists, is non-blank, and is not an option.
    # This means it's a non-option param (file, etc) and we need to keep processing.
    core_LogVerbose 'Argument sent not actually an option, storing in __SBT_NONOPT_ARGS array and moving to next positional argument.'
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

  # Setup variables
  local switches=''                                #@$ Keep track of the switches to send to echo.  This function accepts them the same as echo builtin does.  Sorry printf
  local -i spaces=$(( (${#FUNCNAME[@]} - 2) * 2))  #@$ Track the number of spaces to send

  while true ; do
    if [ "${1:0:1}" == '-' ] ; then switches+=" ${1}" ; shift ; continue ; fi
    break
  done

  printf "%${spaces}s" >&2
  echo ${switches} "(${FUNCNAME[1]}: ${BASH_LINENO[0]})  $@" >&2
  return 0
}


function core_ToolExists {
  #@Description  Find an executable program with the names given.  Variables are stored in __SBT_TOOL_LIST hash.  Help ensure portability.
  #@Description  -
  #@Description  SBT functions should never use this for tools in the known-dependencies list.  This is primarily: coreutils, grep, and perl.
  #@Description  You may specify multiple tools to check for, but if you pass version checking switches they must apply to all tools for this call.  If version numbers, version invocation, or other switches are different for the tools, perform multiple calls in your caller.
  #@Date  2013.07.15

  # Variables
  local __SBT_NONOPT_ARGS=()                #@$ Capture a list of tools for use.  Localize array since we'll only use it here.
  local -i MAJOR=0                          #@$ Major version number
  local -i MEDIUM=0                         #@$ Medium version number
  local -i MINOR=0                          #@$ Minor version number
  local EXACT=false                         #@$ Compare the version numbers exactly, not in a greater-than fashion
  local VERSION_SWITCH='--version'          #@$ The switch syntax to present the version information string
  local REGEX_PATTERN='\d+\.\d+([.]\d+)?'   #@$ The PCRE (grep -P) regex pattern to use to finding the version string.  By default MAJOR.MEDIUM only.
  local tool=''                             #@$ Temp variable to hold tool name, kept in local scope.
  local found_version=''                    #@$ Misc temp variable, kept in local scope.

  # Invocation
  core_LogVerbose 'Entering function.'

  # Get a list of options and commands to check for
  core_LogVerbose 'Checking options and loading tools to check into array.'
  while core_getopts ':1:2:3:er:v:' opt ':exact,major:,medium:,minor:,regex-pattern:,version-switch:' "$@" ; do
    case "${opt}" in
      '1' | 'major'          ) MAJOR="${OPTARG}"          ;;  #@opt_  Sets the major version number for comparison.
      '2' | 'medium'         ) MEDIUM="${OPTARG}"         ;;  #@opt_  Sets the medium version number for comparison.
      '3' | 'minor'          ) MINOR="${OPTARG}"          ;;  #@opt_  Sets the minor version number for comparison.
      'e' | 'exact'          ) EXACT=true                 ;;  #@opt_  Make the version match exactly, rather than greater-than.
      'r' | 'regex-pattern'  ) REGEX_PATTERN="${OPTARG}"  ;;  #@opt_  Specify a custom regex pattern for getting the version number from program output.
      'v' | 'version-switch' ) VERSION_SWITCH="${OPTARG}" ;;  #@opt_  Specify a custom switch to use to get version information from the program output.
      *                      ) core_LogError "Invalid option for the core_ToolExists function:  ${opt}  (continuing)" ;;
    esac
  done

  core_LogVerbose 'Doing pre-flight checks to make sure all necessary options were passed.'
  # No checks

  core_LogVerbose "Checking for programs/tools.  Exact: ${EXACT}.  Version: ${MAJOR}.${MEDIUM}.${MINOR}."
  for tool in ${__SBT_NONOPT_ARGS[@]} ; do
    core_LogVerbose "Scanning existing tool list for an previously found match of: ${tool}"
    found_version="${__SBT_TOOL_LIST[${tool}]}"
    if [ -z "${found_version}" ] ; then
      core_LogVerbose 'Not found.  Seeing if tool exists on our PATH anywhere.'
      if ! ${tool} ${VERSION_SWITCH} >/dev/null 2>/dev/null ; then
        core_LogError 'Could not find tool.  If caller is an SBT function, this is a problem as SBT includes all dependencies.  Please check lib directory and SBT invocation.'
        return 1
      fi
      core_LogVerbose "Trying to grab the version string for comparison using:  ${tool} ${VERSION_SWITCH} | grep -oP '${REGEX_PATTERN}'"
      found_version="$(${tool} ${VERSION_SWITCH} 2>/dev/null | grep -oP "${REGEX_PATTERN}")"
      if [ -z "${found_version}" ] ; then
        core_LogError "Could not find a version string in program output.  If caller is an SBT function, this shouldn't have happened."
        return 1
      fi
    fi
    core_LogVerbose "Found the version string: '${found_version}'.  Comparing it now."
    if ${EXACT} && [ ! "${found_version}" == "${MAJOR}.${MEDIUM}.${MINOR}" ] ; then
      core_LogError 'Exact version match requested, but the versions do not match.  Failing.'
      return 1
    fi
    if [ "$(echo -e "${found_version}\n${MAJOR}.${MEDIUM}.${MINOR}" | sort -V | head -n 1)" == "${found_version}" ] ; then
      core_LogError 'Tool found is a lower version number than required version.'
      return 1
    fi
    core_LogVerbose 'Found tool and it meets requirements!  Storing in __SBT_TOOL_LIST hash for faster future lookups.'
    __SBT_TOOL_LIST["${tool}"]="${found_version}"
  done
  # If we reach this point, we found all the programs.
  return 0
}


function core_SetToolPath {
  #@Description  Any tools that SBT relies on can be compiled and provided with the SBT bundles.  This function will prepend the path specified to $PATH, ensuring it is used before other versions found on the system.
  #@Date  2013.09.16

  # Preflight checks
  core_LogVerbose 'Entering function and starting preflight checks.'
  if [ -z "${1}" ]   ; then core_LogError 'No path sent, cannot prepend nothing to PATH variable.  (aborting)' ; return 1 ; fi
  if [ ! -d "${1}" ] ; then core_LogError "Path specified doesn't exist or is not a directory.  (aborting)"    ; return 1 ; fi

  # Set path with new info
  core_LogVerbose "Adding directory to path, new path will be:  ${1}:${PATH}"
  PATH="${1}:${PATH}"

  return 0
}
