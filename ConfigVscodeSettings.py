import json, os, sys;

cpps = [
	"${workspaceFolder}/Src/" + os.path.relpath(rt + "/" + filename, "./Src/").replace("\\", "/")
	for (rt, dirs, files) in os.walk("./Src/")
	for filename in files
	if filename.endswith(".cpp") 
];

KEY = "C_Cpp.default.forcedInclude";

with open("./.vscode/settings.json") as file:
	settings = json.load(file);
	if KEY not in settings.keys(): settings[KEY] = cpps;
	else:                          settings[KEY] = list(set(settings[KEY]).union(cpps));
pass
with open("./.vscode/settings.json", "w") as file: json.dump(settings, file, indent = "\t");
