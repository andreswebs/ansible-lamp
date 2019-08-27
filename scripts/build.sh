#!/bin/bash

# This script uses Ansible to enforce instance configuration

set -e
set -o pipefail

# source from .env file if present
ENV_PATH="./.env"
if [ -f "${ENV_PATH}" ]; then
    # shellcheck source=/dev/null
    source "${ENV_PATH}"
fi

# check existence of required env vars from buildspec.yml

if [ ! "${CONFIG_BUCKET}" ]; then
    echo "error: missing environment variable: CONFIG_BUCKET"
    exit 1
fi

if [ ! "${HOST_ALIAS}" ]; then
    echo "error: missing environment variable: HOST_ALIAS"
    exit 1
fi

if [ ! "${HOST_IP}" ]; then
    echo "error: missing environment variable: HOST_IP"
    exit 1
fi

if [ ! "${KEY_NAME}" ]; then
    echo "error: missing environment variable: KEY_NAME"
    exit 1
fi

# print usage instructions
function show_instructions () {
    echo "usage: ./build.sh <env>"
    echo "<env> := (dev || prod)"
    echo
    echo "example: ./build.sh dev"
    echo
}

if [ ${#} -eq 0 ]; then
    echo "error: too few arguments"
    echo
    show_instructions
    exit 1
fi

STAGE=${1}

if [ "${STAGE}" != "dev" ] && [ "${STAGE}" != "prod" ]; then
    echo "error: argument ${STAGE} is not supported"
    show_instructions
    exit 1
fi

# TODO: strenghten key encryption and security strategies

# get ssh key from s3
aws s3 cp "s3://${CONFIG_BUCKET}/${STAGE}/key/${KEY_NAME}" "/root/.ssh/${KEY_NAME}"
chmod 0400 "/root/.ssh/${KEY_NAME}"

# set ssh config
cat << EOF >> /root/.ssh/config

Host *
  PreferredAuthentications publickey
  IdentitiesOnly yes
  StrictHostKeyChecking no

EOF

# get aws config vars from s3
aws s3 sync "s3://${CONFIG_BUCKET}/${STAGE}/aws_config" "./infrastructure/vars/${STAGE}"

# get app config vars from s3
aws s3 sync "s3://${CONFIG_BUCKET}/all/app_config" ./infrastructure/vars/all

# get mysql vars from s3
aws s3 sync "s3://${CONFIG_BUCKET}/all/mysql_config" ./infrastructure/vars/all

# get db dump from s3
aws s3 sync "s3://${CONFIG_BUCKET}/mysql_backup" ./infrastructure/files/mysql

# get libs from s3
aws s3 sync "s3://${CONFIG_BUCKET}/libs" ./infrastructure/files/libs

HOST_CONFIG="${HOST_ALIAS} ansible_host=${HOST_IP} ansible_user=ubuntu ansible_private_key_file=\"/root/.ssh/${KEY_NAME}\" env=${STAGE}"

INVENTORY_FILE="inventory/hosts.${STAGE}.ini"

# define host in inventory
cat << EOF > "./infrastructure/${INVENTORY_FILE}"
${HOST_CONFIG}
EOF

# install ansible
apt-add-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

# ansible
cd ./infrastructure && ansible-playbook lamp.playbook.yml -i "./${INVENTORY_FILE}"
