#! /usr/bin/env python

import argparse
import json
import re
import yaml

from functools import reduce

def configure_yaml():
  yaml.SafeDumper.add_representer(
    type(None),
    lambda dumper, value: dumper.represent_scalar(u'tag:yaml.org,2002:null', '')
  )

def args_parser():
  parser = argparse.ArgumentParser()
  parser.add_argument('--eventlog', type=str, required=True, dest='event_log')
  return parser

def get_port(commit_message):
  p = re.compile(r'\(x-nixos:rebuild:relay_port:([1-9][0-9]*)\)')
  m = p.search(commit_message)
  if m:
    # Group 0 is the full matched expression, group 1 is the first subgroup
    return m.group(1)
  return None

def ports(event_log):
  with open(event_log, 'r') as f:
    data = json.load(f)
  return removeNone(map(lambda c: get_port(c["message"]), data["commits"]))

def removeNone(xs):
  return filter(lambda x: x, xs)

def inventory_definition(tunnel_ports):
  return reduce(lambda d, p: { **d, f"tunnelled_{p}": { "ansible_port": p } }, tunnel_ports, dict())

def inventory(tunnel_ports):
  return {
    "all": {
      "children": {
        "relays": {
          "hosts": {
            "sshrelay1.msf.be": None,
            "sshrelay2.msf.be": None
          }
        },
        "tunnelled": {
          "hosts": inventory_definition(tunnel_ports),
          "vars": {
            "ansible_host": "localhost",
            "ansible_ssh_common_args": "-o 'ProxyCommand=ssh -W %h:%p -i /root/.id_ec -p 433 tunneller@sshrelay2.msf.be'"
          }
        }
      },
      "vars": {
        "ansible_user": "robot"
      }
    }
  }

def go():
  configure_yaml()
  args = args_parser().parse_args()

  print(yaml.safe_dump(inventory(ports(args.event_log)), default_flow_style=False, width=120, indent=2))

if __name__ == "__main__":
  go()
