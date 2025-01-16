import os, sys, subprocess, re;
# sys.exit(0);

def copyFolderStructure(fr, to):
	if not os.path.exists(to): os.makedirs(to);
	for (root, dirs, files) in os.walk(fr):
		for d in dirs:
			d = to + "/" + os.path.relpath(root + "/" + d, fr);
			if not os.path.exists(d): os.mkdir(d);
		pass
	pass
pass
def relpath(path, parent): return os.path.relpath(path, parent).replace("\\", "/");
def dirpath(path): return os.path.dirname(path).replace("\\", "/");

def approvedFile(filename): return (False
	or filename.endswith(".lzz")
	or filename.endswith(".hzz")
	or filename.endswith(".cl")
);
def analizeSrcFolder(src_folder) -> dict[str, list[str]]:
	result = {};
	for (rt, dirs, files) in os.walk(src_folder):
		for filename in files:
			if not approvedFile(filename): continue;
			full_name = rt + "/" + filename;
			main_name = relpath(full_name, src_folder);
			if filename.endswith(".cl"): result[main_name] = [];
			else: result[main_name] = analizeSrc(full_name, src_folder);
		pass
	pass
	return result;
pass
dep_re = re.compile(r'\s*#\s*include\s*"(\.[^"]+\.(hpp|hzz))"');
def allIncludes(src, folder, src_folder):
	for m in re.finditer(dep_re, src):
		inc = m.group(1);
		if inc.endswith(".cl.hpp"): inc = inc[ : -4];
		elif inc.endswith(".hpp"): inc = inc[ : -4] + ".lzz";
		yield relpath(folder + "/" + inc, src_folder);
	pass
pass
def analizeSrc(lzz_path, src_folder) -> list[str]:
	with open(lzz_path) as file: src = file.read();
	folder = os.path.dirname(lzz_path);
	true_name = relpath(lzz_path, "./Src/");
	desps = { d for d in allIncludes(src, folder, src_folder) if d != true_name };
	return list(desps);
pass

def getOName(name: str) -> str:
	return "./Build/Objects/" + name + ".o";
pass
def getCName(name: str) -> str:
	return "./Build/Sources/" + name + ".cpp";
pass
def getHName(name: str) -> str:
	return "./Build/Sources/" + name + ".hpp";
pass
def getZName(name: str) -> str:
	return "./Build/Sources/" + name + ".hzz";
pass
def getIName(name: str) -> str:
	return "./Src/" + name + ".hpp";
pass

copyFolderStructure("./Src/", "./Build/Objects/");
copyFolderStructure("./Src/", "./Build/Sources/");

dependancies = analizeSrcFolder("./Src/");
# print(dependancies.keys());
# print(dependancies);
for (src, deps) in dependancies.items():
	# print(src, deps);
	for d in deps:
		assert d in dependancies.keys(), f"<{src}>: <{d}> does not exist";
	pass
pass

def getLinkingDeps(dependancies):
	for src in dependancies:
		if   src.endswith(".lzz"): yield getOName(src[ : -4]);
		elif src.endswith(".hzz"): continue;
		elif src.endswith(".cl" ): yield getOName(src);
		else: assert False, src;
	pass
pass
def getCompileDeps(dependancies):
	for src in dependancies:
		if   src.endswith(".lzz"): yield getOName(src[ : -4]);
		elif src.endswith(".hzz"): yield getZName(src[ : -4]);
		elif src.endswith(".cl" ): yield getOName(src);
		else: assert False, src;
	pass
pass
def getIncludeDeps(dependancies):
	for src in dependancies:
		if   src.endswith(".lzz"): yield getIName(src[ : -4]);
		elif src.endswith(".hzz"): continue;
		elif src.endswith(".cl"): yield getIName(src);
		else: assert False, src;
	pass
pass

objects = " ".join(getLinkingDeps(dependancies.keys()));
# print(objects);
i_files = " ".join(getIncludeDeps(dependancies.keys()));
# print(i_files);

import contextlib, contextvars;
with open("./Build/Makefile", "w") as mk:
	with contextlib.redirect_stdout(mk):
		print(f"OBJECTS = {objects}");
		print(f"I_FILES = {i_files}");
		for (src, deps) in dependancies.items():
			if   src.endswith(".lzz"): 
				dir = dirpath(src);
				o_path = getOName(src[ : -4]);
				c_path = getCName(src[ : -4]);
				h_path = getHName(src[ : -4]);
				i_path = getIName(src[ : -4]);
				l_path = "./Src/" + src;
				dep_paths = " ".join(getCompileDeps(deps));
				inc_paths = " ".join(getIncludeDeps(deps));
				print(f"{o_path}: {l_path} {dep_paths}");
				print(f"\t@lzz -e -hx hpp $(CPPFLAGS) -o ./Build/Sources/{dir} {l_path}");
				print(f"\t@python ./CopyFile.py {h_path} {i_path}");
				print(f"\t@g++ $(CPPFLAGS) $(CXXFLAGS) -c -o $@ {c_path}");
				print(f"{i_path}: {l_path} {inc_paths}");
				print(f"\t@lzz -e -hx hpp $(CPPFLAGS) -o ./Build/Sources/{dir} {l_path}");
				print(f"\t@python ./CopyFile.py {h_path} {i_path}");
			elif src.endswith(".hzz"):
				dir = dirpath(src);
				z_path = getZName(src[ : -4]);
				l_path = "./Src/" + src;
				dep_paths = " ".join(getCompileDeps(deps));
				inc_paths = " ".join(getIncludeDeps(deps));
				print(f"{z_path}: {l_path} {inc_paths}");
				print(f"\t@python ./CopyFile.py {l_path} {z_path}");
			elif src.endswith(".cl"):
				o_path = getOName(src);
				c_path = getCName(src);
				h_path = getHName(src);
				i_path = getIName(src);
				l_path = "./Src/" + src;
				var_name = os.path.basename(src)[ : -3]; # .cl
				print(f"{o_path}: {l_path}");
				print(f"\t@python ./cl_to_c.py {l_path} {c_path} {h_path} {i_path} {var_name}");
				print(f"\t@g++ $(CPPFLAGS) $(CXXFLAGS) -c -o $@ {c_path}");
				print(f"{i_path}: {l_path}");
				print(f"\t@python ./cl_to_c.py {l_path} {c_path} {h_path} {i_path} {var_name}");
			else: assert False, src;
		pass
	pass
pass

sys.exit(subprocess.run(["make", *sys.argv[1 : ]]).returncode);
