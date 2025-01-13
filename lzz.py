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

def analizeSrcFolder(src_folder) -> dict[str, list[str]]:
	result = {};
	for (rt, dirs, files) in os.walk(src_folder):
		for filename in files:
			if not filename.endswith(".lzz"): continue;
			full_name = rt + "/" + filename;
			main_name = os.path.relpath(full_name, src_folder).replace("\\", "/");
			result[main_name] = analizeSrc(full_name, src_folder);
		pass
	pass
	return result;
pass
dep_re = re.compile(r'\s*#\s*include\s*"([^"]+)\.hpp"');
def analizeSrc(file_path, src_folder) -> tuple[str]:
	with open(file_path) as file: src = file.read();
	folder = os.path.dirname(file_path);
	true_name = os.path.relpath(file_path, "./Src/").replace("\\", "/");
	return [
		d for d in (
			(d + ".lzz" if not d.endswith(".cl") else d) for d in {
				os.path.relpath(folder + "/" + m.group(1), src_folder).replace("\\", "/")
				for m in re.finditer(dep_re, src)
			}
		)
		if d != true_name
	];
pass
def findCls(src_folder) -> list[str]:
	result = [];
	for (rt, dirs, files) in os.walk(src_folder):
		for filename in files:
			if not filename.endswith(".cl"): continue;
			full_name = rt + "/" + filename;
			main_name = os.path.relpath(full_name, src_folder).replace("\\", "/");
			result.append(main_name);
		pass
	pass
	return result;
pass

def getBaseName(lzz_name: str):
	if lzz_name.endswith(".lzz"): return lzz_name[ : -4];
	return lzz_name;
pass
def getOName(lzz_name: str) -> str:
	return "./Build/Objects/" + getBaseName(lzz_name) + ".o";
pass
def getCName(lzz_name: str) -> str:
	return "./Build/Sources/" + getBaseName(lzz_name) + ".cpp";
pass
def getHName(lzz_name: str) -> str:
	return "./Build/Sources/" + getBaseName(lzz_name) + ".hpp";
pass
def getIName(lzz_name: str) -> str:
	return "./Src/" + getBaseName(lzz_name) + ".hpp";
pass

copyFolderStructure("./Src/", "./Build/Objects/");
copyFolderStructure("./Src/", "./Build/Sources/");

dependancies = analizeSrcFolder("./Src/");
cls = findCls("./Src/");

for (src, deps) in dependancies.items():
	for d in deps: 
		if d.endswith(".cl"): assert d in cls, f"<{src}>: <{d}> does not exist";
		else: assert d in dependancies.keys(), f"<{src}>: <{d}> does not exist";
	pass
pass

import contextlib, contextvars;
with open("./Build/Makefile", "w") as mk:
	with contextlib.redirect_stdout(mk):
		objects = " ".join([getOName(cl + ".lzz") for cl in cls] + list(map(getOName, dependancies.keys())));
		i_files = " ".join(map(getIName, dependancies.keys()));
		print(f"OBJECTS = {objects}");
		print(f"I_FILES = {i_files}");
		for cl in cls:
			base = os.path.dirname(cl);
			o_path = getOName(cl + ".lzz");
			c_path = getCName(cl + ".lzz");
			h_path = getHName(cl + ".lzz");
			i_path = getIName(cl + ".lzz");
			l_path = "./Src/" + cl;
			var_name = os.path.basename(cl)[ : -3]; # .cl
			print(f"{o_path}: {l_path}");
			print(f"\t@python ./cl_to_c.py {l_path} {c_path} {h_path} {i_path} {var_name}");
			print(f"\t@g++ $(CPPFLAGS) $(CXXFLAGS) -c -o $@ {c_path}");
		pass
		for (src, deps) in dependancies.items():
			base = os.path.dirname(src);
			o_path = getOName(src);
			c_path = getCName(src);
			h_path = getHName(src);
			i_path = getIName(src);
			l_path = "./Src/" + src;
			dep_paths = " ".join(map(getOName, deps));
			idep_paths = " ".join("./Src/" + d for d in deps);
			print(f"{o_path}: {l_path} {dep_paths}");
			print(f"\t@lzz -e -hx hpp $(CPPFLAGS) -o ./Build/Sources/{base} {l_path}");
			print(f"\t@python ./CopyFile.py {h_path} {i_path}");
			print(f"\t@g++ $(CPPFLAGS) $(CXXFLAGS) -c -o $@ {c_path}");
			
			print(f"{i_path}: {l_path} {idep_paths}");
			print(f"\t@lzz -e -hx hpp $(CPPFLAGS) -o ./Build/Sources/{base} {l_path}");
			print(f"\t@python ./CopyFile.py {h_path} {i_path}");
		pass
	pass
pass

sys.exit(subprocess.run(["make", *sys.argv[1 : ]]).returncode);
