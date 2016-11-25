#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


#@Author    Kyle Harper
#@Date      2013.03.19
#@Version   0.1-beta
#@Namespace doc_examples
#@rawr whee

#@Description This is a series of examples to help demonstrate how code should be written in the stupidbashtard modules.  It is important to follow the style guidelines so that the self-documenting system will work.  Also, if this is ever put into an IDE, it will enable intelligent description popups.
#@Description -
#@Description Using the same tag multiple times in succession is how you span lines.  A single hyphen means "blank" line; like above.

#@Description ^^ Empty lines mean nothing.


# +----------+
# |  Basics  |
# +----------+
# -- Synopsis
# Documentation is done through a combination of tags and code crawling.  In typical SBt (Stupid Bashtard) fashion, the documentation process is simplistic.

# -- Shocker
# The tool used to generate documentation is called "Shocker".  The end.


# +--------+
# |  Tags  |
# +--------+
# -- Tag Basics
# Tags are the indicator that the documentation building script ("Shocker") should include info about something it normally wouldn't capture.  Shocker will look for certain tags by default, such as author, date, namespace, et cetera.  Custom tags are valid as well (like rawr above).
#
# You can specify a tag by using the comment and @ symbol combination:  #@SomeAttribute bla (see the #@Description above for a multi-line example).
#
# If you specify a tag at the top of the file (outisde a function), and do not override it in a function, the value provided at the top will be used.  This can be disabled via the document generation script switches.  The only tags that don't propagate are:
#   1. Description

# -- Line-End Tags
# Bash supports line-end comments, therefore Shocker does too.  The two benefits to line-end comments are 1) 'cleaner' code visually and 2) certain line-end tags infer information.  This is quite popular for variable tags, getopt tags, and similar because it allows you to leave off the tag name.  For example, if you wanted to document a variable named VERBOSE, you could do:
# VERBOSE=false  #@$VEBOSE <description text>   or...
# VERBOSE=false  #@$ <description text>

# -- Federated Tags
# If you prefer, you can put any tag anywhere inside a function.  For example, if you have a variable named VERBOSE, you can put a variable tag for it anywhere.  The advantage is the ability to federate the tag from the actual line of code.  The disadvantage is it ALWAYS requires a name.  Using our VERBOSE example, you could create a federated tag like so anywhere inside the function:
# #@$VERBOSE <description text>

# -- Variable Tags
# Variables are auto-detected by either the delcare/typeset/local keyword and/or the assignment operator (=).  If a variable tag (#@$) is used as a line-end comment, the text following will be used as a description.  You do not need to specify the variable name again (#@$var), it will be inferred from the declaration.  Shocker can treat variable tags like all others, if desired.  Their unique prefix (#@$) allows Shocker to still group them all up, so where you place them in the function is irrelevant to Shocker.
#
# Parameters should usually be passed as switches (see getopts below) and combined with pre-flight logic for mandatory things.  If, however, your function expects things like $1, you need to let Shocker know.  Do this by placing a variable tag (#@$1) INSIDE the function.  These are always, of course, federated.
# Note: While its tag looks funny, you are welcome to use the $@ variable.  Its variable tag would be:  #@$@
# Note: Same with the $* variable:  #@$*

# -- GetOpt Tags
# These are specifically for the getopts function.  More details in the code-crawling section below.  For brevity the syntax is: #@opt_ <description text>


# +-----------------+
# |  Code Crawling  |
# +-----------------+
# -- Crawling Basics
# Shocker is designed to crawl code and scan for functions, variables, and certain structures. It uses the information it finds to generate a report about each function.  The information is then stored in the meta-file along with tags (see above).
#
# Note that Shocker scans line-by-line, not by character or word.  If you follow simple, clean coding standards it's good at what it does.

# -- Function Declarations
# You do NOT need to use special comments and tags declare a function.  You ONLY need to write the function using valid bash syntax.  The documentation tool will read everything after it.  The braces for the function simply need to comply with bash rules.  The opening is on the same line or directly after.  The closing must be on it's own line, or preceeded by a semicolon.  Again, whatever bash allows.
#
# A few things to remember:
#   1. Bash treats functions as code marcos.  A function is fully capable of affecting parent-scope variables.
#   2. Anonymous functions (lambdas) are not supported in Bash.
#   3. Despite being able to declare a function inside a function, there's no actual scoping or encapsulation.  Honestly, Bash should just fail; declaring a function inside a function is stupid.
#   4. Functions have no return type besides integer (specifically, 0-255 usually).  You can't return a string, array, etc.  You shouldn't even be returning an integer via the function's return value.
#   ...a lot more sadness :(
#
# Please note, Shocker does not support function declarations inside other functions.  This is almost never useful and should be avoided.

