#! /bin/sh

umask 0077

# The workdir of the Docker container will be the clone of the NixOS repo
ANSIBLE_DIR="/nixos_deploy"

KEYFILE="/root/.id_ec"
VAULTPASS="/root/.vault_pass"
HOSTFILE="${ANSIBLE_DIR}/hosts.yml"
CONNECTION_TIMEOUT=120

echo "${VAULT_PASS}" > "${VAULTPASS}"
ansible-vault view --vault-password-file="${VAULTPASS}" "${ANSIBLE_DIR}"/id_ec_robot.secret > "${KEYFILE}"
chmod 0400 "${KEYFILE}"

python3 "${ANSIBLE_DIR}"/build_inventory.py --keyfile "${KEYFILE}" \
                                            --timeout "${CONNECTION_TIMEOUT}" \
                                            --eventlog "${GITHUB_EVENT_PATH}" > "${HOSTFILE}"

export ANSIBLE_PYTHON_INTERPRETER="auto_silent"
export ANSIBLE_HOST_KEY_CHECKING="False"
export ANSIBLE_SSH_RETRIES=5
ansible-playbook --timeout="${CONNECTION_TIMEOUT}" \
                 --key-file "${KEYFILE}" \
                 --vault-password-file "${VAULTPASS}" \
                 --inventory "${HOSTFILE}" \
                 --extra-vars "build_sha=${GITHUB_SHA}" \
                 "${ANSIBLE_DIR}"/deploy.yml

