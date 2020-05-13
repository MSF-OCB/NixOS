#! /bin/sh

umask 0077

ansible_dir="/nixos_deploy"
keyfile="/root/.id_ec"
vaultpass="/root/.vault_pass"
hostfile="${ansible_dir}/hosts.yml"
connection_timeout=120

echo "${VAULT_PASS}" > "${vaultpass}"
ansible-vault view --vault-password-file="${vaultpass}" "${ansible_dir}"/id_ec_robot.secret > "${keyfile}"
chmod 0400 "${keyfile}"

python3 "${ansible_dir}"/build_inventory.py --keyfile "${keyfile}" \
                                            --timeout "${connection_timeout}" \
                                            --eventlog "${GITHUB_EVENT_PATH}" \
                                            --fixedhosts "${NIXOS_DEPLOY_FIXED_HOSTS}" \
                                            > "${hostfile}"

export ANSIBLE_PYTHON_INTERPRETER="auto_silent"
export ANSIBLE_HOST_KEY_CHECKING="False"
export ANSIBLE_SSH_RETRIES=5
ansible-playbook --timeout="${connection_timeout}" \
                 --key-file "${keyfile}" \
                 --vault-password-file "${vaultpass}" \
                 --inventory "${hostfile}" \
                 "${ansible_dir}"/deploy.yml

