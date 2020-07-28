#!/bin/bash

# (C) 2020 IBM
#
# Written by Vidyasagar Machupalli

# Exit on errors
set -e
set -o pipefail

echo ">>> Checking whether an Activity Tracker with LogDNA cloud service exists..."
RESOURCE_NAME=$(ibmcloud resource service-instances --service-name logdnaat --all-resource-groups --output JSON | jq -r '.[].name')
if [[ -n "${RESOURCE_NAME}" ]]; then
    echo "Activity Tracker with LogDNA service already exists in one of the resource groups of ${REGION} region"
    SERVICE_PLAN=$(ibmcloud resource service-instance "${RESOURCE_NAME}" | grep "^Service Plan Name" | awk -F":" '{ print $2 }' | sed 's/ //g')
    if [[ "${SERVICE_PLAN}" == "lite" ]]; then
      echo "### This sample requires a 7-day log retention PAID plan at minimum. The current log retention service plan is 'Lite'."
      echo "### Upgrade to a 7 day search PAID plan through the UI or run the command 'ibmcloud resource service-instance-update "${RESOURCE_NAME}" --service-plan-id 9aae7491-5cb6-43eb-9b7a-3e0456c781f0 -p \"{\"default_receiver\": true}\"'"
      echo "Once upgraded, re-run this script to create access group and attached policies"
      exit
    fi
else
  echo "This sample requires a Activity Tracker with LogDNA service with 7-day log retention PAID plan..."
  while true; do
    read -p "You must have an activity tracker with LogDNA service to successfully complete this example, would you like to create one?" yn
    case $yn in
        [Yy]* ) ibmcloud resource service-instance-create "${AT_LOGDNA_SERVICE_NAME}" logdnaat 7-day ${REGION} -g "${AT_LOGDNA_RESOURCE_GROUP_NAME}" ; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
 done
fi

echo ">>> Checking whether an access group with required policies exists"
if ibmcloud iam access-group ${AT_ACCESS_GROUP_NAME} > /dev/null; then
   echo "Access group with required policies exists"
else
  AT_ID=$(ibmcloud iam access-group-create ${AT_ACCESS_GROUP_NAME} \
   --description "For VPC events logged into LogDNA" --output json | jq -r '.id')
   if [[ -n "${AT_ID}" ]]; then
      echo ">>> Access group successfully created..."
      echo "Creating access group policy..."
      ibmcloud iam access-group-policy-create ${AT_ACCESS_GROUP_NAME} \
      --service-name logdnaat \
      --roles Administrator,Manager \
      --resource-group-name ${AT_LOGDNA_RESOURCE_GROUP_NAME}
      echo ">>> Adding user(s) to the access group"
      ibmcloud iam access-group-user-add ${AT_ACCESS_GROUP_NAME} ${AG_USER1}
    else
      echo "Access group creation failed"
    fi
fi