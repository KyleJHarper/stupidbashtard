#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

function test__function {
  #@Author  Hank BoFrank
  #@Date    2013.03.04
  #@Usage   test__function [-D 'search for string' [-D ...]] [-h --help] [-v --verbose] <file>
  #@Dep     grep 2.0+ it's awesome
  #@dep     cool_tool 9.21.4-alpha+, but less than 9.21.5

  #@Description   A complex function attempting to show most (or all) of the things/ways you can document stuff.
  #@Description   We will attempt to read a file and list the line number and first occurence of a Zelda keyword.
  #@Description   -
  #@Description   This is a SILLY script that is untested; for demonstration purposes only.


  # Variables
  #@$1 The first option (after shifting from getopts) will be a file name to operate on.
  #@$@ A list of other files to include in the search.
  #@$@ -
  #@$@ I have multiple lines, for kicks.
  local -i -r E_GENERIC=1             #@$E_GENERIC If we need to exit and don't have a better ERROR choice, use this.
  local -i -r E_BAD_INPUT=10          #@$ Send when file specified in $1 is invalid or when -D is blank.
  local       _verbose=false          #@$_verbose Flag to decide if we should be chatty with our output.
  local       _temp='something'       #@$ A temp variable for our operations below.  (Note: Docker will record defaults.)
  local    -r _WIFE_IS_HOT=true       #@$ Pointless boolean flag, and it is now read only (and accurate).
  local -a    _index_array=( Zelda )  #@$ Index array with 1 element (element 0, value of Zelda)
  local -A    _assoc_array            #@$ Associative array (hash) to hold misc things as we read file.
  local -A    _new_hash=([k1]=hi)     #@$ Hash with a single key/value pair.
  local -A    _bigger_hash=([k-1]=hi [k-2]=there    #@$ Hash with a multiple key/value pair.
  local       _implied_array=(hi ho)  #@$ Docker will understand this is an array.
  local -a    _multi_array=(          #@$ Explicitly defined array that holds multiple values via lines.
                            one
                            two
                            'a b c'
                            'd "e" f'
                            'g " h " i'
                            "\\whee"
                            "\"no\" thanks"
                           )
  local -A    _multi_hash=(           #@$ Explicitly defined multiline hash.
                           [key1]=value1
                           ['key2']=value2
                           [key 3]=value3
                           [key 4]='value 4'
                           [key 5]="\"value\" 5"
                          )
  local -i    _i                      #@$ A counter variable, forced to be integer only.
  local       _opt
  local       _line                   #@$ Temporary variable for use in the read loop.
                                      #@$_line I have some extra detail about _line.
  local       _reference              #@$ Variable to hold the name of our nameref for assignment.
  local       _multiline='this
spans a few
    lines'
  final_value=''                      #@$ The final value to expose to the caller after we exit. (Note: Docker will flag 'top' scope as a result.)

  # Process options
  while true ; do
    core__getopts ":D:hR:v" opt 'help,verbose'
    case $? in 1) break ;; 2) return 1 ;; esac
    case "${_opt}" in
      D           ) #@opt_ Add bonus items to the index_array variable.
                    _index_array+=("${OPTARG}")
                    ;;
      h|help      ) #@opt_     Display an error and return non-zero if the user tries to use -h for this function.
                    echo 'No help exists for this function yet.' >&2
                    return ${E_GENERIC}
                    ;;
      'R'         ) _reference="${OPTARG}" ;; #@opt_ Sets the nameref for indirect assignment.
      v | verbose ) _verbose=true ;; #@opt_ Change the verbose flag to true so we can send more output to the caller.
      *           ) echo "Invalid option: -${OPTARG}" >&2 ; return ${E_GENERIC} ;;
    esac
  done
  #@opt_verbose  Federating this option so I can make it multiline.

  # Pre-flight Checks
  if ! core__tool_exists 'grep'    ; then echo 'The required tools to run this function were not found.' >&2 ; return ${E_GENERIC}   ; fi
  if [ ${#_index_array[@]} -lt 2 ] ; then echo "You must provide at least 1 Hyrule item (via -D option)" >&2 ; return ${E_BAD_INPUT} ; fi
  if [ ! -f ${1} ]                 ; then echo "Cannot find specified file to read: ${1}"                >&2 ; return ${E_BAD_INPUT} ; fi
  ${_verbose} && echo "Verbosity enabled.  Done processing variables and cleared pre-flight checks."

  # Main function logic
  _i=1
  while read _line ; do
    # If the line matches a Hyrule keyword, store it in associative array.  Use grep, simply so we can add it to core__tool_exists check above.
    for _temp in ${_index_array[@]} ; do
      if echo "${_line}" | grep -q -s "${_temp}" ; then assoc_array["${_i}"]="${_temp}" ; break ; fi
    done
    let _i++
  done <${1}

  # Print results & leave
  if [ ${#_assoc_array[@]} -eq 0 ] ; then echo "No matches found." ; return 0 ; fi
  for _temp in ${!assoc_array[@]}  ; do echo "Found match for keyword ${_assoc_array[${_temp}]} on line number ${_temp}." ; done
  return 0
}

