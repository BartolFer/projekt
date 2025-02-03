import os, sys, re;

filenames = sys.argv[1:];

for filename in filenames:
	with open(filename) as file:
		src = file.read();
	pass

	src = src.replace("enum", "enum struct");

	with open(filename, "w") as file:
		file.write(src);
	pass
pass
