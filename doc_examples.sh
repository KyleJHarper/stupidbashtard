#!/bin/bash

#@Author    Kyle Harper
#@Date      2013.03.19
#@Version   0.1-beta
#@namespace doc_examples

#@Desc This is a series of examples to help demonstrate how code should be written in the stupidbashtard modules.  It is important to follow the style guidelines so that the self-documenting system will work.  Also, if this is ever put into an IDE, it will enable intelligent description popups.
#@Desc
#@Desc Using the same tag multiple times in succession is how you span lines.

#@Desc ^^ Empty lines mean nothing, but please avoid them for readability.


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
# You can specify a tag by using the comment and @ symbol combination:  #@SomeAttribute bla (see the #@Description above for a multi-line example).
#
# If you specify a tag at the top of the file, and do not override it in a function, the value provided at the top will be used.  This can be disabled via the document generation script switches.

# -- Variable Tags
# Variables are auto-detected by the local keyword.  If a variable tag (#@$) is used as a line-end comment, the text following will be used as a description.  You do not need to specify the variable name again (#$@var), it will be inferred from the declaration.  Can can treat variable tags like all others, if desired.  Their unique prefix (#@$) allows Docker to still group them all up, so where you place them in the function is irrelevant to Docker.

# -- GetOpt Tags
# These are specifically for the getopts function.  More details in the code-crawling below.  For brevity the syntax is: #@opt_ <description text>


# +-----------------+
# |  Code Crawling  |
# +-----------------+
# -- Crawling Basics
# Docker is designed to crawl code and scan for functions, variables, and certain structures. It uses the information it finds to generate a report about each function.  The information is then stored in a meta-file which is used to generate HTML files, plain text, IDE pop-ups, and so forth.

# -- Function Declarations
# You do NOT need to use special comments and tags.  You ONLY need to write the function using valid bash syntax.  The documentation tool will read everything after it.  The braces for the function simply need to comply with bash rules.  The opening is on the same line or directly after.  The closing must be on it's own line, or preceeded by a semicolon.  Again, whatever bash allows.

# -- Method Signature (Compulsory Parameters)
# Generally, options should be passed as switches (see getopts below) and combined with pre-flight logic for mandatory things.  If, however, your function expects things like $1, you need to let the document script know.  Do this by placing a variable tag (#@$1) INSIDE the function.
# Note: While its tag looks funny, you are welcome to use the $@ variable.  Its variable tag would be:  #@$@
# Note: Same with the $* variable:  #@$*

# -- Function Variables
# Functions act more like code macros than subroutines (ignoring async/fork calls for now).  While you can assign values to a variable inside a function and have it exposed to the caller, this is not always easy to detect.  Docker will, however, attempt to treat anything that looks like a variable assignment to a non-local defined variable (via the local keyword) as by-ref.  Variables declared with the local keyword are always scoped to the function, so by-ref/by-val is nonsensical.
#
# The above assumes you call a function synchronously.  Docker cannot know how the function will be called.  Please keep in mind that calling a function asynchronously (via fork, <command>&, etc) will always make a copy of all variables and prevent exposure to the caller (in other words: they're now by-val).

# -- Declare & Typeset
# Bash variables are generally untyped.  If you use the declare keyword, the document script will note this and update correctly.  Declare is preferred, but typeset is acceptable too.  Any valid declare type will be detected.  E.g. -r, -i, etc.  Docker will attempt to point out conflicts and warn about them, but don't rely on this.  (For example: declare -a -A some_var ).

# -- Error Codes
# Any variable starting with E_ will be assumed to be an Error exit-code and documented as such.  The value assigned will be included in docs.  Use variable tags to add descriptions: #@$E_SOME_ERR <description text>

# -- GetOpts
# Docker will scan for a while loop that uses getopts and a case statement.  It MUST be presented like so:
# while getopts '<string>' $some_var ; do   # You CAN use double quotes around <string> too.
#   case $some_var in                       # You CAN use any variable name you want.  $some_var is an example.
#     ...                                   # You CAN put the 'do' keyword on a separate line, if you want.
#   esac                                    # You CAN quote $some_var in your case statement if desired.
# done                                      # You CAN NOT make a description for \? (default) in the case statement.  This would be silly.
#
# When Docker sees the aforementioned, it will scan for getopt tags (#@opt_).  Typically you will place these tags inside each case item.  Docker will understand which case item the tag is in and record it appropriately.  You can also specify the name of the option if desired (e.g. #@opt_a).  This will override Docker's auto-detected case-item at run time... though it should always be the same, so why would you?
#
# For those who like making me work more...  If you specify the option name (e.g. #@opt_a), you can technically place the tag anywhere inside the function, though I recommend against this.  This would allow you to, for example, cram all your tags at the top of the function.  /shrugs
# TODO: Write a getopts_long function and allow docker to read it.  (2013.03.30 - Kyle)


# +------------+
# |  Examples  |
# +------------+
# The following examples are loosly ordered by complexity.


function doc_examples_01-DoNothing {
  #@Desc This function does nothing.  Just gives a description.  It inherits global tags from above
  #@Desc such as Author and Version.
  return 0
}


function doc_examples_02-OneLiner { return 0 ; }
#(proof you can do this and Docker will 'read' it, but you can't really specify any tags... so... ???)


doc_examples_03-AnnoyingDeclaration ()
{
  #@Desc  Proving that even annoying function declarations like this one will still get discovered.
  echo "Please use the unambiguous keyword: function.  It's for the kittens!"
  return 0
}


function doc_examples_99-ComplexZelda {
  #@Author Hank BoFrank
  #@Date   2013.03.04

  #@Desc   A complex function attempting to show most (or all) of the things/ways you can document stuff.
  #@Desc   We will attempt to read a file and list the line number and first occurence of a Zelda keyword.
  #@Desc
  #@Desc   This is a SILLY script that is untested; for demonstration purposes only.

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
  if [ ${#index_array[@]} -lt 2 ] ; then echo "You must provide at least 1 Hyrule item (via -D option)" >&2 ; return ${E_BAD_INPUT} ; fi
  if [ ! -f ${1} ]                ; then echo "Cannot find specified file to read: ${1}"                >&2 ; return ${E_BAD_INPUT} ; fi
  ${VERBOSE} && echo "Verbosity enabled.  Done processing variables and cleared pre-flight checks."

  # Main function logic
  i=1
  while read line ; do
    # If the line matches a Hyrule keyword, store it in associative array.
    for temp in ${index_array[@]} ; do
      if [[ "${line}" =~ ${temp} ]] ; then assoc_array["${i}"]="${temp}" ; break ; fi
    done
    let i++
  done <$1

  # Print results
  if [ ${#assoc_array[@]} -eq 0 ] ; then echo "No matches found." ; return 0 ; fi
  for temp in ${!assoc_array[@]} ; do echo "Found match for keyword ${assoc_array[${temp}]} on line number ${temp}." ; done
}

