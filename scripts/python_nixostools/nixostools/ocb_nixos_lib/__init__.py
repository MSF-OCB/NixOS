
import json
import os
import os.path

from functools import reduce
from typing import Dict, List, Mapping


def read_json_configs(config_path: str) -> Mapping:
  if os.path.isfile(config_path):
    with open(config_path, 'r') as f:
      return json.load(f) # type: ignore
  elif os.path.isdir(config_path):
    json_configs = [ read_json_configs(f.path)
                     for f in os.scandir(config_path)
                     if f.is_file() and os.path.splitext(f.name)[1] == '.json' ]
    return reduce(deep_merge, json_configs, {})
  else:
    raise FileNotFoundError(f'The given config path ({config_path}) does not exist!')


def deep_merge(d1: Mapping, d2: Mapping) -> Mapping:
  out: Dict = {}

  for key in set(d1.keys()).union(set(d2.keys())):
    if key in d1 and key in d2 and \
       not (isinstance(d1[key], type(d2[key])) or \
            isinstance(d2[key], type(d1[key]))):
      raise AssertionError(f"The types of the values for key '{key}' are not the same!")

    # If the key is only present in one of the mappings, we use that value
    if not (key in d1 and key in d2):
      out[key] = d1.get(key, None) or d2.get(key, None)
    # Otherwise, if the key maps to a mapping, we merge those mappings
    elif isinstance(d1.get(key, None) or d2.get(key, None), Mapping):
      out[key] = deep_merge(d1.get(key, {}), d2.get(key, {}))
    # Otherwise, if the key maps to a list, we concat the lists
    # (careful, str is a subset of Iterable!)
    elif isinstance(d1.get(key, None) or d2.get(key, None), List):
      out[key] = d1.get(key, []) + d2.get(key, [])
    # If the key is present in both, but is twice None, then we can merge to None
    elif d1.get(key, None) is None and d2.get(key, None) is None:
      out[key] = None
    # In other cases, we do not know what to do...
    else:
      raise ValueError(f"Unmergeable type found during merge, key: '{key}', " +
                       f"type: '{type(d1.get(key, None) or d2.get(key, None))}'")

  return out

