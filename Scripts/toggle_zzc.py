from __future__ import annotations;
from typing import *;
import inspect as ins;
import sys, os, pathlib;
__actual_file__   = pathlib.Path(ins.getabsfile(ins.currentframe())).resolve();
__actual_dir__    = os.path.dirname(__actual_file__);
if __name__ == '__main__' and not __package__:
	__actual_parent__ = os.path.dirname(__actual_dir__ );
	sys.path.insert(0, __actual_parent__);
	__package__ = os.path.split(__actual_dir__)[1];
pass



with open(__actual_dir__ + "/.zzc.config.json") as file:
	raw = file.read();
pass
index = raw.index('"nocompile": ') + len('"nocompile": ');
a = raw[ : index];
b = raw[index : ];
if b.startswith("false"):
	nc = True;
	b = "true" + b[5 : ];
else:
	nc = False;
	b = "false" + b[4 : ];
pass
with open(__actual_dir__ + "/.zzc.config.json", "w") as file:
	file.write(a + b);
pass

try: import winsound;
except ImportError: pass;
else: winsound.Beep(400 if nc else 600, 200);
