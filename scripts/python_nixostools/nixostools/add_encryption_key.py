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


def main() -> None:
  args = args_parser().parse_args()

  print(f"Generating encryption key for {args.hostname}...")

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

  print(f"Encryption key for {args.hostname} successfully generated.")


if __name__ == "__main__":
  main()

