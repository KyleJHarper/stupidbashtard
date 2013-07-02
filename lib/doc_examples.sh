#!/bin/bash

#@Author    Kyle Harper
#@Date      2013.03.19
#@Version   0.1-beta
#@Namespace doc_examples

#@Description This is a series of examples to help demonstrate how code should be written in the stupidbashtard modules.  It is important to follow the style guidelines so that the self-documenting system will work.  Also, if this is ever put into an IDE, it will enable intelligent description popups.
#@Description
#@Description Using the same tag multiple times in succession is how you span lines.

#@Description ^^ Empty lines mean nothing, but please avoid them for readability.


# +----------+
# |  Basics  |
# +----------+
# -- Synopsis
# Documentation is done through a combination of tags and code crawling.  In typical SBt (Stupid Bashtard) fashion, the documentation process is simplistic.

# -- Docker
# The tool used to generate documentation is called "Docker".  The end.


# +--------+
# |  Tags  |
# +--------+
# -- Tag Basics
# Tags are the indicator that the documentation building script ("Docker") should include info about something it normally wouldn't capture.  Docker will look for certain tags by default, such as author, date, namespace, et cetera.  Custom tags are valid as well, and will be placed in the docuemntation in the order they are found.  Built-ins (like the aforementioned) will always go in default placeholders.
#
# You can specify a tag by using the comment and @ symbol combination:  #@SomeAttribute bla (see the #@Desc above for a multi-line example).
#
# If you specify a tag at the top of the file, and do not override it in a function, the value provided at the top will be used.  This can be disabled via the document generation script switches.  The only tags that don't propagate are:
#   1. Desc

# -- Line-End Tags
# Bash supports line-end comments, therefore Docker does too.  The two benefits to line-end comments are 1) 'cleaner' code visually and 2) certain line-end tags infer information.  This is quite popular for variable tags, getopt tags, and similar because it allows you to leave off the tag name.  For example, if you wanted to document a variable named VERBOSE, you could do:
# VERBOSE=false  #@$VEBOSE <description text>   or...
# VERBOSE=false  #@$ <description text>

# -- Federated Tags
# If you prefer, you can put any tag anywhere inside a function.  For example, if you have a variable named VERBOSE, you can put a variable tag for it anywhere.  The advantage is the ability to federate the tag from the actual line of code.  The disadvantage is it ALWAYS requires a name.  Using our VERBOSE example, you could create a federated tag like so anywhere inside the function:
# #@$VERBOSE <description text>

# -- Variable Tags
# Variables are auto-detected by the local keyword.  If a variable tag (#@$) is used as a line-end comment, the text following will be used as a description.  You do not need to specify the variable name again (#$@var), it will be inferred from the declaration.  Can can treat variable tags like all others, if desired.  Their unique prefix (#@$) allows Docker to still group them all up, so where you place them in the function is irrelevant to Docker.
#
# Parameters should be passed as switches (see getopts below) and combined with pre-flight logic for mandatory things.  If, however, your function expects things like $1, you need to let the document script know.  Do this by placing a variable tag (#@$1) INSIDE the function.
# Note: While its tag looks funny, you are welcome to use the $@ variable.  Its variable tag would be:  #@$@
# Note: Same with the $* variable:  #@$*

# -- GetOpt Tags
# These are specifically for the getopts function.  More details in the code-crawling below.  For brevity the syntax is: #@opt_ <description text>


# +-----------------+
# |  Code Crawling  |
# +-----------------+
# -- Crawling Basics
# Docker is designed to crawl code and scan for functions, variables, and certain structures. It uses the information it finds to generate a report about each function.  The information is then stored in a meta-file which is used to generate HTML files, plain text, IDE pop-ups, and so forth.

# -- Function Declarations
# You do NOT need to use special comments and tags, though tags do help end-users understand your functions better later.  You ONLY need to write the function using valid bash syntax.  The documentation tool will read everything after it.  The braces for the function simply need to comply with bash rules.  The opening is on the same line or directly after.  The closing must be on it's own line, or preceeded by a semicolon.  Again, whatever bash allows.

# -- Parameters
# Functions act more like code macros than subroutines (ignoring async/fork calls for now).  You cannot create functions with parameters defined as by-value, reference, out, and so forth.  All parameters sent to a function are by-value.  While Bash supports indirect referencing, and we could use that to emulte some reference-style parameters... it would be extremely hacky and deviate from the globally accepted rule for linux command output: it should go to STDOUT.
#
# Parameters should be passed and accepted via getopts (read more about that below) or anticipated in $@.  If you need to set variables from the command output of a function, swallow it like you would any other command output:  myvar=$(myfunction -p somevalue)
#
# Given the aforementioned, Docker will not attempt to discern anything about parameter types; all are by-value.

