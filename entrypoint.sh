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
    bash -i "$@" >/dev/tty </dev/tty
    kill -TERM $$
  } &
else
  {
    bash "$@"
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
