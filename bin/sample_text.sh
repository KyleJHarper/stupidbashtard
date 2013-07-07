#!/bin/bash

function doc_examples_43-ParameterVariableTags {
  #@Description  In this function we will accept $1 and $2 parameters.  We will assign descriptions to them.
  #@Description  These must always be federated, as there is no declaration for them.

  #@$1  The file we will use for <whatever>.
  #@$2  The maximum results to find before leaving.

  declare                BOOM_FILE
  declare -r             OUTPUT_FILE
  declare -r    local -l INPUT_FILE="$1"          #@$  This will hold the contents of $1, mostly for readability later.
  declare -r -i local    MAX_RESULTS=$2           #@$  This will hold the value of $2, mostly for readability later.
                         NUMERIC=23               #@$  Some stuff
                         RAWR=nom                 #@$  whoop whoop
                         TOUGH="I am text"        #@$  Some stuff
                         TOUGHER="Don't care!"    #@$  More fun!
                         TOUGHEST="Don\"t # care!"  #@$  More # fun!
                         TOUGHEREST="Don\"t # care!"

  echo "${OUTPUT_FILE}"
  echo "${INPUT_FILE}"
  echo "${MAX_RESULTS}"
  echo "${NUMERIC}"
  echo "${RAWR}"
  echo "${TOUGH}"
  echo "${TOUGHER}"
  echo "${TOUGHEST}"
  echo "${TOUGHEST}"
  return 0
}

doc_examples_43-ParameterVariableTags