# -- Variables & Scope
# Variables in a bash script are thrown into a global top-level scope, even those made inside of functions.  The only exceptions are when calling a function asynchronously (forking) or when the function declares a variable using the keyword: local.  Note that you cannot use the local keyword for variables inside your main process.  This means the more you cram into the 'main' of your shell script the more expensive your async function calls and forking will be, since all variables are copied to forked processes.
#
# As mentioned in the parameters section, you should never set a variable in a function for use outside the function (see thread safety).  If Docker identifies what looks like a variable being set or used which was NOT defined previously in the function with the local keyword, it will flag the function as non-thread safe.

# -- Thread Safety
# While bash doesn't support true threading, it can spawn sub-processes and emulate a similar behavior.  Docker will mark all functions thread-safe until it finds a reason not to.  The primary reason for marking a function as non-thread safe is if Docker finds variables in use that are no delcared with the local keyword.  It will also mark non-thread safe any function with a hard-coded path (why would you ever...)?
#
# Note:  Docker is a static-analysis tool.  It cannot begin to comprehend how you're using various functions.  A function marked thread-safe does not mean it'll magically protect you from race conditions and data corruption if you use the functions with shared resources (and no locking system).

# -- Returns
# You should:
#   ALWAYS include a return statement.
#   ALWAYS return 0 to indicate the function executed as anticipated.
#   ALWAYS return non-zero to indicate an error occurred.
#   ALWAYS send error messages to stderr.
#   NEVER  use the return value to pass data back to the caller.
#
# Docker will send a warning for any function without a return statement.  Every function should have at least 1, regardless.

# -- Declare & Typeset
# Bash variables are generally untyped.  If you use the declare keyword, the document script will note this and update correctly.  Declare is preferred, but typeset is acceptable too.  Any valid declare type will be detected.  E.g. -r, -i, etc.  Docker will attempt to point out conflicts and warn about them, but don't rely on this.  (For example: declare -a -A some_var ).

# -- Error Codes
# Any variable starting with E_ will be assumed to be an Error exit-code and documented as such.  The value assigned will be included in docs.  Use variable tags to add descriptions: #@$E_SOME_ERR <description text>

# -- GetOpts
# Docker will scan for a while loop that uses getopts and a case statement.  It MUST be presented like so:
# while getopts '<string>' $some_var ; do   # You CAN use double quotes around <string> too.
#   case $some_var in                       # You CAN use any variable name you want.  $some_var is an example.
#     ...                                   # You CAN put the 'do' keyword on a separate line, if you want.
#   esac                                    # You CAN quote $some_var or the case items in your case statement if desired.
# done                                      # You CAN NOT make a description for \? (default) in the case statement.  This would be silly.
#
# When Docker sees the aforementioned, it will scan for getopt tags (#@opt_).  Typically you will place these tags inside each case item.  Docker will understand which case item the tag is in and record it appropriately.  You can also specify the name of the option if desired (e.g. #@opt_a).  This will override Docker's auto-detected case-item at run time... though it should always be the same, so why would you?
#
# For those who like making me work more...  If you specify the option name (e.g. #@opt_a), you can technically place the tag anywhere inside the function, though I recommend against this.  This would allow you to, for example, cram all your tags at the top of the function.  /shrugs
# TODO: Write a getopts_long function and allow docker to read it.  (2013.03.30 - Kyle)

# -- Required Programs & Functions (SBt core_ToolExists)
# Docker is capable of reading the core_ToolExists function calls (from StupidBashtard).  If a function invokes core_ToolExists, all arguments listed afterward will be listed in the documentation as dependencies of the caller.


# +------------+
# |  Examples  |
# +------------+
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


#(proof you can do this and Docker will 'read' it, but you can't really specify any tags... so... why???)
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
  #@Description  This form of declaration is valid in bash too, and still annoying.  But Docker will accept it.
  return 0
}


# --
# -- Examples 10 - 19:  Variables (Typing & Scope)
# --
function doc_examples_10-SimpleLocalVariables {
  #@Description  This function will setup a few local variables.  That's it. (No tags).

  local VERBOSE=false
  local MAX_THINGS=20
  # Docker will note the above variables and their default values.

  local i
  # Docker will acknowledge the variable above, and that it does not have a default value.

  return 0
}


