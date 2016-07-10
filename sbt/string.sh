# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


#@Author    Kyle Harper
#@Date      2013.08.12
#@Version   0.1.0
#@Namespace string

#@Description Bash has some built-in string handling functionality, but it's far from complete.  This helps extend that.  In many cases, it simply provides a nice name to do things that the bash syntax for is convoluted.  Like lowercase: ${var,,}


#
# [Header Guard]
#
if [ -z "${__SBT_NAMESPACES_LOADED[core]}" ] ; then
  echo "The 'core' namespace hasn't been loaded.  It is required before this one can be.  Exiting for safety." >&2
  exit 1
fi
if [ ! -z "${__SBT_NAMESPACES_LOADED[string]}" ] ; then
  echo "The 'string' namespace has already been loaded.  You shouldn't have included it again.  Exiting for safety." >&2
  exit 1
fi
__SBT_NAMESPACES_LOADED[string]='loaded'




function string__to_upper {
  #@Description  Takes all positional arguments and returns them in upper case format.
  #@Description  -
  #@Description  Sends all heavy lifting to string__format_case.  This is a wrapper for convenience; not as powerful as string__format_case.  Supports any other options string__format_case does.
  #@Usage  string__to_upper <'values' in positionals or -f --file 'FILE' or STDIN>

  # Enter the function
  core__log_verbose 'Entering function.'

  # Call the real workhorse
  core__log_verbose 'Handing options off to string__format_case for the real work.'
  string__format_case -u "$@"
  return $?
}


function string__to_lower {
  #@Description  Takes all positional arguments and returns them in lower case format.
  #@Description  -
  #@Description  Sends all heavy lifting to string__format_case.  This is a wrapper for convenience; not as powerful as string__format_case.  Supports any other options string__format_case does.
  #@Usage  string__to_lower <'values' in positionals or -f --file 'FILE' or STDIN>

  # Enter the function
  core__log_verbose 'Entering function.'

  # Call the real workhorse
  core__log_verbose 'Handing options off to string__format_case for the real work.'
  string__format_case -l "$@"
  return $?
}


function string__proper_case {
  #@Description  Takes all positional arguments and returns them in proper (title) case format.
  #@Description  -
  #@Description  Sends all heavy lifting to string__format_case.  This is a wrapper for convenience; not as powerful as string__format_case.  Supports any other options string__format_case does.
  #@Usage  string__proper_case <'values' in positionals or -f --file 'FILE' or STDIN>

  # Enter the function
  core__log_verbose 'Entering function.'

  # Call the real workhorse
  core__log_verbose 'Handing options off to string__format_case for the real work.'
  string__format_case -p "$@"
  return $?
}


function string__toggle_case {
  #@Description  Takes all positional arguments and returns them in toggled case.
  #@Description  -
  #@Description  Sends all heavy lifting to string__format_case.  This is a wrapper for convenience; not as powerful as string__format_case.  Supports any other options string__format_case does.
  #@Usage  string__toggle_case <'values' in positionals or -f --file 'FILE' or STDIN>

  # Enter the function
  core__log_verbose 'Entering function.'

  # Call the real workhorse
  core__log_verbose 'Handing options off to string__format_case for the real work.'
  string__format_case -t "$@"
  return $?
}


