echo ">>> Pulling Docker Python image"
docker pull ibmfunctions/action-python-v3.7

echo ">>> Install dependencies and create a virtual environment using Docker..."
docker run --rm -v "$PWD:/tmp" ibmfunctions/action-python-v3.7 bash -c \
"cd /tmp && virtualenv virtualenv && source virtualenv/bin/activate \
&& pip install -r requirements.txt"

echo ">>> Zip the actions and the virtualenv..."
zip -r functions.zip virtualenv __main__.py helper.py
