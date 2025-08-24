a.exe: ./ClValidate.cpp ../../Src/Util.zzc ../../Src/MyOpenCL.zzc
	g++ -std=c++23 -DCL_TARGET_OPENCL_VERSION=300 -DTESTING -DDEBUG "-Dself=(*this)" "-I$$cl_include$$" "-o" $@ $< "-L$$cl_lib$$" -lOpenCl
