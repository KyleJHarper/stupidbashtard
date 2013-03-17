#!/bin/bash

##@Author   : Kyle Harper
##@Date     : 2013.03.04
##@Version  : 0.1-beta
##@namespace: examples_template
##
##@Desc: This is an example template to help demonstrate how code should be written
##@Desc: in the stupidbashtard modules.  It is important to follow the style guidelines
##@Desc: so that the self-documenting system will work.  Also, if this is ever put
##@Desc: into an IDE, it will enable intelligent description popups.
##@Desc:
##@Desc: This is how you skip a line.
##@Desc:
##@Desc: Using the same tag multiple times in succession is how you span lines.

##@Desc: ^^ Empty lines mean nothing, but please avoid them for readability. A blank
##@Desc: line (without the ##@Description tag) will not put a blank line in the
##@Desc: automated documentation generation.


## -- Function Basics
## When called synchronously, functions act more like macros than subroutines.  While you can
## assign values to a variable inside a function and have it exposed (in the same scope) to the
## caller, this is not always advised.  As such, the document script will not look for non-local
## variables.

## -- Function Declarations
## You do NOT need to use special comments and tags.  You ONLY need to write the function using
## the function keyword.  The documentation tool will read everything after it, including getopts.

## -- Author, Version, Date, and Description (and any other tag you want)
## You can specify an author, version, date, description, or any other tag by using the comment
## and @ symbol combination:  ## @SomeAttribute value value value
## (see the @Description above for a multi-line example)

## If you specify a tag at the top of the file, and do not override it in a function, the value
## provided at the top will be used.  This can be disabled via the document generation script
## switches.

## -- Method Signature
## Generally, options should be passed as switches (see getopts below).  If, however, your
## function expects things like $1 you need to let the document script know.  Do this by placing
## a variable tag (## @$1) INSIDE the function, preferably right after declaration.
##
## Note:  You MUST provide a name for $1, $2, etc in your variable tags or the document script
##        will not have a clue what name to use.  You *can* use 1, 2, etc, but that will probably
##        be unhelpful to future readers.

## -- Variables
## Variables are auto-detected by the local keyword.  If a variable tag (## @$) is used as a line-
## end comment, the text following will be used as a description.  You do not need to specify
## the variable name again (## $@var), it will be inferred from the declaration: local var

## Declare:
## Variables are generally untyped.  If you use the declare keyword, the document script will
## note this and update correctly.  Declare is preferred, but typeset is acceptable too.

## Error Codes:
## Any variable starting with E_ will be assumed to be an Error exit-code and documented as such.
## The value assigned will be included in docs.  Use line-end variable tags (## @$) to add
## descriptions.


function examples_template_ExampleFunction {
  ##@Author: Hank BoFrank
  ##@Date  : 2013.03.04
  ##@$1 some_variable_name Description for some_variable_name.  Do not continue on a new line, it won't work.
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

