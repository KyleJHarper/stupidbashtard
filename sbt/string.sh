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

  local opt       #@$ Localizing opt for use in getopts below.
  local -i i=0    #@$ Localized temporary variable used in loops.
  local BYREF=''  #@$ Name to use for setting output rather than sending to std out.
  local CASE=''   #@$ The type of formatting to do.

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Grab options
  core_LogVerbose 'Getting options, if any.  Resetting __SBT_NONOPT_ARGS.'
  __SBT_NONOPT_ARGS=()
  while core_getopts ':lLpR:tuU' opt '' "$@" ; do
    case "${opt}" in
      l )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with lower (continuing)."     ; CASE='lower'     ;;
      L )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with onelower (continuing)."  ; CASE='onelower'  ;;
      R )  BYREF="${OPTARG}" ;;
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
  if [ ! -z "${BYREF}" ] ; then
    core_LogVerbose "By-Ref was set.  Redirecting output to variable named ${BYREF}"
    while [ ${i} -lt ${#__SBT_NONOPT_ARGS[@]} ] ; do
      case "${CASE}" in
        'lower'     ) eval "${BYREF}+=\"${__SBT_NONOPT_ARGS[${i}],,}\"" ;;
        'onelower'  ) eval "${BYREF}+=\"${__SBT_NONOPT_ARGS[${i}],}\"" ;;
        'proper'    ) __SBT_NONOPT_ARGS[${i}]="${__SBT_NONOPT_ARGS[${i}],,}"
                      eval "${BYREF}+=\"${__SBT_NONOPT_ARGS[${i}]~}\"" ;;
        'toggle'    ) eval "${BYREF}+=\"${__SBT_NONOPT_ARGS[${i}]~~}\"" ;;
        'upper'     ) eval "${BYREF}+=\"${__SBT_NONOPT_ARGS[${i}]^^}\"" ;;
        'oneupper'  ) eval "${BYREF}+=\"${__SBT_NONOPT_ARGS[${i}]^}\"" ;;
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
