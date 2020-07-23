#!/bin/bash

# Shared functions

function get_workspace_id() {
  # get the workspace id by name
  ibmcloud schematics workspace list --json | jq -e -r '.workspaces[]|select(.name=="'$TF_VAR_basename'")|.id' 2>/dev/null
}

function poll_for_latest_action_to_finish() {
  # schematics activities do not complete synchronously, poll waiting for completion
  local wsid=$1
  local value=$2
  while true; do
    status=$(ibmcloud schematics workspace action --id $wsid --json | jq -r '.actions[0].status')
    if [ "$status" == COMPLETED ]; then
      echo "$value completed successfully"
      return 0
    fi
    if [ "$status" == INPROGRESS ]; then
      echo "$value is in progress..."
    fi
    if [ "$status" == FAILED ]; then
      return 1
    fi
    sleep 10
  done
}
