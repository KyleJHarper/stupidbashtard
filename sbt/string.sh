# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


#@Author    Kyle Harper
#@Date      2013.08.12
#@Version   0.0.1-beta
#@Namespace string

#@Description Bash has some built-in string handling functionality, but it's far from complete.  This helps extend that.  In many cases, it simply provides a nice name to do things that the bash syntax for is convoluted.  Like lowercase: ${var,,}


function string_ToUpper {
  #@Description  Takes all positional arguments and returns them in upper case format.
  #@Description  -
  #@Description  Sends all heavy lifting to string_FormatCase.  This is a wrapper for convenience; not as powerful as string_FormatCase.  Supports any other options string_FormatCase does.
  #@Usage  string_ToUpper <'values' or -f --file 'FILE' or STDIN>

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Call the real workhorse
  core_LogVerbose 'Handing options off to string_FormatCase for the real work.'
  string_FormatCase -u "$@"
  return $?
}


function string_ToLower {
  #@Description  Takes all positional arguments and returns them in lower case format.
  #@Description  -
  #@Description  Sends all heavy lifting to string_FormatCase.  This is a wrapper for convenience; not as powerful as string_FormatCase.  Supports any other options string_FormatCase does.
  #@Usage  string_ToLower <'values' or -f --file 'FILE' or STDIN>

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Call the real workhorse
  core_LogVerbose 'Handing options off to string_FormatCase for the real work.'
  string_FormatCase -l "$@"
  return $?
}


function string_ProperCase {
  #@Description  Takes all positional arguments and returns them in proper (title) case format.
  #@Description  -
  #@Description  Sends all heavy lifting to string_FormatCase.  This is a wrapper for convenience; not as powerful as string_FormatCase.  Supports any other options string_FormatCase does.
  #@Usage  string_ProperCase <'values' or -f --file 'FILE' or STDIN>

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Call the real workhorse
  core_LogVerbose 'Handing options off to string_FormatCase for the real work.'
  string_FormatCase -p "$@"
  return $?
}


function string_ToggleCase {
  #@Description  Takes all positional arguments and returns them in toggled case.
  #@Description  -
  #@Description  Sends all heavy lifting to string_FormatCase.  This is a wrapper for convenience; not as powerful as string_FormatCase.  Supports any other options string_FormatCase does.
  #@Usage  string_ToggleCase <'values' or -f --file 'FILE' or STDIN>

  # Enter the function
  core_LogVerbose 'Entering function.'

  # Call the real workhorse
  core_LogVerbose 'Handing options off to string_FormatCase for the real work.'
  string_FormatCase -t "$@"
  return $?
}


function string_FormatCase {
  #@Description  Takes all positional arguments and returns them in the case format prescribed.  Usually referred by ToUpper, ToLower, etc. so we don't program long options.
  #@Description  -
  #@Description  Supports the -R switch for passing a variable name for indirect referencing.  If found, it places output in the named variable, rather than sending to stdout.
  #@Usage  string_FormatCase [-l] [-L] [-p] [-R 'ref_var_name'] [-t] [-u] [-U] <'values' or -f --file 'FILE' or STDIN>

  core_LogVerbose 'Entering function.'
  local opt                   #@$ Localizing opt for use in getopts below.
  local REFERENCE=''          #@$ Name to use for setting output rather than sending to std out.
  local CASE=''               #@$ The type of formatting to do.
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local -a FILES              #@$ Files to read if no positionals passed.
  local temp=''               #@$ Temporary junk while working, mostly with loops.
  local DATA=''               #@$ Storage for values from positionals, files, or STDIN, whichever is used.

  # Grab options
  while core_getopts ':f:lLpR:tuU' opt ':file:' "$@" ; do
    case "${opt}" in
      'f' | 'file' )  files+=("${OPTARG}")                                                                                                          ;;
      'l'          )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with lower (continuing)."     ; CASE='lower'     ;;
      'L'          )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with onelower (continuing)."  ; CASE='onelower'  ;;
      'p'          )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with proper (continuing)."    ; CASE='proper'    ;;
      'R'          )  REFERENCE="${OPTARG}"                                                                                                         ;;
      't'          )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with toggle (continuing)."    ; CASE='toggle'    ;;
      'u'          )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with upper (continuing)."     ; CASE='upper'     ;;
      'U'          )  [ ! -z "${CASE}" ] && core_LogError "Case already set to ${CASE}, overriding with oneupper (continuing)."  ; CASE='oneupper'  ;;
      *            )  core_LogError "Invalid option:  -${opt}  (failing)" ; return 1 ;;
    esac
  done

  # Preflights checks
  [ ${#__SBT_NONOPT_ARGS[@]} -gt 1 ] && core_LogVerbose "More than one value sent to act upon, they will be joined and treated as a single item."
  for temp in "${__SBT_NONOPT_ARGS[@]}" ; do DATA+="${temp}" ; done
  core_ReadDATA "${files[@]}" || return 1

  # Main logic
  core_LogVerbose "Converting to case '${CASE}' and sending results back."
  case "${CASE}" in
    'lower'     ) DATA="${DATA,,}"  ;;
    'onelower'  ) DATA="${DATA,}"   ;;
    'proper'    ) DATA="${DATA,,}"
                  DATA="${DATA~}"   ;;
    'toggle'    ) DATA="${DATA~~}"  ;;
    'upper'     ) DATA="${DATA^^}"  ;;
    'oneupper'  ) DATA="${DATA^}"   ;;
    *           ) core_LogError "Invalid case format attempted: ${CASE}  (failing)" ; return 1 ;;
  esac

  core_StoreByRef "${REFERENCE}" "${DATA}" || echo -e "${DATA}"
  return 0
}


