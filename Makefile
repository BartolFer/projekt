CFLAGS = 
CPPFLAGS = 
CXXFLAGS = "-Dself=(*this)" "-Ddepend(...)="
LDFLAGS = 

.DEFAULT_GOAL = all
.PHONY: Build/a.exe clean

clean:
	python Clean.py

include ./Build/Makefile

all: Build/a.exe
Build/a.exe: $(OBJECTS)
	@g++ $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $^
