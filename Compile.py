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
import subprocess;

def maybe_exit(r):
	if r != 0: sys.exit(r);
pass

def cl_to_zzc(filename: str):
	filename = filename.replace("\\", "/");
	endex_slash = filename.rindex("/") + 1 if "/" in filename else 0;
	index_dot = filename.index(".", endex_slash) if "/" in filename else len(filename);
	name = filename[endex_slash : index_dot];
	hdr_filename = filename + ".tmp.hdr.zzc";
	dst_filename = filename + ".tmp.src.zzc";
	
	if not os.path.exists(hdr_filename):
		with open(hdr_filename, "w") as file:
			print(f"namespace BJpeg {{ extern char const* {name}; }}", file = file);
		pass
	pass
	
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

maybe_exit(subprocess.run(["make"], cwd = __actual_dir__ + "/ClValidate/", stdout = subprocess.DEVNULL).returncode);
for (base, folders, files) in os.walk(__actual_dir__ + "/Src"):
	for filename in files:
		if filename.endswith(".cl"): maybe_exit(subprocess.run([__actual_dir__ + "/ClValidate/a.exe", base + "/" + filename]).returncode);
	pass
pass

maybe_exit(subprocess.run([sys.executable, __actual_dir__ + "/ZZC/zzc.py", __actual_dir__ + "/Targets/Decode/"]).returncode);
maybe_exit(subprocess.run([sys.executable, __actual_dir__ + "/ZZC/zzc.py", __actual_dir__ + "/Targets/Encode/"]).returncode);
maybe_exit(subprocess.run([sys.executable, __actual_dir__ + "/Targets/Library/Static/Build.py"                ]).returncode);
maybe_exit(subprocess.run([sys.executable, __actual_dir__ + "/ZZC/zzc.py", __actual_dir__ + "/Targets/Test/"  ]).returncode);

try: import winsound;
except ImportError: pass;
else: winsound.Beep(600, 200);
#	#	just so that i don't need to bother with subprocess
#	sys.argv[1 : ] = [__actual_dir__];
#	import ZZC.zzc;