# -- Parameters
# Parameters should be passed and accepted via getopts (read more about that below) or anticipated in $@.  If you need to set variables from the command output of a function, swallow it like you would any other command output.
#
# Functions act more like code macros than subroutines (ignoring async/fork calls for now).  You cannot create functions with parameters defined as by-value, reference, out, and so forth.  All parameters sent to a function are by-value.  While Bash supports indirect referencing, and we could use that with funky naming conventions to emulate some reference-style parameters... it would be extremely hacky and deviate from the globally accepted rule for GNU/linux command output: it should go to STDOUT.
#
# That said:  By-Ref can be helpful at times.  For example, if we have a function that sorts an array it's easier (and faster) to simply return a variable with the array contents rather than swallowing the function output from a subshell.  StupidBashTard functions will always reserve the getopts option '-R' (capital R, not lowercase) for this purpose.  Functions which support this feature will use indirect referencing to assign the output to the variable name passed as an arg to the '-R' option.  As an added bonus, Shocker will flag any function with a '-R' option as 'allow_indirect_output: true'. (You're welcome.)

# -- Variables & Scope
# Variables in a bash script are thrown into a global top-level scope, even those made inside of functions.  The only exceptions are when calling a function asynchronously (forking) or when the function declares a variable using one of the keywords: declare, typeset, or local.  Note that you cannot use the local keyword for variables inside your main process.  This means the more you cram into the 'main' of your shell script the more expensive your async function calls and forking will be, since all variables are copied to forked processes.
#
# As mentioned in the parameters section, you should never set a variable in a function for use outside the function (see thread safety).  If Shocker identifies a variable being set which was NOT defined earlier in the function with a local/declare/typeset keyword, it will flag the function as non-thread safe.

# -- Thread Safety
# While bash doesn't support true threading, it can spawn (asynchronous) sub-processes and emulate a similar watered-down behavior.  Shocker will mark all functions thread-safe until it finds a reason not to.  The primary reason for marking a function as non-thread safe is if Shocker finds non-local variables.
#
# This is, at best, a generic indicator that a thread isn't trying to assign values to a variable declared in another scope.
#
# Note:  Shocker is a static-analysis tool.  It cannot begin to comprehend how you're using various functions.  A function marked thread-safe does not mean it'll magically protect you from race conditions and data corruption if you use the functions with shared resources or in a non-thread safe manner.  (You have been warned.)

# -- Returns
# You should:
#   ALWAYS include a return statement.
#   ALWAYS return 0 to indicate the function executed as anticipated.
#   ALWAYS return non-zero to indicate an error occurred.
#   ALWAYS send error messages to stderr.
#   ALWAYS practice 'else-less' programming techniques.  *See Else-Less Note below
#   NEVER  use the return value to pass data back to the caller.
#
# *Else-Less Note: Else blocks are almost always unnecessary and result in nastier code.  Trapped errors and returns are often crammed into these and generate edge-cases where the wrong return is sent or program flow continues where it shouldn't.
#
# Shocker will NOT send a warning for any function without a 'return #' statement at the end.  However, functions should have a default return status if the end of the function is ever reached.  Conditional blocks may contain returns as well; but no matter what you should always have a default return value.

# -- Declare, Local, & Typeset
# Bash variables are generally untyped.  If you use the declare keyword, the document script will note this and update correctly.  The keywords 'declare' or 'local' are preferred, but 'typeset' is acceptable too.  Any valid declare type will be detected.  E.g. -r, -i, etc.  Shocker will attempt to point out conflicts and warn about them, but don't rely on this.  (For example: declare -a -A some_var ).

# -- Exit Codes
# Any variable starting with E_ will be assumed to be an exit-code and documented as such.  The value assigned will be included in docs.  Use variable tags to add descriptions: #@$E_SOME_ERR <description text>

