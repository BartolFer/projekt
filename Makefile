CFLAGS = 
#	CPPFLAGS = "-DCL_TARGET_OPENCL_VERSION=300" "-DDEBUG" "-Dself=(*this)" "-Ddepend(...)=" "-Drecord=struct __attribute__((packed))"
CPPFLAGS = "-DCL_TARGET_OPENCL_VERSION=300" "-DTESTING" "-DDEBUG" "-Dself=(*this)" "-Ddepend(...)=" "-Drecord=struct __attribute__((packed))"
CXXFLAGS = "-Werror" "-pedantic" "-std=c++23" "-fmodules-ts" "-IC:/Programs/Cuda/include/"
LDFLAGS = "-LC:/Programs/Cuda/lib/x64/" "-lOpenCl"

.DEFAULT_GOAL = all
.PHONY: Build/a.exe clean lzz run

clean:
	python Clean.py

run: Build/a.exe
	@Build/a.exe

-include ./Build/Makefile

all: Build/a.exe
Build/a.exe: $(OBJECTS)
	@echo build
	@g++ $(CXXFLAGS) $(CPPFLAGS) -o $@ $^ $(LDFLAGS)
lzz: $(I_FILES)
	@echo lzz

