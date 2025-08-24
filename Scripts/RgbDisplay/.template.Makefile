run: build
	a.exe ./test.rgba

build: a.exe
.PHONY: build run


a.exe: RgbDisplay.cpp ../../Src/MetaData.zzc
	@g++ -o a.exe "-Dself=(*this)" "-Ddepend(...)=" "-Dpack=struct __attribute__((packed))" "-I$$glad_include$$" $< "$$glad_c$$" -lopengl32 "-L$$gl_dll$$" "-L$$glfw_lib$$" -lglfw3 -lgdi32