# -- GetOpts
# Shocker will scan for a while loop that uses getopts (or core__getopts) and a case statement.  It MUST be presented like so:
#   while getopts '<chars>' some_var ; do     # You CAN use double quotes around <chars> too.
#     case $some_var in                       # You CAN use any variable name you want.  some_var is an example.
#       ...                                   # You CAN put the 'do' keyword on a separate line, if you want.
#     esac                                    # You CAN NOT make a description for \? or * (wildcards) in the case statement.  This would be silly.
#   done
#
#   [OR]
#
#   while true ; do                           # This second form is useful with core__getopts because core__getopts differentiates between "no more options" (code 1) and "error processing option" (code 2).
#     core__getopts '<chars>' some_var
#     case $? in  2 ) core__log_error "Getopts failed.  Aborting function." ; return 1 ;;  1 ) break ;; esac
#     case $some_var in
#       ...
#     esac
#   done
#
# When Shocker sees the aforementioned, it will scan for getopt tags (#@opt_).  Typically you will place these tags inside each case item.  Shocker will understand which case item the tag is in and record it appropriately.  You can also specify the name of the option if desired (e.g. #@opt_a).  This will override Shocker's auto-detected case-item at run time... though it should always be the same, so why would you?
#
# StupidBashTard supports long options via the core__getopts function.  It is fully backward compatible with the built-in getopts.  It takes a 3rd parameter, a comma-separated list of long option names.  The above example with long opts would be as such:
#   while core__getopts '<chars>' some_var '<long_opts>' ; do     # You CAN use double quotes around <chars> or long_opts too.

# -- Required Programs & Functions (SBT core__tool_exists)
# Shocker is capable of reading the core__tool_exists function calls (from StupidBashtard).  If a function invokes core__tool_exists, all arguments listed afterward will be listed in the documentation as dependencies of the caller.


# +------------+
# |  Examples  |
# +------------+
# NOTE!!!  These violate the normal naming convention for SBT functions.  Just FYI.
# 01 - 09:  Function Declarations
# 10 - 19:  Variables (Typing & Scope)
# 20 - 29:  Parameters
# 30 - 39:  (reserved)
# 40 - 49:  Variable Tags
# 50 - 59:  GetOpts Tags
# 60 - 69:  (reserved)
# 70 - 79:  (reserved)
# 80 - 89:  (reserved)
# 90 - 99:  Complex Examples

# --
# -- Examples 01 - 09:  Function Declarations
# --
function doc_examples_01-DoNothing {
  #@Description This function does nothing.  Just gives a description.  It inherits global tags from above
  #@Description such as Author and Version.
  return 0
}


#(proof you can do this and Shocker will 'read' it, but you can't really specify any tags... so... why???)
function doc_examples_02-OneLiner { return 0 ; }


doc_examples_03-AnnoyingDeclaration ()
{
  #@Description  Proving that even annoying function declarations like this one will still get discovered.
  echo "Please use the unambiguous keyword: function.  It's for the kittens!"
  return 0
}


#(proof this works too)
doc_examples_04-AnnoyingDeclarationOneLiner () { return 0 ; }


function doc_examples_05-MixedDeclaration () {
  #@Description  This form of declaration is valid in bash too, and still annoying.  But Shocker will accept it.
  return 0
}


# --
# -- Examples 10 - 19:  Variables (Typing & Scope)
# --
function doc_examples_10-SimpleLocalVariables {
  #@Description  This function will setup a few local variables.  That's it. (No tags).

  local _verbose=false
  local _max_things=20
  # Shocker will note the above variables and their default values.

  local _i
  # Shocker will acknowledge the variable above, and that it does not have a default value.

  return 0
}


function doc_examples_11-MixedVariables {
  #@Description  This function establishes both local variables and a few non-locals.

  local _verbose=false
  items_found=13
  # Shocker will notice the missing local keyword and flag ITEMS_FOUND as a by-ref variable (when synchronous of course).

  return 0
}


function doc_examples_12-ThreadSafe {
  #@Description  Thread safety is possible in limited capacity.  Obviously this only applies when the function is called
  #@Description  asynchronously.  If all detected variables are declared with the local keyword, the function will be flagged
  #@Description  as thread safe.

  local _start_time="$(date +%s)"
  local _verbose=false

  return 0
}


function doc_examples_13-NonThreadSafe {
  #@Description  This simple function will be flaged as non-thread safe because there is a variable defined without a local
  #@Description  keyword.  Ruh roh!

  local _start_time="$(date +%s)"
  verbose=false

  return 0
}


