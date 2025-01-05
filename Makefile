CFLAGS = 
CPPFLAGS = "-DTESTING" "-DDEBUG" "-Dself=(*this)" "-Ddepend(...)=" "-Drecord=struct __attribute__((packed))"
CXXFLAGS = "-std=c++23" "-fmodules-ts"
LDFLAGS = 

.DEFAULT_GOAL = all
.PHONY: Build/a.exe clean lzz

clean:
	python Clean.py

-include ./Build/Makefile

all: Build/a.exe
Build/a.exe: $(OBJECTS)
	@g++ $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $^
lzz: $(I_FILES)

