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
  #@Usage  string_ToUpper <'Value to upper case' [...]>

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
  #@Usage  string_ToLower <'value to lower case' [...]>

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
  #@Usage  string_ProperCase <'Value to proper case' [...]>

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
  #@Usage  string_ToggleCase <'Value to toggle case on' [...]>

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Call the real workhorse
  core_LogVerbose 'Handing options off to string_FormatCase for the real work'
  string_FormatCase -t "$@" || return 1

  return 0
}


function string_FormatCase {
  #@Description  Takes all positional arguments and returns them in the case format prescribed.  Usually referred by ToUpper, ToLower, etc. so we don't program long options.
  #@Description  -
  #@Description  Supports the -R switch for passing a variable name for indirect referencing.  If found, it places output in the named variable, rather than sending to stdout.
  #@Usage  string_FormatCase [-l] [-L] [-p] [-R 'ref_var_name'] [-t] [-u] [-U] <'Values to manipulate' [...]>

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
      p )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with proper (continuing)."    ; CASE='proper'    ;;
      R )  REFERENCE="${OPTARG}"                                                                                                         ;;
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
  #@Usage  string_IndexOf [-o --occurrence '#'] <-n --needle 'needle' [...]> [-R 'ref_var_name'] <'haystack' [...]>
  #@Date   2013.09.16

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
      'o' | 'occurrence' ) if [[ "${OPTARG}" == 'last' ]] ; then occurrence=9999 ; else occurrence="${OPTARG}" ; fi ;;
      'n' | 'needle'     ) needles+=( "${OPTARG}" )  ;;
      'R'                ) REFERENCE="${OPTARG}"     ;;
      *                  ) core_LogError "Invalid option sent to me: ${opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks and warnings
  core_LogVerbose 'Checking requirements before processing function.'
  if [ ${#needles[@]} -eq 0 ] ; then
    core_LogError "No needles were specified to find an index with.  (aborting)"
    return 1
  fi
  if [ ${#__SBT_NONOPT_ARGS[@]} -eq 0 ] ; then
    core_LogError "No strings specified, so I have no idea what you want me to search.  (aborting)"
    return 1
  fi
  if [ ${#__SBT_NONOPT_ARGS[@]} -gt 1 ] ; then
    core_LogVerbose 'More than one haystack was passed.  Index returned will reflect that of haystacks "mashed" together.'
  fi
  core_ToolExists 'gawk' || return 1

  # Call external tool and store results in temp var.  We can += the index because awk will give a 1-based index, 0 == failed.
  core_LogVerbose 'Starting search for needles specified'
  for temp in "${__SBT_NONOPT_ARGS[@]}" ; do haystack+="${temp}" ; done
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


function string_Substring {
  #@Description  Returns the portion of a string starting at index X, up to length Y.
  #@Usage  string_Substring [-i --index '#'] [-l --length '#'] [-R 'ref_var_name'] <'haystack' [...]>
  #@Date   2013.10.19

  core_LogVerbose 'Entering function.'
  # Variables
  local -i index=0            #@$ Zero-based index to start the substring at.  Supports negative values to wrap back from end of string.
  local -i length=0           #@$ Number of characters to return.  Negative value will return remainder minus $length characters.  Zero means return all.
  local opt=''                #@$ Temporary variable for core_getopts, brought to local scope.
  local REFERENCE=''          #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local haystack=''           #@$ Stores the values we're going to search within.
  local temp=''               #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':i:l:R:' opt ':index:,length:' "$@" ; do
    case "${opt}" in
      'i' | 'index'   ) index="${OPTARG}"      ;;
      'l' | 'length'  ) length="${OPTARG}"     ;;
      'R'             ) REFERENCE="${OPTARG}"  ;;
      *               ) core_LogError "Invalid option sent to me: ${opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core_LogVerbose 'Checking requirements before processing function.'
  for temp in "${__SBT_NONOPT_ARGS[@]}" ; do haystack+="${temp}" ; done
  if [ ${index} -ge ${#haystack} ] ; then
    core_LogError "Index specified (${index}) is higher than haystack size (${#haystack}).  (aborting)"
    return 1
  fi
  temp="${haystack: ${index}}"
  if [ ${length} -lt 0 ] && [ ${length} -lt -${#temp} ] ; then
    core_LogError "A negative length was sent (${length}) that extends behind the substring made with index '${index}'.  This will cause a bash error.  (aborting)"
    return 1
  fi
  if [ ${#__SBT_NONOPT_ARGS[@]} -gt 1 ] ; then
    core_LogVerbose 'More than one haystack was passed.  Substring returned will reflect that of haystacks "mashed" together.'
  fi
  if [ ${index} -eq 0 ] && [ ${length} -eq 0 ] ; then
    core_LogVerbose 'Both index and length are zero.  The substring will exactly match the strings sent, just fyi.'
  fi

  # Main logic
  core_LogVerbose "Grabbing the substring with index '${index}' and length '${length}'."
  if [ ${length} -eq 0 ] ; then
    temp="${haystack: ${index}}"
  else
    temp="${haystack: ${index}: ${length}}"
  fi

  # Report back
  core_StoreByRef "${REFERENCE}" "${temp}" || echo -n "${temp}"
  return 0
}


function string_CountOf {
  #@Description  Returns a count of the times characters/strings are found in the passed values.
  #@Description  -
  #@Description  If count is zero, exit value will still be 0 for success.
  #@Usage  string_CountOf [-a --all] <-p --pattern 'find me' > [-R 'ref_var_name'] <'haystack' [...]>
  #@Date   2013.10.21

  core_LogVerbose 'Entering function.'
  # Variables
  local all=false             #@$ Flag to see if we just want a count of all characters.  Like ${#var}
  local pattern=''            #@$ Holds the pattern to search for.  PCRE insomuch as grep is PCRE.
  local haystack=''           #@$ Holds all items to search within, mostly to help with the -a/--all items.
  local opt=''                #@$ Temporary variable for core_getopts, brought to local scope.
  local REFERENCE=''          #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local temp=''               #@$ Garbage variable for looping.
  local -i rv=0               #@$ Return value.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':an:R:' opt ':all,needle:' "$@" ; do
    case "${opt}" in
      'a' | 'all'     ) all=true               ;;
      'p' | 'pattern' ) pattern="${OPTARG}"    ;;
      'R'             ) REFERENCE="${OPTARG}"  ;;
      *               ) core_LogError "Invalid option sent to me: ${opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  for temp in "${__SBT_NONOPT_ARGS[@]}" ; do haystack+="${temp}" ; done
  if [ -z "${pattern}" ] && ! ${all} ; then
    core_LogError "No pattern was specified to find and we weren't told to find 'all'.  (aborting)"
    return 1
  fi
  if [ -z "${haystack}" ] ; then
    core_LogError "No strings specified to search within, so I have no idea what you want me to search.  (aborting)"
    return 1
  fi
  core_ToolExists 'perl' || return 1

  # Time to count some things
REWORK THIS TO USE THE PERL EXT SCRIPT, MUCH BETTER
  ${all}   && rv=${#temp}
  ! ${all} && rv=$(grep -oP "${pattern}" <<< "${haystack}" | wc -l)
  core_StoreByRef "${REFERENCE}" "${rv}" || echo -n "${rv}"

  return 0
}