function doc_examples_14-TypedVariables {
  #@Description  This function will specify attributes about some variables by way of the keyword: declare.  It is also possible
  #@Description  to use the typeset or local keywords.

  # Shocker will note the special attributes for the following variables
  local    -r MY_UUID="$(uuidgen)"  # Read only
  local -i    _i                    # integer
  local -a    _index_array          # Simple array
  local -A    _some_hash            # Associative array (hash)

  # Shocker understands typeset too
  typeset -r _START_TIME="$(date +%s)"

  # Regular variables are untyped.
  local _woohoo=true

  return 0
}


# --
# -- Examples 20 - 29:  Parameters
# --
function doc_examples_20-NumericParameters {
  #@Description  This function accepts $1 and $2 as parameters.
  #@$1           Parameter 1 is for bla.
  #@$2           Parameter 2 is for something else.

}


# --
# -- Examples 40 - 49:  Variable Tags
# --
function doc_examples_40-SimpleVariableTag {
  #@Description  A single, simple variable tag (happens to be a line-end tag too)

  local _verbose=false  #@$_verbose  Disable verbosity unless the user enables it with -v
  return 0
}


function doc_examples_41-LineEndVariableTags {
  #@Description  This function will show simple variable tags:  Line-End and federated.

  local _verbose=false  #@$_verbose  Disable verbosity unless the user enables it with -v
  local _suppress=false #@$_suppress Don't sent error messages if the user specifies -s

  # Line-end tags infer names, so Shocker will transform the following variable tag (#@$) into  #@$QUIET
  local _quiet=false    #@$ Limit output of regular messages.  Will NOT disable error message output (see -s).

  return 0
}


function doc_examples_42-FederatedVariableTags {
  #@Description  This function shows how variable tags can be federated from the actual code declaring the variable; if desired.
  #@$_verbose  Disable verbosity unless the user enables it with -v
  #@$_suppress Don't sent error messages if the user specifies -s
  #@$_quiet    Limit output of regular messages.  Will NOT disable error message output (see -s).

  local _verbose=false
  local _suppress=false
  local _quiet=false

  return 0
}


function doc_examples_43-ParameterVariableTags {
  #@Description  In this function we will accept $1 and $2 parameters.  We will assign descriptions to them.
  #@Description  These must always be federated, as there is no declaration for them.

  #@$1  The file we will use for <whatever>.
  #@$2  The maximum results to find before leaving.

  local -r    _INPUT_FILE="$1"  #@$  This will hold the contents of $1, mostly for readability later.
  local -r -i _MAX_RESULTS=$2   #@$  This will hold the value of $2, mostly for readability later.

  return 0
}


# --
# -- Examples 50 - 59:  GetOpts Tags
# --
function doc_examples_50-GetOptsTags {
  #@Description  This function will show a few ways to provide comments for the getopts loop.
  #@Usage        doc_examples_50-GetOptsTags <-b 'Book Name'> [-a]

  local _my_opt
  local _awesome_mode=false
  local _book_name='Plumbing Guide to Angling'
  while getopts 'ab:' _my_opt ; do
    case "${_my_opt}" in
      'a' ) #@opt_ When specified, turns on AWESOME mode... yea.
            _awesome_mode=true     ;;
      'b' ) #@opt_ Override the default book name to use.
            _book_name="${OPTARG}" ;;
      *   ) echo "Invalid option -${OPTARG}" >&2
            return 1
            ;;
    esac
  done

  return 0
}


function doc_examples_51-LineEndGetOptsTags {
  #@Description  This function will show a few ways to provide comments for the getopts loop.
  #@Usage        doc_examples_51-LineEndGetOptsTags <-b 'Book Name'> [-a]

  local _my_opt
  local _awesome_mode=false
  local _book_name='Plumbing Guide to Angling'
  while getopts 'ab:' _my_opt ; do
    case "${_my_opt}" in
      'a' ) _awesome_mode=true     ;;  #@opt_ When specified, turns on AWESOME mode... yea.
      'b' ) _book_name="${OPTARG}" ;;  #@opt_ Override the default book name to use.
      *   ) echo "Invalid option -${OPTARG}" >&2
            return 1
            ;;
    esac
  done

  return 0
}