function string__format_case {
  #@Description  Takes all positional arguments and returns them in the case format prescribed.  Usually referred by ToUpper, ToLower, etc. so we don't program long options.
  #@Description  -
  #@Description  Supports the -R switch for passing a variable name for indirect referencing.  If found, it places output in the named variable, rather than sending to stdout.
  #@Usage  string__format_case [-l] [-L] [-p] [-R 'ref_var_name'] [-t] [-u] [-U] <'values' in positionals or -f --file 'FILE' or STDIN>

  core__log_verbose 'Entering function.'
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core__getopts processing below since this will never need exposed to parents.
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt               #@$ Localizing opt for use in getopts below.
  local    _reference=''      #@$ Name to use for setting output rather than sending to std out.
  local    _case=''           #@$ The type of formatting to do.
  local -a _files             #@$ Files to read if no positionals passed.
  local    _temp=''           #@$ Temporary junk while working, mostly with loops.
  local    _data=''           #@$ Storage for values from positionals, files, or STDIN, whichever is used.

  # Grab options
  while core__getopts ':f:lLpR:tuU' _opt ':file:' "$@" ; do
    case "${_opt}" in
      'f' | 'file' )  _files+=("${OPTARG}")                                                                                                              ;;  #@opt_  File(s) to slurp for input.  The -f and --file can be specified multiple times.
      'l'          )  [ ! -z "${_case}" ] && core__log_error "Case already set to ${_case}, overriding with lower (continuing)."     ; _case='lower'     ;;  #@opt_  Convert the first character of the data sent to lower case.
      'L'          )  [ ! -z "${_case}" ] && core__log_error "Case already set to ${_case}, overriding with onelower (continuing)."  ; _case='onelower'  ;;  #@opt_  Convert all characters in the data sent to lower case.
      'p'          )  [ ! -z "${_case}" ] && core__log_error "Case already set to ${_case}, overriding with proper (continuing)."    ; _case='proper'    ;;  #@opt_  Convert data to proper (title) case, separation based on IFS.
      'R'          )  _reference="${OPTARG}"                                                                                                             ;;  #@opt_  Reference variable to assign resultant data to.
      't'          )  [ ! -z "${_case}" ] && core__log_error "Case already set to ${_case}, overriding with toggle (continuing)."    ; _case='toggle'    ;;  #@opt_  Convert data by switching the case of all characters between upper/lower.
      'u'          )  [ ! -z "${_case}" ] && core__log_error "Case already set to ${_case}, overriding with upper (continuing)."     ; _case='upper'     ;;  #@opt_  Convert the first character in data sent to upper case.
      'U'          )  [ ! -z "${_case}" ] && core__log_error "Case already set to ${_case}, overriding with oneupper (continuing)."  ; _case='oneupper'  ;;  #@opt_  Convert all characters in data sent to upper case.
      *            )  core__log_error "Invalid option:  -${_opt}  (failing)" ; return 1 ;;
    esac
  done

  # Preflights checks
  [ ${#__SBT_NONOPT_ARGS[@]} -gt 1 ] && core__log_verbose "More than one value sent to act upon, they will be joined and treated as a single item."
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _data+="${_temp}" ; done
  core__read_data "${_files[@]}" || return 1

  # Main logic
  core__log_verbose "Converting to case '${_case}' and sending results back."
  case "${_case}" in
    'lower'     ) _data="${_data,,}"  ;;
    'onelower'  ) _data="${_data,}"   ;;
    'proper'    ) _data="${_data,,}"
                  _data="${_data~}"   ;;
    'toggle'    ) _data="${_data~~}"  ;;
    'upper'     ) _data="${_data^^}"  ;;
    'oneupper'  ) _data="${_data^}"   ;;
    *           ) core__log_error "Invalid case format attempted: ${_case}  (failing)" ; return 1 ;;
  esac

  core__store_by_ref "${_reference}" "${_data}" || echo -e "${_data}"
  return 0
}


