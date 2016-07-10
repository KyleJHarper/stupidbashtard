# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


#@Author    Kyle Harper
#@Date      2014.08.18
#@Version   0.0.1-beta
#@Namespace core

#@Description  Functions to handle arrays.  Searching, sorting, merging, dissecting, etc.
#@Description  -
#@Description  Functions should work for both arrays and associative arrays.  This is because ALL arrays are associative in bash.  The original arrays use ordinals (numeric identifiers) but there is no such concept as push/pop.  The numbers are just integer place holders.  You can unset mid-array elements and the indexes don't change above or below it.  I think Chet just woke up one day and went "Oh yea... I could just use words as keys here...".


#
# [Header Guard]
#
if [ -z "${__SBT_NAMESPACES_LOADED[core]}" ] ; then
  echo "The 'core' namespace hasn't been loaded.  It is required before this one can be.  Exiting for safety." >&2
  exit 1
fi
if [ ! -z "${__SBT_NAMESPACES_LOADED[array]}" ] ; then
  echo "The 'array' namespace has already been loaded.  You shouldn't have included it again.  Exiting for safety." >&2
  exit 1
fi
__SBT_NAMESPACES_LOADED[array]='loaded'


#
# -- Initialize Globals for this Namespace
#



function array__length {
  #@Description  Returns the number of elements of an array.  Trivial for now, but might support advanced checking/reporting in the future.
  #@Usage        array__length <-a --array 'name_of_array_to_check'> [-R 'ref_var_name']

  core__log_verbose "Entering function."
  local -i OPTIND=1    #@$ Localizing OPTIND to avoid scoping issues.
  local -i _count=0    #@$ Stores the count in case we need to manipulate it in the future.
  local    _opt        #@$ Localizing opt for use in getopts below.
  local    _array      #@$ Local variable to hold the array we're going to work with.
  local    _reference  #@$ Holds the variable name to store output in if desired.

  # Grab options
  while true ; do
    core__getopts ':a:R:' _opt ':array:' "$@"
    case $? in  2 ) core__log_error "Getopts failed.  Aborting function." ; return 1 ;;  1 ) break ;; esac
    case "${_opt}" in
      'a' | 'array' )  _array="${OPTARG}"                                               ;;  #@opt_  Name of the array to work with.
      'R'           )  _reference="${OPTARG}"                                           ;;  #@opt_  Return variable to send output to.
      *             )  core__log_error "Invalid option: -${_opt}  (failing)" ; return 1 ;;
    esac
  done

  # Preflight checks
  if [ -z "${_array}" ] ; then core__log_error "The _array variable name is empty.  This is wrong.  Please send with -a/--array." ; return 1 ; fi

  # Main logic
  core__log_verbose "Getting ready to count the elements in array named '${_array}'."
  eval _count=\${#${_array}[@]}

  # Return information
  core__store_by_ref "${_reference}" "${_count}" || echo -e "${_count}"
  return 0
}


