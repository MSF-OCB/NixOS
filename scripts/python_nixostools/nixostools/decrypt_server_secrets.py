#! /usr/bin/env nix-shell
#! nix-shell -i python3 ../shell.nix

import argparse
import os
import traceback
import yaml

from base64 import b64decode

from typing import Any, Mapping

from nixostools import secret_lib
from nixostools.secret_lib import OPENSSH_PRIVATE_KEY_SIGNATURE, \
                                  PRIVATE_KEY_LENGTH, \
                                  GENERATED_SECRETS_FILENAME


def args_parser() -> argparse.ArgumentParser:
  parser = argparse.ArgumentParser()
  parser.add_argument("--server_name", type=str, required=True, dest='server_name',
                      help="name of the server we are running this script on")
  parser.add_argument("--secrets_path", type=str, required=True, dest='secrets_path',
                      help="path to the folder where we should look for the generated secrets")
  parser.add_argument("--output_path", type=str, required=True, dest='output_path',
                      help="path to the folder where we should output the secrets to")
  parser.add_argument("--private_key_file", type=str, required=True, dest='private_key_file',
                      help="private key file of the server")
  return parser


def do_write_file(output_path: str,
                  secret: Mapping):
  with open(output_path, 'w') as f:
    f.write(secret['content'])
    print(f"wrote {output_path}")


def write_files(output_path_prefix: str,
                secrets: Mapping):
  for secret in secrets.values():
    output_path = os.path.join(output_path_prefix, secret['path'])
    try:
      do_write_file(output_path, secret)
    except:
      print(f"ERROR : failed to write to {secret['path']}")
      print(traceback.format_exc())


def validate_paths(private_key_file, secrets_path, output_path):
  if not os.path.isfile(private_key_file):
    raise Exception(f'Cannot open the private key file ({private_key_file})')
  if not os.path.isdir(secrets_path):
    raise Exception(f'The secrets path is not a directory ({secrets_path})')
  if not os.path.isdir(output_path):
    raise Exception(f'The output path is not a directory ({output_path})')


def main():
  args = args_parser().parse_args()
  validate_paths(args.private_key_file, args.secrets_path, args.output_path)

  secrets_file = os.path.join(args.secrets_path,
                              GENERATED_SECRETS_FILENAME)

  if os.path.isfile(secrets_file):
    with open(args.private_key_file, 'r') as f :
      server_privk = f.read()
    with open(secrets_file, 'r') as f:
      all_secrets = yaml.safe_load(f)

    if all_secrets[args.server_name]:
      secrets_data = all_secrets[args.server_name]

      if not secrets_data['server_name'] == args.server_name:
        raise Exception(f'The given server name "{args.server_name}" ' +
                         'does not correspond to the one found ' +
                         '"{secrets_data["server_name"]}".')

      # decrypt the symmetric key using the server private key
      key = secret_lib.decrypt_asymmetric(secret_lib.extract_curve_private_key(server_privk),
                                        secrets_data['encrypted_key'])
      # then use it to decrypt the secrets
      decrypted_secrets = yaml.safe_load(
        secret_lib.decrypt_symmetric(key,
                                     secrets_data['encrypted_secrets']))
      write_files(args.output_path, decrypted_secrets)


if __name__ == "__main__":
  main()

