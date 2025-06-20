import sys, os;
import subprocess;
import contextlib;
import json;
from collections import defaultdict;
import random;
import time;

from common import *;
from file_names import *;
from config import config;
import tokenizer, macro_processor, semantic, file_composer;

class Timer:
	def __init__(self):
		self.t = time.monotonic();
	pass
	def __repr__(self):
		y = time.monotonic();
		d = y - self.t;
		self.t = y;
		d = round(d);
		(m, s) = divmod(d, 60);
		return f"{m:02}:{s:02}";
	pass
pass

#	typs = ["-zzc", "-src", "-hdr"];
#	files = {};
#	args = iter(sys.argv[1 : ]);
#	for (i, typ) in enumerate(args):
#		index = 2 * i + 1;
#		path = next(args);
#		if typ not in typs: raise ValueError(f"File type must be one of {typs} (at {index} <{typ}>)");
#		files[typ] = path;
#	pass
#	if any(typ not in files.keys() for typ in typs): raise ValueError(f"Must name all of the files: {typs}");


#	zzc_name = files["-zzc"];
#	src_name = files["-src"];
#	hdr_name = files["-hdr"];
#	with \
#		open(zzc_name, "r") as zzc_file, \
#		open(src_name, "w") as src_file, \
#		open(hdr_name, "w") as hdr_file, \
#	NULL_CONTEXT_MANAGER as _:
#		parser.generateSrcAndHdr(zzc_file, src_file, hdr_file);
#	pass


#	def buildDependancies() -> tuple[dict[File, list[File]], dict[File, set[File]]]:
#		#	step 1: inflate
#		inflated = {k: v.copy() for (k, v) in config.dependancies.items()};
#		for (file, dependancy) in inflated.items():
#			i = 0;
#			while i < len(dependancy):
#				dep = dependancy[i];
#				dependancy.extend(d for d in inflated.get(dep, []) if d not in dependancy)
#				i += 1;
#			pass
#		pass
#		reversed = defaultdict(set);
#		for (file, dependancies) in config.dependancies.items():
#			for f in dependancies:
#				reversed[f].add(file);
#			pass
#		pass
#		return (inflated, reversed);
#	pass
def tokenize(file: File):
	with open(file.path) as f:
		raw = f.read();
	pass
	file.tokens = list(tokenizer.tokenize(raw));
pass

def compile(command: ConfigCommand, input: str, output: str):
	cmd = command({"in": input, "out": output});
	#	print(cmd);
	result = subprocess.run(cmd, stderr=subprocess.PIPE, text=True);
	if result.returncode != 0:
		sys.stderr.write(result.stderr);
		sys.stderr.write("\n" + "=" * 80 + "\n");
		raise ParseError(cmd);
	pass
pass

timer = Timer();
total = Timer();
timing = False;
	#	index: 00:00
	#	1st  : 00:00
	#	pp   : 00:02
	#	2nd  : 00:02
	#	obj  : 00:15
	#	exe  : 00:00
	#	total: 00:19


zzc_files: list[File] = [];
for (base, folders, files) in os.walk(root + "/" + config.paths.zzc):
	for filename in files:
		if filename.endswith(".zzc"):
			file = File(base + "/" + filename)
			if file not in zzc_files: zzc_files.append(file);
		pass
	pass
pass

if timing: print("index:", timer, flush = True);

#	if config.is_new:
#		for file in zzc_files:
#			tokenize(file);
#			macro_processor.transformIntoRTokens(file.tokens);
#		pass
#		for file in zzc_files:
#			config.dependancies[file] = [file.relativeFile(token.relevant_info.filename) for token in file.tokens if token.typ == tokenizer.TokenType.MACRO and token.relevant_info.is_zzc]
#		pass
#		files_to_upadte = zzc_files;
#	else:
#		(inflated, reversed) = buildDependancies();
#		...
#		files_to_upadte = [file for file in zzc_files if]
#		#	also, do 1st tokenization and RToken transform here
#	pass

#	ok, so, plan!
#	we complete File class to have automatic paths for different file types
#	we will create dependancy table (+reverse?)
#	see which files need to be updated
#	update step 1: macro preprocess all
#	update step 2: semantic


for file in zzc_files:
	with open(file.abs_file.path) as f: raw = f.read();
	file.tokens = list(tokenizer.tokenize(raw));
	macro_processor.transformIntoRTokens(file.tokens);
	with open(file.abs_file.macro_temp_1, "w") as f:
		for chunk in macro_processor.prepareForPreprocess(file.tokens):
			f.write(chunk);
		pass
	pass
pass
if timing: print("1st  :", timer, flush = True);
for file in zzc_files:
	compile(config.compiler.cpp.preprocess, file.abs_file.macro_temp_1, file.abs_file.macro_temp_2);
pass
if timing: print("pp   :", timer, flush = True);
for file in zzc_files:
	with open(file.abs_file.macro_temp_2) as f: raw = f.read();
	raw = "".join(macro_processor.processMarkers(raw, file.tokens));
	#	if "Test" in file.path: print("===\n" + raw + "\n___");
	file.tokens = list(tokenizer.tokenize(raw));
	macro_processor.transformIntoRTokens(file.tokens);
	macro_processor.transformMacroTokensAfterPreprocess(file.tokens);
	semantic.semanticAnalysis(file.tokens);
	
	#	file_id = random.randint(1<<32, (1<<64)-1);
	with open(file.abs_file.hdr, "w") as f:
		f.write("#pragma once\n");
		for chunk in file_composer.compose(file.tokens, "hdr_decl"):
			f.write(chunk);
		pass
		f.write("\n");
		for chunk in file_composer.compose(file.tokens, "hdr_impl"):
			f.write(chunk);
		pass
	pass
	with open(file.abs_file.src, "w") as f:
		f.write(f'#include "./{file.hdr}"\n');
		for chunk in file_composer.compose(file.tokens, "src_decl"):
			f.write(chunk);
		pass
		f.write("\n");
		for chunk in file_composer.compose(file.tokens, "src_impl"):
			f.write(chunk);
		pass
	pass
	for token in file.tokens:
		if token.typ != tokenizer.TokenType.MACRO: continue;
		if token.macro_type != macro_processor.MacroType.INCLUDE: continue;
		if not token.relevant_info.is_zzc: continue;
		parts = FilenameParts(token.relevant_info.filename);
		token.raw = token.relevant_info.before_filename + parts.folder + parts.name + ".zzh" + token.relevant_info.after_filename;
		for k in semantic.sematic_region_keys:
			if getattr(token.region, k): setattr(token.region, k, token.raw);
		pass
	pass
	with open(file.abs_file.inc, "w") as f:
		f.write("#pragma once\n");
		for chunk in file_composer.compose(file.tokens, "hdr_decl"):
			f.write(chunk);
		pass
		f.write("\n");
		for chunk in file_composer.compose(file.tokens, "hdr_impl"):
			f.write(chunk);
		pass
	pass
pass
if timing: print("2nd  :", timer, flush = True);
for file in zzc_files:
	compile(config.compiler.cpp.obj, file.abs_file.src, file.abs_file.obj);
pass
if timing: print("obj  :", timer, flush = True);
compile(config.compiler.target, [file.abs_file.obj for file in zzc_files], config.paths.exe);

if timing: print("exe  :", timer, flush = True);
if timing: print("total:", total, flush = True);
