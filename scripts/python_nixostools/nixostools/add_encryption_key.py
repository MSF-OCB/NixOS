#! /usr/bin/env nix-shell
#! nix-shell -i python3 ../shell.nix

import argparse
import secrets

from nixostools import ansible_vault_lib

from nixostools.secret_lib import SECRETS_KEY, \
                                  SERVERS_KEY, \
                                  PATH_KEY, \
                                  CONTENT_KEY


def args_parser() -> argparse.ArgumentParser:
  parser = argparse.ArgumentParser()
  parser.add_argument("--hostname", dest="hostname", required=True, type=str)
  parser.add_argument("--secrets_file", dest="secrets_file", required=True, type=str,
                      help="path to the file where we should store the generated encryption keys")
  parser.add_argument("--ansible_vault_passwd", dest="ansible_vault_passwd", required=False, type=str,
                      help="the ansible-vault password, if empty the script will ask for the password")
  return parser


def print_vault_banner() -> None:
  print("\n\nYou will need the key for the Ansible Vault storing the encryption keys.")
  print("This key can be found here:")
  print("\nhttps://start.1password.com/open/i?a=3ZSXL3IG55ER5E467CLRTXXE4U&h=msfocb.1password.eu&i=3zol6ujo4xg7vcxp5sxxt5mjpa&v=xsnpr3xpsu3x433llrascuqj4e\n")


def main() -> None:
  args = args_parser().parse_args()

  print_vault_banner()
  ansible_vault_passwd = ansible_vault_lib.get_ansible_passwd(args.ansible_vault_passwd)

  try:
    data = ansible_vault_lib.read_vault_file(ansible_vault_passwd,
                                             args.secrets_file)
  except FileNotFoundError:
    data = { SECRETS_KEY: {} }

  data[SECRETS_KEY][f'{args.hostname}-encryption-key'] = {
    PATH_KEY: "keyfile",
    CONTENT_KEY: secrets.token_hex(64),
    SERVERS_KEY: [ args.hostname ]
  }

  ansible_vault_lib.write_vault_file(ansible_vault_passwd,
                                     args.secrets_file,
                                     data)


if __name__ == "__main__":
  main()

