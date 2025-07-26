# Rgb Display

`cd` into `RgbDisplay/`  
To build & run the program: `make`  
To just build it `make build`  

To just run (you don't need to be inside `RgbDisplay/`)  
```
RgbDisplay/a.exe input_file.rgb  
```

`input_file.rgb` must be in binary format  
it first lists metadata (width, height, maybe something else)  
then tightly packed RGB values, from top left corner, row by row (`rgb[0,0], rgb[0,1], ...`)  

dependancies:  
 - OpenGl 3.3  
 - glfw  
 - glad  

disclaimer: I'm not well versed in using dependencies, so I just put them locally in `RgbDisplay/OpenGlDep/",  
but I do not provide any binaries or a way to download them automatically.  
If you do want to use this program (WHICH IS NOT A CORE PART of this project), you'll have to figure it out yourself.  
