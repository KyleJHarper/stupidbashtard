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
  #@Description  Find the Nth occurrence of a given substring inside a string.  If not found, return non-zero in fixed exit code.
  #@Description  -
  #@Description  Index will be zero based.  This offloads the work to awk which is a 1-based index, but that's atypical, so I adjust it.
  #@Description  -
  #@Description  Cannot operate on files, yet.
  #@Date  2013.09.16

  core_LogVerbose 'Entering function.'
  # Variables
  local -i index=-1           #@$ Positional index to return, zero-based.  Starting at -1 because awk is 1-based, not 0.
  local -i occurrence=1       #@$ The Nth occurrence we want to find the index of.
  local -a needles=()         #@$ Holds the patterns to search for.  Should be a string as we'll do fixed-string searching
  local opt=''                #@$ Temporary variable for core_getopts, brought to local scope.
  local REFERENCE=''          #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local needle=''             #@$ Hold values for looping.
  local haystack=''           #@$ Stores the values we're going to search within.
  local temp=''               #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':n:o:R:' opt ':needle:,occurrence:' "$@" ; do
    case "${opt}" in
      'o' | 'occurrence' ) occurrence="${OPTARG}"    ;;
      'n' | 'needle'     ) needles+=( "${OPTARG}" )  ;;
      'R'                ) REFERENCE="${OPTARG}"     ;;
      *                  ) core_LogError "Invalid option sent to me: ${opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks and warnings
  core_LogVerbose 'Checking requirements before processing function.'
  if [ "${#needles[@]}" -eq 0 ] ; then core_LogError "No needles were specified to find an index with.  (aborting)" ; return 1 ; fi
  if [ ${#__SBT_NONOPT_ARGS[@]} -eq 0 ] ; then
    core_LogError "No strings specified, so I have no idea what you want me to search.  (aborting)"
    return 1
  fi
  if [ ${#__SBT_NONOPT_ARGS[@]} -gt 1 ] ; then
    core_LogVerbose 'More than one haystack was passed.  Index returned will reflect that of haystacks "mashed" together.'
  fi
  for temp in "${__SBT_NONOPT_ARGS[@]}" ; do haystack+="${temp}" ; done
  core_ToolExists 'gawk' || return 1

  # Call external tool and store results in temp var.
  core_LogVerbose 'Starting search for needles specified'
  for needle in "${needles[@]}" ; do
    core_LogVerbose "Searching for: '${needle}'"
    let "index += $(gawk -v haystack="${haystack}" -v needle="${needle}" -v occurrence="${occurrence}" -f "${__SBT_EXT_DIR}/string_IndexOf.awk")"
    [ ${index} -eq -1 ] || break
  done

  # Report findings
  [ ${index} -gt -1 ] && core_LogVerbose "Found a match at index ${index} to needle: '${needle}'"
  core_StoreByRef "${REFERENCE}" "${index}" || echo -n "${index}"
  return 0
}
