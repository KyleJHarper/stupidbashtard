#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


#@Author    Kyle Harper
#@Date      2013.08.12
#@Version   0.1-beta
#@Namespace string

#@Description Bash has some built-in string handling functionality, but it's far from complete.  This helps extend that.  In many cases, it simply provides a nice name to do things that the bash syntax for is convoluted.  Like lowercase: ${var,,}


function string_ToUpper {
  #@Description  Takes all positional arguments and returns them in upper case format.
  #@Description  -
  #@Description  Sends all heavy lifting to string_FormatCase.  This is a wrapper.

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Call the real workhorse
  core_LogVerbose 'Handing options off to string_FormatCase for the real work'
  string_FormatCase -u "$@" || return 1

  return 0
}


function string_ToLower {
  #@Description  Takes all positional arguments and returns them in lower case format.
  #@Description  -
  #@Description  Sends all heavy lifting to string_FormatCase.  This is a wrapper.

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Call the real workhorse
  core_LogVerbose 'Handing options off to string_FormatCase for the real work'
  string_FormatCase -l "$@" || return 1

  return 0
}


function string_ProperCase {
  #@Description  Takes all positional arguments and returns them in proper (title) case format.
  #@Description  -
  #@Description  Sends all heavy lifting to string_FormatCase.  This is a wrapper.

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Call the real workhorse
  core_LogVerbose 'Handing options off to string_FormatCase for the real work'
  string_FormatCase -p "$@" || return 1

  return 0
}


function string_ToggleCase {
  #@Description  Takes all positional arguments and returns them in toggled case.
  #@Description  -
  #@Description  Sends all heavy lifting to string_FormatCase.  This is a wrapper.

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Call the real workhorse
  core_LogVerbose 'Handing options off to string_FormatCase for the real work'
  string_FormatCase -t "$@" || return 1

  return 0
}


function string_FormatCase {
  #@Description  Takes all positional arguments and returns them in the case format prescribed.  Usually referred by ToUpper, ToLower, etc.
  #@Description  -
  #@Description  Supports the -R switch for passing a variable name for indirect referencing.  If found, it places output in the named variable, rather than sending to stdout.

  local opt                   #@$ Localizing opt for use in getopts below.
  local -i i=0                #@$ Localized temporary variable used in loops.
  local REFERENCE=''          #@$ Name to use for setting output rather than sending to std out.
  local CASE=''               #@$ The type of formatting to do.
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Grab options
  while core_getopts ':lLpR:tuU' opt '' "$@" ; do
    case "${opt}" in
      l )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with lower (continuing)."     ; CASE='lower'     ;;
      L )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with onelower (continuing)."  ; CASE='onelower'  ;;
      R )  REFERENCE="${OPTARG}"                                                                                                         ;;
      p )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with proper (continuing)."    ; CASE='proper'    ;;
      t )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with toggle (continuing)."    ; CASE='toggle'    ;;
      u )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with upper (continuing)."     ; CASE='upper'     ;;
      U )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with oneupper (continuing)."  ; CASE='oneupper'  ;;
      * )  core_LogError "Invalid option:  -${opt}  (failing)" ; return 1 ;;
    esac
  done

  # Preflights checks
  if [ ${#__SBT_NONOPT_ARGS[@]} -eq 0 ] ; then
    core_LogVerbose 'Found no positional arguments to work with.  This will return an empty string.'
  fi

  # Set BYREF if it was sent
  core_LogVerbose "Converting all arguments to case '${CASE}' and joining together."
  if [ ! -z "${REFERENCE}" ] ; then
    core_LogVerbose "Reference was sent.  Redirecting output to variable named ${REFERENCE}"
    while [ ${i} -lt ${#__SBT_NONOPT_ARGS[@]} ] ; do
      case "${CASE}" in
        'lower'     ) eval "${REFERENCE}+=\"${__SBT_NONOPT_ARGS[${i}],,}\""  ;;
        'onelower'  ) eval "${REFERENCE}+=\"${__SBT_NONOPT_ARGS[${i}],}\""   ;;
        'proper'    ) __SBT_NONOPT_ARGS[${i}]="${__SBT_NONOPT_ARGS[${i}],,}"
                      eval "${REFERENCE}+=\"${__SBT_NONOPT_ARGS[${i}]~}\""   ;;
        'toggle'    ) eval "${REFERENCE}+=\"${__SBT_NONOPT_ARGS[${i}]~~}\""  ;;
        'upper'     ) eval "${REFERENCE}+=\"${__SBT_NONOPT_ARGS[${i}]^^}\""  ;;
        'oneupper'  ) eval "${REFERENCE}+=\"${__SBT_NONOPT_ARGS[${i}]^}\""   ;;
        *           ) core_LogError "Invalid case format attempted: ${CASE}  (failing)" ; return 1 ;;
      esac
      let i++
    done
    return 0
  fi

  # Send data to stdout
  core_LogVerbose 'Sending output to std out.'
  while [ ${i} -lt ${#__SBT_NONOPT_ARGS[@]} ] ; do
    case "${CASE}" in
      'lower'     ) echo -ne "${__SBT_NONOPT_ARGS[${i}],,}" ;;
      'onelower'  ) echo -ne "${__SBT_NONOPT_ARGS[${i}],}" ;;
      'proper'    ) __SBT_NONOPT_ARGS[${i}]="${__SBT_NONOPT_ARGS[${i}],,}"
                    echo -ne "${__SBT_NONOPT_ARGS[${i}]~}" ;;
      'toggle'    ) echo -ne "${__SBT_NONOPT_ARGS[${i}]~~}" ;;
      'upper'     ) echo -ne "${__SBT_NONOPT_ARGS[${i}]^^}" ;;
      'oneupper'  ) echo -ne "${__SBT_NONOPT_ARGS[${i}]^}" ;;
      *           ) core_LogError "Invalid case format attempted: ${CASE}  (failing)" ; return 1 ;;
    esac
    let i++
  done

  # All done
  return 0
}


