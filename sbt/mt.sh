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

declare __SBT_MT_BASE_DIR='/tmp/sbt-mt'          #@$ Root director for pools, workers, etc.
declare __SBT_MT_DISPATCHER_POLL_INTERVAL='0.1'  #@$ How long should a dispatcher wait, in seconds, before trying trying to run a new task?


# +------------------+
# |  Pool Functions  |
# +------------------+
function mt_InitializePool {
  #@Description  Build a directory structure and files for a new pool.  This is called automatically when a task is assigned to a non-existent pool.
  #@Description  -
  #@Description  The name should be provided by the caller.  If absent 'default' is used.
  #@Usage  mt_InitializePool [-n --name 'pool_name'] [-s --size '#']
  #@Date   2013.11.07

  core_LogVerbose "Entering function."
  local    _pool="default"                          #@$ The pool name to use when creating directories.
  local -i _size="4"                                #@$ The size of the pool (number of workers)
  local -r _my_dir="${__SBT_MT_BASE_DIR}/${_pool}"  #@$ This instances directory to work with.  For convenience mostly.
  local    _opt                                     #@$ For getopts loop

  core_LogVerbose "Getting options, if any, and overriding defaults."
  while core_getopts ':n:s:' _opt ':name:,size:' "$@" ; do
    case "${_opt}" in
      'n' | 'name' ) _pool="${OPTARG}"   ;;  #@opt_  The name to store in _pool for referencing this pool.
      's' | 'size' ) _size="${OPTARG}"   ;;  #@opt_  The size of the pool, representing the number of workers to execute simultaneously.
      *            ) core_LogError "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done
  local -r _my_dir="${__SBT_MT_BASE_DIR}/${_pool}"  #@$ This instances directory to work with.  For convenience mostly.

  core_LogVerbose "Doing preflight checks."
  if [ ! -w "${__SBT_MT_BASE_DIR}" ] ; then core_LogError "Cannot write to MT Base directory '${__SBT_MT_BASE_DIR}'  (aborting)" ; return 1 ; fi
  if [[ ! "${_size}" =~ ^[0-9]+$ ]]  ; then core_LogError "Size (${_size}) must be a number.  (aborting)"                        ; return 1 ; fi
  if [ -z "${_pool}" ]               ; then core_LogError "Pool name (-n) cannot be blank."                                      ; return 1 ; fi
  if [ "${_pool}" == '__ALL' ]       ; then core_LogError "Pool cannot be named '__ALL', that name is reserved.  (aborting)"     ; return 1 ; fi
  if [ -d "${_my_dir}" ]             ; then core_LogVerbose "Pool directory already exists: '${_my_dir}."                        ; return 0 ; fi
  core_ToolExists 'mkdir' || return 1

  core_LogVerbose "Creating directories."
  if ! mkdir -p "${_my_dir}/{workers,tasks,flags}" ; then
    core_LogError "Failed to create one or more of the directories with: mkdir -p \"${_my_dir}/{workers,tasks,flags}\".  (aborting)"
    return 1
  fi

  core_LogVerbose "Automatically assigning a dispatcher to the new pool."
  if ! mt_Dispatcher -a 'start' -p "${_pool}" -s "${size}" ; then core_LogError "Failed to start the dispatcher.  (aborting)" ; return 1 ; fi

  core_LogVerbose "Pool successfully created, registering pool shutdown function with trap, if not already there."
#TODO  core_RegisterForShutdown "mt_DestroyPool __ALL"
  return 0
}


function mt_DestroyPool {
  # Set flag to disallow dispatching new processes.
  # Flag for all pools
  # For each pool directory:
  #  1. Kill each PID listed in workers directory
  #  2. Log the aborted PID and task
  #  3. Log all aborted tasks
  #  4. probably more... like rotate the contents out and rm the directory for next run.
}



