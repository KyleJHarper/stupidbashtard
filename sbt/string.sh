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
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local    _opt               #@$ Localizing opt for use in getopts below.
  local    _REFERENCE=''      #@$ Name to use for setting output rather than sending to std out.
  local    _CASE=''           #@$ The type of formatting to do.
  local -a _files             #@$ Files to read if no positionals passed.
  local    _temp=''           #@$ Temporary junk while working, mostly with loops.
  local    _DATA=''           #@$ Storage for values from positionals, files, or STDIN, whichever is used.

  # Grab options
  while core_getopts ':f:lLpR:tuU' _opt ':file:' "$@" ; do
    case "${_opt}" in
      'f' | 'file' )  _files+=("${OPTARG}")                                                                                                            ;;
      'l'          )  [ ! -z "${_CASE}" ] && core_LogError "Case already set to ${_CASE}, overriding with lower (continuing)."     ; _CASE='lower'     ;;
      'L'          )  [ ! -z "${_CASE}" ] && core_LogError "Case already set to ${_CASE}, overriding with onelower (continuing)."  ; _CASE='onelower'  ;;
      'p'          )  [ ! -z "${_CASE}" ] && core_LogError "Case already set to ${_CASE}, overriding with proper (continuing)."    ; _CASE='proper'    ;;
      'R'          )  _REFERENCE="${OPTARG}"                                                                                                           ;;
      't'          )  [ ! -z "${_CASE}" ] && core_LogError "Case already set to ${_CASE}, overriding with toggle (continuing)."    ; _CASE='toggle'    ;;
      'u'          )  [ ! -z "${_CASE}" ] && core_LogError "Case already set to ${_CASE}, overriding with upper (continuing)."     ; _CASE='upper'     ;;
      'U'          )  [ ! -z "${_CASE}" ] && core_LogError "Case already set to ${_CASE}, overriding with oneupper (continuing)."  ; _CASE='oneupper'  ;;
      *            )  core_LogError "Invalid option:  -${_opt}  (failing)" ; return 1 ;;
    esac
  done

  # Preflights checks
  [ ${#__SBT_NONOPT_ARGS[@]} -gt 1 ] && core_LogVerbose "More than one value sent to act upon, they will be joined and treated as a single item."
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _DATA+="${_temp}" ; done
  core_ReadDATA "${_files[@]}" || return 1

  # Main logic
  core_LogVerbose "Converting to case '${_CASE}' and sending results back."
  case "${_CASE}" in
    'lower'     ) _DATA="${_DATA,,}"  ;;
    'onelower'  ) _DATA="${_DATA,}"   ;;
    'proper'    ) _DATA="${_DATA,,}"
                  _DATA="${_DATA~}"   ;;
    'toggle'    ) _DATA="${_DATA~~}"  ;;
    'upper'     ) _DATA="${_DATA^^}"  ;;
    'oneupper'  ) _DATA="${_DATA^}"   ;;
    *           ) core_LogError "Invalid case format attempted: ${_CASE}  (failing)" ; return 1 ;;
  esac

  core_StoreByRef "${_REFERENCE}" "${_DATA}" || echo -e "${_DATA}"
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
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ Files to read if no positionals passed.
  local -i _index=-1          #@$ Positional index to return, zero-based.  Starting at -1 because awk is 1-based, not 0.
  local -i _occurrence=1      #@$ The Nth occurrence we want to find the index of.
  local -a _needles=()        #@$ Holds the patterns to search for.  Should be a string as we'll do fixed-string searching
  local    _opt=''            #@$ Temporary variable for core_getopts, brought to local scope.
  local    _REFERENCE=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _needle=''         #@$ Hold values for looping.
  local    _DATA=''           #@$ Stores the values we're going to search within.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':f:n:o:R:' _opt ':file:,needle:,occurrence:' "$@" ; do
    case "${_opt}" in
      'f' | 'file'       ) _files+=("${OPTARG}") ;;
      'o' | 'occurrence' ) if [[ "${OPTARG}" == 'last' ]] ; then _occurrence=9999 ; else _occurrence="${OPTARG}" ; fi ;;
      'n' | 'needle'     ) _needles+=( "${OPTARG}" )  ;;
      'R'                ) _REFERENCE="${OPTARG}"     ;;
      *                  ) core_LogError "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks and warnings
  core_LogVerbose 'Checking requirements before processing function.'
  if [ ${#_needles[@]} -eq 0 ] ; then
    core_LogError "No needles were specified to find an index with.  (aborting)"
    return 1
  fi
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _DATA+="${_temp}" ; done
  core_ReadDATA "${_files[@]}" || return 1
  core_ToolExists 'gawk' || return 1

  # Call external tool and store results in temp var.  We can += the index because awk will give a 1-based index, 0 == failed.
  core_LogVerbose 'Starting search for needles specified.'
  for _needle in "${_needles[@]}" ; do
    core_LogVerbose "Searching for: '${_needle}'"
    let "_index += $(gawk -v haystack="${_DATA}" -v needle="${_needle}" -v occurrence="${_occurrence}" -f "${__SBT_EXT_DIR}/string_IndexOf.awk")"
    [ ${_index} -eq -1 ] || break
  done

  # Report findings
  [ ${_index} -gt -1 ] && core_LogVerbose "Found a match at index ${_index} to needle: '${_needle}'"
  core_StoreByRef "${_REFERENCE}" "${_index}" || echo -e "${_index}"
  return 0
}


function string_Substring {
  #@Description  Returns the portion of a string starting at index X, up to length Y.
  #@Usage  string_Substring [-i --index '#'] [-l --length '#'] [-R 'ref_var_name'] <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.10.19

  core_LogVerbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ Files to read if no positionals passed.
  local -i _index=0           #@$ Zero-based index to start the substring at.  Supports negative values to wrap back from end of string.
  local -i _length=0          #@$ Number of characters to return.  Negative value will return remainder minus $length characters.  Zero means return all.
  local    _opt=''            #@$ Temporary variable for core_getopts, brought to local scope.
  local    _REFERENCE=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _DATA=''           #@$ Stores the values we're going to search within.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':f:i:l:R:' _opt ':file:,index:,length:' "$@" ; do
    case "${_opt}" in
      'f' | 'file'    ) _files+=("${OPTARG}")   ;;
      'i' | 'index'   ) _index="${OPTARG}"      ;;
      'l' | 'length'  ) _length="${OPTARG}"     ;;
      'R'             ) _REFERENCE="${OPTARG}"  ;;
      *               ) core_LogError "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core_LogVerbose 'Checking requirements before processing function.'
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _DATA+="${_temp}" ; done
  core_ReadDATA "${_files[@]}" || return 1
  if [ ${_index} -ge ${#_DATA} ] ; then
    core_LogError "Index specified (${_index}) is higher than data size (${#_DATA}).  (aborting)"
    return 1
  fi
  _temp="${_DATA: ${_index}}"
  if [ ${_length} -lt 0 ] && [ ${_length} -lt -${#_temp} ] ; then
    core_LogError "A negative length was sent (${_length}) that extends behind the substring made with index '${_index}'.  This will cause a bash error.  (aborting)"
    return 1
  fi
  if [ ${_index} -eq 0 ] && [ ${_length} -eq 0 ] ; then
    core_LogVerbose 'Both index and length are zero.  The substring will exactly match the strings sent, just fyi.'
  fi

  # Main logic
  core_LogVerbose "Grabbing the substring with index '${_index}' and length '${_length}'."
  if [ ${_length} -eq 0 ] ; then
    _temp="${_DATA: ${_index}}"
  else
    _temp="${_DATA: ${_index}: ${_length}}"
  fi

  # Report back
  core_StoreByRef "${_REFERENCE}" "${_temp}" || echo -e "${_temp}"
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
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ List of files to count occurrence in.
  local    _pattern=''        #@$ Holds the pattern to search for.  PCRE (as in, real perl, not grep -P).
  local    _opt=''            #@$ Temporary variable for core_getopts, brought to local scope.
  local    _REFERENCE=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _DATA=''           #@$ Holds all items to search within, mostly to help with the -a/--all items.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':af:p:R:' _opt ':all,file:,pattern:' "$@" ; do
    case "${_opt}" in
      'a' | 'all'     ) _pattern='[\s\S]'      ;;
      'f' | 'file'    ) _files+=("${OPTARG}")  ;;
      'p' | 'pattern' ) _pattern="${OPTARG}"   ;;
      'R'             ) _REFERENCE="${OPTARG}" ;;
      *               ) core_LogError "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core_LogVerbose "Checking a few requirements before proceeding."
  core_ToolExists 'perl' || return 1
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _DATA+="${_temp}" ; done
  core_ReadDATA "${_files[@]}" || return 1
  if [ -z "${_pattern}" ] ; then
    core_LogError "No pattern was specified to find and we weren't told to find 'all'.  (aborting)"
    return 1
  fi

  # Time to count some things
  core_LogVerbose "Attempting to count occurrences."
  _temp="$(perl "${__SBT_EXT_DIR}/string_CountOf.pl" -p "${_pattern}" <<<"${_DATA}")"
  if [ $? -ne 0 ] ; then
    core_LogError "Perl returned an error code, counting failed.  (aborting)."
    return 1
  fi
  core_StoreByRef "${_REFERENCE}" "${_temp}" || echo -e "${_temp}"

  return 0
}