function string__index_of {
  #@Description  Find the Nth occurrence of a given substring inside a string.  If not found, return non-zero in fixed exit code.
  #@Description  -
  #@Description  Index will be zero based.  This offloads the work to awk which is a 1-based index, but that's atypical, so I adjust it.
  #@Usage  string__index_of [-o --occurrence '#'] <-n --needle 'needle' [...]> [-R 'ref_var_name'] <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.09.16

  core__log_verbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core__getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ Files to read if no positionals passed.
  local -i _index=-1          #@$ Positional index to return, zero-based.  Starting at -1 because awk is 1-based, not 0.
  local -i _occurrence=1      #@$ The Nth occurrence we want to find the index of.
  local -a _needles=()        #@$ Holds the patterns to search for.  Should be a string as we'll do fixed-string searching
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt=''            #@$ Temporary variable for core__getopts, brought to local scope.
  local    _reference=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _needle=''         #@$ Hold values for looping.
  local    _data=''           #@$ Stores the values we're going to search within.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core__getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core__log_verbose 'Processing options.'
  while core__getopts ':f:n:o:R:' _opt ':file:,needle:,occurrence:' "$@" ; do
    case "${_opt}" in
      'f' | 'file'       ) _files+=("${OPTARG}")                                                                        ;;  #@opt_  File(s) to slurp for input.  The -f and --file can be specified multiple times.
      'o' | 'occurrence' ) if [[ "${OPTARG,,}" == 'last' ]] ; then _occurrence=9999 ; else _occurrence="${OPTARG}" ; fi ;;  #@opt_  Which occurrence to return.  Specify 'last' to indicate 9999 (basically, last).
      'n' | 'needle'     ) _needles+=( "${OPTARG}" )                                                                    ;;  #@opt_  A need to search for.  Can specify many with multiple switchs: -n 'bla' -n 'bla2'
      'R'                ) _reference="${OPTARG}"                                                                       ;;  #@opt_  Reference variable to assign resultant data to.
      *                  ) core__log_error "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks and warnings
  core__log_verbose 'Checking requirements before processing function.'
  if [ ${#_needles[@]} -eq 0 ] ; then
    core__log_error "No needles were specified to find an index with.  (aborting)"
    return 1
  fi
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _data+="${_temp}" ; done
  core__read_data "${_files[@]}" || return 1
  core__tool_exists 'awk' -v '-W version' || return 1

  # Call external tool and store results in temp var.  We can += the index because awk will give a 1-based index, 0 == failed.
  core__log_verbose 'Starting search for needles specified.'
  for _needle in "${_needles[@]}" ; do
    core__log_verbose "Searching for: '${_needle}'"
    let "_index += $(awk -v haystack="${_data}" -v needle="${_needle}" -v occurrence="${_occurrence}" -f "${__SBT_EXT_DIR}/string__index_of.awk")"
    [ ${_index} -eq -1 ] || break
  done

  # Report findings
  [ ${_index} -gt -1 ] && core__log_verbose "Found a match at index ${_index} to needle: '${_needle}'"
  core__store_by_ref "${_reference}" "${_index}" || echo -e "${_index}"
  return 0
}


function string__substring {
  #@Description  Returns the portion of a string starting at index X, up to length Y.
  #@Usage  string__substring [-i --index '#'] [-l --length '#'] [-R 'ref_var_name'] <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.10.19

  core__log_verbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core__getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ Files to read if no positionals passed.
  local -i _index=0           #@$ Zero-based index to start the substring at.  Supports negative values to wrap back from end of string.
  local -i _length=0          #@$ Number of characters to return.  Negative value will return remainder minus $length characters.  Zero means return all.
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt=''            #@$ Temporary variable for core__getopts, brought to local scope.
  local    _reference=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _data=''           #@$ Stores the values we're going to search within.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core__getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core__log_verbose 'Processing options.'
  while core__getopts ':f:i:l:R:' _opt ':file:,index:,length:' "$@" ; do
    case "${_opt}" in
      'f' | 'file'    ) _files+=("${OPTARG}")   ;;  #@opt_  File(s) to slurp for input.  The -f and --file can be specified multiple times.
      'i' | 'index'   ) _index="${OPTARG}"      ;;  #@opt_  Starting index to pull from (zero-based).
      'l' | 'length'  ) _length="${OPTARG}"     ;;  #@opt_  Number of characters to return after index.
      'R'             ) _reference="${OPTARG}"  ;;  #@opt_  Reference variable to assign resultant data to.
      *               ) core__log_error "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core__log_verbose 'Checking requirements before processing function.'
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _data+="${_temp}" ; done
  core__read_data "${_files[@]}" || return 1
  if [ ${_index} -ge ${#_data} ] ; then
    core__log_error "Index specified (${_index}) is higher than data size (${#_DATA}).  (aborting)"
    return 1
  fi
  _temp="${_data: ${_index}}"
  if [ ${_length} -lt 0 ] && [ ${_length} -lt -${#_temp} ] ; then
    core__log_error "A negative length was sent (${_length}) that extends behind the substring made with index '${_index}'.  This will cause a bash error.  (aborting)"
    return 1
  fi
  if [ ${_index} -eq 0 ] && [ ${_length} -eq 0 ] ; then
    core__log_verbose 'Both index and length are zero.  The substring will exactly match the strings sent, just fyi.'
  fi

  # Main logic
  core__log_verbose "Grabbing the substring with index '${_index}' and length '${_length}'."
  if [ ${_length} -eq 0 ] ; then
    _temp="${_data: ${_index}}"
  else
    _temp="${_data: ${_index}: ${_length}}"
  fi

  # Report back
  core__store_by_ref "${_reference}" "${_temp}" || echo -e "${_temp}"
  return 0
}


function string__count_of {
  #@Description  Returns a count of the times characters/strings are found in the passed values.  Uses PCRE (perl) in pattern.
  #@Description  -
  #@Description  If count is zero, exit value will still be 0 for success.
  #@Usage  string__count_of [-a --all] <-p --pattern 'PCRE regex' > [-R 'ref_var_name'] <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.10.21

  core__log_verbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core__getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ List of files to count occurrence in.
  local    _pattern=''        #@$ Holds the pattern to search for.  PCRE (as in, real perl, not grep -P).
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt=''            #@$ Temporary variable for core__getopts, brought to local scope.
  local    _reference=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _data=''           #@$ Holds all items to search within, mostly to help with the -a/--all items.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core__getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core__log_verbose 'Processing options.'
  while core__getopts ':af:p:R:' _opt ':all,file:,pattern:' "$@" ; do
    case "${_opt}" in
      'a' | 'all'     ) _pattern='[\s\S]'      ;;  #@opt_  Count all characters in data.  A niceness.
      'f' | 'file'    ) _files+=("${OPTARG}")  ;;  #@opt_  File(s) to slurp for input.  The -f and --file can be specified multiple times.
      'p' | 'pattern' ) _pattern="${OPTARG}"   ;;  #@opt_  The PCRE pattern to match against for counting.
      'R'             ) _reference="${OPTARG}" ;;  #@opt_  Reference variable to assign resultant data to.
      *               ) core__log_error "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core__log_verbose "Checking a few requirements before proceeding."
  core__tool_exists 'perl' || return 1
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _data+="${_temp}" ; done
  core__read_data "${_files[@]}" || return 1
  if [ -z "${_pattern}" ] ; then
    core__log_error "No pattern was specified to find and we weren't told to find 'all'.  (aborting)"
    return 1
  fi

  # Time to count some things
  core__log_verbose "Attempting to count occurrences."
  _temp="$(perl "${__SBT_EXT_DIR}/string__count_of.pl" -p "${_pattern}" <<<"${_data}")"
  if [ $? -ne 0 ] ; then
    core__log_error "Perl returned an error code, counting failed.  (aborting)."
    return 1
  fi
  core__store_by_ref "${_reference}" "${_temp}" || echo -e "${_temp}"

  return 0
}


