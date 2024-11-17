import os, sys, subprocess, re;
from dataclasses import dataclass;

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
			if not filename.endswith(".cpp"): continue;
			full_name = rt + "/" + filename;
			main_name = os.path.relpath(full_name, src_folder).replace("\\", "/");
			result[main_name] = analizeSrc(full_name, src_folder);
		pass
	pass
	return result;
pass
dep_re = re.compile(r"\s*depend\s*\(");
def analizeSrc(file_path, src_folder) -> tuple[str]:
	with open(file_path) as file: src = file.read();
	folder = os.path.dirname(file_path);
	m = re.match(dep_re, src);
	if m is None: return ();
	left = index = m.span()[1];
	while True:
		i = tryParseString(src, index);
		if i is None:
			index = tryParseClose(src, index);
			break;
		pass
		index = i;
		i = tryParseComma(src, index);
		if i is not None: index = i;
	pass
	deps = eval("depend(" + src[left : index], {"depend": lambda *a: a});
	return tuple(map(lambda d: os.path.relpath(folder + "/" + d, src_folder).replace("\\", "/"), deps));
pass

def tryParseString(src: str, index: int) -> int | None:
	for index in range(index, len(src)):
		if not src[index].isspace(): break;
		index += 1;
	else: return None;
	if src[index] != '"': return None;
	index += 1;
	escape = False;
	for i in range(index, len(src)):
		c = src[i];
		if escape:
			escape = False;
			continue;
		pass
		if c == '"': break;
		elif c == "\\": escape = True;
	else: raise Exception(f'Not parseable, no matching " on position {index} around <{src[index - 5 : index + 5]}>');
	return i + 1;
pass
def tryParseComma(src: str, index: int) -> int | None:
	for index in range(index, len(src)):
		if not src[index].isspace(): break;
		index += 1;
	else: return None;
	if src[index] != ',': return None;
	return index + 1;
pass
def tryParseClose(src: str, index: int) -> int:
	for index in range(index, len(src)):
		if not src[index].isspace(): break;
		index += 1;
	else: raise Exception(f'Not parseable, no matching )');
	if src[index] != ')': raise Exception(f'Not parseable, expected ), got [{index}] <{src[index]}> near <{src[index - 5 : index + 5]}>');
	return index + 1;
pass

def getOName(cpp_name: str) -> str:
	return "./Build/Objects/" + cpp_name[ : -4] + ".o";
pass

copyFolderStructure("./Src/", "./Build/Objects/");
dependancies = analizeSrcFolder("./Src/");

for (src, deps) in dependancies.items():
	for d in deps: assert d in dependancies.keys(), f"<{d}> does not exist";
pass

import contextlib, contextvars;
with open("./Build/Makefile", "w") as mk:
	with contextlib.redirect_stdout(mk):
		objects = " ".join(map(getOName, dependancies.keys()));
		print(f"OBJECTS = {objects}");
		print(f"CXXFLAGS += -std=c++23 -fmodules-ts");
		for (src, deps) in dependancies.items():
			o_path = getOName(src);
			s_path = "./Src/" + src;
			dep_paths = " ".join(map(getOName, deps));
			print(f"{o_path}: {s_path} {dep_paths}");
			print(f"\t@g++ $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<");
		pass
	pass
pass

sys.exit(subprocess.run(["make", *sys.argv[1 : ]]).returncode)
