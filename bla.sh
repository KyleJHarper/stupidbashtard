#!/bin/bash

function not_async {
  echo "not_async ${BASHPID}"
}

function async {
  echo "async ${BASHPID}"
}

echo "Main ${BASHPID}"
not_async
async &

wait