function string_IndexOf {
  #@Description  Find the Nth occurrence of a given substring inside a string.  If not found, return non-zero in fixed exit code.
  #@Description  -
  #@Description  Index will be zero based.  This offloads the work to awk which is a 1-based index, but that's atypical, so I adjust it.
  #@Usage  string_IndexOf [-o --occurrence '#'] <-n --needle 'needle' [...]> [-R 'ref_var_name'] <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.09.16

  core_LogVerbose 'Entering function.'
  # Variables
  local -i index=-1           #@$ Positional index to return, zero-based.  Starting at -1 because awk is 1-based, not 0.
  local -i occurrence=1       #@$ The Nth occurrence we want to find the index of.
  local -a needles=()         #@$ Holds the patterns to search for.  Should be a string as we'll do fixed-string searching
  local opt=''                #@$ Temporary variable for core_getopts, brought to local scope.
  local REFERENCE=''          #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local -a files              #@$ Files to read if no positionals passed.
  local needle=''             #@$ Hold values for looping.
  local DATA=''               #@$ Stores the values we're going to search within.
  local temp=''               #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':f:n:o:R:' opt ':file:,needle:,occurrence:' "$@" ; do
    case "${opt}" in
      'f' | 'file'       ) files+=("${OPTARG}") ;;
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
  for temp in "${__SBT_NONOPT_ARGS[@]}" ; do DATA+="${temp}" ; done
  core_ReadDATA "${files[@]}" || return 1
  core_ToolExists 'gawk' || return 1

  # Call external tool and store results in temp var.  We can += the index because awk will give a 1-based index, 0 == failed.
  core_LogVerbose 'Starting search for needles specified.'
  for needle in "${needles[@]}" ; do
    core_LogVerbose "Searching for: '${needle}'"
    let "index += $(gawk -v haystack="${DATA}" -v needle="${needle}" -v occurrence="${occurrence}" -f "${__SBT_EXT_DIR}/string_IndexOf.awk")"
    [ ${index} -eq -1 ] || break
  done

  # Report findings
  [ ${index} -gt -1 ] && core_LogVerbose "Found a match at index ${index} to needle: '${needle}'"
  core_StoreByRef "${REFERENCE}" "${index}" || echo -e "${index}"
  return 0
}