function string_Pad {
  #@Description  Return the string specified with a padded version.  Padding can be left, right, or both; default of right.  Pad can be any string to repeat.  If remaining length is odd and padding is both, extra padding goes to the right.
  #@Usage  string_Pad [-d --direction 'right|left|both'] <-l --length '#'> [-p --pad 'string'] [-R 'ref_var_name'] <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.11.03

  core_LogVerbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ List of files to count occurrence in.
  local    _opt=''            #@$ Temporary variable for core_getopts, brought to local scope.
  local    _REFERENCE=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _DATA=''           #@$ Holds all items to search within, mostly to help with the -a/--all items.
  local    _pad=' '           #@$ String to repeat over and over.
  local -i _length=0          #@$ Length of the final string we want to send back.
  local -i _extra_length=0    #@$ Stores the extra length we want to use for padding characters.
  local    _direction='right' #@$ The direction to pad.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':d:f:l:p:R:' _opt ':direction:,file:,length:,pad:' "$@" ; do
    case "${_opt}" in
      'd' | 'direction'  ) _direction="${OPTARG}"  ;;
      'f' | 'file'       ) _files+=("${OPTARG}")   ;;
      'l' | 'length'     ) _length="${OPTARG}"     ;;
      'p' | 'pad'        ) _pad="${OPTARG}"        ;;
      'R'                ) _REFERENCE="${OPTARG}"  ;;
      *                  ) core_LogError "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core_LogVerbose "Checking a few requirements before proceeding."
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _DATA+="${_temp}" ; done
  core_ReadDATA "${_files[@]}" || return 1
  _extra_length=$(( ${_length} - ${#_DATA} ))
  if [ ${_length} -le 0 ]       ; then core_LogError "Length is less than 1: '${_length}'  (aborting)"            ; return 1 ; fi
  if [ -z "${_pad}" ]           ; then core_LogError "Pad string is empty.  (aborting)"                           ; return 1 ; fi
  if [ ${_extra_length} -le 0 ] ; then core_LogVerbose "_DATA length <= length requested.  No change to be made.."            ; fi

  # Main logic
  core_LogVerbose "Expanding pad string until it at least matches length desired."
  while [ ${#_pad} -lt ${_extra_length} ] ; do _pad+="${_pad}" ; done
  core_LogVerbose "Applying padding to the ${_direction} of the string."
  case "${_direction,,}" in
    'both'   ) core_LogVerbose "Attempting to split up the _extra_length to pad left then right sides."
               printf -v _temp '%*.*s%s'            0 $(( ${_extra_length} / 2 )) "${_pad}" "${_DATA}"
               if [ $(( ${_extra_length} % 2 )) -eq 1 ] ; then
                 core_LogVerbose "The _extra_length is odd (${_extra_length}); the right-padding will get the extra position."
                 let _extra_length++
               fi
               printf -v _temp '%s%*.*s' "${_temp}" 0 $(( ${_extra_length} / 2 )) "${_pad}"
               ;;
    'left'   ) printf -v _temp '%*.*s%s'            0 ${_extra_length} "${_pad}" "${_DATA}"              ;;
    'right'  ) printf -v _temp '%s%*.*s' "${_DATA}" 0 ${_extra_length} "${_pad}"                         ;;
    *        ) core_LogError "Direction specified ('${_direction}') isn't valid.  (aborting)" ; return 1 ;;
  esac
  core_StoreByRef "${_REFERENCE}" "${_temp}" || echo -e "${_temp}"
  return 0
}


