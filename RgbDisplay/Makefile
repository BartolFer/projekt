run: build
	a.exe ./test.rgb

build: a.exe
.PHONY: build run


a.exe: RgbDisplay.cpp
	@g++ -o a.exe "-I./OpenGlDep/glad/include/" $^ ./OpenGlDep/glad/src/glad.c -lopengl32 "-LC:/Windows/System32/opengl32.dll" "-L./OpenGlDep/glfw-3.4.bin.WIN64/lib-mingw-w64/" -lglfw3 -lgdi32