function doc_examples_11-MixedVariables {
  #@Description  This function establishes both local variables and a few non-locals.

  local VERBOSE=false
  ITEMS_FOUND
  # Docker will notice the missing local keyword and flag ITEMS_FOUND as a by-ref variable (when synchronous of course).

  return 0
}


function doc_examples_12-ThreadSafe {
  #@Description  Thread safety is possible in limited capacity.  Obviously this only applies when the function is called
  #@Description  asynchronously.  If all detected variables are declared with the local keyword, the function will be flagged
  #@Description  as thread safe.

  local START_TIME="$(date +%s)"
  local VERBOSE=false

  return 0
}


function doc_examples_13-NonThreadSafe {
  #@Description  This simple function will be flaged as non-thread safe because there is a variable defined without a local
  #@Description  keyword.  Ruh roh!

  local START_TIME="$(date +%s)"
  VERBOSE=false

  return 0
}


function doc_examples_14-TypedVariables {
  #@Description  This function will specify attributes about some variables by way of the keyword: declare.  It is also possible
  #@Descrition  to use the typeset keyword.

  # Docker will note the special attributes for the following variables
  declare -r local my_uuid="$(uuidgen)"  # Read only
  declare -i local i                     # integer
  declare -a local index_array           # Simple array
  declare -A local some_hash             # Associative array (hash)

  # Docker understands typeset too
  typeset -r local START_TIME="$(date +%s)"

  # Regular variables are untyped.
  local WOOHOO=true

  return 0
}


# --
# -- Examples 20 - 29:  Parameters
# --
function doc_examples_20-NumericParameters {
  #@Description  This function accepts $1 and $2 as parameters.

}


# --
# -- Examples 40 - 49:  Variable Tags
# --
function doc_examples_40-SimpleVariableTag {
  #@Description  A single, simple variable tag (happens to be a line-end tag too)

  local VERBOSE=false  #@$VERBOSE  Disable verbosity unless the user enables it with -v
  return 0
}


function doc_examples_41-LineEndVariableTags {
  #@Description  This function will show simple variable tags:  Line-End and federated.

  local VERBOSE=false  #@$VERBOSE  Disable verbosity unless the user enables it with -v
  local SUPPRESS=false #@$SUPPRESS Don't sent error messages if the user specifies -s

  # Line-end tags infer names, so Docker will transform the following variable tag (#@$) into  #@$QUIET
  local QUIET=false    #@$ Limit output of regular messages.  Will NOT disable error message output (see -s).

  return 0
}


function doc_examples_42-FederatedVariableTags {
  #@Description  This function shows how variable tags can be federated from the actual code declaring the variable; if desired.
  #@$VERBOSE  Disable verbosity unless the user enables it with -v
  #@$SUPPRESS Don't sent error messages if the user specifies -s
  #@$QUIET    Limit output of regular messages.  Will NOT disable error message output (see -s).

  local VERBOSE=false
  local SUPPRESS=false
  local QUIET=false

  return 0
}


function doc_examples_43-ParameterVariableTags {
  #@Description  In this function we will accept $1 and $2 parameters.  We will assign descriptions to them.
  #@Description  These must always be federated, as there is no declaration for them.

  #@$1  The file we will use for <whatever>.
  #@$2  The maximum results to find before leaving.

  declare -r    local INPUT_FILE="$1"  #@$  This will hold the contents of $1, mostly for readability later.
  delcare -r -i local MAX_RESULTS=$2   #@$  This will hold the value of $2, mostly for readability later.

  return 0
}


# --
# -- Examples 50 - 59:  GetOpts Tags
# --
function doc_examples_50-GetOptsTags {
  #@Description  This function will show a few ways to provide comments for the getopts loop.

  local my_opt
  local AWESOME_MODE=false
  local BOOK_NAME='Plumbing Guide to Angling'
  while getopts 'ab:' my_opt ; do
    case "${my_opt}" in
      'a' ) #@opt_ When specified, turns on AWESOME mode... yea.
            AWESOME_MODE=true     ;;
      'b' ) #@opt_ Override the default book name to use.
            BOOK_NAME="${OPTARG}" ;;
      *   ) echo "Invalid option -${OPTARG}" >&2
            return 1
            ;;
    esac
  done

  return 0
}


