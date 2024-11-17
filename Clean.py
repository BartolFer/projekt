import os, shutil;

def rmdir(path):
	if os.path.exists(path): shutil.rmtree(path);
pass
rmdir("./Build/");
rmdir("./gcm.cache/");
