#! /usr/bin/env nix-shell
#! nix-shell -i python3 ../shell.nix

# ---- Import needed modules ----
import argparse
import collections
import dataclasses
import glob
import itertools
import json
import os
import traceback
import yaml

from base64      import b64decode
from dataclasses import dataclass
from functools   import reduce
from getpass     import getpass
from textwrap    import wrap
from typing      import Any, Dict, Iterable, List, Mapping
from nacl.public import PublicKey # type: ignore

from nixostools import ansible_vault_lib, secret_lib

from nixostools.secret_lib import OPENSSH_PUBLIC_KEY_STRING_LENGTH, \
                                  OPENSSH_PUBLIC_KEY_SIGNATURE, \
                                  PUBLIC_KEY_LENGTH, \
                                  SECRETS_KEY, \
                                  SERVERS_KEY, \
                                  PATH_KEY, \
                                  CONTENT_KEY, \
                                  UTF8


@dataclass(frozen=True)
class ServerSecretData:
  server_name: str
  secrets: Mapping

  def str_secrets(self) -> str:
    return yaml.safe_dump(self.secrets) # type: ignore

@dataclass(frozen=True)
class PaddedServerSecretData:
  server_name: str
  padded_secrets: str

@dataclass(frozen=True)
class EncryptedSecrets:
  server_name: str
  encrypted_key: str
  encrypted_secrets: str


def args_parser() -> argparse.ArgumentParser:
  parser = argparse.ArgumentParser()
  parser.add_argument("--output_path", dest="output_path", required=True, type=str,
                      help="path to the folder where we should store the generated encrypted files")
  parser.add_argument("--ansible_vault_passwd", dest="ansible_vault_passwd", required=False, type=str,
                      help="the ansible-vault password, if empty the script will ask for the password")
  parser.add_argument("--secrets_directory", dest="secrets_directory", required=True, type=str,
                      help="The directory containing the *-secrets.yml files, encrypted with Ansible Vault")
  parser.add_argument("--public_keys_file", dest="public_keys_file", required=True, type=str,
                      help="The JSON file containing the server public keys")
  return parser


def get_secrets(secrets) -> Iterable[ServerSecretData]:
  def validate_secret(secret_name: str, secret: Any) -> Mapping:
    if not (isinstance(secret, Mapping) and
            secret.get(PATH_KEY) and
            secret.get(CONTENT_KEY) and
            secret.get(SERVERS_KEY)):
      raise Exception(f'The secret {secret_name} should be a mapping containing ' +
                      f'the mandatory fields "{PATH_KEY}", "{CONTENT_KEY}" and "{SERVERS_KEY}".')
    return secret

  def filter_secret(secret: Mapping) -> Mapping:
    def filter_keys(item):
      key = item[0]
      return key in [ PATH_KEY, CONTENT_KEY ]

    return dict(filter(filter_keys, secret.items()))

  # Build a mapping from every server to its secrets
  def reducer(server_dict: Mapping[str, ServerSecretData],
              secret_item) -> Mapping[str, ServerSecretData]:
    (secret_name, secret) = secret_item
    validate_secret(secret_name, secret)
    out = { **server_dict }
    for server in secret.get(SERVERS_KEY, []):
      existing_secrets = out[server].secrets if server in out else {}
      out[server] = ServerSecretData(server_name = server,
                                     secrets = { **existing_secrets,
                                                 secret_name: filter_secret(secret)})
    return out

  init: Mapping[str, ServerSecretData] = {}
  return reduce(reducer, secrets[SECRETS_KEY].items(), init).values()


def encrypt_data(data: PaddedServerSecretData,
                 pubkey: PublicKey) -> EncryptedSecrets:
  # Encrypt the secrets with a new key generated on the fly.
  # Only short, random data should ever by encrypted with a public key.
  new_key = secret_lib.generate_symmetric_key()
  encrypted_secrets = secret_lib.encrypt_symmetric_string(new_key,
                                                          data.padded_secrets)

  # Encrypt the newly generated key using the server's public key.
  encrypted_key = secret_lib.encrypt_asymmetric(pubkey, new_key)

  return EncryptedSecrets(server_name = data.server_name,
                          encrypted_key = encrypted_key,
                          encrypted_secrets = encrypted_secrets)


# The only information still communicated by the ciphertext,
# is the length of the original plaintext.
# In order to hide the relative amount of secrets accessible by every server,
# we padd the plaintexts with newlines such that they all have equal length.
# It is important to look at the length in bytes, rather than
# the length in characters, to account for variable-width encoding.
def pad_secrets(data: Iterable[ServerSecretData]) -> Iterable[PaddedServerSecretData]:
  def reducer(length: int, data: ServerSecretData) -> int:
    return max(length, len(data.str_secrets().encode(UTF8)))

  max_len = reduce(reducer, data, 0)

  pad = lambda secrets: secrets.ljust(max_len, '\n')
  return [ PaddedServerSecretData(server_name = secret_data.server_name,
                                  padded_secrets = pad(secret_data.str_secrets()))
           for secret_data in data ]


