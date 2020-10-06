#! /usr/bin/env python3

import argparse
import glob
import json
import os
import shutil
import subprocess
import tempfile

from subprocess import PIPE

def args_parser():
  parser = argparse.ArgumentParser(description='Build all NixOS configs.')
  parser.add_argument('--group_amount', type = int, dest = 'group_amount', required = True)
  parser.add_argument('--group_id',     type = int, dest = 'group_id',     required = True)
  parser.add_argument('--host_dir',     type = str, dest = 'host_dir',     required = False,
                      default = os.path.join('.', 'ocb-config', 'hosts'))
  return parser

def validate_json(build_dir):
  def has_duplicates(l):
    seen = set()
    for e in l:
      key = e[0]
      if key in seen:
        return key
      else:
        seen |= { key }
    return None

  def no_duplicates(filename):
    def check_duplicates(l):
      duplicate_key = has_duplicates(l)
      if duplicate_key:
        raise ValueError(f"Duplicate JSON key ({duplicate_key}) in {filename}.")
    return check_duplicates

  for root, _, files in os.walk(build_dir):
    for f in files:
      filename = os.path.join(root, f)
      if filename.endswith('json'):
        with open(filename, 'r') as fp:
          json.load(fp, object_pairs_hook = no_duplicates(filename))

def init_tree(build_dir):
  if os.path.isdir(build_dir):
    shutil.rmtree(build_dir)
  shutil.copytree(os.getcwd(), build_dir,
                  symlinks = True,
                  ignore = shutil.ignore_patterns('.git', 'result', 'id_tunnel', 'settings.nix'))
  with open(os.path.join(build_dir, 'hardware-configuration.nix'), 'w') as fp:
    fp.write('{}')
  with open(os.path.join(build_dir, 'local', 'id_tunnel'), 'w') as _:
    pass

def prepare_tree(build_dir, config_name):
  settings_path = os.path.join(build_dir, 'settings.nix')
  if os.path.exists(settings_path):
    os.unlink(settings_path)
  os.symlink(os.path.join(build_dir, 'ocb-config', 'hosts', config_name),
             settings_path)

def build_config(build_dir, hostname):
  print(f'Building config: {hostname}')
  config_name = os.path.basename(hostname)
  prepare_tree(build_dir, config_name)
  return subprocess.run([ 'nix-build',
                          '<nixpkgs/nixos>',
                          '-I', f'nixos-config={build_dir}/configuration.nix',
                          '-A', 'system' ],
                        stdout = PIPE, stderr = PIPE)

def do_build_configs(build_dir, configs):
  init_tree(build_dir)
  validate_json(build_dir)
  for config in configs:
    proc = build_config(build_dir, config)
    print(proc.stderr.decode())
    print(proc.stdout.decode())
    proc.check_returncode()

def build_configs(build_dir, group_amount, group_id):
  configs = sorted(glob.glob('./ocb-config/hosts/*.nix'))
  length = len(configs)

  slice_size = length // group_amount
  modulo = length % group_amount
  begin  = group_id * slice_size + min(group_id, modulo)
  size   = slice_size + (1 if (group_id < modulo) else 0)
  end    = begin + size

  print(f"Found {length} configs, {group_amount} builders, building group ID {group_id}, starting at {begin}, building {size} configs.")
  print(f"Configs to build: {configs[begin:end]}")

  do_build_configs(build_dir, configs[begin:end])

def validate_args(args):
  if args.group_amount < 1:
    raise ValueError(f"The group amount ({args.group_amount}) should be at least 1.")
  if args.group_id > args.group_amount:
    raise ValueError(f"The build group ID ({args.group_id}) cannot exceed the number of build groups ({args.group_amount}).")
  if args.group_id < 0:
    raise ValueError(f"The build group ID ({args.group_id}) cannot be less than zero.")
  return args

def main():
  args = validate_args(args_parser().parse_args())
  build_dir = os.path.join(tempfile.gettempdir(), 'nix_config_build')
  build_configs(build_dir, args.group_amount, args.group_id)

if __name__ == '__main__':
  main()

