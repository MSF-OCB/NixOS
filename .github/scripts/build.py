#! /usr/bin/env python3

import glob
import itertools
import os
import shutil

from subprocess import Popen, PIPE

config_directory = os.path.join('.', 'org-spec', 'hosts')

def partition(lst, size):
  it = iter(lst)
  return iter(lambda: tuple(itertools.islice(it, size)), ())

def do_build_config(hostname):
  print(f'Building config: {hostname}')
  config_file = os.path.basename(hostname)
  dst = os.path.join('/tmp', config_file)
  shutil.copytree(os.getcwd(), dst,
                  symlinks = True,
                  ignore = shutil.ignore_patterns('.git', 'result', 'id_tunnel', 'settings.nix'))
  os.symlink(os.path.join(dst, 'org-spec', 'hosts', config_file),
             os.path.join(dst, 'settings.nix'))
  with open(os.path.join(dst, 'hardware-configuration.nix'), 'w') as fp:
    fp.write('{}')
  with open(os.path.join(dst, 'local', 'id_tunnel'), 'w') as fp:
    pass
  return Popen(['nix-build',
                '<nixpkgs/nixos>',
                '-I', f'nixos-config={dst}/configuration.nix',
                '-A', 'system'],
               stdout=PIPE, stderr=PIPE)

def build_config(configs):
  processes = [do_build_config(config) for config in configs]
  for process in processes:
    (stdout, stderr) = process.communicate()
    print(stderr.decode())
    print(stdout.decode())


def build_configs():
  configs = sorted(glob.glob('./org-spec/hosts/*.nix'))
  head, *tail = configs
  build_config([head])
  for slice_ in partition(tail, 4):
    build_config(slice_)

build_configs()

