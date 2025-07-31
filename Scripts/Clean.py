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



import os, shutil;
import subprocess;

def rmdir(path):
	if os.path.exists(path) and os.path.isdir(path): shutil.rmtree(path);
pass
def rmfile(path):
	if os.path.exists(path) and os.path.isfile(path): os.remove(path);
pass
for (base, folders, files) in os.walk(__actual_dir__ + "/" + "./../Src/"):
	for filename in files:
		if filename.endswith(".zzh"):
			os.remove(base + "/" + filename);
		elif ".tmp." in filename:
			os.remove(base + "/" + filename);
		pass
	pass
pass
for (base, folders, files) in os.walk(__actual_dir__ + "/" + "./../Targets/"):
	if ".zzc.config.json" not in files: continue;
	if "Clean.py" in files:
		if subprocess.run([sys.executable, base + "/Clean.py"]).returncode != 0: print("Could not Clean", base);
	else:
		if "PreClean.py" in files:
			if subprocess.run([sys.executable, base + "/PreClean.py"]).returncode != 0: print("Could not Pre-Clean", base);
		pass
		rmdir(base + "/Build/");
		rmfile(base + "/.zzc.cache.json");
		if "PostClean.py" in files:
			if subprocess.run([sys.executable, base + "/PostClean.py"]).returncode != 0: print("Could not Post-Clean", base);
		pass
	pass
pass
