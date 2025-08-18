
from collections import defaultdict;
import os, json;

from common import *;

from file_names import *;

CACHE_NAME  = root + "/.zzc.cache.json";

Dependancies = dict[File, list[File]];

class Cache:
	direct_dependancies: Dependancies;
	def __init__(self, json: dict):
		x = json.get("direct_dependancies", {});
		self.direct_dependancies = {File(path, False): [File(p, False) for p in ps] for (path, ps) in x.items()};
	pass
	def save(self):
		x = {
			"direct_dependancies": {file.path: [f.path for f in ds] for (file, ds) in self.direct_dependancies.items()},
		};
		print(CACHE_NAME);
		with open(CACHE_NAME, "w") as file:
			json.dump(x, file, indent="\t");
		pass
	pass
pass

def buildDependancies() -> tuple[Dependancies, Dependancies]:
	#	step 1: inflate
	inflated = {k: v.copy() for (k, v) in cache.direct_dependancies.items()};
	for (file, dependancy) in inflated.items():
		i = 0;
		while i < len(dependancy):
			dep = dependancy[i];
			dependancy.extend(d for d in inflated.get(dep, []) if d not in dependancy and d != file);
			i += 1;
		pass
	pass
	reversed = defaultdict(set);
	for (file, dependancies) in inflated.items():
		for f in dependancies:
			reversed[f].add(file);
		pass
	pass
	reversed = {k: list(v) for (k, v) in reversed.items()};
	return (inflated, reversed);
pass
def isOutdated(file: File) -> bool:
	relevant = file.abs_file.obj if not config.nocompile else file.abs_file.macro_temp_1;
	if not os.path.exists(relevant): return True;
	a = os.stat(file.abs_file.path);
	b = os.stat(relevant);
	if a.st_mtime > b.st_mtime: return True;
	return False;
pass

if os.path.exists(CACHE_NAME):
	with open(CACHE_NAME) as file:
		cache = Cache(json.load(file));
	pass
else:
	cache = Cache({});
pass

