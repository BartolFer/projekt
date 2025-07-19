a.exe: ./ClValidate.cpp ../Src/Util.zzc ../Src/MyOpenCL.zzc
	g++ -std=c++23 -DCL_TARGET_OPENCL_VERSION=300 -DTESTING -DDEBUG "-Dself=(*this)" -IC:/Programs/Cuda/include/ "-o" $@ $< -LC:/Programs/Cuda/lib/x64/ -lOpenCl
