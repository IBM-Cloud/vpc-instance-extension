#!/bin/bash

# (C) 2020 IBM
#
# Written by Vidyasagar Machupalli

# Exit on errors
set -e
set -o pipefail

echo ">>> Creating Activity Tracker with LogDNA cloud service..."
if ibmcloud resource service-instance ${AT_LOGDNA_SERVICE_NAME} > /dev/null 2>&1; then
  echo "Activity Tracker with LogDNA service ${AT_LOGDNA_SERVICE_NAME} already exists"
else
  echo "Creating Activity Tracker with LogDNA service..."
  ibmcloud resource service-instance-create ${AT_LOGDNA_SERVICE_NAME} logdnaat lite ${REGION} || exit 1
fi

echo ">>> Creating access group, adding policies and users..."
AT_ID=$(ibmcloud iam access-group-create ${AT_ACCESS_GROUP_NAME} \
--description "For VPC events logged into LogDNA" --output json | jq -r '.id')
if [[ -n "${AT_ID}" ]]; then
  echo ">>> Access group successfully created..."
  echo "Creating access group policy..."
  ibmcloud iam access-group-policy-create ${AT_ACCESS_GROUP_NAME} \
   --service-name logdnaat \
   --roles Administrator,Manager \
   --resource-group-name ${RESOURCE_GROUP_NAME}
  echo ">>> Adding user(s) to the access group"
  ibmcloud iam access-group-user-add ${AT_ACCESS_GROUP_NAME} ${AG_USER1}
else
  echo "Access group creation failed"
fi