function doc_examples_52-LongOptsWithLineEndComments {
  #@Description  Long options and some line-end comments.
  #@Usage        doc_examples_52-LongOptsWithLineEndComments <-b --book 'Book Name'> [-a --awesome]

  local _my_opt
  local _awesome_mode=false
  local _book_name='Plumbing Guide to Angling'
  while getopts 'ab:' my_opt 'awesome,book:' ; do
    case "${_my_opt}" in
      'a'       ) _awesome_mode=true     ;;  #@opt_ When specified, turns on AWESOME mode... yea.
      'b'       ) _book_name="${OPTARG}" ;;  #@opt_ Override the default book name to use.
      'awesome' ) _awesome_mode=true     ;;  #@opt_ When specified, turns on AWESOME mode... yea.
      'book'    ) _book_name="${OPTARG}" ;;  #@opt_ Override the default book name to use.
      *         ) echo "Invalid option -${OPTARG}" >&2
                  return 1
                  ;;
    esac
  done

  return 0
}


function doc_examples_53-FederatedGetOptsTags {
  #@Description  This function will show a few ways to provide comments for the getopts loop.
  #@Usage        doc_examples_53-FederatedGetOptsTags <-b 'Book Name'> [-a]
  #@opt_a When specified, turns on AWESOME mode... yea.
  #@opt_b Override the default book name to use.

  local _my_opt
  local _awesome_mode=false
  local _book_name='Plumbing Guide to Angling'
  while getopts 'ab:' _my_opt ; do
    case "${_my_opt}" in
      'a' ) _awesome_mode=true     ;;
      'b' ) _book_name="${OPTARG}" ;;
      *   ) echo "Invalid option -${OPTARG}" >&2
            return 1
            ;;
    esac
  done

  return 0
}


