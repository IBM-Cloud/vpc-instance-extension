
# (C) 2020 IBM
#
# Written by Vidyasagar Machupalli

# Exit on errors
set -e
set -o pipefail

echo '>>> Creating zip of python action'
( cd functions; ./init.sh )

echo '>>> Creating cloud functions namespace...'
NAMESPACE=${PREFIX}-actions
if ibmcloud fn property set --namespace ${NAMESPACE} > /dev/null 2>&1; then
  echo "Namespace ${NAMESPACE} already exists."
  ibmcloud fn namespace target ${NAMESPACE}
else
  ibmcloud fn namespace create ${NAMESPACE}
  ibmcloud fn namespace target ${NAMESPACE}
fi

echo ">>> Creating or updating the action..."
ibmcloud fn action update vpc-instance-extension functions/functions.zip \
--kind python:3.7 \
--param IAM_API_KEY ${IAM_API_KEY} \
--web true \
--web-secure true

echo ">>> Web URL of the action..."
ibmcloud fn action get vpc-instance-extension --url

echo ">>> Copy the value of the key 'require-whisk-auth'"
ibmcloud fn action get vpc-instance-extension