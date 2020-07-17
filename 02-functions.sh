
# (C) 2020 IBM
#
# Written by Vidyasagar Machupalli

# Exit on errors
set -e
set -o pipefail
echo '>>> Creating cloud functions namespace...'
NAMESPACE=${PREFIX}-actions
if ibmcloud fn property set --namespace ${NAMESPACE} > /dev/null 2>&1; then
  echo "Namespace ${NAMESPACE} already exists."
  ibmcloud fn namespace target ${NAMESPACE}
else
  ibmcloud fn namespace create ${NAMESPACE}
  ibmcloud fn namespace target ${NAMESPACE}
fi

echo '>>> Creating zip of python action'
( cd functions; ./init.sh )
