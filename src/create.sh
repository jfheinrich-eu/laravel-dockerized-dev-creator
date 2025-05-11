#!/usr/bin/env bash
set -e

SCRIPTDIR=$(realpath $(dirname $0))
BUILD_DIR=$(realpath ${SCRIPTDIR}/../build)

if [ ! -d $BUILD_DIR ]; then
	echo "Create build directory: $BUILD_DIR"
	mkdir $BUILD_DIR
else
	echo "Reset build directory ${BUILD_DIR}"
	(cd ${BUILD_DIR} && rm -rf *)
fi

if [ -r ${SCRIPTDIR}/.env ]; then
	echo "Load environment..."
	set -a
	source ${SCRIPTDIR}/.env
	set +a
else
	echo "File .env not found. No environment loaded!"
fi
MOUNT_POINT=${DOCKER_MOUNT_SOURCE}

if [ -r ${SCRIPTDIR}/Dockerfile.in ]; then
	echo "Create Dockerfile"
	envsubst "$(printf '${%s} ' $(cat ${SCRIPTDIR}/.env | cut -d'=' -f1))" <${SCRIPTDIR}/Dockerfile.in >${BUILD_DIR}/Dockerfile
	cp ${SCRIPTDIR}/docker-entrypoint.sh ${BUILD_DIR}/docker-entrypoint.sh
else
	echo "File Dockerfile.in not found. File Dockerfile not created!"
fi

if [ -r ${SCRIPTDIR}/docker-compose.in ]; then
	echo "Create docker-compose.yml"
	envsubst "$(printf '${%s} ' $(cat ${SCRIPTDIR}/.env | cut -d'=' -f1))" <${SCRIPTDIR}/docker-compose.in >${BUILD_DIR}/docker-compose.yml
else
	echo "File docker-compose.in not found. File docker-compose.yml not created!"
fi

if [ -r ${SCRIPTDIR}/create-application.in ]; then
	echo "Create create-application.sh"
	envsubst "$(printf '${%s} ' $(cat ${SCRIPTDIR}/.env | cut -d'=' -f1))" <${SCRIPTDIR}/create-application.in >${BUILD_DIR}/create-application.sh
	chmod 755 ${BUILD_DIR}/create-application.sh
else
	echo "File create-application.in not found. File create-application.sh not created!"
fi

if [ -r ${SCRIPTDIR}/laravel-default-env.in ]; then
	echo "Create laravel-default-env"
	envsubst "$(printf '${%s} ' $(cat ${SCRIPTDIR}/.env | cut -d'=' -f1))" <${SCRIPTDIR}/laravel-default-env.in >${BUILD_DIR}/laravel-default-env
else
	echo "File laravel-default-env.in not found. File laravel-default-env not created!"
fi

if [ -d ${MOUNT_POINT}} ]; then
	rm -rf ${MOUNT_POINT}
	echo "reset docker mount point ${MOUNT_POINT}"
else
	echo "create docker mount point ${MOUNT_POINT}"
fi

echo "Create installer..."
cat <<EOF >${BUILD_DIR}/install.sh
#!/usr/bin/env bash
set -e

cd ${BUILD_DIR}
echo "Create all service container..."
docker-compose up --build -d

echo "Create Laravel 12 Livewire Fortify application..."
docker compose exec app /laravel-install.sh

echo "Restart app container..."
docker compose restart app

echo "You can access th site with ${APP_URL}"

EOF

mkdir -p ${MOUNT_POINT}

echo "copy defaults and docker..."
cp -a ${SCRIPTDIR}/defaults ${BUILD_DIR}
cp -a ${SCRIPTDIR}/docker ${BUILD_DIR}
