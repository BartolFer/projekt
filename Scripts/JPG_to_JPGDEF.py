import sys;

jpg  = "D:/Personal/nastava/projekt/Temp/Zugpsitze_mountain.jpg";
jdef = "D:/Personal/nastava/projekt/Temp/Zugpsitze_mountain.def.jpg";
args = sys.argv[1 : ];
if len(args) == 1:
	jpg = args[0];
	assert jpg.endswith(".jpg") or jpg.endswith(".jpeg");
	jdef = jpg[ : jpg.rindex(".")] + ".def.jpg";
else:
	[jpg, jdef] = args;
	assert jpg .endswith(".jpg") or jpg .endswith(".jpeg");
	assert jdef.endswith(".jpg") or jdef.endswith(".jpeg");
pass


res = [];

with open(jpg, "rb") as file:
	data = file.read();
pass

SOI = 0xD8;
EOI = 0xD9;
care_about = [
	0xC4, #	Define Huffman Table
	0xDB, #	Define Quantization Table
	0xCC, #	Define arithmetic coding conditioning
	0xD8, #	Start of Image
	0xD9, #	End of Image
];

i = 0;
while i < len(data):
	if data[i] == 0xFF:
		m = data[i + 1];
		i += 2;
		if m == 0x00: continue;
		if m in (SOI, EOI):
			res.append(data[i - 2: i]);
			continue;
		else:
			print(hex(m));
			l = data[i] << 8 | data[i + 1];
			if m in care_about: res.append(data[i - 2: i + l]);
			i += l;
			continue;
		pass
	pass
	i += 1;
pass

with open(jdef, "wb") as file:
	file.write(b"".join(res));
pass