function doc_examples_51-LineEndGetOptsTags {
  #@Description  This function will show a few ways to provide comments for the getopts loop.

  local my_opt
  local AWESOME_MODE=false
  local BOOK_NAME='Plumbing Guide to Angling'
  while getopts 'ab:' my_opt ; do
    case "${my_opt}" in
      'a' ) AWESOME_MODE=true     ;;  #@opt_ When specified, turns on AWESOME mode... yea.
      'b' ) BOOK_NAME="${OPTARG}" ;;  #@opt_ Override the default book name to use.
      *   ) echo "Invalid option -${OPTARG}" >&2
            return 1
            ;;
    esac
  done

  return 0
}


function doc_examples_52-FederatedGetOptsTags {
  #@Description  This function will show a few ways to provide comments for the getopts loop.
  #@opt_a When specified, turns on AWESOME mode... yea.
  #@opt_b Override the default book name to use.

  local my_opt
  local AWESOME_MODE=false
  local BOOK_NAME='Plumbing Guide to Angling'
  while getopts 'ab:' my_opt ; do
    case "${my_opt}" in
      'a' ) AWESOME_MODE=true     ;;
      'b' ) BOOK_NAME="${OPTARG}" ;;
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
function doc_examples_99-ComplexZelda {
  #@Author Hank BoFrank
  #@Date   2013.03.04

  #@Description   A complex function attempting to show most (or all) of the things/ways you can document stuff.
  #@Description   We will attempt to read a file and list the line number and first occurence of a Zelda keyword.
  #@Description
  #@Description   This is a SILLY script that is untested; for demonstration purposes only.

  # Variables
  #@$1 The first option (after shifting from getopts) will be a file name to operate on.
  local E_GENERIC=1                      #@$E_GENERIC If we need to exit and don't have a better ERROR choice, use this.
  local E_BAD_INPUT=10                   #@$ Send when file specified in $1 is invalid or when -D is blank.
  local VERBOSE=false                    #@$VERBOSE Flag to decide if we should be chatty with our output.
  local temp='something'                 #@$ A temp variable for our operations below.  (Note: Docker will record defaults.)
  declare -r local wife_is_hot=true      #@$ Pointless boolean flag, and it is now read only (and accurate).
  declare -a local index_array=( Zelda ) #@$ Index array with 1 element (element 0, value of Zelda)
  declare -A local assoc_array           #@$ Associative array (hash) to hold misc things as we read file.
  delcare -i local i                     #@$ A counter variable, forced to be integer only.
  final_value=''                         #@$ The final value to expose to the caller after we exit. (Note: Docker will flag as by-ref.)

  # Process options
  while getopts ":D:hv" opt; do
    case $opt in
      D  ) #@opt_ Add bonus items to the index_array variable.
           #@opt_ Note, this option can be specified multiple times, so always concatenate the array.
           index_array+=("${OPTARG}")
           ;;
      h  ) #@opt_ Display an error and return non-zero if the user tries to use -h for this function.
           echo 'No help exists for this function yet.' >&2
           return ${E_GENERIC}
           ;;
      v  ) VERBOSE=true ;; #@opt_ Change the verbose flag to true so we can send more output to the caller.
      \? ) echo "Invalid option: -$OPTARG" >&2 ; return ${E_GENERIC} ;;
    esac
  done

  # Pre-flight Checks
  if ! core_ToolExists 'grep'     ; then echo 'The required tools to run this function were not found.' >&2 ; return ${E_GENERIC}   ; fi
  if [ ${#index_array[@]} -lt 2 ] ; then echo "You must provide at least 1 Hyrule item (via -D option)" >&2 ; return ${E_BAD_INPUT} ; fi
  if [ ! -f ${1} ]                ; then echo "Cannot find specified file to read: ${1}"                >&2 ; return ${E_BAD_INPUT} ; fi
  ${VERBOSE} && echo "Verbosity enabled.  Done processing variables and cleared pre-flight checks."

  # Main function logic
  i=1
  while read line ; do
    # If the line matches a Hyrule keyword, store it in associative array.  Use grep, simply so we can add it to core_ToolExists check above.
    for temp in ${index_array[@]} ; do
      if echo "${line}" | grep -q -s ${temp} ; then assoc_array["${i}"]="${temp}" ; break ; fi
    done
    let i++
  done <$1

  # Print results & leave
  if [ ${#assoc_array[@]} -eq 0 ] ; then echo "No matches found." ; return 0 ; fi
  for temp in ${!assoc_array[@]} ; do echo "Found match for keyword ${assoc_array[${temp}]} on line number ${temp}." ; done
  return 0
}
