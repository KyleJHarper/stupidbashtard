#!/bin/bash

#@Author   : Kyle Harper
#@Date     : 2013.03.19
#@Version  : 0.1-beta
#@namespace: doc_examples

#@Desc: This is an example template to help demonstrate how code should be written in the stupidbashtard modules.  It is important to follow the style guidelines so that the self-documenting system will work.  Also, if this is ever put into an IDE, it will enable intelligent description popups.
#@Desc:
#@Desc: Using the same tag multiple times in succession is how you span lines.

#@Desc: ^^ Empty lines mean nothing, but please avoid them for readability. A blank line(without the #@Description tag) will not put a blank line in the automated documentation generation.


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
# done
#
# When Docker sees the aforementioned, it will scan for getopt tags (#@opt_).  Typically you will place these tags inside each case item.  Docker will understand which case item the tag is in and record it appropriately.  You can also specify the name of the option if desired (e.g. #@opt_a).  This will override Docker's auto-detected case-item at run time... though it should always be the same, so why would you?
#
# For those who like making me work more...  If you specify the option name (e.g. #@opt_a), you can technically place the tag anywhere inside the function, though I recommend against this.  This would allow you to, for example, cram all your tags at the top of the function.  /shrugs
# TODO: Write a getopts_long function and allow docker to read it.  (2013.03.30 - Kyle)


# +------------+
# |  Examples  |
# +------------+
# The following examples are loosly ordered by complexity.




function doc_examples_Function99 {
  #@Author: Hank BoFrank
  #@Date  : 2013.03.04
  #@$1 Description for some_variable_name.  Do not continue on a new line, it won't work.
  local E_SOME_ERROR_CONDITION=10        ##@$ Error code when some error happens
  local E_ANOTHER_BADDY=82               ##@$ If another bad thing happens, we send this code.
  local temp='something'                 ##@$ A temp thing to hold stuff.  The value assigned will show up in docs.
  declare -r local wife_is_hot=true      ##@$ This boolean is now read only (and accurate).
  declare -a local index_array=( Zelda ) ##@$ Made an index array with 1 element (element 0, value of Zelda)
  declare -A local assoc_array           ##@$ Created an associative array.  Now it has a description.
  delcare -i local i                     ##@$ A counter variable, forced to be integer only.  No default value.
  naughtiness='boo'                      ##@$ This will NOT show up in docs, at all, because it lacks the local keyword.

  while getopts ":acD:vw:" opt; do
    case $opt in
      a  ) bla ;;
      c  ) bla ;;
      D  ) bla ;;
      v  ) bla ;;
      w  ) bla ;;
      \? ) echo "Invalid option: -$OPTARG" >&2  ;;
    esac
  done
}

