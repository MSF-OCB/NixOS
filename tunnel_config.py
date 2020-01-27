#! /usr/bin/env python

def format_line(line):
  splitted = line.split(" ")
  name = splitted[2].replace("tunnel@", "").replace("\n", "")
  key = " ".join(splitted[0:2])
  port = "6" + name.replace("benuc", "") if "benuc" in name else ""
  return '''\
    {name} = {{
      remote_forward_port = {port};
      public_key = "{key}";
    }};\
  '''.format(name=name, port=port, key=key)


pred = lambda l: l.startswith("permitlisten")  

with open("./keys/tunnel") as f:
  formatted = map(format_line, filter(lambda l: not pred(l), f))
  print("\n".join(formatted))

with open("./keys/tunnel") as f:
  ignored = map(lambda l: "Ignored line: " + l , filter(pred, f))
  print("\n\n" + "\n".join(ignored))

