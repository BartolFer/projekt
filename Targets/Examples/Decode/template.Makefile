Build/BJpegDecode.exe: Main.cpp ../../Library/Static/Build/libBJpeg.so ../../Library/Static/include/BJpeg.hpp | Build/
	@g++ -std=c++23 -o $@ -DCL_TARGET_OPENCL_VERSION=300 "-I$$cl_include$$" Main.cpp ../../Library/Static/Build/libBJpeg.so "-L$$cl_lib$$" "-lOpenCl"

Build/:
	@mkdir $@

