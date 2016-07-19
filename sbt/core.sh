# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


#@Author    Kyle Harper
#@Date      2013.07.07
#@Version   0.1.0
#@Namespace core

#@Description  These functions serve as some of the primative tools and requirements for all of SBT.  This will likely become a large namespace, but attempts should be made to keep it as small as possible.  ALL modules require this namespace.  No other namespace should be a wide-spread requirement like this.

#
# [Header Guard]
#
# We don't check for core because we are core... duh.
if [ ! -z "${__SBT_NAMESPACES_LOADED[core]}" ] ; then
  echo "The 'core' namespace has already been loaded.  You shouldn't have included it again.  Exiting for safety." >&2
  exit 1
fi
# We will load 'core' implicitly below due to a chicken-egg situation.


#
# -- Initialize Globals for this Namespace
#
# First Order
declare -a __SBT_NONOPT_ARGS                                                                   #@$ Holds all arguments sent to getopts that are not part of the switch syntax.  Unique to SBT.  Similar to BASH_ARGV, only better.  Can store unlimited options, BASH_ARGV stores a max of 10, and in reverse order which is unintuitive when processing as-passed-in.
declare -i __SBT_SHORT_OPTIND=1                                                                #@$ Tracks the position of the short option if they're side by side -abcd etc.  Unique to SBT.
declare    __SBT_NO_MORE_OPTS=false                                                            #@$ If a double hypen (--) is passed, we put all future items into __SBT_NONOPT_ARGS.
declare    __SBT_VERBOSE=false                                                                 #@$ Enable or disable verbose messages for debugging.
declare    __SBT_WARNING=true                                                                  #@$ Enable or disable warning messages.
declare -r __SBT_UUID="$(uuidgen)"                                                             #@$ Unique identifier for the invocation of SBT globally.  It's relatively safe to use if you want to, but it's mostly for internal purposes.  The uuidgen program is part of util-linux, which is an SBT requirement.
declare -r __SBT_ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." ; pwd)"   #@$ Root directory for the SBT system when sourced properly
declare -r __SBT_TRAP_FUNCTION='core__shutdown'                                                #@$ Contains the name of the function to run when an EXIT trap is set up.  Core will automatically set this.  If you set your own traps, you need to include this for proper shutdown processing.
declare -a __SBT_SHUTDOWN_REGISTRY                                                             #@$ Collection of events that have been registered for execution at shutdown.
declare    __SBT_LOG_FILE=''                                                                   #@$ Location of the log file for core__log_verbose and core__log_error.  When set to an empty string, no file logging is done.  Cannot be a relative path.
           OPTIND=1                                                                            #@$ Tracks the position of the argument we're reading.  Bash internal.
           OPTARG=''                                                                           #@$ Holds either the switch active in getopts, or the value sent to the switch if it's compulsory.  Bash internal.
           OPTERR=1                                                                            #@$ Flag to determine if getopts should report invalid switches itself or rely in case statement in caller.  Bash internal.
# Second Order
declare -r __SBT_EXT_DIR="${__SBT_ROOT_DIR}/sbt/ext"                                           #@$ Extension directory for non-bash functions
declare -A __SBT_NAMESPACES_LOADED=([core]='loaded')                                           #@$ Tracks sources which have already been loaded.
declare    __SBT_TMP_DIR="/tmp/sbt/${__SBT_UUID}"                                              #@$ Global temp directory for misc stuff.



