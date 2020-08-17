#! /usr/bin/env python3

import argparse
import json
import os
import requests

from itertools import chain
from operator  import attrgetter

def args_parser():
  parser = argparse.ArgumentParser(description='Manage the SSH keys for the NixOS GitHub account.')
  parser.add_argument('--api_token', dest = 'api_token', required = True, type = str)
  parser.add_argument('--dry_run',   dest = 'dry_run',   required = False, action = 'store_true')
  return parser

def headers(api_token):
  return {
    'Accept': 'application/vnd.github.v3+json',
    'Authorization': f'token {api_token}'
  }

def getKeysFromGithub(session, api_token):

  def parseResponse(response):
    return dict([ (k['title'], {'key': k['key'], 'key_id': k['id']})
                  for k in response ])

  def doGetKeys(url):
    response = session.get(url, headers=headers(api_token))
    if 'next' in response.links:
      return chain(response.json(), doGetKeys(response.links['next']['url']))
    else:
      return response.json()

  url = f"https://api.github.com/user/keys"
  return parseResponse(doGetKeys(url))

def printResponse(response):
  print(response.status_code)
  print(response.text)
  return response

def deleteKeyFromGithub(session, api_token, title, key_id, dry_run):
  print(f"Deleting deploy key with title {title} and id {key_id} from GitHub...")
  url = f"https://api.github.com/user/keys/{key_id}"
  if not dry_run:
    return printResponse(session.delete(url, headers=headers(api_token)))

def addKeyToGithub(session, api_token, title, key, dry_run):
  print(f"Adding deploy key with title {title} to GitHub...")
  url = f"https://api.github.com/user/keys"
  data = {
    'title': title,
    'key': key,
#    'read_only': True
  }
  print(data)
  if not dry_run:
    return printResponse(session.post(url,
                                      headers=headers(api_token),
                                      data=json.dumps(data)))

def getKeysFromConfig():
  nixos_hosts = os.listdir(os.path.join(os.getcwd(), 'org-spec', 'hosts'))

  with open(os.path.join(os.getcwd(), 'org-spec', 'json', 'tunnels.json'), 'r') as f:
    tunnel_data = json.load(f)

  return dict([ (k, {'key': v['public_key']})
                for (k,v) in tunnel_data['tunnels']['per-host'].items()
                if f"{k}.nix" in nixos_hosts ])

def main():
  args = args_parser().parse_args()
  session = requests.Session()

  gh_key_records  = getKeysFromGithub(session, args.api_token)
  cfg_key_records = getKeysFromConfig()
  gh_titles  = set(gh_key_records.keys())
  cfg_titles = set(cfg_key_records.keys())

  to_remove = gh_titles.difference(cfg_titles)
  to_add    = cfg_titles.difference(gh_titles)
  to_change = { title for title in gh_titles.intersection(cfg_titles)
                      if gh_key_records[title]['key'] != cfg_key_records[title]['key'] }

  for title in sorted(chain(to_remove, to_change)):
    response = deleteKeyFromGithub(session,
                                   args.api_token,
                                   title,
                                   gh_key_records[title]['key_id'],
                                   args.dry_run)

  for title in sorted(chain(to_add, to_change)):
    response = addKeyToGithub(session,
                              args.api_token,
                              title,
                              cfg_key_records[title]['key'],
                              args.dry_run)

if __name__ == '__main__':
  main()

