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
from cache import *;
import tokenizer, macro_processor, semantic, file_composer;

class Timer:
	def __init__(self):
		self.t = time.monotonic();
	pass
	def __repr__(self):
		y = time.monotonic();
		d = y - self.t;
		self.t = y;
		d = round(d * 1000);
		(d, ms) = divmod(d, 1000);
		(m, s) = divmod(d, 60);
		return f"{m:02}:{s:02}.{ms:03}";
	pass
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

def step1(file: File):
	if file.tokens is not None: return;
	with open(file.abs_file.path) as f: raw = f.read();
	file.tokens = list(tokenizer.tokenize(raw));
	macro_processor.transformIntoRTokens(file.tokens);
	with open(file.abs_file.macro_temp_1, "w") as f:
		for chunk in macro_processor.prepareForPreprocess(file.tokens):
			f.write(chunk);
		pass
	pass
pass
def updateCache(file: File):
	direct_dependancy = cache.direct_dependancies[file] = [];
	dirname = config.paths.zzc + "/" + (os.path.dirname(file.path) or ".");
	#	print(repr(dirname), "        ", root + "/" + config.paths.zzc);
	#	dirname = os.path.relpath(dirname1, root + "/" + config.paths.zzc);
	for token in file.tokens:
		if token.typ != tokenizer.TokenType.MACRO: continue;
		if token.macro_type != macro_processor.MacroType.INCLUDE: continue;
		if not token.relevant_info.is_zzc: continue;
		filename = token.relevant_info.filename;
		if filename.endswith(".zzh"): filename = filename[ : -4] + ".zzc";
		f = File(dirname + "/" + filename);
		if f not in direct_dependancy: direct_dependancy.append(f);
		#	print(dirname, file.path, f.path, sep="         ");
	pass
	#	print(file, direct_dependancy);
pass

timer = Timer();
total = Timer();
timing = True;
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

outdated = [file for file in zzc_files if isOutdated(file)];
if not outdated: sys.exit(0);
for file in zzc_files:
	if file in outdated: continue;
	if file in cache.direct_dependancies.keys(): continue;
	step1(file);
	updateCache(file);
pass
for file in outdated:
	step1(file);
	updateCache(file);
pass
cache.direct_dependancies = {file: [d for d in deps if d in zzc_files] for (file, deps) in cache.direct_dependancies.items() if file in zzc_files};
(dependancies, reversed_dependancies) = buildDependancies();
cache.save();
if timing: print("cache:", timer, flush = True);

for file in outdated:
	if file not in reversed_dependancies.keys(): continue;
	for f in reversed_dependancies[file]:
		if f not in outdated: outdated.append(f);
	pass
pass

for file in outdated: step1(file);
if timing: print("1st  :", timer, flush = True);
for file in outdated:
	compile(config.compiler.cpp.preprocess, file.abs_file.macro_temp_1, file.abs_file.macro_temp_2);
pass
if timing: print("pp   :", timer, flush = True);
for file in outdated:
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
		self_inc = os.path.split(file.hdr)[-1];
		f.write(f'#include "./{self_inc}"\n');
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
if config.nocompile or "-nocompile" in sys.argv[2 : ]:
	print("nocompile");
	sys.exit();
pass
for file in outdated:
	compile(config.compiler.cpp.obj, file.abs_file.src, file.abs_file.obj);
pass
if timing: print("obj  :", timer, flush = True);
compile(config.compiler.target, [file.abs_file.obj for file in zzc_files], config.paths.exe);

if timing: print("exe  :", timer, flush = True);
if timing: print("total:", total, flush = True);
