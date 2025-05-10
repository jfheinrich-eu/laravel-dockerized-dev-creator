#!/usr/bin/env bash

if [ -r .env ]
then
	echo "Load environment..."
	set -a
	source .env
	set +a
else
	echo "File .env not found. No environment loaded!"
fi

if [ -r Dockerfile.in ]
then
	echo "Create Dockerfile"
	envsubst "$(printf '${%s} ' $(cat .env|cut -d'=' -f1))" < Dockerfile.in > Dockerfile
else
	echo "File Dockerfile.in not found. File Dockerfile not created!"
fi

if [ -r docker-compose.in ]
then
	echo "Create docker-compose.yml"
	envsubst "$(printf '${%s} ' $(cat .env|cut -d'=' -f1))" < docker-compose.in > docker-compose.yml
else
	echo "File docker-compose.in not found. File docker-compose.yml not created!"
fi

if [ -r create-application.in ]
then
	echo "Create create-application.sh"
	envsubst "$(printf '${%s} ' $(cat .env|cut -d'=' -f1))" < create-application.in > create-application.sh
	chmod 755 create-application.sh
else
	echo "File create-application.in not found. File create-application.sh not created!"
fi
