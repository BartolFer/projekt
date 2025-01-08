import os, shutil;

def rmdir(path):
	if os.path.exists(path): shutil.rmtree(path);
pass
rmdir("./Build/");
rmdir("./gcm.cache/");
for (root, folders, files) in os.walk("./Src/"):
	for filename in files:
		if filename.endswith(".hpp") or filename.endswith(".hzz"):
			os.remove(root + "/" + filename);
		pass
	pass
pass

