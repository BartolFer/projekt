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
import shutil;

serial = False;
SERIAL_FLAG = "-bjpeg-compile-serial";
if SERIAL_FLAG in sys.argv[1 : ]:
	serial = True;
	i = sys.argv.index(SERIAL_FLAG, 1);
	sys.argv[i : i + 1] = [];
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

def build(base, files = None):
	if files is None: files = [path for path in os.listdir(base) if os.path.isfile(base + "/" + path)];
	print("Building", base);
	if "Build.py" in files:
		p = subprocess.Popen([sys.executable, base + "/Build.py", *sys.argv[1 : ]]);
	else:
		p = subprocess.Popen([sys.executable, __actual_dir__ + "/" + "./../ZZC/zzc.py", base, *sys.argv[1 : ]]);
	pass
	if serial and p.wait() != 0: raise Exception(str(p.args));
	return p;
pass

if subprocess.run([sys.executable, __actual_dir__ + "./SetupVars.py"]).returncode != 0: print("Could not SetupVars");

for (base, folders, files) in os.walk(__actual_dir__ + "/" + "./../Src"):
	for filename in files:
		if filename.endswith(".cl"): cl_to_zzc(base + "/" + filename);
	pass
pass

if build(__actual_dir__ + "/" + "./../Targets/Ide/").wait() != 0: raise Exception;
subprocess.run(["make"], cwd = __actual_dir__ + "/" + "./ClValidate/", stdout = subprocess.DEVNULL).check_returncode();
for (base, folders, files) in os.walk(__actual_dir__ + "/" + "./../Src"):
	for filename in files:
		if filename.endswith(".cl"): subprocess.run([__actual_dir__ + "/" + "./ClValidate/ClValidate.exe", base + "/" + filename]).check_returncode();
	pass
pass

subprocess.run(["make"], cwd = __actual_dir__ + "/" + "./RgbDisplay/").check_returncode();

def waitAll(processes: list[subprocess.Popen]):
	failed = False;
	for p in processes:
		if p.wait() != 0:
			failed = True;
			for pp in processes: pp.terminate();
			break;
		pass
	pass
	if failed:
		raise Exception(str(p.args));
	pass
pass
processes = [
	build(__actual_dir__ + "/" + "../Targets/Test/"),
	build(__actual_dir__ + "/" + "../Targets/Library/Static/"),
];
waitAll(processes);
processes = [
	build(__actual_dir__ + "/" + "../Targets/Examples/Decode/"),
	build(__actual_dir__ + "/" + "../Targets/Examples/Encode/"),
];
waitAll(processes);


#	for (base, folders, files) in os.walk(__actual_dir__ + "/" + "./../Targets/"):
#		if ".zzc.config.json" in files or "Build.py" in files:
#			if base.endswith("Ide") or base.endswith("Ide/"): continue;
#			processes.append(build(base, files));
#		pass
#	pass


try: import winsound;
except ImportError: pass;
else: winsound.Beep(600, 200);
#	#	just so that i don't need to bother with subprocess
#	sys.argv[1 : ] = [__actual_dir__];
#	import ZZC.zzc;
