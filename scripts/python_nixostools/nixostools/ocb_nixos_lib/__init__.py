
import json
import os
import os.path

from collections import ChainMap
from typing import Mapping


def read_tunnel_config(tunnel_config_path: str) -> Mapping:
  if os.path.isfile(tunnel_config_path):
    with open(tunnel_config_path, 'r') as f:
      return json.load(f) # type: ignore
  elif os.path.isdir(tunnel_config_path):
    return ChainMap(
      *[ read_tunnel_config(f.path)
         for f in os.scandir(tunnel_config_path)
         if f.is_file() and os.path.splitext(f.name)[1] == '.json' ])
  else:
    raise FileNotFoundError(f'The given tunnel config path ({tunnel_config_path}) does not exist!')