function core__getopts {
  #@Description  Largely backward compatible replacement for the built-in getopts routine in Bash.  It allows long options, that's the only major change.  Long and short options can use a-z A-Z and 0-9 (and hyphens for long opts, but long opt names cannot start or end with a hyphen).  Long options are comma separated.  Adding a colon after an option (but before the comma) implies an argument should follow; same as the built-in getopts.
  #@Description  -
  #@Description  We will use positional numeric parameters because BASH_ARGV only exists when extdebug is on and it pushes/pops up to $9.  Positionals go up to ${10}+ if you use braces for proper interpolation.  Additional non-option arguments are stored in __SBT_NONOPT_ARGS to make life easier.  You're welcome.
  #@Description  -
  #@Description  A note about the OPTIND global.  Bash uses this and so do we.  But we have added a niceness feature.  This is it:
  #@Description  SBT's getopts will set OPTIND back to default when we're done.  The normal getopts doesn't do this niceness.  I deviate here because the only time it'll conflict is if a getopts case statement in a caller hits a function which does its own getopts. BUT!!!  For this to work in normal bash getopts, you need:  local OPTIND=1 anyway.  So we add one niceness without affecting anticipated logic.  It is still perfectly safe and frankly quite reasonable to add local OPTIND to each function to avoid reliance on the parent/global OPTIND anyway.

  #@Date  2013.07.13
  #@Usage core__getopts <'short options'> <'return_variable_name'> <'long options'> <"$@">

  #@$1  The list short options, same format as bash built-in getopts.
  #@$2  Textual name of the variable to send back to the caller, same as built-in getopts.
  #@$3  A list of the allowed long options.  Even if it's blank, it must be passed: "" or ''
  #@$4  The arguments sent to the caller and now passed to us.  It should always be passed quoted, like so:  "$@"  (NOT "$*").
  #@$4  You must use the 'at' symbol, not asterisk.  Otherwise the positionals will be merged into a single word.

  # Invocation and preflight checks.  Clean out OPTARG and setup variables.
  core__log_verbose 'Entering function.'
  core__log_verbose 'Setting up variables.'
  OPTARG=''
  local    _opt_=''     #@$ Holds the positional argument based on OPTIND.  Needs to be unique compared to all callers because we use eval!
  local    _temp_opt    #@$ Used for parsing against _opt_ to find a match.
  local -i _i           #@$ Loop control, that's it.
  local -i _my_optind   #@$ Holds the correctly offset OPTIND for grabbing arguments (because this function shifts 1, 2, and 3 for control).
  local -i E_GENERIC=1  #@$ Basic catch-all.  Used when option parsing should stop for expected reasons (like no more options found).
  local -i E_UHOH=2     #@$ If a parsing error occurs that is fatal, send this code.

  # Invocation and preflight checks.
  if [ -z "${1}" ] && [ -z "${3}" ] ; then core__log_error   'Both short and long options ($1 and $3) are blank.  Aborting.'     ; return ${E_UHOH}    ; fi
  if [ -z "${2}" ]                  ; then core__log_error   'Variable to assign option to ($2) is blank.'                       ; return ${E_UHOH}    ; fi
  if [ "${#@}" -lt 4 ]              ; then core__log_verbose 'No positionals were sent ($4+), odd.  Not an error, but aborting.' ; return ${E_GENERIC} ; fi

  # If we're on the first index, turn off OPTERR if our prescribed opts start with a colon.
  core__log_verbose 'Checking to see if OPTIND is 1 so we can reset items.'
  if [ ${OPTIND} -eq 1 ] ; then
    core__log_verbose 'OPTIND is 1.  Resetting OPTERR and __SBT_NO_MORE_OPTS.'
    OPTERR=1
    __SBT_NO_MORE_OPTS=false
    if [ "${1:0:1}" == ':' ] || [ "${3:0:1}" == ':' ] ; then
      core__log_verbose 'Error handling overriden, to be handled by caller.  OPTERR disabled.'
      OPTERR=0
    fi
  fi

  core__log_verbose 'Starting loop to find the option sent.'
  while true ; do
    # If the item was a non-switch item (__SBT_NONOPT_ARGS), we will loop multiple times.  Ergo, reset vars here.
    core__log_verbose "Clearing variables for loop with OPTIND of ${OPTIND}"
    _opt_=''
    _temp_opt=''
    _my_optind=${OPTIND}
    let _my_optind+=3
    let OPTIND++

    # Try to store positional argument in _opt_.  If the option we tried to store in _opt is blank, we're done.
    core__log_verbose 'Assigning value to _opt_.'
    eval "_opt_=\"\${${_my_optind}}\""
    if [ -z "${_opt_}" ] ; then
      if [ ${_my_optind} -le ${#@} ] ; then
        core__log_verbose "The positional was blank, but there may be more positionals to grab.  Storing the empty value in __SBT_NONOPT_ARGS and continuing."
        __SBT_NONOPT_ARGS+=('')
        continue
      fi
      core__log_verbose "The positional was blank and we're out of them.  There's nothing left to process.  Reset for niceness and return 1."
      OPTIND=1
      __SBT_SHORT_OPTIND=1
      return ${E_GENERIC}
    fi

    # If the _opt_ has an equal sign, we need to place the right-hand contents in value and trim _opt_.
    if [[ "${_opt_}" =~ ^--[a-zA-Z0-9][a-zA-Z0-9-]*= ]] || [[ "${_opt_}" =~ ^-[a-zA-Z0-9][a-zA-Z0-9-]*= ]] ; then
      core__log_verbose 'Option specified has a value via assignment operator (=).  Setting OPTARG and re-setting _opt_.'
      OPTARG="${_opt_##*=}"
      _opt_="${_opt_%%=*}"
    fi

    # Check for a double hyphen (--) and/or __SBT_NO_MORE_OPTS setting.
    if [ "${_opt_}" = '--' ] ; then core__log_verbose "Found bare double-hyphen (--).  Disabling option parsing."  ; __SBT_NO_MORE_OPTS=true           ; continue ; fi
    if ${__SBT_NO_MORE_OPTS} ; then core__log_verbose "__SBT_NO_MORE_OPTS flag set, storing in __SBT_NONOPT_ARGS." ; __SBT_NONOPT_ARGS+=( "${_opt_}" ) ; continue ; fi

    # If _opt_ is a short opt with muliple switches at once, read/modify the __SBT_SHORT_OPTIND and _opt_.
    # Also need to decrement OPTIND if we're on the last item in the compact list.
    if [[ "${_opt_}" =~ ^-[a-zA-Z0-9][a-zA-Z0-9]+ ]] ; then
      core__log_verbose "Option is short and compacted (-abc...).  Getting new _opt_ with short index of ${__SBT_SHORT_OPTIND} and incrementing short index."
      _temp_opt="-${_opt_:${__SBT_SHORT_OPTIND}:1}"
      let __SBT_SHORT_OPTIND++
      let OPTIND--
      if [ -z "${_opt_:${__SBT_SHORT_OPTIND}:1}" ] ; then
        core__log_verbose "Next SHORT_OPTIND makes empty string.  Setting SHORT_OPTIND to 1 and incrementing OPTIND back to next item."
        __SBT_SHORT_OPTIND=1
        let OPTIND++
      fi
      _opt_="${_temp_opt}"
    fi

    ###############################################
    #  Try to match _opt_ against a long option.  #
    ###############################################
    if [ "${_opt_:0:2}" == '--' ] ; then
      core__log_verbose 'Option is long format.  Processing as such.'
      _opt_="${_opt_:2}"
      if [ ${#_opt_} -lt 1 ] ; then
        core__log_error "Long option attempted (--) but no name found."
        OPTIND=1
        return ${E_UHOH}
      fi
      core__log_verbose "Searching available options for option specified: ${_opt_}"
      for _temp_opt in ${3//,/ } ; do
        [ "${_temp_opt:0:1}" = ':' ] && _temp_opt="${_temp_opt:1}"
        if [ "${_temp_opt%:}" = "${_opt_}" ] ; then
          core__log_verbose "Found a matching option.  Assigning to: $2"
          eval "$2=\"${_temp_opt%:}\""
          if [ "${_temp_opt: -1}" == ':' ] && [ -z "${OPTARG}" ] ; then
            core__log_verbose "Option sent (${_opt_}) requires an argument; gathering now."
            let OPTIND++
            let _my_optind++
            eval "OPTARG=\"\${${_my_optind}}\""
            if [ -z "${OPTARG}" ] ; then
              core__log_error "Option specified (--${_opt_}) requires a value."
              OPTIND=1
              return ${E_UHOH}
            fi
          fi
          core__log_verbose "Successfully captured a long option. Leaving returning 0."
          return 0
        fi
      done
      # No options were found in the allowed list.  Send a warning but keep going, because bash does... odd.
      if [ ${OPTERR} -ne 0 ] ; then
        core__log_error "Option specified (--${_opt_}) not found in list: '$3' (storing in __SBT_NONOPT_ARGS and continuing).  If you meant to send a non-option argument that starts with a hyphen, end getopts processing first with the double-hyphen switch: --"
        __SBT_NONOPT_ARGS+=( "${_opt_}" )
        continue
      fi
      # If we're not handling errors internally. Return success and let the user handle it.  Set OPTARG too because bash does... odd.
      core__log_verbose "Found an option that isn't in the list but I was told to shut up about it:  --${_opt_}"
      eval "$2=\"\${_opt_}\""
      eval "OPTARG=\"\${_opt_}\""
      return 0
    fi

    ###############################################
    #  Try to match _opt_ against a short option  #
    ###############################################
    if [ "${_opt_:0:1}" == '-' ] ; then
      core__log_verbose 'Option is short format.  Processing as such.'
      _opt_="${_opt_:1}"
      if [ ${#_opt_} -lt 1 ] ; then
        core__log_error "Short option attempted (-) but no name found."
        OPTIND=1
        return ${E_UHOH}
      fi
      core__log_verbose "Searching available options for option specified: ${_opt_}"
      _i=0
      while [ ${_i} -lt ${#1} ] ; do
        core__log_verbose "Checking item ${_i} with value of: ${1:${_i}:1}"
        _temp_opt="${1:${_i}:1}"
        if [ "${_temp_opt}" = "${_opt_}" ] ; then
          core__log_verbose "Found a matching option.  Assigning to: $2"
          eval "$2=\"\${_temp_opt}\""
          let _i++
          if [ "${1:${_i}:1}" == ':' ] && [ -z "${OPTARG}" ] ; then
            core__log_verbose "Option sent (${_opt_}) requires an argument; gathering now. Also resetting SHORT OPTIND, as it must be the end."
            __SBT_SHORT_OPTIND=1
            let OPTIND++
            let _my_optind++
            eval "OPTARG=\"\${${_my_optind}}\""
            if [ -z "${OPTARG}" ] ; then
              core__log_error "Option specified (-${_opt_}) requires a value."
              OPTIND=1
              return ${E_UHOH}
            fi
          fi
          core__log_verbose "Successfully captured a short option. Leaving returning 0."
          return 0
        fi
        let _i++
      done
      # No options were found in the allowed list.  Send a warning and continue on... because bash does :(
      if [ ${OPTERR} -ne 0 ] ; then
        core__log_error "Option specified (-${_opt_}) not found in list: '$1' (storing in __SBT_NONOPT_ARGS and continuing).  If you meant to send a non-option argument that starts with a hyphen, end getopts processing first with the double-hyphen switch: --"
        __SBT_NONOPT_ARGS+=( "${_opt_}" )
        continue
      fi
      # If we're not handling errors internally. Return success and let the user handle it.  Set OPTARG too because bash does... odd.
      core__log_verbose "Found an option that isn't in the list but I was told to shut up about it:  -${_opt_}"
      eval "$2=\"\${_opt_}\""
      eval "OPTARG=\"\${_opt_}\""
      return 0
    fi

    # If we're here, then the positional item exists, is non-blank, and is not an option.
    # This means it's a non-option param (file, etc) and we need to keep processing.
    core__log_verbose 'Argument sent not actually an option, storing in __SBT_NONOPT_ARGS array and moving to next positional argument.'
    __SBT_NONOPT_ARGS+=( "${_opt_}" )
  done
  OPTIND=1
  return ${E_UHOH}  # This should never be reached
}


function core__easy_getopts {
  #@Description  A much simpler function for getopts processing.  It acts like perl's getopts, putting them into opt_<name>.
  #@Description  Important: Long options with hyphens will be converted to underscores because hyphens are not allowed in bash variable names.  E.g.:  long-option becomes long_option.  The full option name assigned will be option_long_option.
  #@Description  -
  #@Description  Since variables are assigned automatically, they are top-scoped.  To help keep lexical scope the caller (parent function) should declare each possible option name.  For example, if you have options a, b, and c you should declare/local/typeset option_a, option_b, and option_c.  This will prevent the options from being thrown all the way to top scope which is probably not what you'll ever want to have happen.
  #@Date         2014.08.16
  #@Usage        core__easy_getopts <'short options'> <'long options'> "$@"

  #@$1  The list short options, same format as bash built-in getopts.
  #@$2  A list of the allowed long options.  Even if it's blank, it must be passed: "" or ''
  #@$3  The arguments sent to the caller and now passed to us.  It should always be passed quoted, like so:  "$@"  (NOT "$*").

  # Setup variables and shift out
  local -i    OPTIND=1          #@$ Localizing OPTIND to avoid scoping issues.
  local       _opt              #@$ Temporary option holder for the while-loop below.
  local -a    _opts_found=()    #@$ Stores all variables found for reporting later.
  local    -r _SHORT_OPTS="$1"  #@$ List of short options.  Will be passed directly to core__getopts.
  local    -r _LONG_OPTS="$2"   #@$ List of long optins.  Will be passed directly to core__getopts.
  local -i    _rc=0             #@$ Stored the return code from core__getopts so we can use it non-immediately.
  shift 2

  # Build the loop and start handling options.
  while true ; do
    core__getopts "${_SHORT_OPTS}" _opt "${_LONG_OPTS}" "$@"
    _rc=$?
    case ${_rc} in
      0 )  [[ "${_opt}" =~ - ]] && _opt="${_opt//-/_}"
           _opts_found+=("${_opt}")
           if [ -z "${OPTARG}" ] ; then
             core__log_verbose "Option found was '${_opt}' and OPTARG is blank.  Giving this option 'true' and continuing loop."
             eval "option_${_opt}=true"
             continue
           fi
           core__log_verbose "Option found was '${_opt}' and OPTARG has a value.  Assigning OPTARG to option and continuing loop."
           eval "option_${_opt}=\"\${OPTARG}\""
           ;;
      1 )  core__log_verbose "Received code 1, getopts is done.  Breaking loop."                     ; break    ;;
      2 )  core__log_error   "Received code 2 (E_UHOH) from core__getopts.  Returning failure here." ; return 1 ;;
      * )  core__log_error   "Received an unexpected return code (${_rc}).  Quitting here."          ; return 1 ;;
    esac
  done

  # All Done
  core__log_verbose "Option parsing done.  Variables found are: ${_opts_found[@]}"
  return 0
}


function core__initialize {
  #@Description  Creates a few necessary items.  For core, mostly directories for temp files that might get used by logging.
  #@Description  -
  #@Description  This should be called any time __SBT_TMP_DIR is changed.
  #@Date         2016.07.09
  #@Usage        core__initialize

  # Variables
  local -i -r E_GENERIC=1    #@$ Generic error.
  local -i -r E_BAD_PATH=11  #@$ Exit code when a path is wrong or somehow nonsensical.

  # We need to make sure the temp directory exists.
  core__log_verbose "Attempting to set up required directories for SBT internals; mostly logging related."
  if [ "${__SBT_TMP_DIR:0:1}" != '/' ] ; then
    core__log_error "The __SBT_TMP_DIR is set to a relative path (i.e.: it doesn't start with a forward slash):  ${__SBT_TMP_DIR}"
    return ${E_BAD_PATH}
  fi
  if [ ! -d "${__SBT_TMP_DIR}" ] ; then
    core__log_verbose "The __SBT_TMP_DIR doesn't exist.  Creating it."
    if ! mkdir -p "${__SBT_TMP_DIR}" ; then
      core__log_error "Failed to create the directory (and its parents) for the tmp/uuid directories:  ${__SBT_TMP_DIR}"
      return ${E_GENERIC}
    fi
  fi
  # Register the directory removal.
  core__register_shutdown_event "rm -r '${__SBT_TMP_DIR}'"

  # Set a trap for our shutdown registry.
  core__log_verbose "Setting an EXIT trap with function:  ${__SBT_TRAP_FUNCTION}"
  trap "${__SBT_TRAP_FUNCTION}" EXIT
  return 0
}


function core__log_error {
  #@Description  Mostly for internal use.  Sends info to std err if warnings are enabled.  No calls to other SBT functions allowed to prevent infinite loops.
  #@Date         2013.07.14
  #@Usage        core__log_error [-e] [-n] <'text to send' [...]>

  #@opt_e  Passes -e to echo for interpretation.
  #@opt_n  Passes -n to echo for interpretation.
  # Check for __SBT_WARNING first.
  ${__SBT_WARNING} || return 0

  # Setup variables
  local -i -r E_BAD_PATH=12                            #@$ Exit code for bad paths and permission issues.
  local       _switches=''                             #@$ Keep track of the switches to send to echo.  This function accepts them the same as echo builtin does.  Sorry printf
  local -i -r _SPACES=$(( (${#FUNCNAME[@]} - 2) * 2))  #@$ Track the number of spaces to send

  # Process options.  Can't use core__getopts or similar because a loop would occur.
  while true ; do
    if [ "${1:0:1}" == '-' ] ; then _switches+=" ${1}" ; shift ; continue ; fi
    break
  done

  # Print to stderr and file, if desired.
  printf "%${_SPACES}s" '' >&2
  echo ${_switches} "(error in ${FUNCNAME[1]}: ${BASH_LINENO[0]})  $@" >&2
  # If file logging is enabled, log.
  if [ ! -z "${__SBT_LOG_FILE}" ] ; then
    # If the __SBT_LOG_FILE isn't fully qualified, we have a problem.
    if [ "${__SBT_LOG_FILE:0:1}" != '/' ] ; then
      echo "The __SBT_LOG_FILE variable isn't set to a fully qualified path, this is a no-no:  ${__SBT_LOG_FILE}" >&2
      return ${E_BAD_PATH}
    fi
    # Try to touch the file to ensure we can write to it.
    if ! touch "${__SBT_LOG_FILE}" 2>/dev/null ; then
      echo "Cannot touch the __SBT_LOG_FILE.  Directory missing or permissions wrong:  ${__SBT_LOG_FILE}" >&2
      return ${E_BAD_PATH}
    fi
    # For now we will log directly to the file.  Future synchronization mechnisms might be necessary.
    printf "%${_SPACES}s" '' >>"${__SBT_LOG_FILE}"
    echo ${_switches} "(error in ${_error_string}${FUNCNAME[1]}: ${BASH_LINENO[0]})  $@" >>"${__SBT_LOG_FILE}"
  fi

  return 0
}


function core__log_verbose {
  #@Description  Mostly for internal use.  Sends info to std err if verbosity is enabled.  No calls to other SBT functions allowed to prevent infinite loops.
  #@Date   2013.07.14
  #@Usage  core__log_verbose [-e] [-n] <'text to send' [...]>

  #@opt_e  Passes -e to echo for interpretation.
  #@opt_n  Passes -n to echo for interpretation.

  # Check for __SBT_VERBOSE first.  Save a lot of time if verbosity isn't enabled.
  ${__SBT_VERBOSE} || return 0

  # Setup variables
  local -i -r E_BAD_PATH=12                            #@$ Exit code for bad paths and permission issues.
  local       _switches=''                             #@$ Keep track of the switches to send to echo.  This function accepts them the same as echo builtin does.  Sorry printf
  local -i -r _SPACES=$(( (${#FUNCNAME[@]} - 2) * 2))  #@$ Track the number of spaces to send

  # Process options.  Can't use core__getopts or similar because a loop would occur.
  while true ; do
    if [ "${1:0:1}" == '-' ] ; then _switches+=" ${1}" ; shift ; continue ; fi
    break
  done

  # Print to stderr and file, if desired.
  printf "%${_SPACES}s" '' >&2
  echo ${_switches} "(${FUNCNAME[1]}: ${BASH_LINENO[0]})  $@" >&2
  # If file logging is enabled, log.
  if [ ! -z "${__SBT_LOG_FILE}" ] ; then
    # If the __SBT_LOG_FILE isn't fully qualified, we have a problem.
    if [ "${__SBT_LOG_FILE:0:1}" != '/' ] ; then
      echo "The __SBT_LOG_FILE variable isn't set to a fully qualified path, this is a no-no:  ${__SBT_LOG_FILE}" >&2
      return ${E_BAD_PATH}
    fi
    # Try to touch the file to ensure we can write to it.
    if ! touch "${__SBT_LOG_FILE}" 2>/dev/null ; then
      echo "Cannot touch the __SBT_LOG_FILE.  Directory missing or permissions wrong:  ${__SBT_LOG_FILE}" >&2
      return ${E_BAD_PATH}
    fi
    # For now we will log directly to the file.  Future synchronization mechnisms might be necessary.
    printf "%${_SPACES}s" '' >>"${__SBT_LOG_FILE}"
    echo ${_switches} "(${_error_string}${FUNCNAME[1]}: ${BASH_LINENO[0]})  $@" >>"${__SBT_LOG_FILE}"
  fi

  return 0
}


function core__tool_exists {
  #@Description  Find an executable program with the names given.  Acts a lot like the 'which' program, but offers a few extra features.
  #@Description  You may specify multiple tools to check for, but if you pass version checking switches then you can only check for 1 tool at a time.
  #@Description  -
  #@Description  You may also specify multiple tools and the -a or --any switch, which will return true if Any of the tools match.  For example, you might want gawk by default, but you can reasonably trust whatever version of awk is on a system.  So you send: 'gawk' and 'awk' IN ORDER OF PREFERENCE!  The found tool will be reported to stdout unless -q/--quiet is sent.
  #@Description  -
  #@Description  Minimum and maximum versions are tested by using GNU sort -V along with the discovered version.  If you want an exact match, simply set minimum and maximum versions to the same value you want an exact match for.
  #@Date         2016.07.11
  #@Usage        core__tool_exists [-a --any] [-m --max-version ''] [-n --min-version ''] [-q --quiet] [-r --regex-pattern 'pattern'] [-v --version-switch '-V'] <'tool' [...]>

  # Variables
  local -a    __SBT_NONOPT_ARGS            #@$ Capture a list of tools for use.  Localize array since we'll only use it here.
  local -i    OPTIND=1                     #@$ Localizing OPTIND to avoid scoping issues.
  local       _opt=''                      #@$ Used for looping through getopts
  local -i -r E_GENERIC=1                  #@$ General error when there are problems.
  local -i -r E_BAD_CLI=2                  #@$ Return value if CLI is wrong or invalid.
  local -i -r E_CMD_NOT_FOUND=10           #@$ Help differentiate between a generic failure and a failure due to a tool not found.
  local       _min_version=''              #@$ The minimum version to tolerate.  Anything below this is a failure.
  local       _max_version=''              #@$ The maximum version to tolerate.  Anything above this is a failure.
  local -A    _tools_found                 #@$ A hash of the tools found.
  local       _any=false                   #@$ Flag to determine if we should abort when any of the tools checked for are found.
  local       _quiet=false                 #@$ Flag to disable the normal output for the --any flag (by default, we report the name of the tool found).
  local       _version_switch='--version'  #@$ The switch syntax to present the version information string.  Usually --version, -v, -V, -h, --help, etc...
  local       _regex_pattern=''            #@$ The PCRE (grep -P) regex pattern to use to finding the version string.  If empty, no version check is done.
  local       _tool=''                     #@$ Temp variable to hold tool name, kept in local scope.
  local       _found_version=''            #@$ Misc temp variable, kept in local scope.

  # Invocation
  core__log_verbose 'Entering function.'

  # Get a list of options and commands to check for
  core__log_verbose 'Checking options and loading tools to check into array.'
  while true ; do
    core__getopts ':am:n:qr:v:' _opt ':any,max-version:,min-version:,quiet,regex-pattern:,version-switch:' "$@"
    case $? in  2 ) core__log_error "Getopts failed.  Aborting function." ; return ${E_BAD_CLI} ;;  1 ) break ;; esac
    case "${_opt}" in
      'a' | 'any'            ) _any=true                   ;;  #@opt_  Return successful after matching any tool, if multiple provided, rather than all.
      'm' | 'max-version'    ) _max_version="${OPTARG}"    ;;  #@opt_  Sets the minimum supported version.  Anything above this is a failure.
      'n' | 'min-version'    ) _min_version="${OPTARG}"    ;;  #@opt_  Sets the maximum supported version.  Anything below this is a failure.
      'q' | 'quiet'          ) _quiet=true                 ;;  #@opt_  Prevents the output of the found tools (normally goes to stdout).
      'r' | 'regex-pattern'  ) _regex_pattern="${OPTARG}"  ;;  #@opt_  Specify a custom regex pattern for getting the version number/string from program output.
      'v' | 'version-switch' ) _version_switch="${OPTARG}" ;;  #@opt_  Specify a custom switch to use to get version information from the program output.
      *                      ) core__log_error "Invalid option for the core__tool_exists function:  ${_opt}  (aborting)" ; return ${E_BAD_CLI} ;;
    esac
  done

  # Preflight checks
  core__log_verbose 'Doing pre-flight checks to make sure all necessary options were passed.'
  if [ ! -z "${_min_version}" ] || [ ! -z "${_max_version}" ] ; then
    if [ -z "${_regex_pattern}" ]         ; then core__log_error "You sent either a minimum or maximum version but didn't specify a regex-pattern to find the version string." ; return ${E_BAD_CLI} ; fi
    if [ ${#__SBT_NONOPT_ARGS[@]} -gt 1 ] ; then core__log_error "You can't specify a minimum or maximum version along with more than 1 tool at a time."                       ; return ${E_BAD_CLI} ; fi
  fi
  if [ -z "${_version_switch}" ]        ; then core__log_error 'Version switch cannot be blank.  (aborting)' ; return ${E_BAD_CLI} ; fi
  if [ ${#__SBT_NONOPT_ARGS[@]} -eq 0 ] ; then core__log_error 'No tools sent to check for.  (aborting).'    ; return ${E_BAD_CLI} ; fi
  for _tool in "${__SBT_NONOPT_ARGS[@]}" ; do
    [ -z "${_tool}" ] && core__log_error "You sent a blank string as a tool to check for.  For safety, this is an error.  (aborting)" && return ${E_BAD_CLI}
  done

  # Search for tools
  core__log_verbose "Checking for programs/tools.  Version switch: '${_version_switch}'.  Pattern match: '${regex_pattern}'.  Min/max versions: '${_min_version}'/'${_max_version}'."
  for _tool in "${__SBT_NONOPT_ARGS[@]}" ; do
    # Try to execute the tool and version string.
    core__log_verbose "Seeing if tool '${_tool}' exists on our PATH anywhere."
    if ! ${_tool} ${_version_switch} >/dev/null 2>/dev/null ; then
      ${_any} && core__log_verbose "Didn't find it but the any flag is set, checking next tool specified." && continue
      core__log_verbose "Could not find tool '${_tool}'.  Check PATH and your version switch (currently: '${_version_switch}')."
      continue
    fi
    # Found the tool.  If the regex-pattern is blank then we're not interested in a match.
    _tools_found["${_tool}"]='na'
    if [ -z "${_regex_pattern}" ] ; then
      core__log_verbose "Tool was found and no -r/--regex-pattern sent.  Continuing to the next tool."
      ${_any} && core__log_verbose "Actually, the any flag is set so we're done now.  Breaking from the loop so we can exit." && break
      continue
    fi
    # The regex-pattern has contents.  User wants to find a match.
    core__log_verbose "Found tool, trying to grab the version string for comparison using:  ${_tool} ${_version_switch} | grep -oP '${_regex_pattern}'"
    _found_version="$(${_tool} ${_version_switch} 2>/dev/null | grep -oP "${_regex_pattern}" -m 1)"
    if [ $? -ne 0 ] || [ -z "${_found_version}" ] ; then
      core__log_verbose "Couldn't find the version string, rejecting this tool as a match."
      unset _tools_found["${_tool}"]
      ${_any} && core__log_verbose "The any flag is set, so we can continue looping trying to find other tools." && continue
      core__log_error "Tool found but version not discovered.  The any flag isn't set, nothing more we can do.  Breaking loop to exit properly."
      break
    fi
    # Found a version string.  Store it then start matching.
    core__log_verbose "Found a version string, storing it:  '${_found_version}'"
    _tools_found["${_tool}"]="${_found_version}"
    # Minimum version requirement.
    if [ ! -z "${_min_version}" ] ; then
      core__log_verbose "Minimum version requirement was sent.  Checking for found version '${_found_version}' to be greater than/equal to minimum version '${_min_version}'."
      if ! echo -e "${_min_version}\n${_found_version}" | sort -V -C ; then
        core__log_verbose "Version found '${_found_version}' is lower than the minimum required '${_min_version}'.  Rejecting this match."
        unset _tools_found["${_tool}"]
        break
      fi
    fi
    # Maximum version requirement.
    if [ ! -z "${_max_version}" ] ; then
      core__log_verbose "Maximum version requirement was sent.  Checking for found version '${_found_version}' to be less than/equal to maximum version '${_max_version}'."
      if ! echo -e "${_found_version}\n${_max_version}" | sort -V -C ; then
        core__log_verbose "Version found '${_found_version}' is greater than the maximum allowed '${_max_version}'.  Rejecting this match."
        unset _tools_found["${_tool}"]
        break
      fi
    fi
  done

  # If the any flag is set and we found at least 1 tool, we're done.  Report it and leave.
  if ${_any} && [ ${#_tools_found[@]} -gt 0 ] ; then
    core__log_verbose "Any flag sent and at least one tool found with matching version(s).  Success."
    ${_quiet} || echo "${!_tools_found[@]}"
    return 0
  fi
  # The any flag wasn't sent, but if tools found match tools sent we're good.
  if [ ${#_tools_found[@]} -eq ${#__SBT_NONOPT_ARGS[@]} ] ; then
    core__log_verbose "All tools found.  Returning successfully."
    return 0
  fi

  core__log_error "Unable to find the required tool(s) and/or versions.  Tool(s) we did find (if any):  ${!_tools_found[@]}"
  return ${E_CMD_NOT_FOUND}
}


function core__set_tool_path {
  #@Description  Any tools that SBT relies on can be compiled and provided with the SBT bundles.  This function will prepend the path specified to $PATH, ensuring it is used before other versions found on the system.
  #@Date   2013.09.16
  #@Usage  core__set_tool_path <'/path/to/prepend'>

  # Preflight checks
  core__log_verbose 'Entering function and starting preflight checks.'
  if [ -z "${1}" ]   ; then core__log_error 'No path sent, cannot prepend nothing to PATH variable.  (aborting)' ; return 1 ; fi
  if [ ! -d "${1}" ] ; then core__log_error "Path specified doesn't exist or is not a directory.  (aborting)"    ; return 1 ; fi

  # Set path with new info
  core__log_verbose "Adding directory to path, new path will be:  ${1}:${PATH}"
  PATH="${1}:${PATH}"

  return 0
}


function core__store_by_ref {
  #@Description  This uses eval to do an indirect assignment to positional 1 with positionals 2+.  If $1 is blank, the caller doesn't intend/support saving to a variable; therefore output goes to stdout.
  #@Description  -
  #@Description  This needs to be quite simple, and extremely fast.
  #@Date   2013.10.03
  #@Usage  core__store_by_ref <'variable_to_assign_to'> <'Value to store' [...]>

  # Preflight checks
  core__log_verbose "Entering function, doing preflight checks now."
  local -r _REFERENCE="${1}"  #@$ Store positional number 1 so we can shift out and use $@.
  if [ ${#@} -lt 2 ] ; then core__log_error   'You must specify at least 2 positionals.  1 = name.  2+ = values to assign.  (aborting)' ; return 1 ; fi
  if [ -z "${1}" ]   ; then core__log_verbose 'Positional number 1 is missing, no by-ref storage intended.  (aborting)'                 ; return 1 ; fi
  shift

  # Assign the values
  core__log_verbose "Assigning remaining positionals to variable: ${_REFERENCE}"
  eval "${_REFERENCE}=\"$@\""
  return 0
}


function core__slurp_stdin {
  #@Description  Attempts to read from Standard Input and store data in a variable named: _data.  The _data variable must be provided by the caller to keep things safe.
  #@Description  -
  #@Description  This function lacks most frills in an effort to be as efficient as possible.  Work offloaded to 'cat' program for speed.
  #@Description  IMPORTANT!!!  You MUST ensure there is a pipe waiting on STDIN or this will hang forever, like any program waiting on STDIN.
  #@Date   2013.10.26
  #@Usage  core__slurp_stdin

  core__log_verbose 'Entering function.'
  _data="$(cat -)"
  return $?
}


function core__slurp_files {
  #@Description  Attempts to read from files specified and store data in a variable named: _data.  The _data variable must be provided by the caller to keep things safe.
  #@Description  -
  #@Description  This function lacks most frills in an effort to be as efficient as possible.  Work offloaded to 'cat' program for speed.
  #@Description  IMPORTANT!!!  This function will test existence and read permissions of files specified, but that's it.
  #@Date   2013.10.27
  #@Usage  core__slurp_files

  core__log_verbose 'Entering function.'
  local -i -r E_BAD_IO=10    #@$ Exit status when a file is missing or not readable for some reason.
  local -a    _files=("$@")  #@$ List of files to slurp
  local       _temp=''       #@$ Miscellaneous crap goes into here, mostly for loops.

  # Check for existence and read acces to files
  if [ ${#_files[@]} -lt 1 ] ; then core__log_verbose "No files sent to me, leaving." ; return 0 ; fi
  for _temp in "${_files[@]}" ; do
    if [ ! -f "${_temp}" ] ; then core__log_error "File specified not found: '${_temp}'  (aborting)"    ; return ${E_BAD_IO} ; fi
    if [ ! -r "${_temp}" ] ; then core__log_error "No read permission for file: '${_temp}'  (aborting)" ; return ${E_BAD_IO} ; fi
  done

  _data="$(cat "${_files[@]}")"
  return $?
}


function core__read_data {
  #@Description  Employs the basic 1-2 of data entry for SBT functions: slurp files from positionals ($1, $2...) and slurp from STDIN.
  #@Description  If data is sent via positionals the CALLER needs to check for that and put it in _data.  We will safely abort from there.
  #@Description  Helps deduplicate code efforts.
  #@Description  -
  #@Description  IMPORTANT!!!  The caller MUST provide a variable named:  _data.  Used by core__slurp_files and core__slurp_stdin.
  #@Date   2013.10.27
  #@Usage  core__read_data ['/path/to/file/for/core__slurp_files' [...]]

  core__log_verbose 'Entering function.'
  # If positionals already loaded in _data, leave.
  if [ ! -z "${_data}" ] ; then core__log_verbose "The _data variable wasn't blank, must have received values from positionals.  Leaving." ; return 0 ; fi

  # Try to slurp any files sent into _data.  Leave on success.
  core__slurp_files "$@" || return $?
  if [ ! -z "${_data}" ] ; then core__log_verbose "The _data variable is no longer blank, must have found files to read.  Leaving." ; return 0 ; fi

  # Last chance to find some data to work with... otherwise we're gonna be hung here.
  core__slurp_stdin || return $?

  # If data is still empty (not sure how...) send a warning but keep going.
  [ -z "${_data}" ] && core__log_verbose "Reached the end and _data is still empty, not sure how though.  Continuing."
  return 0
}


function core__shutdown {
  #@Description  Performs necessary actions to cleanly shut down SBT.  Primarily it processes the event registry.
  #@Description  -
  #@Description  By default, it's quiet.  If commands are blank or or fail, this function continues running and still returns OK.  You can change this behavior with switches.
  #@Date         2016.07.09
  #@Usage        core__shutdown

  # Variables.
  local -r -i E_GENERIC=1            #@$ Generic error when badness happens.
  local -r -i E_ABORT_EARLY=14       #@$ Throw a differnt code if we abort early.
  local -r -i E_COMMANDS_FAILED=15   #@$ Generic error when badness happens.
  local    -a __SBT_NONOPT_ARGS      #@$ Capture a list of tools for use.  Localize array since we'll only use it here.
  local    -i OPTIND=1               #@$ Localizing OPTIND to avoid scoping issues.
  local       _opt=''                #@$ Used for looping through getopts
  local       _cmd                   #@$ Junk variable for looping.
  local       _empty_ok=true         #@$ Flag to determine if empty entries are OK.
  local       _abort_on_error=false  #@$ Flag to decide if we should fail-fast when an error happens.  This will consider empty commands as errors if _empty_ok=false.
  local       _found_errors=false    #@$ Flag that flips to true if any commands fail.

  # Process options.
  core__log_verbose "Entering function."
  core__log_verbose "Processing options."
  while true ; do
    core__getopts ':a:e:' _opt ':abort-on-error:,empty-ok:' "$@"
    case $? in  2 ) core__log_error "Getopts failed.  Aborting function." ; return 1 ;;  1 ) break ;; esac
    case "${_opt}" in
      'a' | 'abort-on-error' ) #@opt_  Sets the flag to control if we will abort early if any command in the registry fails.  Note this will result in the registry NOT being cleared, at all!
                               if ! grep -qP '^(true|false)$' <<<"${OPTARG}" ; then
                                 core__log_error "The -a/--abort-on-error switch requires a value of 'true' or 'false', not '${OPTARG}'.  (aborting)"
                                 return ${E_GENERIC}
                               fi
                               _abort_on_error="${OPTARG}"
                               ;;
      'e' | 'empty-ok'       ) #@opt_  Sets the flag to control if empty commands are OK.  If set it's treated as an error and the functino will return non-zero.  If -a/--abort-on-error is set it will fail immediately.
                               if ! grep -qP '^(true|false)$' <<<"${OPTARG}" ; then
                                 core__log_error "The -e/--empty-ok switch requires a value of 'true' or 'false', not '${OPTARG}'.  (aborting)"
                                 return ${E_GENERIC}
                               fi
                               _empty_ok="${OPTARG}"
                               ;;
      *                      ) core__log_error "Invalid option for the core__shutdown function:  ${_opt}  (failing)" ; return ${E_GENERIC} ;;
    esac
  done

  # Run through the shutdown registry.
  core__log_verbose "Starting to process the shutdown registry."
  for _cmd in "${__SBT_SHUTDOWN_REGISTRY[@]}" ; do
    core__log_verbose "Processing command:  ${_cmd}"
    if [ -z "${_cmd}" ] ; then
      ${_empty_ok} && core__log_verbose "Command was blank and _empty_ok is true, so skipping and moving on." && continue
      # Empty is not OK so flag it.  If abort-on-error is also true then we need to quit.
      _found_errors=true
      ${_abort_on_error} && core__log_error "Command was blank and blanks aren't allowed.  Abort-on-error is also set, so we're failing early without cleaning up." && return ${E_ABORT_EARLY}
    fi
    if ! eval "${_cmd}" ; then
      _found_errors=true
      ${_abort_on_error} && core__log_error "Command failed!  Abort-on-error is set, so we're failing early without cleaning up." && return ${E_ABORT_EARLY}
      core__log_error "Command failed!  Continuing to next command."
    fi
  done
  core__log_verbose "Done processing shutdown registry.  Clearing the __SBT_SHUTDOWN_REGISTRY.  Errors found: ${_found_errors}"
  unset __SBT_SHUTDOWN_REGISTRY
  declare -a __SBT_SHUTDOWN_REGISTRY=()
  ${_found_errors} && return ${E_COMMANDS_FAILED}

  return 0
}


function core__register_shutdown_event {
  #@Description  Saves an event in the registry to run later.  You can only send multiple commands at once.
  #@Date         2016.07.09
  #@Usage        core__register_shutdown_event [-d | --duplicates] [-e | --error-on-duplicate] <'command to run --including "args"' ['another cmd']>

  # Variables.
  local -r -i E_GENERIC=1                #@$ Generic error when badness happens.
  local    -a __SBT_NONOPT_ARGS          #@$ Capture a list of tools for use.  Localize array since we'll only use it here.
  local    -i OPTIND=1                   #@$ Localizing OPTIND to avoid scoping issues.
  local       _opt=''                    #@$ Used for looping through getopts
  local       _allow_duplicates=false    #@$ Boolean to determine if duplicates are allowed.
  local       _error_on_duplicate=false  #@$ Boolean to throw an error if a duplicate is found.  Default is to ignore it.
  local       _cmd                       #@$ The command we're trying to register; comes from __SBT_NONOPT_ARGS[0].
  local       _existing_cmd              #@$ Temporary variable for looping.

  # Process options.
  core__log_verbose "Entering function."
  core__log_verbose "Processing options."
  while true ; do
    core__getopts ':de' _opt ':duplicates,error-on-duplicate' "$@"
    case $? in  2 ) core__log_error "Getopts failed.  Aborting function." ; return 1 ;;  1 ) break ;; esac
    case "${_opt}" in
      'd' | 'duplicates'         ) _allow_duplicates=true   ;;  #@opt_  If specified, allows duplicates to be put in the registry.  Usually, they aren't.
      'e' | 'error-on-duplicate' ) _error_on_duplicate=true ;;  #@opt_  If specified, throws an error when a duplicate is found rather than exiting cleanly.
      *                          ) core__log_error "Invalid option for the core__register_for_shutdown function:  ${_opt}  (failing)" ; return ${E_GENERIC} ;;
    esac
  done

  # Preflight checks
  for _cmd in "${__SBT_NONOPT_ARGS[@]}" ; do
    [ -z "${_cmd}" ] && core__log_error "You sent a blank command; this is disallowed." && return ${E_GENERIC}
  done

  # Check all commands.
  for _cmd in "${__SBT_NONOPT_ARGS[@]}" ; do
    # If duplicates aren't allowed, loop through and check the registry.
    if ! ${_allow_duplicates} ; then
      core__log_verbose "Duplicates aren't allowed, checking the existing registry."
      for _existing_cmd in "${__SBT_SHUTDOWN_REGISTRY[@]}" ; do
        if [ "${_cmd}" == "${_existing_cmd}" ] ; then
          core__log_verbose "A duplicate was found.  The _error_on_duplicate is set to '${_error_on_duplicate}', exiting appropriately."
          ${_error_on_duplicate} && return ${E_GENERIC}
          return 0
        fi
      done
    fi
    # At this point the command isn't a duplicate or duplicates are allowed, so we really don't need to check anything.  Just add it and leave.
    core__log_verbose "Adding a command to the __SBT_SHUTDOWN_REGISTRY:  ${_cmd}"
    __SBT_SHUTDOWN_REGISTRY+=("${_cmd}")
  done

  return 0
}



#
# Run initializer to set a few things up.
#
if ! core__initialize ; then core__log_error "Failed to run first initialization.  This is fatal." ; exit 1 ; fi
