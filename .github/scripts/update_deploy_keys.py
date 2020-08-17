#! /usr/bin/env python3

import json
import os
import requests

from itertools import chain

api_token = '37361ca60d0ecd16248755ed5755d0b2227540eb'
repo_owner = 'msf-ocb'
repo = 'nixos-ocb'

def headers():
  return {
    'Accept': 'application/vnd.github.v3+json',
    'Authorization': f'token {api_token}'
  }

def getKeysFromGithub(session):

  def parseResponse(response):
    return dict([ (k['title'], {'key': k['key'], 'key_id': k['id']})
                  for k in response ])

  def doGetKeys(session, url):
    response = session.get(url, headers=headers())
    if 'next' in response.links:
      return chain(response.json(), doGetKeys(session, response.links['next']['url']))
    else:
      return response.json()

  url = f"https://api.github.com/repos/{repo_owner}/{repo}/keys"
  return parseResponse(doGetKeys(session, url))

def printResponse(response):
  print(response.status_code)
  print(response.json())
  return response

def deleteKeyFromGithub(session, key_id):
  print(f"Deleting deploy key with id {key_id} from GitHub...")
  url = f"https://api.github.com/repos/{repo_owner}/{repo}/keys/{key_id}"
  return printResponse(session.delete(url, headers=headers()))

def addKeyToGithub(session, host, key):
  print(f"Adding deploy key for host {host} to GitHub...")
  url = f"https://api.github.com/repos/{repo_owner}/{repo}/keys"
  data = {
    'title': host,
    'key': key,
    'read_only': True
  }
  print(data)
  return printResponse(session.post(url, headers=headers(), data=json.dumps(data)))

def getKeysFromConfig():
  nixos_hosts = os.listdir(os.path.join(os.getcwd(), 'org-spec', 'hosts'))

  with open(os.path.join(os.getcwd(), 'org-spec', 'json', 'tunnels.json'), 'r') as f:
    tunnel_data = json.load(f)

  return dict([ (k, {'key': v['public_key']})
                for (k,v) in tunnel_data['tunnels']['per-host'].items()
                if f"{k}.nix" in nixos_hosts ])

def main():
  session = requests.Session()

  gh_key_records  = getKeysFromGithub(session)
  cfg_key_records = getKeysFromConfig()
  gh_hosts  = set(gh_key_records.keys())
  cfg_hosts = set(cfg_key_records.keys())

  print(gh_key_records)

  to_remove = gh_hosts.difference(cfg_hosts)
  to_add    = cfg_hosts.difference(gh_hosts)
  to_change = { host for host in gh_hosts.intersection(cfg_hosts)
                     if gh_key_records[host]['key'] != cfg_key_records[host]['key'] }

  for host in chain(to_remove, to_change):
    response = deleteKeyFromGithub(session, gh_key_records[host]['key_id'])

  for host in chain(to_add, to_change):
    response = addKeyToGithub(session, host, cfg_key_records[host]['key'])

if __name__ == '__main__':
  main()

