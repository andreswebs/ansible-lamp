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
    echo "Missing environment variable: CONFIG_BUCKET"
    exit 1
fi

if [ ! "${HOST_ALIAS}" ]; then
    echo "Missing environment variable: HOST_ALIAS"
    exit 1
fi

if [ ! "${HOST_GROUP}" ]; then
    echo "Missing environment variable: HOST_GROUP"
    exit 1
fi

if [ ! "${HOST_IP}" ]; then
    echo "Missing environment variable: HOST_IP"
    exit 1
fi

if [ ! "${KEY_NAME}" ]; then
    echo "Missing environment variable: KEY_NAME"
    exit 1
fi

# get libs from s3
aws s3 sync "s3://${CONFIG_BUCKET}/libs" ./app

# TODO: strenghten key encryption and security strategies

# get ssh key from s3
aws s3 sync "s3://${CONFIG_BUCKET}/key" /root/.ssh
chmod 0400 "/root/.ssh/${KEY_NAME}"

# set ssh config
cat << EOF >> /root/.ssh/config
Host *
  PreferredAuthentications publickey
  IdentitiesOnly yes
  StrictHostKeyChecking no
EOF

# get codedeploy keys from s3
# aws s3 sync "s3://${CONFIG_BUCKET}/codedeploy" ./infrastructure/vars

# get mysql vars from s3
aws s3 sync "s3://${CONFIG_BUCKET}/mysql_config" ./infrastructure/vars

# get db dump from s3
aws s3 sync "s3://${CONFIG_BUCKET}/mysql_dump" ./infrastructure/files/mysql

HOST_CONFIG="${HOST_ALIAS} ansible_host=${HOST_IP} ansible_user=ubuntu ansible_private_key_file=\"/root/.ssh/${KEY_NAME}\""

# define host
cat << EOF > ./infrastructure/hosts
[${HOST_GROUP}]
${HOST_CONFIG}
EOF

# place app files
mv -f ./app ./infrastructure/files

# TODO: add a flag argument to script to skip
# install ansible
apt-add-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

# ansible
cd ./infrastructure && ansible-playbook playbook.yml

# cd .. && rm -rf ./infrastructure