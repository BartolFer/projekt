import sys;

[_, src, dst, hdr, inc, name] = sys.argv;

with open(src) as file:
	cl = file.read();
pass

with open(dst, "w") as file:
	print(f"namespace BJpeg {{ char const* {name} = {cl!r}; }}", file = file);
pass
with open(hdr, "w") as file:
	print(f"namespace BJpeg {{ extern char const* {name}; }}", file = file);
pass
with open(inc, "w") as file:
	print(f"namespace BJpeg {{ extern char const* {name}; }}", file = file);
pass
