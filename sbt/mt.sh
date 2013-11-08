# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


#@Author     Kyle Harper
#@Date       2013.11.07
#@Version    0.0.1-beta
#@Namespace  mt

#@Description  Bash is capable of parallel execution through forking.  This namespace provides facilities to store tasks in pools and execute them through asynchronous dispatchers.
#@Description  -
#@Description  Forking is expensive compared to native threading in other languages.  The shorter your operation, the larger percentage of time your program will spend forking vs doing useful work.
#@Description  -
#@Description  Be sure your operations are atomic!  Be sure you aren't relying on any shared resources!  Be aware there is no such thing as a delegate; every forked action is its little world!



#
# -- Initialize Globals for this Namespace
#

declare    __SBT_MT_BASE_DIR='/tmp/sbt-mt'   #@$ Root director for pools, workers, etc.
declare -i __SBT_MT_WORKER_SIZE=4            #@$ Number of workers per pool for processing tasks.


function mt_InitializePool {
  #@Description  Build a directory structure and files for a new pool.  This is called automatically when a task is assigned to a non-existent pool.
  #@Description  -
  #@Description  The name should be provided by the caller.  If absent 'default' is used.  Not using core_getopts because it's overkill.
  #@Usage  mt_InitializePool ['pool_name']
  #@Date   2013.11.07

  core_LogVerbose "Entering function."
  local -r _name="${1:-default}"                    #@$ The pool name to use when creating directories.
  local -r _my_dir="${__SBT_MT_BASE_DIR}/${_name}"  #@$ This instances directory to work with.  For convenience mostly.

  core_LogVerbose "Doing preflight checks."
  if [ ! -w "${__SBT_MT_BASE_DIR}" ] ; then core_LogError "Cannot write to MT Base directory '${__SBT_MT_BASE_DIR}'  (aborting)" ; return 1 ; fi
  if [ -d "${_my_dir}" ]             ; then core_LogVerbose "Pool directory already exists: '${_my_dir}."                        ; return 0 ; fi

  core_LogVerbose "Creating directories."
  if ! mkdir -p "${_my_dir}/{workers,tasks,flags}" ; then
    core_LogError "Failed to create one or more of the directories with: mkdir -p \"${_my_dir}/{workers,tasks,flags}\".  (aborting)"
    return 1
  fi

  core_LogVerbose "Setting default flags."
  if ! (set -o 'noclobber' ; echo "${__SBT_MT_WORKER_SIZE}" > "${_my_dir}/worker_size") ; then
    core_LogError "Cannot set 'worker_size' file, already set.  This shouldn't have happened."
    return 1
  fi

  core_LogVerbose "Pool successfully created, registering pool shutdown function with trap, if not already there."
  core_RegisterForShutdown "mt_DestroyPools"
  return 0
}


function mt_DestroyPools {
  # Set flag to disallow dispatching new processes.
  # For each pool directory:
  #  1. Kill each PID listed in workers directory
  #  2. Log the aborted PID and task
  #  3. Log all aborted tasks
  #  4. probably more... like rotate the contents out and rm the directory for next run.
}


function mt_SetTempDirectory {
  #@Description  Specify a different pool directory.  For performance reasons, this should be a tmpfs/ramfs directory when possible.
}

function mt_TODO {
#TODO  Remove this, it's here for reference as I work on MT
  #@Description  Returns a count of the times characters/strings are found in the passed values.  Uses PCRE (perl) in pattern.
  #@Description  -
  #@Description  If count is zero, exit value will still be 0 for success.
  #@Usage  string_CountOf [-a --all] <-p --pattern 'PCRE regex' > [-R 'ref_var_name'] <'values' or -f --file 'FILE' or STDIN>
  #@Date   2013.10.21

  core_LogVerbose 'Entering function.'
  # Variables
  local -a __SBT_NONOPT_ARGS  #@$ Local instance for the core_getopts processing below since this will never need exposed to parents.
  local -a _files             #@$ List of files to count occurrence in.
  local    _pattern=''        #@$ Holds the pattern to search for.  PCRE (as in, real perl, not grep -P).
  local    _opt=''            #@$ Temporary variable for core_getopts, brought to local scope.
  local    _REFERENCE=''      #@$ Will hold the name of the var to use for indirect referencing later, if -R used.
  local    _DATA=''           #@$ Holds all items to search within, mostly to help with the -a/--all items.
  local    _temp=''           #@$ Garbage variable for looping.

  # Use core_getopts to not only handle options elegantly, but to put nonopts in __SBT_NONOPT_ARGS
  core_LogVerbose 'Processing options.'
  while core_getopts ':af:p:R:' _opt ':all,file:,pattern:' "$@" ; do
    case "${_opt}" in
      'a' | 'all'     ) _pattern='[\s\S]'      ;;  #@opt_  Count all characters in data.  A niceness.
      'f' | 'file'    ) _files+=("${OPTARG}")  ;;  #@opt_  File(s) to slurp for input.  The -f and --file can be specified multiple times.
      'p' | 'pattern' ) _pattern="${OPTARG}"   ;;  #@opt_  The PCRE pattern to match against for counting.
      'R'             ) _REFERENCE="${OPTARG}" ;;  #@opt_  Reference variable to assign resultant data to.
      *               ) core_LogError "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done

  # Preflight checks
  core_LogVerbose "Checking a few requirements before proceeding."
  core_ToolExists 'perl' || return 1
  for _temp in "${__SBT_NONOPT_ARGS[@]}" ; do _DATA+="${_temp}" ; done
  core_ReadDATA "${_files[@]}" || return 1
  if [ -z "${_pattern}" ] ; then
    core_LogError "No pattern was specified to find and we weren't told to find 'all'.  (aborting)"
    return 1
  fi

  # Time to count some things
  core_LogVerbose "Attempting to count occurrences."
  _temp="$(perl "${__SBT_EXT_DIR}/string_CountOf.pl" -p "${_pattern}" <<<"${_DATA}")"
  if [ $? -ne 0 ] ; then
    core_LogError "Perl returned an error code, counting failed.  (aborting)."
    return 1
  fi
  core_StoreByRef "${_REFERENCE}" "${_temp}" || echo -e "${_temp}"

  return 0
}



#
# --- Post Initialization Logic
#

mt_SetTempDirectory  # This will try to find a tmpfs/ramfs directory in a few known locations.
mt_SetWorkerSize     # This will try to read the number of CPUs and adjust accordingly.
