# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


#@Author    Kyle Harper
#@Date      2014.08.18
#@Version   0.0.1-beta
#@Namespace core

#@Description  Functions to handle arrays.  Searching, sorting, merging, dissecting, etc.


#
# -- Initialize Globals for this Namespace
#



function array_Length {
  #@Description  Returns the number of elements of an array.  Trivial for now, but might support advanced checking/reporting in the future.
  #@Usage        array_Length <-a or --array 'name_of_array_to_check'> [-R 'ref_var_name']

  core_LogVerbose "Entering function."
  local -i OPTIND=1    #@$ Localizing OPTIND to avoid scoping issues.
  local -i _count=0    #@$ Stores the count in case we need to manipulate it in the future.
  local    _opt        #@$ Localizing opt for use in getopts below.
  local    _array      #@$ Local variable to hold the array we're going to work with.
  local    _REFERENCE  #@$ Holds the variable name to store output in if desired.

  # Grab options
  while true ; do
    core_getopts ':a:R:' _opt ':array:' "$@"
    case $? in  2 ) core_LogError "Getopts failed.  Aborting function." ; return 1 ;;  1 ) break ;; esac
    case "${_opt}" in
      'a' | 'array' )  _array="${OPTARG}"                                             ;;  #@opt_  Name of the array to work with.
      'R'           )  _REFERENCE="${OPTARG}"                                         ;;  #@opt_  Return variable to send output to.
      *             )  core_LogError "Invalid option: -${_opt}  (failing)" ; return 1 ;;
    esac
  done

  # Preflight checks
  if [ -z "${_array}" ] ; then core_LogError "The _array variable name is empty.  This is wrong.  Please send with -a/--array." ; return 1 ; fi

  # Main logic
  core_LogVerbose "Getting ready to count the elements in array named '${_array}'."
  eval _count=\${#${_array}[@]}

  # Return information
  core_StoreByRef "${_REFERENCE}" "${_count}" || echo -e "${_count}"
  return 0
}