function string_Substring {
  #@Description  Returns the portion of a string starting at index X, up to length Y.
  #@Usage  string_Substring [-i --index '#'] [-l --length '#'] [-R 'ref_var_name'] <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.10.19

  core_LogVerbose 'Entering function.'
  # Variables
  local -i index=0            #@$ Zero-based index to start the substring at.  Supports negative values to wrap back from end of string.
  local -i length=0           #@$ Number of characters to return.  Negative value will return remainder minus $length characters.  Zero means return all.
  local opt=''                #@$ Temporary variable for core_getopts, brought to local scope.
  local REFERENCE=''          #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local -a files              #@$ Files to read if no positionals passed.
  local DATA=''               #@$ Stores the values we're going to search within.
  local temp=''               #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':f:i:l:R:' opt ':file:,index:,length:' "$@" ; do
    case "${opt}" in
      'f' | 'file'    ) files+=("${OPTARG}")   ;;
      'i' | 'index'   ) index="${OPTARG}"      ;;
      'l' | 'length'  ) length="${OPTARG}"     ;;
      'R'             ) REFERENCE="${OPTARG}"  ;;
      *               ) core_LogError "Invalid option sent to me: ${opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core_LogVerbose 'Checking requirements before processing function.'
  for temp in "${__SBT_NONOPT_ARGS[@]}" ; do DATA+="${temp}" ; done
  core_ReadDATA "${files[@]}" || return 1
  if [ ${index} -ge ${#DATA} ] ; then
    core_LogError "Index specified (${index}) is higher than data size (${#DATA}).  (aborting)"
    return 1
  fi
  temp="${DATA: ${index}}"
  if [ ${length} -lt 0 ] && [ ${length} -lt -${#temp} ] ; then
    core_LogError "A negative length was sent (${length}) that extends behind the substring made with index '${index}'.  This will cause a bash error.  (aborting)"
    return 1
  fi
  if [ ${index} -eq 0 ] && [ ${length} -eq 0 ] ; then
    core_LogVerbose 'Both index and length are zero.  The substring will exactly match the strings sent, just fyi.'
  fi

  # Main logic
  core_LogVerbose "Grabbing the substring with index '${index}' and length '${length}'."
  if [ ${length} -eq 0 ] ; then
    temp="${DATA: ${index}}"
  else
    temp="${DATA: ${index}: ${length}}"
  fi

  # Report back
  core_StoreByRef "${REFERENCE}" "${temp}" || echo -e "${temp}"
  return 0
}


function string_CountOf {
  #@Description  Returns a count of the times characters/strings are found in the passed values.
  #@Description  -
  #@Description  If count is zero, exit value will still be 0 for success.
  #@Usage  string_CountOf [-a --all] <-p --pattern 'PCRE regex' > [-R 'ref_var_name'] <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.10.21

  core_LogVerbose 'Entering function.'
  # Variables
  local pattern=''            #@$ Holds the pattern to search for.  PCRE (as in, real perl, not grep -P).
  local opt=''                #@$ Temporary variable for core_getopts, brought to local scope.
  local REFERENCE=''          #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local -a files              #@$ List of files to count occurrence in.
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local DATA=''               #@$ Holds all items to search within, mostly to help with the -a/--all items.
  local temp=''               #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':af:p:R:' opt ':all,file:,pattern:' "$@" ; do
    case "${opt}" in
      'a' | 'all'     ) pattern='[\s\S]'      ;;
      'f' | 'file'    ) files+=("${OPTARG}")  ;;
      'p' | 'pattern' ) pattern="${OPTARG}"   ;;
      'R'             ) REFERENCE="${OPTARG}" ;;
      *               ) core_LogError "Invalid option sent to me: ${opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core_LogVerbose "Checking a few requirements before proceeding."
  core_ToolExists 'perl' || return 1
  for temp in "${__SBT_NONOPT_ARGS[@]}" ; do DATA+="${temp}" ; done
  core_ReadDATA "${files[@]}" || return 1
  if [ -z "${pattern}" ] ; then
    core_LogError "No pattern was specified to find and we weren't told to find 'all'.  (aborting)"
    return 1
  fi

  # Time to count some things
  core_LogVerbose "Attempting to count occurrences."
  temp="$(perl "${__SBT_EXT_DIR}/string_CountOf.pl" -p "${pattern}" <<<"${DATA}")"
  if [ $? -ne 0 ] ; then
    core_LogError "Perl returned an error code, counting failed.  (aborting)."
    return 1
  fi
  core_StoreByRef "${REFERENCE}" "${temp}" || echo -e "${temp}"

  return 0
}