# +------------------------+
# |  Dispatcher Functions  |
# +------------------------+
function mt_Dispatcher {
  #@Description  Controls a dispatcher by affecting it's flags.  This function cannot infer _pool because it might getting controlled manually (user code).
  #@Usage  mt_Dispatcher <-a --action 'start or stop'> <-n --name 'pool_name'>
  #@Date   2013.11.29

  core_LogVerbose "Entering function."
  local _action  #@$ The action we want to take.
  local _pool    #@$ The pool we want to perform an action against
  local _opt     #@$ For getopts loop

  core_LogVerbose "Getting options, if any."
  while core_getopts ':a:n:' _opt ':action:,name:' "$@" ; do
    case "${_opt}" in
      'a' | 'action' ) _action="${OPTARG}"   ;;  #@opt_  Action to take.
      'n' | 'name'   ) _pool="${OPTARG}"     ;;  #@opt_  The name to store in _pool for referencing this pool.
      *              ) core_LogError "Invalid option sent to me: ${_opt}  (aborting)" ; return 1 ;;
    esac
  done
  local -r _my_dir="${__SBT_MT_BASE_DIR}/${_pool}"  #@$ This instances directory to work with.  For convenience mostly.
  local -r _my_dispatcher="${_my_dir}/dispatcher/pid"

  core_LogVerbose "Doing preflight checks."
  if [ -z "${_pool}" ]     ; then core_LogError "Pool name (-n) cannot be blank."            ; return 1 ; fi
  if [ ! -d "${_my_dir}" ] ; then core_LogVerbose "Pool directory not found: '${_my_dir}."   ; return 1 ; fi
  core_ToolExists 'sleep' 'ps' 'cat' 'rm' || return 1

  core_LogVerbose "Attempting to to execute the action '${_action}' on the dispatcher for pool '${_pool}'."
  case "${_action}" in
    'start' )
              if [ -f "${_my_dispatcher}" ] ; then
                core_LogVerbose "This pool (${_pool}) already has a dispatcher running.  Leaving with code 0 (ok)."
                return 0
              fi
              if ! (set -o noclobber ; exec 2&>/dev/null ; > "${_my_dispatcher}") ; then
                core_LogError "Unable to create the dispatcher pid file for this pool.  Aborting."
                return 1
              fi
              core_LogVerbose "Starting the dispatcher asynchronously."
              mt_RunDispatcher &
              ;;
    'stop'  )
              if [ ! -f "${_my_dispatcher}" ] ; then
                core_LogError "The dispatcher pid file is missing: ${_my_dispatcher}  (aborting)"
                return 1
              fi
              local -r -i _dispatcher_pid=$(cat "${_my_dispatcher}")  #@$ Stores the pid number of the dispatcher we're stopping.
              local    -i _i=0                                        #@$ Counter to increment while we wait for dispatcher pid to evaporate.
              if [[ ! ${_dispatcher_pid} =~ ^[0-9}+$ ]] ; then
                core_LogError "PID for dispatcher came back blank or not-a-number: '${_dispatcher_pid}'  (aborting)"
                return 1
              fi
              if ! rm "${_my_dispatcher}" ; then
                core_LogError "Unable to remove the dispatcher PID file for this pool.  Returning failure."
                return 1
              fi
              while [ ${i} -lt 5 ] && ps ${_dispatcher_pid} 1>/dev/null ; do sleep 1 ; let i++ ; done
              [ ${i} -ge 5 ] && core_LogVerbose "Dispatcher's PID didn't die after ${i} seconds.  Could be due to long timeouts.  Continuing."
              core_LogVerbose "'Stop' operation finished, be aware tasks started by the dispatcher are still alive if they haven't finished."
              ;;
    *       )
              core_LogError "Action specified must be 'start' or 'stop', not '${_action}'.  (aborting)"
              return 1
              ;;
  esac

  core_LogVerbose "Finished the '${_action}' action for the pool '${_pool}'."
  return 0
}