function string_PadRight {
  #@Description  Wrapper for string_Pad for padding characters to the right-hand side of a string.
  #@Usage  string_PadRight <-l --length '#'> [-p --pad 'string'] [-R 'ref_var_name'] <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.11.03

  core_LogVerbose 'Entering function.  Handing off work to string_Pad'
  string_Pad -d 'right' "$@"
  return $?
}


function string_PadLeft {
  #@Description  Wrapper for string_Pad for padding characters to the left-hand side of a string.
  #@Usage  string_PadLeft <-l --length '#'> [-p --pad 'string'] [-R 'ref_var_name'] <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.11.03

  core_LogVerbose 'Entering function.  Handing off work to string_Pad'
  string_Pad -d 'left' "$@"
  return $?
}


function string_PadBoth {
  #@Description  Wrapper for string_Pad for padding characters to both sides of a string.
  #@Usage  string_PadBoth <-l --length '#'> [-p --pad 'string'] [-R 'ref_var_name'] <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.11.03

  core_LogVerbose 'Entering function.  Handing off work to string_Pad'
  string_Pad -d 'both' "$@"
  return $?
}


function string_Reverse {
  #@Description  Read each line of input and output them in reverse.  Simple enough.
  #@Description  -
  #@Description  If multiple lines are sent they'll be stored in a single string.  Enumerate them in a loop by setting IFS to newline: IFS=$'\n'  Remember you can NOT send this to a loop after a pipe, pipes create subshells.  Use command substitution instead.  See FAQ #5 for more info.
  #@Usage  string_Reverse [-R 'ref_var_name'] <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.11.03

  core_LogVerbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ List of files to count occurrence in.
  local    _opt=''            #@$ Temporary variable for core_getopts, brought to local scope.
  local    _REFERENCE=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _DATA=''           #@$ Holds all items to search within, mostly to help with the -a/--all items.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':f:R:' _opt ':file:' "$@" ; do
    case "${_opt}" in
      'f' | 'file'  ) _files+=("${OPTARG}")   ;;
      'R'           ) _REFERENCE="${OPTARG}"  ;;
      *             ) core_LogError "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core_LogVerbose "Doing preflight checks."
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _DATA+="${_temp}" ; done
  core_ReadDATA "${_files[@]}" || return 1
  core_ToolExists 'gawk' || return 1

  # Main
  core_LogVerbose "Reversing strings and storing in _temp before reporting."
  _temp="$(gawk -f "${__SBT_EXT_DIR}/string_Reverse.awk" <<<"${_DATA}")"
  if [ $? -ne 0 ] ; then core_LogError "Error trying to reverse the information sent.  (aborting)" ; return 1 ; fi
  core_StoreByRef "${_REFERENCE}" "${_temp}" || echo -e "${_temp}"
  return 0
}


