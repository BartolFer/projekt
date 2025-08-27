build: RgbDisplay.exe
run: build
	RgbDisplay.exe ./test.rgba

.PHONY: build run


RgbDisplay.exe: RgbDisplay.cpp ../../Targets/Examples/Metadata.hpp
	@g++ -o $@ "-Dself=(*this)" "-Ddepend(...)=" "-Dpack=struct __attribute__((packed))" "-I$$glad_include$$" $< "$$glad_c$$" -lopengl32 "-L$$gl_dll$$" "-L$$glfw_lib$$" -lglfw3 -lgdi32
