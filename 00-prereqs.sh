#!/bin/bash

# (C) 2020 IBM
#
# Written by Vidyasagar Machupalli

# Exit on errors
set -e
set -o pipefail

echo ">>> Targeting region $REGION..."
ibmcloud target -r $REGION

echo ">>> Targeting resource group $RESOURCE_GROUP_NAME..."
ibmcloud target -g $RESOURCE_GROUP_NAME

echo ">>> Checking whether Infrastructure service/VPC plugin is installed"
if ibmcloud is help >/dev/null; then
  echo "Infrastructure service/VPC plugin is installed"
else
  echo "Installing Infrastructure service/VPC plugin"
  ibmcloud plugin install vpc-infrastructure
fi

echo ">>> Targeting vpc generation 2..."
ibmcloud is target --gen 2

echo ">>> Checking whether Cloud Functions plugin is installed"
if ibmcloud fn namespace list >/dev/null; then
  echo "cloud-functions plugin is installed"
else
  echo "Installing cloud functions plugin..."
  ibmcloud plugin install cloud-functions
fi

echo ">>> Checking whether Schematics plugin is installed"
if ibmcloud schematics workspace list >/dev/null; then
  echo "Schematics plugin is installed"
else
  echo "Installing schematics plugin..."
  ibmcloud plugin install schematics
fi

echo ">>> Is jq (https://stedolan.github.io/jq/) installed?"
jq -V
