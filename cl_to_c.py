import sys;

import json;

[_, src, dst, hdr, inc, name] = sys.argv;

with open(src) as file:
	cl = file.read();
pass

c_str = json.dumps(cl);

with open(dst, "w") as file:
	print(f"namespace BJpeg {{ char const* {name} = {c_str}; }}", file = file);
pass
with open(hdr, "w") as file:
	print(f"namespace BJpeg {{ extern char const* {name}; }}", file = file);
pass
with open(inc, "w") as file:
	print(f"namespace BJpeg {{ extern char const* {name}; }}", file = file);
pass
