echo ">>> Checking whether Docker is installed and running"
if docker ps >/dev/null; then
  echo "Docker is installed and running..."
else
  echo "Install and start Docker..."
fi

echo ">>> Pulling Docker Python image"
docker pull ibmfunctions/action-python-v3.7

echo ">>> Checking whether PIP is installed"
if pip install --upgrade pip >/dev/null; then
  echo "pip is installed and upgraded..."
else
  echo "Install pip for downloading required Python packages..."
fi

echo ">>> Install dependencies and create a virtual environment using Docker..."
docker run --rm -v "$PWD:/tmp" ibmfunctions/action-python-v3.7 bash -c \
"cd /tmp && virtualenv virtualenv && source virtualenv/bin/activate \
&& pip install -r requirements.txt"

echo ">>> Zip the actions and the virtualenv..."
zip -r functions.zip virtualenv __main__.py helper.py

echo ">>> Creating or updating the action..."
ibmcloud fn action update vpc-resource-automation functions.zip \
--kind python:3.7 \
--param IAM_API_KEY ${IAM_API_KEY} \
--web true \
--web-secure true

echo ">>> Web URL of the action..."
ibmcloud fn action get vpc-resource-automation --url