def write_secrets(encrypted_secrets: EncryptedSecrets,
                  output_path: str) -> bool:
  server_name = encrypted_secrets.server_name
  content = dataclasses.asdict(encrypted_secrets)
  try:
    # write the encrypted secrets yml in [servername]-secrets.yml
    with open(os.path.join(output_path, f'{server_name}-secrets.yml'), 'w') as f:
      yaml.safe_dump(content, f, default_style='|')
  except:
    print(f'ERROR : failed to write file for {server_name}')
    print(traceback.format_exc())
    return False
  print(f'Wrote secrets for {server_name}')
  return True


def read_secrets_files(secrets_files: Iterable[str], ansible_passwd: str) -> Mapping:
  def reducer(secrets_data: Mapping, secrets_file: str) -> Mapping:
    print(f"Parsing {secrets_file}...")
    new_secrets = ansible_vault_lib.read_vault_file(ansible_passwd, secrets_file)

    # If we detect a duplicate secret, we run our more expensive method to list all duplicates
    if set(secrets_data.get(SECRETS_KEY, {}).keys()).intersection(
            set(new_secrets.get(SECRETS_KEY, {}).keys())):
      check_duplicate_secrets(secrets_files, ansible_passwd)
      raise AssertionError("Duplicate secrets found, see above.")

    return deep_merge(secrets_data, new_secrets)

  return reduce(reducer, secrets_files, {})


def deep_merge(d1: Mapping, d2: Mapping) -> Mapping:
  out: Dict = {}

  for key in set(d1.keys()).union(set(d2.keys())):
    if key in d1 and key in d2 and not (isinstance(d1[key], type(d2[key])) or isinstance(d2[key], type(d1[key]))):
      raise AssertionError(f"The types of the values for key '{key}' are not the same!")

    # If the key is only present in one of the mappings, we use that value
    if not (key in d1 and key in d2):
      out[key] = d1.get(key, None) or d2.get(key, None)
    # Otherwise, if the key maps to a mapping, we merge those mappings
    elif isinstance(d1.get(key, None) or d2.get(key, None), Mapping):
      out[key] = deep_merge(d1.get(key, {}), d2.get(key, {}))
    # Otherwise, if the key maps to a list, we concat the lists
    # (careful, str is a subset of Iterable!)
    elif isinstance(d1.get(key, None) or d2.get(key, None), List):
      out[key] = d1.get(key, []) + d2.get(key, [])
    # If the key is present in both, but is twice None, then we can merge to None
    elif d1.get(key, None) is None and d2.get(key, None) is None:
      out[key] = None
    # In other cases, we do not know what to do...
    else:
      raise ValueError(f"Unmergeable type found during merge, key: '{key}', " +
                       f"type: '{type(d1.get(key, None) or d2.get(key, None))}'")

  return out


def check_duplicate_secrets(secrets_files: Iterable[str], ansible_passwd: str) -> None:
  print(f"Finding duplicates...")
  def reducer(secrets_data: Mapping, secrets_file: str) -> Mapping:
    new_secrets = ansible_vault_lib.read_vault_file(ansible_passwd, secrets_file)

    # Make a mapping of every secret to the files defining a secret with that name
    secrets = { **secrets_data }
    for secret in new_secrets.get(SECRETS_KEY, {}).keys():
      if not secret in secrets:
        secrets[secret] = []
      secrets[secret] = itertools.chain(secrets[secret], [secrets_file])

    return secrets

  secret: str
  files: Iterable[str]
  init: Mapping = {}
  for (secret, files) in reduce(reducer, secrets_files, init).items():
    if len(list(files)) > 1:
      print(f"ERROR: secret with name '{secret}' is defined in multiple files: {', '.join(files)}")


def main() -> None:
  args = args_parser().parse_args()

  # First, we fetch and load the secrets data
  secrets_files = glob.glob(os.path.join(args.secrets_directory, '*-secrets.yml'))
  secrets_dict = read_secrets_files(secrets_files,
                                    ansible_vault_lib.get_ansible_passwd(args.ansible_vault_passwd))

  # We'll also want to get the server public keys found in json/tunnels.json,
  with open(args.public_keys_file, 'r') as f:
    tunnels_json = json.load(f)

  secrets = get_secrets(secrets_dict)
  padded_secrets = pad_secrets(secrets)

  encrypted_data = [ encrypt_data(secrets,
                                  secret_lib.extract_public_key(tunnels_json,
                                                                secrets.server_name,
                                                                args.public_keys_file))
                     for secrets in padded_secrets ]

  for encrypted_secrets in encrypted_data:
    write_secrets(encrypted_secrets, args.output_path)


if __name__ == "__main__":
  main()