function string_IndexOf {
  #@Description  Find the Nth occurrence of a given index idx.  If idx isn't found, return non-zero in fixed error code.
  #@Description  -
  #@Description  This is an alpha version and will likely be rebuilt in smaller functions or called from wrappers for special indexof cases.

#TODO  Is it better to pass all of this to another tool?  Perl is heavy, maybe awk?  Maybe read builtin can perform... I doubt it :S
#      Can we rely on awk to be a tool?  It could be awk, mawk, nawk, or gawk.  If I'm sticking to GNU it'll be gawk, but many don't have that by default.
  core_LogVerbose 'Entering function.'
  # Variables
  local file=''               #@$ File to scan rather than processing nonopt positionals.
  local -i index=0            #@$ Positional index to return, zero-based.
  local -i occurrence=1       #@$ The Nth occurrence we want to find the index of.
  local -a pattern=()         #@$ Holds the pattern to search for.  Should be a string as we'll do fixed-string searching
  local opt=''                #@$ Temporary variable for core_getopts, brought to local scope.
  local REFERENCE=''          #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.


  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':f:o:p:R:' opt '' "$@" ; do
    case "${opt}" in
      'f' ) [ ! -z "${file}" ] && core_LogError "A file was already specified, overwriting file to search and continuing." ; file="${OPTARG}" ;;
      'o' ) occurrence="${OPTARG}"    ;;
      'p' ) pattern+=( "${OPTARG}" )  ;;
      'R' ) REFERENCE="${OPTARG}"     ;;
      *   ) core_LogError "Invalid option sent to me: ${opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core_LogVerbose 'Checking requirements before processing function.'
  if [ -z "${pattern[@]}" ] ; then core_LogError "No pattern was specified to find an index with.  (aborting)" ; return 1 ; fi
  if [ ! -z "${file}" ; then
    if [ ! -r "${file}" ] ; then core_LogError "File specified either does not exist or cannot be read:  ${file}  (aborting)" ; return 1 ; fi
  fi
  if [ -z "${file}" ] && [ ${#__SBT_NONOPT_ARGS[@]} -eq 0 ] ; then
    core_LogError "You didn't specify any strings or files, so I have no idea what you want me to search.  (aborting)"
    return 1
  fi
  if [ ${#__SBT_NONOPT_ARGS[@]} -gt 1 ] ; then
    core_LogVerbose 'More than one item was passed.  Index returned will reflect that of items "mashed" together.'
  fi

#TODO  No idea what the best method is here.


}
