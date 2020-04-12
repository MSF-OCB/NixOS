#! /usr/bin/env python

import argparse
import json
import re
import yaml

from functools import reduce
from itertools import chain

def flatmap(f, items):
  return chain.from_iterable(map(f, items))

def configure_yaml():
  yaml.SafeDumper.add_representer(
    type(None),
    lambda dumper, value: dumper.represent_scalar(u'tag:yaml.org,2002:null', '')
  )

def args_parser():
  parser = argparse.ArgumentParser()
  parser.add_argument('--eventlog', type=str, required=True, dest='event_log')
  parser.add_argument('--keyfile',  type=str, required=True, dest='key_file')
  parser.add_argument('--timeout',  type=int, required=True, dest='time_out')
  return parser

def get_ports(regex, commit_message):
  ms = regex.finditer(commit_message)
  # Group 0 is the full matched expression, group 1 is the first subgroup
  return map(lambda m: m.group(1), ms)

def ports(event_log):
  with open(event_log, 'r') as f:
    data = json.load(f)
  regex = re.compile(r'\(x-nixos:rebuild:relay_port:([1-9][0-9]*)\)')
  return removeNone(flatmap(lambda c: get_ports(regex, c["message"]),
                            data["commits"]))

def removeNone(xs):
  return filter(lambda x: x, xs)

def inventory_definition(tunnel_ports):
  return reduce(lambda d, p: { **d, f"tunnelled_{p}": { "ansible_port": p } },
                tunnel_ports, dict())

def inventory(tunnel_ports, key_file, time_out):
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
            "ansible_ssh_common_args": f"-o 'ProxyCommand=ssh -W %h:%p -i {key_file} -p 22 -o ConnectTimeout={time_out} tunneller@sshrelay2.msf.be'"
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
  #print(json.dumps(inventory(ports(args.event_log), args.key_file, args.time_out), indent=2))
  print(yaml.safe_dump(inventory(ports(args.event_log), args.key_file, args.time_out),
                       default_flow_style=False, width=120, indent=2))

if __name__ == "__main__":
  go()