function array__remove {
  #@Description  Removes elements from an array based on the criteria specified.  In it's simplest form it does: unset array[key].  Be aware, specifying a key will always result in that key being removed, even if you specify pattern matching removing, N-th element removal, etc.  The order of precedence is:  N-th > pattern > key.
  #@Description  -
  #@Description  The better uses for this are: removing multiple in one function call, removing those matching pattern(s), removing every N-th.  You must specify at least one of the following: a pattern, an N-th value, or a key.  Keys purposely do not require a switch like -k; this is to support feeding the output of array__index_of to this function more easily.
  #@Description  !! IMPORTANT !!  Using the N-th switch with an associative array is nonsensical.  Associative arrays do not maintain key order.  Also be aware that standard arrays don't push/pop.  So performing an N-th removal will not move ordinal values up/down; so running an N-th removal on the same array multiple times is probably not going to do what you expect.  You've been warned.
  #@Usage        array__remove <-a --array 'name_of_array'> [-n --nth '#'] [-p --pattern 'PCRE regex pattern'] ['key1' ...]

  core__log_verbose "Entering function."
  local -a __SBT_NONOPT_ARGS  #@$ Localizing to store the keys we'll use later.
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt               #@$ Localizing _opt for use in getopts below.
  local    _temp=''           #@$ Junk variable for loops.
  local    _array=''          #@$ Name of the array we wil be working with.
  local -i _array_length=0    #@$ Size of the array.  Using a variable so we only call array__length once.
  local    _pattern=''        #@$ Holds the regex pattern for key removal.  Leaving blank means disabled.
  local -a _pattern_removals  #@$ Keys removed when pattern matching is attempted and successful.
  local -i _nth=0             #@$ Holds the N-th integer for removing keys every N-th occurrence.  Leaving at 0 means disabled.
  local -a _nth_removals      #@$ Keys removed by the nth switch.
  local -i _index=1           #@$ Holds current index for loop checking below.
  local -a _keys              #@$ Hold a list of all keys for use when N-th or pattern removal is happening.
  local -a _key_removals      #@$ Keys removed after searching list specified in arguments to this function.

  # Grab options
  while true ; do
    core__getopts ':a:n:p:' _opt ':array:,nth:,pattern:' "$@"
    case $? in  2 ) core__log_error "Getopts failed.  Aborting function." ; return 1 ;;  1 ) break ;; esac
    case "${_opt}" in
      'a' | 'array'   ) _array="${OPTARG}"                                              ;;  #@opt_  Name of the array to work with.
      'n' | 'nth'     ) _nth="${OPTARG}"                                                ;;  #@opt_  Sets the integer for N-th removal of keys.
      'p' | 'pattern' ) _pattern="${OPTARG}"                                            ;;  #@opt_  Sets the regex pattern for pattern based removal of keys.  Must be PCRE.  This function will NOT check for that, it will just fail if wrong.
      *               ) core__log_error "Invalid option: ${_opt}  (failing)" ; return 1 ;;
    esac
  done

  # Preflight checks
  if [ -z "${_array}" ] ; then core__log_error "The _array variable is empty, you must send the array name with -a/--array." ; return 1 ; fi
  if [ ${_nth} -lt 1 ] && [ -z "${_pattern}" ] && [ ${#__SBT_NONOPT_ARGS[@]} -eq 0 ] ; then core__log_error "You didn't send a pattern, N-th value, or any keys.  At least 1 of these is required.  Aborting." ; return 1 ; fi

  # Main logic
  core__log_verbose "Gathering key information from '${_array}' for processing below."
  array__keys -a "${_array}" -R '_keys' || return 1

  # -- N-th removal
  if [ ${_nth} -gt 0 ] ; then
    core__log_verbose "Removing every N-th element with an increment value of: ${_nth}."
    for _temp in "${_keys[@]}" ; do
      if [ ${_index} -eq ${_nth} ] ; then
        eval unset -v ${_array}\[\"${_temp}\"\]
        _index=1 ; _nth_removals+=("${_temp}") ; continue 1
      fi
      let _index++
    done
    core__log_verbose "Keys removed (${#_nth_removals[@]}): ${_nth_removals[@]}"
  fi

  # -- Pattern removal
  if [ ! -z "${_pattern}" ] ; then
    core__log_verbose "Removing keys that match the following PCRE pattern: ${_pattern} "
    while read -r _temp ; do
      eval unset -v ${_array}\[\"${_temp}\"\]
      _pattern_removals+=("${_temp}")
    done < <(printf '%s\n' "${_keys[@]}" | perl -n -e "if (/${_pattern}/) { print; }")
    core__log_verbose "Keys removed (${#_pattern_removals[@]}): ${_pattern_removals[@]}"
  fi

  # -- Key removal
  if [ ${#__SBT_NONOPT_ARGS[@]} -gt 0 ] ; then
    core__log_verbose "Removing keys specified in __SBT_NONOPT_ARGS: ${__SBT_NONOPT_ARGS[@]}"
    for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do
      eval [ -z  \"\${${_array}\[\'${_temp}\'\]}\" ] && continue 1
      _key_removals+=("${_temp}")
      eval unset -v ${_array}\[\"${_temp}\"\]
    done
    core__log_verbose "Keys removed (${#_key_removals[@]}): ${_key_removals[@]}"
  fi

  # All Done
  return 0
}


function array__keys {
  #@Description  Very simple function to return the list of all keys in an array.  Only takes options for the array name and reference variable to store the keys in.
  #@Description  !! IMPORTANT !! The reference variable specified by -R MUST be an array already declared by the caller!
  #@Usage        array__keys <-a --array 'name_of_array'> <-R 'reference_output_name'>

  core__log_verbose "Entering function."
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt               #@$ Localizing _opt for use in getopts below.
  local    _array=''          #@$ Name of the array we wil be working with.
  local    _reference_        #@$ Hold a list of all keys found.

  # Grab options
  while true ; do
    core__getopts ':a:R:' _opt ':array:' "$@"
    case $? in  2 ) core__log_error "Getopts failed.  Aborting function." ; return 1 ;;  1 ) break ;; esac
    case "${_opt}" in
      'a' | 'array'  ) _array="${OPTARG}"                                              ;;  #@opt_  Name of the array to work with.
      'R'            ) _reference_="${OPTARG}"                                         ;;  #@opt_  Reference variable name to put results in.  MUST be an array.
      *              ) core__log_error "Invalid option: ${_opt}  (failing)" ; return 1 ;;
    esac
  done

  # Preflight checks
  if [ -z "${_array}" ]      ; then core__log_error "The _array variable is empty, you must send the array name with -a/--array."     ; return 1 ; fi
  if [ -z "${_reference_}" ] ; then core__log_error "The _reference_ variable is empty, you must specify an array name here with -R." ; return 1 ; fi

  # Main logic
  core__log_verbose "Assigning keys to the variable '${_reference_}' from the array named '${_array}' with a nasty eval."
  eval ${_reference_}=\(\"\${!${_array}[@]}\"\)
  return 0
}


function array__keys_exist {
  #@Description  Returns true (code 0) if the key(s) specified exist in the array specified.  A switch is available to return true (code 0) if any key matches.
  #@Usage        array__keys_exist <-a --array 'name_of_array'> [--any] <'key1' ['key2'...]>

  core__log_verbose "Entering function."
  local -a __SBT_NONOPT_ARGS  #@$ Localizing to store the keys we'll use later.
  local -i OPTIND=1           #@$ Localizing OPTIND to avoid scoping issues.
  local    _opt               #@$ Localizing _opt for use in getopts below.
  local    _array=''          #@$ Name of the array we wil be working with.
  local    _any=false         #@$ Flag to cut-out early if any of mutliple keys are found.
  local    _temp              #@$ Junk variable for the loop below.
  local    _key               #@$ Temporary variable to hold key to check against the list.
  local -i _found=0           #@$ Count of the number of items found, useful when needing multiple keys and --any isn't specified.
  local -i E_GENERIC=1        #@$ Return code for generic failures.
  local -i E_NOT_FOUND=2      #@$ Code for failure to find the key(s) to differentiate from generic failures (code 1).

  # Grab options
  while true ; do
    core__getopts ':a:' _opt ':any,array:' "$@"
    case $? in  2 ) core__log_error "Getopts failed.  Aborting function." ; return ${E_GENERIC} ;;  1 ) break ;; esac
    case "${_opt}" in
            'any'   ) _any=true                                                                  ;;  #@opt_  Toggles the flag to quit early when checking multiple keys and one is found.
      'a' | 'array' ) _array="${OPTARG}"                                                         ;;  #@opt_  Name of the array to work with.
      *             ) core__log_error "Invalid option: ${_opt}  (failing)" ; return ${E_GENERIC} ;;
    esac
  done

  # Preflight checks
  if [ -z "${_array}" ] ; then core__log_error "The _array variable is empty, you must send the array name with -a/--array." ; return ${E_GENERIC} ; fi

  # Main logic
  core__log_verbose "Beginning double-loop structure to find matching keys.  Keys are: ${__SBT_NONOPT_ARGS[@]}"
  while read -r _temp ; do
    for _key in "${__SBT_NONOPT_ARGS[@]}" ; do
      if [ "${_temp}" = "${_key}" ] ; then
        core__log_verbose "Found key: ${_key}"
        ${_any} && core__log_verbose "The any flag was set, leaving." && return 0
        let _found++
        continue 2
      fi
    done
  done < <(eval printf \"%s\\n\" \"\${!${_array}[@]}\")
  if [ ${_found} -eq ${#__SBT_NONOPT_ARGS[@]} ] ; then
    core__log_verbose "Found all keys.  Returning success."
    return 0
  fi

  # If we haven't returned successfully by now, we failed.
  core__log_verbose "Couldn't find one or more keys.  Returning E_NOT_FOUND (code 2)."
  return ${E_NOT_FOUND}
}
