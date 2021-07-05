
import json
import os
import os.path

from collections import ChainMap
from typing import Mapping


def read_json_configs(config_path: str) -> Mapping:
  if os.path.isfile(config_path):
    with open(config_path, 'r') as f:
      return json.load(f) # type: ignore
  elif os.path.isdir(config_path):
    return ChainMap(
      *[ read_json_configs(f.path)
         for f in os.scandir(config_path)
         if f.is_file() and os.path.splitext(f.name)[1] == '.json' ])
  else:
    raise FileNotFoundError(f'The given config path ({config_path}) does not exist!')

