import sys;

if len(sys.argv) != 3:
	print("Usage: python CopyFile.py <source_file> <destination_file>");
	sys.exit(1);
pass
src_name = sys.argv[1]
dst_name = sys.argv[2]
with open(src_name, "rb") as src, open(dst_name, "wb") as dst:
	dst.write(src.read());
pass