function string_Trim {
  #@Description  Cuts the extraneous length of the specified character off the end(s) of a string.  Default is to trim spaces from both ends.
  #@Usage  string_Trim [-c --character ' '] [-d --direction 'both'] [-R 'ref_var_name']  <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.11.04

  core_LogVerbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ List of files to count occurrence in.
  local    _opt=''            #@$ Temporary variable for core_getopts, brought to local scope.
  local    _REFERENCE=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _DATA=''           #@$ Holds all items to search within, mostly to help with the -a/--all items.
  local    _character=' '     #@$ Character to cut off the end(s) of the string.
  local    _direction='both'  #@$ The direction to trim on: right, left, or both.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':c:d:f:R:' _opt ':character:,direction:,file:' "$@" ; do
    case "${_opt}" in
      'c' | 'character'  ) _character="${OPTARG}"  ;;
      'd' | 'direction'  ) _direction="${OPTARG}"  ;;
      'f' | 'file'       ) _files+=("${OPTARG}")   ;;
      'R'                ) _REFERENCE="${OPTARG}"  ;;
      *                  ) core_LogError "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core_LogVerbose "Doing preflight checks."
  if [ -z "${_character}" ]   ; then core_LogError "Character to trim is blank.  (aborting)"                  ; return 1 ; fi
  if [ ${#_character} -gt 1 ] ; then core_LogError "Character is longer than 1: '${_character}'.  (aborting)" ; return 1 ; fi
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _DATA+="${_temp}" ; done
  core_ReadDATA "${_files[@]}" || return 1
  core_ToolExists tr || return 1

  # Main
  core_LogVerbose "Trimming the string on the direction '${_direction}'"
  case "${_direction,,}" in
!!! SEND THIS TO PERL
    'left'  ) _DATA="${_DATA%%${_character}*}"  ;;
    'right' ) _DATA="${_DATA##*${_character}}"  ;;
    'both'  ) _DATA="${_DATA%%${_character}*}"
              _DATA="${_DATA##*${_character}}"  ;;
    *       ) core_LogError "Direction specified (${_direction}) isn't one of: left, right, both  (aborting)" ; return 1  ;;
  esac
  core_StoreByRef "${_REFERENCE}" "${_DATA}" || echo -e "${_DATA}"
  return 0
}


function string_TrimRight {
  #@Description  Cuts the extraneous length off the right-hand side of a string.  Wrapper for string_Trim
  #@Usage  string_TrimRight [-c --character ' '] [-R 'ref_var_name']  <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.11.04

  core_LogVerbose 'Entering function and offloading work to string_Trim'
  string_Trim -d 'right' "$@"
  return $?
}


function string_TrimLeft {
  #@Description  Cuts the extraneous length of the specified character off the end(s) of a string.  Default is to trim spaces from both ends.
  #@Usage  string_TrimLeft [-c --character ' '] [-R 'ref_var_name']  <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.11.04

  core_LogVerbose 'Entering function and offloading work to string_Trim'
  string_Trim -d 'left' "$@"
  return $?
}
