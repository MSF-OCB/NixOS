
import yaml

from typing import Mapping

from ansible.constants     import DEFAULT_VAULT_ID_MATCH # type: ignore
from ansible.parsing.vault import VaultLib, VaultSecret  # type: ignore

from getpass import getpass


UTF8 = "utf-8"


def get_ansible_passwd(args_passwd: str) -> str:
  if not args_passwd:
    return getpass("Vault password: ")
  return args_passwd


def read_vault_file(passwd: str,
                    vault_file: str) -> Mapping:
  vault = VaultLib([(DEFAULT_VAULT_ID_MATCH, VaultSecret(passwd.encode(UTF8)))])
  with open(vault_file, 'r') as f:
    return yaml.safe_load(vault.decrypt(f.read())) # type: ignore


