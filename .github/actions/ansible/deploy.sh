#! /bin/sh

umask 0077

echo "${VAULT_PASS}" > /root/.vault_pass
ansible-vault view --vault-password-file=/root/.vault_pass ansible/id_ec_robot.secret > /root/.id_ec
chmod 0600 /root/.id_ec

python3 ansible/build_inventory.py --eventlog "${GITHUB_EVENT_PATH}" > ansible/hosts.yaml

ansible-playbook --timeout=30 \
                 --key-file "/root/.id_ec" \
                 --vault-password-file /root/.vault_pass \
                 --inventory ansible/hosts.yml \
                 --extra-vars "build_sha=${GITHUB_SHA}" \
                 ansible/deploy.yml

