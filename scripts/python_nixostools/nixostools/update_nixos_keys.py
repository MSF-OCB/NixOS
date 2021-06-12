#! /usr/bin/env nix-shell
#! nix-shell -i python3 ../shell.nix

import argparse
import json
import os
import requests

from itertools import chain
from typing    import Iterable, Mapping


def args_parser() -> argparse.ArgumentParser:
  parser = argparse.ArgumentParser(description='Manage the SSH keys for the NixOS GitHub account.')
  parser.add_argument('--api_token', dest = 'api_token', required = True, type = str)
  parser.add_argument('--dry_run',   dest = 'dry_run',   required = False, action = 'store_true')
  parser.add_argument('--nixos_config_dir', dest = 'nixos_config_dir', required = False, default = os.getcwd())
  return parser


def headers(api_token: str) -> Mapping:
  return {
    'Accept': 'application/vnd.github.v3+json',
    'Authorization': f"token {api_token}"
  }


def get_keys_from_github(session: requests.Session, api_token: str) -> Mapping:

  def parse_response(response: Iterable) -> Mapping:
    return { key['title']: {'key': key['key'], 'key_id': key['id']}
             for key in response }

  def do_get_keys(url: str) -> Iterable:
    response = check_response(session.get(url, headers=headers(api_token)))
    if 'next' in response.links:
      return chain(response.json(), do_get_keys(response.links['next']['url']))
    else:
      return response.json() # type: ignore

  url = f"https://api.github.com/user/keys"
  response = parse_response(do_get_keys(url))
  print(f"Loaded {len(response.keys())} keys from GitHub")
  return response


def check_response(response: requests.Response) -> requests.Response:
  response.raise_for_status()
  return response


def print_response(response: requests.Response) -> requests.Response:
  print(f'{response.status_code} {response.reason}')
  print(response.text)
  return check_response(response)


def delete_key_from_github(session: requests.Session,
                           api_token: str,
                           title: str,
                           key_id: str,
                           dry_run: bool) -> None:
  print(f"Deleting key with title {title} and id {key_id} from GitHub...")
  url = f"https://api.github.com/user/keys/{key_id}"
  if not dry_run:
    print_response(session.delete(url, headers=headers(api_token)))


def add_key_to_github(session: requests.Session,
                      api_token: str,
                      title: str,
                      key: str,
                      dry_run: bool) -> None:
  print(f"Adding key with title {title} to GitHub...")
  url = "https://api.github.com/user/keys"
  data = {
    'title': title,
    'key': key,
  }
  print(data)
  if not dry_run:
    print_response(session.post(url,
                                headers=headers(api_token),
                                data=json.dumps(data)))


def get_keys_from_config(config_dir: str) -> Mapping:
  nixos_hosts = os.listdir(os.path.join(config_dir, 'hosts'))

  def isElligible(host, tunnel_conf):
    if f"{host}.nix" in nixos_hosts and tunnel_conf['public_key']:
      return True
    else:
      print(f"Ignoring host {host}, its configuration is not elligible")
      return False

  with open(os.path.join(config_dir, 'json', 'tunnels.json'), 'r') as f:
    tunnel_data = json.load(f)

  tunnel_confs = tunnel_data['tunnels']['per-host']
  response = { host: {'key': tunnel_conf['public_key']}
               for (host, tunnel_conf) in tunnel_confs.items()
               if isElligible(host, tunnel_conf) }

  print(f"Loaded {len(response.keys())} keys from the local config")
  return response


def main() -> None:
  args = args_parser().parse_args()
  session = requests.Session()

  gh_key_records  = get_keys_from_github(session, args.api_token)
  cfg_key_records = get_keys_from_config(args.nixos_config_dir)
  gh_titles  = set(gh_key_records.keys())
  cfg_titles = set(cfg_key_records.keys())

  to_remove = gh_titles.difference(cfg_titles)
  to_add    = cfg_titles.difference(gh_titles)
  to_change = { title for title in gh_titles.intersection(cfg_titles)
                      if gh_key_records[title]['key'] != cfg_key_records[title]['key'] }

  for title in sorted(chain(to_remove, to_change)):
    delete_key_from_github(session,
                           args.api_token,
                           title,
                           gh_key_records[title]['key_id'],
                           args.dry_run)

  for title in sorted(chain(to_add, to_change)):
    add_key_to_github(session,
                      args.api_token,
                      title,
                      cfg_key_records[title]['key'],
                      args.dry_run)


if __name__ == '__main__':
  main()