function string__pad {
  #@Description  Return the string specified with a padded version.  Padding can be left, right, or both; default of right.  Pad can be any string to repeat.  If remaining length is odd and padding is both, extra padding goes to the right.
  #@Usage  string__pad [-d --direction 'right|left|both'] <-l --length '#'> [-p --pad 'string'] [-R 'ref_var_name'] <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.11.03

  core__log_verbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core__getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ List of files to count occurrence in.
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt=''            #@$ Temporary variable for core__getopts, brought to local scope.
  local    _reference=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _data=''           #@$ Holds all items to work with.
  local    _pad=' '           #@$ String to repeat over and over.
  local -i _length=0          #@$ Length of the final string we want to send back.
  local -i _extra_length=0    #@$ Stores the extra length we want to use for padding characters.
  local    _direction='right' #@$ The direction to pad.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core__getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core__log_verbose 'Processing options.'
  while core__getopts ':d:f:l:p:R:' _opt ':direction:,file:,length:,pad:' "$@" ; do
    case "${_opt}" in
      'd' | 'direction'  ) _direction="${OPTARG}"  ;;  #@opt_  Side of the data pad, default right.
      'f' | 'file'       ) _files+=("${OPTARG}")   ;;  #@opt_  File(s) to slurp for input.  The -f and --file can be specified multiple times.
      'l' | 'length'     ) _length="${OPTARG}"     ;;  #@opt_  Length of the string to return.
      'p' | 'pad'        ) _pad="${OPTARG}"        ;;  #@opt_  Character(s) to repeat and pad with until length specified is met.
      'R'                ) _reference="${OPTARG}"  ;;  #@opt_  Reference variable to assign resultant data to.
      *                  ) core__log_error "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core__log_verbose "Checking a few requirements before proceeding."
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _data+="${_temp}" ; done
  core__read_data "${_files[@]}" || return 1
  _extra_length=$(( ${_length} - ${#_data} ))
  if [ ${_length} -le 0 ]       ; then core__log_error "Length is less than 1: '${_length}'  (aborting)"            ; return 1 ; fi
  if [ -z "${_pad}" ]           ; then core__log_error "Pad string is empty.  (aborting)"                           ; return 1 ; fi
  if [ ${_extra_length} -le 0 ] ; then core__log_verbose "_data length <= length requested.  No change to be made."            ; fi

  # Main logic
  core__log_verbose "Expanding pad string until it at least matches length desired."
  while [ ${#_pad} -lt ${_extra_length} ] ; do _pad+="${_pad}" ; done
  core__log_verbose "Applying padding to the ${_direction} of the string."
  case "${_direction,,}" in
    'both'   ) core__log_verbose "Attempting to split up the _extra_length to pad left then right sides."
               printf -v _temp '%*.*s%s'            0 $(( ${_extra_length} / 2 )) "${_pad}" "${_data}"
               if [ $(( ${_extra_length} % 2 )) -eq 1 ] ; then
                 core__log_verbose "The _extra_length is odd (${_extra_length}); the right-padding will get the extra position."
                 let _extra_length++
               fi
               printf -v _temp '%s%*.*s' "${_temp}" 0 $(( ${_extra_length} / 2 )) "${_pad}"
               ;;
    'left'   ) printf -v _temp '%*.*s%s'            0 ${_extra_length} "${_pad}" "${_data}"              ;;
    'right'  ) printf -v _temp '%s%*.*s' "${_data}" 0 ${_extra_length} "${_pad}"                         ;;
    *        ) core__log_error "Direction specified ('${_direction}') isn't valid.  (aborting)" ; return 1 ;;
  esac
  core__store_by_ref "${_reference}" "${_temp}" || echo -e "${_temp}"
  return 0
}