# --
# -- Examples 90 - 99:  Complex Examples
# --
function doc_examples_98-ComplexZelda {
  #@Author Hank BoFrank
  #@Date   2013.03.04

  #@Description   A complex function attempting to show most (or all) of the things/ways you can document stuff.
  #@Description   We will attempt to read a file and list the line number and first occurence of a Zelda keyword.
  #@Description   -
  #@Description   This is a SILLY script that is untested; for demonstration purposes only.
  #@Usage         doc_examples_98-ComplexZelda [-D 'dun dun dun'] [-h] [-v]

  # Variables
  #@$1 The first option (after shifting from getopts) will be a file name to operate on.
  local       E_GENERIC=1             #@$E_GENERIC If we need to exit and don't have a better ERROR choice, use this.
  local       E_BAD_INPUT=10          #@$ Send when file specified in $1 is invalid or when -D is blank.
  local       _verbose=false          #@$_verbose Flag to decide if we should be chatty with our output.
  local       _temp='something'       #@$ A temp variable for our operations below.  (Note: Shocker will record defaults.)
  local    -r _WIFE_IS_HOT=true       #@$ Pointless boolean flag, and it is now read only (and accurate).
  local -a    _index_array=( Zelda )  #@$ Index array with 1 element (element 0, value of Zelda)
  local -A    _assoc_array            #@$ Associative array (hash) to hold misc things as we read file.
  local -i    _i                      #@$ A counter variable, forced to be integer only.
  local       _opt                    #@$ Localize opt for getopts processing.
  local       _line                   #@$ Local temp variable for read loop.
  final_value=''                      #@$ The final value to expose to the caller after we exit. (Note: Shocker will flag as by-ref.)

  # Process options
  while getopts ":D:hv" _opt; do
    case "${_opt}" in
      D  ) #@opt_ Add bonus items to the index_array variable.
           #@opt_ Note, this option can be specified multiple times, so always concatenate the array.
           _index_array+=("${OPTARG}")
           ;;
      h  ) #@opt_ Display an error and return non-zero if the user tries to use -h for this function.
           echo 'No help exists for this function yet.' >&2
           return ${E_GENERIC}
           ;;
      v  ) _verbose=true ;; #@opt_ Change the verbose flag to true so we can send more output to the caller.
      *  ) echo "Invalid option: -${OPTARG}" >&2 ; return ${E_GENERIC} ;;
    esac
  done

  # Pre-flight Checks
  if ! core__tool_exists 'grep'    ; then echo 'The required tools to run this function were not found.' >&2 ; return ${E_GENERIC}   ; fi
  if [ ${#_index_array[@]} -lt 2 ] ; then echo "You must provide at least 1 Hyrule item (via -D option)" >&2 ; return ${E_BAD_INPUT} ; fi
  if [ ! -f "${1}" ]               ; then echo "Cannot find specified file to read: ${1}"                >&2 ; return ${E_BAD_INPUT} ; fi
  ${_verbose} && echo "Verbosity enabled.  Done processing variables and cleared pre-flight checks."

  # Main function logic
  _i=1
  while read _line ; do
    # If the line matches a Hyrule keyword, store it in associative array.  Use grep, simply so we can add it to core__tool_exists check above.
    for _temp in ${_index_array[@]} ; do
      if echo "${_line}" | grep -q -s "${_temp}" ; then _assoc_array["${_i}"]="${_temp}" ; break ; fi
    done
    let i++
  done <"${1}"

  # Print results & leave
  if [ ${#_assoc_array[@]} -eq 0 ] ; then echo "No matches found." ; return 0 ; fi
  for _temp in ${!_assoc_array[@]} ; do echo "Found match for keyword ${_assoc_array[${_temp}]} on line number ${_temp}." ; done
  return 0
}


function doc_examples_99-ComplexZeldaLongOpts {
  #@Author Hank BoFrank
  #@Date   2013.03.04

  #@Description   A complex function attempting to show most (or all) of the things/ways you can document stuff.
  #@Description   We will attempt to read a file and list the line number and first occurence of a Zelda keyword.
  #@Description   -
  #@Description   This is a SILLY script that is untested; for demonstration purposes only.
  #@Usage         doc_examples_99-ComplexZeldaLongOpts [-D 'dun dun dun'] [-h --help] [-v --verbose]

  # Variables
  #@$1 The first option (after shifting from getopts) will be a file name to operate on.
  local    -r E_GENERIC=1             #@$E_GENERIC If we need to exit and don't have a better ERROR choice, use this.
  local    -r E_BAD_INPUT=10          #@$ Send when file specified in $1 is invalid or when -D is blank.
  local       _verbose=false          #@$_verbose Flag to decide if we should be chatty with our output.
  local       _temp='something'       #@$ A temp variable for our operations below.  (Note: Shocker will record defaults.)
  local    -r _WIFE_IS_HOT=true       #@$ Pointless boolean flag, and it is now read only (and accurate).
  local -a    _index_array=( Zelda )  #@$ Index array with 1 element (element 0, value of Zelda)
  local -A    _assoc_array            #@$ Associative array (hash) to hold misc things as we read file.
  local -i    _i                      #@$ A counter variable, forced to be integer only.
  local       _opt                    #@$ Localize opt for getopts processing.
  local       _line                   #@$ Local temp variable for read loop.
  final_value=''                      #@$ The final value to expose to the caller after we exit. (Note: Shocker will flag as by-ref.)

  # Process options
  while core__getopts ":D:hv" _opt 'help,verbose'; do
    case "${_opt}" in
      D           ) #@opt_  Add bonus items to the index_array variable.
                    _index_array+=("${OPTARG}")
                    ;;
      h|help      ) #@opt_  Display an error and return non-zero if the user tries to use -h for this function.
                    echo 'No help exists for this function yet.' >&2
                    return ${E_GENERIC}
                    ;;
      v | verbose ) _verbose=true ;; #@opt_  Change the verbose flag to true so we can send more output to the caller.
      *           ) echo "Invalid option: -${OPTARG}" >&2 ; return ${E_GENERIC} ;;
    esac
  done

  # Pre-flight Checks
  if ! core__tool_exists 'grep'    ; then echo 'The required tools to run this function were not found.' >&2 ; return ${E_GENERIC}   ; fi
  if [ ${#_index_array[@]} -lt 2 ] ; then echo "You must provide at least 1 Hyrule item (via -D option)" >&2 ; return ${E_BAD_INPUT} ; fi
  if [ ! -f "${1}" ]               ; then echo "Cannot find specified file to read: ${1}"                >&2 ; return ${E_BAD_INPUT} ; fi
  ${_verbose} && echo "Verbosity enabled.  Done processing variables and cleared pre-flight checks."

  # Main function logic
  _i=1
  while read _line ; do
    # If the line matches a Hyrule keyword, store it in associative array.  Use grep, simply so we can add it to core__tool_exists check above.
    for _temp in ${_index_array[@]} ; do
      if echo "${_line}" | grep -q -s "${_temp}" ; then _assoc_array["${_i}"]="${_temp}" ; break ; fi
    done
    let _i++
  done <"${1}"

  # Print results & leave
  if [ ${#_assoc_array[@]} -eq 0 ] ; then echo "No matches found." ; return 0 ; fi
  for _temp in ${!_assoc_array[@]} ; do echo "Found match for keyword ${_assoc_array[${_temp}]} on line number ${_temp}." ; done
  return 0
}
