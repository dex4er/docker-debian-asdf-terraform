#!/bin/bash

## Entrypoint for propagating termination signal too all processes
## so Terraform can stop gracefully.

if [[ -n ${ENTRYPOINT_DEBUG} ]]; then
  set -ex
fi

trap finish INT TERM

function finish() {
  if [[ -n ${ENTRYPOINT_DEBUG} ]]; then
    set -ex
  fi

  trap '' INT TERM

  pkill -TERM .

  wait "${pid}"
  status=$?

  exit "${status}"
}

## Run bash interactively on terminal or with command otherwise
if [[ -t 0 ]]; then
  {
    if [[ $# -gt 0 ]]; then
      "$@" >/dev/tty </dev/tty
    else
      bash >/dev/tty </dev/tty
    fi
    kill -TERM $$
  } &
else
  {
    if [[ $# -gt 0 ]]; then
      "$@"
    fi
    kill -TERM $$
  } &
fi

pid=$!

if [[ -n ${ENTRYPOINT_DEBUG} ]]; then
  set +ex
fi

## Wait forever until terminating signal will be trapped
while :; do
  sleep 1
done
