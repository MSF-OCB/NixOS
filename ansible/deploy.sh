#! /bin/sh

umask 0077

KEYFILE="/root/.id_ec"
VAULTPASS="/root/.vault_pass"

echo "${VAULT_PASS}" > "${VAULTPASS}"
ansible-vault view --vault-password-file="${VAULTPASS}" ansible/id_ec_robot.secret > "${KEYFILE}"
chmod 0600 "${KEYFILE}"

python3 ansible/build_inventory.py --keyfile "${KEYFILE}" --eventlog "${GITHUB_EVENT_PATH}" > ansible/hosts.yml

ansible-playbook --timeout=30 \
                 --key-file "${KEYFILE}" \
                 --vault-password-file "${VAULTPASS}" \
                 --inventory ansible/hosts.yml \
                 --extra-vars "build_sha=${GITHUB_SHA}" \
                 ansible/deploy.yml

