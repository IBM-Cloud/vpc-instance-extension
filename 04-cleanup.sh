#!/bin/bash
set -o pipefail
source ./shared.sh

echo ">>> Deleting Schematics workspace..."
if workspace_id=$(get_workspace_id); then
  ibmcloud schematics destroy --id $workspace_id -f
  poll_for_latest_action_to_finish $workspace_id
  ibmcloud schematics workspace delete --id $workspace_id -f
fi

echo ">>> Deleting Cloud functions resources..."
# Cloud Functions
ibmcloud fn action delete vpc-instance-extension

NAMESPACE=$PREFIX-actions
ibmcloud fn namespace delete $NAMESPACE 

# Resource authorizations:
echo '>>> Removing ${AT_ACCESS_GROUP_NAME} access group along with policies and users'
ibmcloud iam access-group-user-remove ${AT_ACCESS_GROUP_NAME} ${AG_USER1} --force
ibmcloud iam access-group-delete ${AT_ACCESS_GROUP_NAME} --force
