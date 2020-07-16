#!/bin/bash
set -e
set -o pipefail
source ./shared.sh

# Use schematics to create a vpc environment

echo '>>> creating schematics.json from schematics.template.json'
jq -n --arg TF_VAR_basename $TF_VAR_basename --arg TF_VAR_ssh_key_name $TF_VAR_ssh_key_name "$(cat schematics.template.json)" > schematics.json

echo '>>> schematics workspace'
if workspace_id=$(get_workspace_id); then
  echo workspace $TF_VAR_basename already exists updating
  ibmcloud schematics workspace update --id $workspace_id --file schematics.json
else
  echo 'creating schematics workspace'
  workspace_id=$(ibmcloud schematics workspace new --file schematics.json --output json | jq -r '.id')
fi
poll_for_latest_action_to_finish $workspace_id

echo basename = "\"$TF_VAR_basename\"" > schematics.tfvars
echo ssh_key_name = "\"$TF_VAR_ssh_key_name\"" >> schematics.tfvars

echo '>>> schematics apply'
ibmcloud schematics apply --id $workspace_id --var-file schematics.tfvars -f
poll_for_latest_action_to_finish $workspace_id

echo '>>> get vpc id'
vpc_id=$(ibmcloud schematics output --id $workspace_id --json | jq -r '.[0].output_values[0]|.vpc_id.value')

echo ">>> create flow log collector for vpc $vpc_id"
ibmcloud is target --gen 2
ibmcloud is flow-log-create --bucket $COS_BUCKET_NAME --target $vpc_id --name $PREFIX-flowlog

echo '>>> to exercise the vpc'
ibmcloud schematics output --id $workspace_id --json | jq -r '.[0]|.output_values[0]|.ibm1_curl.value'