function string__pad_right {
  #@Description  Wrapper for string__pad for padding characters to the right-hand side of a string.
  #@Usage  string__padRight <-l --length '#'> [-p --pad 'string'] [-R 'ref_var_name'] <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.11.03

  core__log_verbose 'Entering function.  Handing off work to string__pad'
  string__pad -d 'right' "$@"
  return $?
}


function string__pad_left {
  #@Description  Wrapper for string__pad for padding characters to the left-hand side of a string.
  #@Usage  string__padLeft <-l --length '#'> [-p --pad 'string'] [-R 'ref_var_name'] <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.11.03

  core__log_verbose 'Entering function.  Handing off work to string__pad'
  string__pad -d 'left' "$@"
  return $?
}


function string__pad_both {
  #@Description  Wrapper for string__pad for padding characters to both sides of a string.
  #@Usage  string__padBoth <-l --length '#'> [-p --pad 'string'] [-R 'ref_var_name'] <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.11.03

  core__log_verbose 'Entering function.  Handing off work to string__pad'
  string__pad -d 'both' "$@"
  return $?
}


function string__reverse {
  #@Description  Read each line of input and output them in reverse.  Simple enough.
  #@Description  -
  #@Description  If multiple lines are sent they'll be stored in a single string.  Enumerate them in a loop by setting IFS to newline: IFS=$'\n'  Remember you can NOT send this to a loop after a pipe, pipes create subshells.  Use command substitution instead.  See FAQ #5 for more info.
  #@Usage  string__reverse [-R 'ref_var_name'] <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.11.03

  core__log_verbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core__getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ List of files to count occurrence in.
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt=''            #@$ Temporary variable for core__getopts, brought to local scope.
  local    _reference=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _data=''           #@$ Holds all items to work with.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core__getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core__log_verbose 'Processing options.'
  while core__getopts ':f:R:' _opt ':file:' "$@" ; do
    case "${_opt}" in
      'f' | 'file'  ) _files+=("${OPTARG}")   ;;  #@opt_  File(s) to slurp for input.  The -f and --file can be specified multiple times.
      'R'           ) _reference="${OPTARG}"  ;;  #@opt_  Reference variable to assign resultant data to.
      *             ) core__log_error "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core__log_verbose "Doing preflight checks."
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _data+="${_temp}" ; done
  core__read_data "${_files[@]}" || return 1
  core__tool_exists 'awk' -v '-W version' || return 1

  # Main
  core__log_verbose "Reversing strings and storing in _temp before reporting."
  _temp="$(awk -f "${__SBT_EXT_DIR}/string__reverse.awk" <<<"${_data}")"
  if [ $? -ne 0 ] ; then core__log_error "Error trying to reverse the information sent.  (aborting)" ; return 1 ; fi
  core__store_by_ref "${_reference}" "${_temp}" || echo -e "${_temp}"
  return 0
}


