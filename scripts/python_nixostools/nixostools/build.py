#! /usr/bin/env nix-shell
#! nix-shell -i python3 ../shell.nix

import argparse
import glob
import json
import os
import re
import shutil
import subprocess
import tempfile

from subprocess import PIPE
from typing import Iterable, Mapping


def args_parser() -> argparse.ArgumentParser:
  parser = argparse.ArgumentParser(description='Build all NixOS configs.')
  parser.add_argument('--group_amount', type = int, dest = 'group_amount', required = True)
  parser.add_argument('--group_id',     type = int, dest = 'group_id',     required = True)
  parser.add_argument('--host_dir',     type = str, dest = 'host_dir',     required = False,
                      default = os.path.join('.', 'org-config', 'hosts'))
  return parser


def validate_json(build_dir: str) -> None:
  def has_duplicates(kv_pairs: Iterable):
    seen = set()
    for kv in kv_pairs:
      key = kv[0]
      if key in seen:
        return key
      else:
        seen |= { key }
    return None

  def no_duplicates_hook(filename: str):
    def check_duplicates(kv_pairs) -> None:
      duplicate_key = has_duplicates(kv_pairs)
      if duplicate_key:
        raise ValueError(f"Duplicate JSON key ({duplicate_key}) in {filename}.")
    return check_duplicates

  for root, _, files in os.walk(build_dir):
    for f in files:
      filename = os.path.join(root, f)
      if filename.endswith('json'):
        with open(filename, 'r') as fp:
          json.load(fp, object_pairs_hook = no_duplicates_hook(filename))


def init_tree(build_dir: str) -> None:
  if os.path.isdir(build_dir):
    shutil.rmtree(build_dir)
  shutil.copytree(os.getcwd(), build_dir,
                  symlinks = True,
                  ignore = shutil.ignore_patterns('.git', 'result',
                                                  'id_tunnel', 'settings.nix'))
  # Create a minimal hardware-configuration.nix file
  with open(os.path.join(build_dir, 'hardware-configuration.nix'), 'w') as fp:
    fp.write('{}')
  # Create an empty key file
  with open(os.path.join(build_dir, 'local', 'id_tunnel'), 'w') as _:
    pass


def prepare_tree(build_dir: str, config_name: str) -> None:
  settings_path = os.path.join(build_dir, 'settings.nix')
  host_config_path = os.path.join(build_dir, 'org-config', 'hosts', config_name)
  if os.path.exists(settings_path):
    os.unlink(settings_path)
  os.symlink(host_config_path, settings_path)


ELM_ERROR_REGEX = re.compile(
  r"/build/frontend/elm-stuff/.*/d\.dat: openBinaryFile: resource busy \(file is locked\)",
  re.MULTILINE)

# The ELM compiler sometimes crashes due to a file being locked.
# We do not yet understand why this happens, but restarting the build
# seems to fix it...
def retry_if_elm_failed(proc, retry_routine):
  stderr = proc.stderr.decode() if proc.stderr else ""
  retry_needed = proc.returncode != 0 and \
                 ELM_ERROR_REGEX.search(stderr)
  return proc if not retry_needed else retry_routine()


def build_config(build_dir: str, hostname: str, retry: bool = False):
  if retry:
    print(f'Retry building config: {hostname}')
  else:
    print(f'Building config: {hostname}')
  config_name = os.path.basename(hostname)
  prepare_tree(build_dir, config_name)
  config_path = os.path.join(build_dir, 'configuration.nix')
  proc = subprocess.run([ 'nix-build',
                          '<nixpkgs/nixos>',
                          '-I', f'nixos-config={config_path}',
                          '-A', 'system' ],
                        stdout = PIPE, stderr = PIPE)
  print(proc.stderr.decode())
  print(proc.stdout.decode())

  retry_routine = lambda: build_config(build_dir, hostname, True)
  # If we are already retrying, we do not consider retrying again,
  # otherwise we run the routine to decide if we need to retry.
  return proc if retry else retry_if_elm_failed(proc, retry_routine)


def do_build_configs(build_dir: str, configs: Iterable) -> None:
  init_tree(build_dir)
  validate_json(build_dir)
  for config in configs:
    proc = build_config(build_dir, config)
    proc.check_returncode()


def build_configs(build_dir: str, group_amount: int, group_id: int) -> None:
  configs = sorted(glob.glob(os.path.join('.', 'org-config', 'hosts', '*.nix')))
  length = len(configs)

  # Let's imagine 10 configs, and 4 builders, in that case the slice_size is 10 / 4 = 2
  # and the module is 10 % 4 = 2. We thus need to add an additional config to the first
  # two groups, and not to the two following ones. The below formulas do exactly that:
  # 1: from 0 * 2 + min(0, 2) = 0, size 2 + 1 = 3 (because 0 <  2), so [0:3]  = [0, 1, 2]
  # 2: from 1 * 2 + min(1, 2) = 3, size 2 + 1 = 3 (because 1 <  2), so [3:6]  = [3, 4, 5]
  # 3: from 2 * 2 + min(2, 2) = 6, size 2 + 0 = 2 (because 2 >= 2), so [6:8]  = [6, 7]
  # 4: from 3 * 2 + min(3, 2) = 8, size 2 + 0 = 2 (because 3 >= 2), so [8:10] = [8, 9]
  slice_size = length // group_amount
  modulo = length % group_amount
  begin  = group_id * slice_size + min(group_id, modulo)
  size   = slice_size + (1 if (group_id < modulo) else 0)
  end    = begin + size

  print(f"Found {length} configs, {group_amount} builders, " + \
        f"building group ID {group_id}, starting at {begin}, building {size} configs.")
  print(f"Configs to build: {configs[begin:end]}")

  do_build_configs(build_dir, configs[begin:end])


def validate_args(args):
  if args.group_amount < 1:
    raise ValueError(f"The group amount ({args.group_amount}) should be at least 1.")
  if args.group_id > args.group_amount:
    raise ValueError(f"The build group ID ({args.group_id}) cannot exceed " + \
                     f"the number of build groups ({args.group_amount}).")
  if args.group_id < 0:
    raise ValueError(f"The build group ID ({args.group_id}) cannot be less than zero.")
  return args


def main():
  args = validate_args(args_parser().parse_args())
  build_dir = os.path.join(tempfile.gettempdir(), 'nix_config_build')
  build_configs(build_dir, args.group_amount, args.group_id)


if __name__ == '__main__':
  main()

