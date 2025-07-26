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

import subprocess;


subprocess.run([sys.executable, __actual_dir__ + "/../../../../ZZC/zzc.py", __actual_dir__]).check_returncode();

def copy_file(src: str, dst: str):
	assert os.path.exists(src);
	if os.path.exists(dst) and os.stat(src).st_mtime < os.stat(dst).st_mtime: return;
	
	with open(src, "rb") as file_in, open(dst, "wb") as file_out:
		file_out.write(file_in.read());
	pass
pass

def ww(p: str, w: int):
	return p + " " * (w - len(p));
pass
def pp(p: str):
	er = "D:/Personal/nastava/projekt/";
	(r, p) = (p[ : len(er)], p[len(er) : ]);
	assert r.replace("\\", "/") == er;
	w = 97 - len(er)
	p = ww(p, w);
	return p;
pass
def rebase(path, base_src, base_dst):
	rel = os.path.relpath(path, base_src);
	res = base_dst + "/" + rel;
	#	print(pp(path), ww(rel, 36), pp(res));
	return res;
pass

src = __actual_dir__ + "/Build/Cpp/";
inner = __actual_dir__ + "/include/inner/";
if not os.path.exists(inner): os.mkdir(inner);
for (base, folders, files) in os.walk(src):
	for folder in folders:
		inner_folder = rebase(base + "/" + folder, src, inner);
		if not os.path.exists(inner_folder): os.mkdir(inner_folder);
	pass
	for filename in files:
		if filename.endswith(".hpp") or filename.endswith(".h"):
			inner_filename = rebase(base + "/" + filename, src, inner);
			copy_file(base + "/" + filename, inner_filename);
		pass
	pass
pass

