#!/bin/bash

#@Author    Kyle Harper
#@Date      2013.07.07
#@Version   0.1-beta
#@Namespace core

#@Description  These functions serve as some of the primative tools and requirements for all of SBT.  This will likely become a large namespace.


function core_getopts {
  #@Description  Fully backward compatible replacement for the built-in getopts routine in Bash.  It allows long options, that's the only change.
  #@Description  Long options are comma separated.  Adding a colon after an option (but before the comma) implies an argument should follow; same as the built-in getopts.
  #@Description  -
  #@Description  This breaks the typical naming convention (upper/proper-casing  latter segement of function name) on purpose.

  #@$1  The list short options, same as bash built-in getopts.
  #@$2  Textual name of the variable to send back to the caller, same as built-in getopts.
  #@$3  The list of long options, optional.


}
