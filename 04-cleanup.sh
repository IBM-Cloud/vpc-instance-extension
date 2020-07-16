#!/bin/bash
set -e
set -o pipefail
source ./shared.sh

if workspace_id=$(get_workspace_id); then
  ibmcloud schematics destroy --id $workspace_id -f
  poll_for_latest_action_to_finish $workspace_id
  ibmcloud schematics workspace delete --id $workspace_id -f
fi

# Cloud Functions
ibmcloud fn action delete vpc-resource-automation

NAMESPACE=$PREFIX-actions
ibmcloud fn namespace delete $NAMESPACE

# Resource authorizations:
echo '>>> Removing ${AT_ACCESS_GROUP_NAME} access group along with policies and users'
ibmcloud iam access-group-delete ${AT_ACCESS_GROUP_NAME}

# Services
AT_LOGDNA_INSTANCE_ID=$(ibmcloud resource service-instance --output JSON ${AT_LOGDNA_SERVICE_NAME} | jq -r .[0].id)
ibmcloud resource service-instance-delete ${AT_LOGDNA_INSTANCE_ID} --force --recursive