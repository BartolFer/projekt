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

import json;

def cl_to_zzc(filename: str):
	filename = filename.replace("\\", "/");
	endex_slash = filename.rindex("/") + 1 if "/" in filename else 0;
	index_dot = filename.index(".", endex_slash) if "/" in filename else len(filename);
	name = filename[endex_slash : index_dot];
	dst_filename = filename + ".tmp.zzc";
	
	if os.path.exists(dst_filename) and os.stat(filename).st_mtime < os.stat(dst_filename).st_mtime: return;
	
	with open(filename) as file: cl = file.read();
	c_str = json.dumps(cl);
	
	with open(dst_filename, "w") as file:
		print(f"namespace BJpeg {{ char const* {name} = {c_str}; }}", file = file);
	pass
pass


for (base, folders, files) in os.walk(__actual_dir__ + "/Src"):
	for filename in files:
		if filename.endswith(".cl"): cl_to_zzc(base + "/" + filename);
	pass
pass

import subprocess;
r = subprocess.run([sys.executable, "./ZZC/zzc.py", __actual_dir__]).returncode;

if r == 0:
	try: import winsound;
	except ImportError: pass;
	else: winsound.Beep(600, 200);
pass
sys.exit(r);
#	#	just so that i don't need to bother with subprocess
#	sys.argv[1 : ] = [__actual_dir__];
#	import ZZC.zzc;