function mt_RunDispatcher {
  #@Description  This IS a dispatcher.  It is an asynchronous process which will regularly scan the task folder of a given pool for things to do.  Tasks will be passed off to workers in futher asynchronous calls.
  #@Description  -
  #@Description  It's compulsory for the caller to have variables called _pool and _my_dir with the name of the pool and directory location.  This check is handled by the caller (mt_Dispatcher) and therefore is not checked here.
  #@Usage        mt_RunDispatcher &
  #@Date         2013.12.04

  #@$_pool    The name of the pool to work with.  This must be provided by the parent (caller).
  #@$_my_dir  The root directory of the pool.  This must be provided by the parent (caller).
  if getconf INT_MAX >/dev/null 2>&1 ; then
    core_LogVerbose "Found the 'getconf' command, using it to capture INT_MAX to override the _MAX_TASK_ID safety variable."
    _MAX_TASK_ID="$(getconf INT_MAX)"
  fi
#OVERRIDE LOG FILE LOCATION FOR core_LogVerbose and core_LogError:  _my_log_file="${_my_dir}/dispatcher/output.log"
  core_LogVerbose "Doing pre-flight checks."
  if [ ${BASHPID} -eq $$ ] ; then
    core_LogError 'The dispatcher must run asynchronously.  Currently BASHPID matches $$.  (aborting)'
    mt_DestroyPool -p "${_pool}"
  fi
  # MUST BE CALLED ASYNCHRONOUSLY!!!  _pool PROVIDED BY CALLER.
  # This is a parent to all further calls, so worker_id will propagate.
  # Put PID in dispatcher file, no clobber.  Fail if already running.
  # If $BASHPID == $$ fail
  # _poll_interval=${__SBT_MT_DISPATCHER_POLL_INTERVAL}  (override with getopts)
  # while <dispatcher file exists>
    # If no tasks to run, sleep ${__SBT_MT_DISPATCHER_POLL_INTERVAL} a few and continue 1
    # until worker_id=$(mt_FindFreeWorker) sleep a few and continue 1
    # mt_LockWorker
    # mt_RunTask -t 'task_id' &
  # done
}


# +------------------+
# |  Task Functions  |
# +------------------+
function mt_AddTask {
  # DO NOT CALL ASYNC!!!
}

function mt_RunTask {
  # MUST BE CALLED ASYNCHRONOUSLY!!!  _pool AND _worker_id PROVIDED BY CALLER.
  # If $BASHPID == $$ fail
  # Build header file for worker
  #   Spacing
  #   Thick Separator
  #   Thin Separator
  #   Command String
  #   PID
  #   Exit Code
  #   Thin Separator
  # Run the task synchronously 1>/Worker_Output_File 2>&1
  # Thick Separator 1>/Worker_Output_File 2>&1
  # mt_ConsolidateWorkerLogs
  # mt_ReleaseWorker
}



# +--------------------+
# |  Worker Functions  |
# +--------------------+
function mt_FindFreeWorker {
  # Search all available workers in _pool from caller.  Return with the id of a the open worker.
}
function mt_LockWorker {
  # Lock the worker with id in _worker_id from caller.
}
function mt_ReleaseWorker {
  # Release the worker with id in _worker_id from caller.
}
function mt_WorkerLog {
  # Log an item to the header or body section of a temp file.  Or consolidate the two into the main log and wipe the temps out.
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



# +--------------------------+
# |  Property Set Functions  |
# +--------------------------+
function mt_SetTempDirectory {
  #@Description  Specify a different pool directory.  For performance reasons, this should be a tmpfs/ramfs directory when possible.

#FIND a RAMFS drive
#Make the sbt folder
}




#
# --- Post Initialization Logic
#

mt_SetTempDirectory  # This will try to find a tmpfs/ramfs directory in a few known locations.
mt_SetWorkerSize     # This will try to read the number of CPUs and adjust accordingly.
