from __future__ import annotations;

cl_include = "C:/Programs/Cuda/include/";
cl_lib     = "C:/Programs/Cuda/lib/x64/";

use_RgbDisplay = True;
if use_RgbDisplay:
	glad_include = "./OpenGlDep/glad/include/";   #	relative to ./Scripts/RgbDisplay/
	glad_c       = "./OpenGlDep/glad/src/glad.c"; #	relative to ./Scripts/RgbDisplay/
	gl_dll       = "C:/Windows/System32/opengl32.dll";
	glfw_lib     = "./OpenGlDep/glfw-3.4.bin.WIN64/lib-mingw-w64/"; #	relative to ./Scripts/RgbDisplay/
pass


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



if __name__ == "__main__":
	for arg in sys.argv[1 : ]:
		assert arg in ["clean"], arg;
	pass
pass


#	def getDstPath(path: str) -> str:
#		i = path.rindex(".template");
#		j = i + len(".template");
#		assert path[j : j + 1] in "."; #	"." or ""
#		return path[ : i] + path[j : ];
#	pass

def getClReplacement(text: str) -> str:
	text = text.replace("$$cl_include$$", str(cl_include));
	text = text.replace("$$cl_lib$$"    , str(cl_lib    ));
	return text;
pass
def getGlReplacement(text: str) -> str:
	if not use_RgbDisplay: return text;
	text = text.replace("$$glad_include$$", str(glad_include));
	text = text.replace("$$glad_c$$"      , str(glad_c      ));
	text = text.replace("$$gl_dll$$"      , str(gl_dll      ));
	text = text.replace("$$glfw_lib$$"    , str(glfw_lib    ));
	return text;
pass

def fillClFile(path: str, dst_path: str):
	if "clean" in sys.argv[1 : ]:
		if os.path.exists(dst_path): os.remove(dst_path);
		return;
	pass
	with open(path) as template, open(dst_path, "w") as dst:
		text = template.read();
		text = getClReplacement(text)
		dst.write(text);
	pass
pass
def fillGlFile(path: str, dst_path: str):
	if "clean" in sys.argv[1 : ]:
		if os.path.exists(dst_path): os.remove(dst_path);
		return;
	pass
	with open(path) as template, open(dst_path, "w") as dst:
		text = template.read();
		text = getGlReplacement(text)
		dst.write(text);
	pass
pass
def fillClGlFile(path: str, dst_path: str):
	if "clean" in sys.argv[1 : ]:
		if os.path.exists(dst_path): os.remove(dst_path);
		return;
	pass
	with open(path) as template, open(dst_path, "w") as dst:
		text = template.read();
		text = getClReplacement(text)
		text = getGlReplacement(text)
		dst.write(text);
	pass
pass

#	fillClFile(__actual_dir__ + "/" + "./ClValidate/.template.Makefile", __actual_dir__ + "/" + "./ClValidate/Makefile");
#	fillGlFile(__actual_dir__ + "/" + "./RgbDisplay/.template.Makefile", __actual_dir__ + "/" + "./RgbDisplay/Makefile");
#	for (base, folders, files) in os.walk(__actual_dir__ + "/" + "../Targets/"):
#		filename     = ".template.zzc.config.json";
#		dst_filename = ".zzc.config.json";
#		if filename in files:
#			fillClFile(base + "/" + filename, base + "/" + dst_filename);
#		pass
#	pass
for (base, folders, files) in os.walk(__actual_dir__ + "/" + "../"):
	for filename in files:
		if filename in ("template.", ".template"): continue;
		
		if filename.startswith("template."): dst_filename = filename.replace( "template.", "" , 1);
		elif ".template." in filename:       dst_filename = filename.replace(".template.", ".", 1);
		elif filename.endswith(".template"): dst_filename = filename.replace(".template" , "" , 1);
		else: continue;
		fillClGlFile(base + "/" + filename, base + "/" + dst_filename);
	pass
pass

