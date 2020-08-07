#! /usr/bin/env python3

import argparse
import glob
import itertools
import os
import shutil
import subprocess
import tempfile

def args_parser():
  parser = argparse.ArgumentParser(description='Disable the encryption key')
  parser.add_argument('--group_amount', type = int, dest = 'group_amount', required = True)
  parser.add_argument('--group_id',     type = int, dest = 'group_id',     required = True)
  parser.add_argument('--host_dir',     type = str, dest = 'host_dir',     required = False,
                      default = os.path.join('.', 'org-spec', 'hosts'))
  return parser

def init_tree(build_dir):
  shutil.copytree(os.getcwd(), build_dir,
                  symlinks = True,
                  ignore = shutil.ignore_patterns('.git', 'result', 'id_tunnel', 'settings.nix'))
  with open(os.path.join(build_dir, 'hardware-configuration.nix'), 'w') as fp:
    fp.write('{}')
  with open(os.path.join(build_dir, 'local', 'id_tunnel'), 'w') as fp:
    pass

def prepare_tree(build_dir, config_name):
  settings_path = os.path.join(build_dir, 'settings.nix')
  if os.path.exists(settings_path):
    os.unlink(settings_path)
  os.symlink(os.path.join(build_dir, 'org-spec', 'hosts', config_name),
             settings_path)

def build_config(build_dir, hostname):
  print(f'Building config: {hostname}')
  config_name = os.path.basename(hostname)
  prepare_tree(build_dir, config_name)
  return subprocess.run([ 'nix-build',
                          '<nixpkgs/nixos>',
                          '-I', f'nixos-config={build_dir}/configuration.nix',
                          '-A', 'system' ],
                        capture_output = True)

def do_build_configs(build_dir, configs):
  init_tree(build_dir)
  for config in configs:
    p = build_config(build_dir, config)
    print(p.stderr.decode())
    print(p.stdout.decode())
    p.check_returncode()

def build_configs(build_dir, group_amount, group_id):
  if group_id > group_amount:
    raise ValueError(f"The build group ID ({group_id}) cannot exceed the number of build groups ({group_amount}).")
  if group_id < 0:
    raise ValueError(f"The build group ID ({group_id}) cannot be less than or equal to zero.")

  configs = sorted(glob.glob('./org-spec/hosts/*.nix'))
  length = len(configs)

  slice_size = length // group_amount
  modulo = length % group_amount
  begin  = group_id * slice_size + min(group_id, modulo)
  size   = slice_size + (1 if (group_id < modulo) else 0)
  end    = begin + size

  print(f"Found {length} configs, {group_amount} builders, building group ID {group_id}, starting at {begin}, building {size} configs.")
  print(f"Configs to build: {configs[begin:end]}")

  do_build_configs(build_dir, configs[begin:end])

def main():
  build_dir = os.path.join(tempfile.gettempdir(), 'nix_config_build')
  if os.path.isdir(build_dir):
    shutil.rmtree(build_dir)
  args = args_parser().parse_args()
  build_configs(build_dir, args.group_amount, args.group_id)

if __name__ == '__main__':
  main()

