
import os
import yaml

from typing import Mapping

from ansible.constants     import DEFAULT_VAULT_ID_MATCH # type: ignore
from ansible.parsing.vault import VaultLib, VaultSecret  # type: ignore

from getpass import getpass


UTF8 = "utf-8"


# See the following link for the source code and the API of the vault library:
# https://github.com/ansible/ansible/blob/devel/lib/ansible/parsing/vault/__init__.py


def print_vault_banner() -> None:
  print("\n\nYou will need the password for the Ansible Vault storing the encryption keys.")
  print("This password can be found here:")
  print("\nhttps://start.1password.com/open/i?a=3ZSXL3IG55ER5E467CLRTXXE4U&h=msfocb.1password.eu&i=3zol6ujo4xg7vcxp5sxxt5mjpa&v=xsnpr3xpsu3x433llrascuqj4e\n")


def get_ansible_passwd(args_passwd: str) -> str:
  if not args_passwd:
    print_vault_banner()
    return getpass("Vault password: ")
  return args_passwd


def get_vaultlib(passwd: str) -> VaultLib:
  return VaultLib([(DEFAULT_VAULT_ID_MATCH, VaultSecret(passwd.encode(UTF8)))])


def read_vault_file(passwd: str,
                    vault_file: str) -> Mapping:
  vault = get_vaultlib(passwd)
  if os.path.isfile(vault_file):
    with open(vault_file, 'r') as f:
      return yaml.safe_load(vault.decrypt(f.read(), filename=vault_file)) # type: ignore
  else:
      raise FileNotFoundError(f'Ansible Vault file ({vault_file}): no such file!')


def write_vault_file(passwd: str,
                     vault_file: str,
                     content: Mapping) -> None:
  vault = get_vaultlib(passwd)
  encrypted_content = vault.encrypt(yaml.safe_dump(content))
  with open(vault_file, 'wb+') as f:
    f.write(encrypted_content)