function string__trim {
  #@Description  Cuts the extraneous length of the specified character off the end(s) of a string.  Default is to trim spaces from both ends.
  #@Usage  string__trim [-c --character ' '] [-d --direction 'both'] [-R 'ref_var_name']  <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.11.04

  core__log_verbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core__getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ List of files to count occurrence in.
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt=''            #@$ Temporary variable for core__getopts, brought to local scope.
  local    _reference=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _data=''           #@$ Holds all items to work with.
  local    _character=' '     #@$ Character to cut off the end(s) of the string.
  local    _direction='both'  #@$ The direction to trim on: right, left, or both.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core__getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core__log_verbose 'Processing options.'
  while core__getopts ':c:d:f:R:' _opt ':character:,direction:,file:' "$@" ; do
    case "${_opt}" in
      'c' | 'character'  ) _character="${OPTARG}"    ;;  #@opt_  Character to trim from ends.
      'd' | 'direction'  ) _direction="${OPTARG,,}"  ;;  #@opt_  Direction to trim on: left, right, both.  Default both.
      'f' | 'file'       ) _files+=("${OPTARG}")     ;;  #@opt_  File(s) to slurp for input.  The -f and --file can be specified multiple times.
      'R'                ) _reference="${OPTARG}"    ;;  #@opt_  Reference variable to assign resultant data to.
      *                  ) core__log_error "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core__log_verbose "Doing preflight checks."
  if [ -z "${_character}" ]                     ; then core__log_error "Character to trim is blank.  (aborting)"                               ; return 1 ; fi
  if [ ${#_character} -gt 1 ]                   ; then core__log_error "Character is longer than 1: '${_character}'.  (aborting)"              ; return 1 ; fi
  if [[ ! "${_direction}" =~ left|right|both ]] ; then core__log_error "Direction (${_direction}) isn't one of: left, right, both  (aborting)" ; return 1 ; fi
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _data+="${_temp}" ; done
  core__read_data "${_files[@]}" || return 1
  core__tool_exists 'perl' || return 1

  # Main
  core__log_verbose "Trimming the string on the direction '${_direction}'"
  _temp="$(perl "${__SBT_EXT_DIR}/string__trim.pl" -c "${_character}" -d "${_direction}" <<<"${_data}")"
  if [ $? -ne 0 ] ; then core__log_error "Perl returned an error, aborting." ; return 1 ; fi
  core__store_by_ref "${_reference}" "${_temp}" || echo -e "${_temp}"
  return 0
}


function string__trim_right {
  #@Description  Cuts the extraneous length off the right-hand side of a string.  Wrapper for string__trim
  #@Usage  string__trimRight [-c --character ' '] [-R 'ref_var_name']  <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.11.04

  core__log_verbose 'Entering function and offloading work to string__trim'
  string__trim -d 'right' "$@"
  return $?
}


function string__trim_left {
  #@Description  Cuts the extraneous length of the specified character off the end(s) of a string.  Default is to trim spaces from both ends.
  #@Usage  string__trimLeft [-c --character ' '] [-R 'ref_var_name']  <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.11.04

  core__log_verbose 'Entering function and offloading work to string__trim'
  string__trim -d 'left' "$@"
  return $?
}


function string__insert {
  #@Description  Inserts the item (source) specified into the _DATA specified at the index specified.  So much specificity!
  #@Usage  string__insert [-i --index '#'] [-s --source 'something'] [-R 'ref_var_name']  <'values' in positionals or -f --file 'FILE' or STDIN>
  #@Date   2013.11.05

  core__log_verbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core__getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ List of files to count occurrence in.
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt=''            #@$ Temporary variable for core__getopts, brought to local scope.
  local    _reference=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _data=''           #@$ Holds data sent for manipulation.
  local    _source=''         #@$ The source we that will insert into _DATA.
  local -i _index=0           #@$ The zero-based index to inject at.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core__getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core__log_verbose 'Processing options.'
  while core__getopts ':f:i:R:s:' _opt ':file:,index:,source:' "$@" ; do
    case "${_opt}" in
      'f' | 'file'    ) _files+=("${OPTARG}")  ;;  #@opt_  File(s) to slurp for input.  The -f and --file can be specified multiple times.
      'i' | 'index'   ) _index="${OPTARG}"     ;;  #@opt_  The index at which to insert data.  Follows bash rules for index, including negative indexes.
      's' | 'source'  ) _source="${OPTARG}"    ;;  #@opt_  Source to insert into _DATA.
      'R'             ) _reference="${OPTARG}" ;;  #@opt_  Reference variable to assign resultant data to.
      *               ) core__log_error "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core__log_verbose "Doing preflight checks."
  [ -z "${_source}" ]           && core__log_verbose 'Source is blank, which is odd.  Value will become simple _data sent.'
  [ ${_index} -eq 0 ]           && core__log_verbose 'Index is zero, you could have simply concatinated: bla="${one}${two}".  FYI.'
  [ ${_index} -ge ${#_source} ] && core__log_verbose 'Index is >= length of source, could have concatinated: bla="${two}${one}"  FYI.'
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _data+="${_temp}" ; done
  core__read_data "${_files[@]}" || return 1

  # Main
  core__log_verbose "Inserting _data into source specified."
  _temp="${_data: 0: ${_index}}${_source}${_data: ${_index}}"
  core__store_by_ref "${_reference}" "${_temp}" || echo -e "${_temp}"
  return 0
}

