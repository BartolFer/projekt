from __future__ import annotations;
from typing import *;
import inspect as ins;
import sys, os, pathlib;
__actual_file__   = pathlib.Path(ins.getabsfile(ins.currentframe())).resolve();
__actual_dir__    = os.path.dirname(__actual_file__);
if __name__ == '__main__' and not __package__:
	__actual_parent__ = os.path.dirname(__actual_dir__ );
	sys.path.insert(0, __actual_parent__);
	__package__ = os.path.split(__actual_dir__)[1];
pass

import tkinter as tk;
from tkinter import ttk;
from tkinter import filedialog;
import json;

import subprocess;

class Command:
	child_proc: None | subprocess.Popen = None;
	def __init__(self, *args):
		self.frame = tk.Frame(frame);
		self.entries: list[SmartEntry] = [];
		self.run_button       = tk.Button(self.frame, text = "▶", command = self.run);
		self.inner            = tk.Frame (self.frame);
		self.add_button       = tk.Button(self.frame, text = "+", command = self.addEntry);
		self.terminate_button = tk.Button(self.frame, text = "X", command = self.terminate);
		self.run_button      .pack(side = tk.LEFT)
		self.inner           .pack(side = tk.LEFT, fill = tk.X, expand = True);
		self.terminate_button.pack(side = tk.RIGHT, padx = 5);
		self.add_button      .pack(side = tk.RIGHT);
		if args:
			for arg in args: self.addEntry(arg);
		else:
			self.addEntry();
		pass
	pass
	def addEntry(self, arg = None):
		var = tk.StringVar(self.inner, arg);
		entry = SmartEntry(self.inner, var);
		entry.pack(side = tk.LEFT, fill = tk.X, expand = True);
		self.entries.append(entry);
	pass
	def run(self):
		args = [en.var.get() for en in self.entries];
		if self.child_proc is not None:
			if self.child_proc.poll() is None:
				return;
			pass
			self.child_proc = None;
		pass
		self.child_proc = subprocess.Popen(args, cwd = cwd, stdin = sys.stdin, stdout = sys.stdout, stderr = sys.stderr);
		self.checkProc();
	pass
	def terminate(self):
		if self.child_proc is not None:
			self.child_proc.terminate();
			self.run_button.config(bg = "light green" if self.child_proc.returncode == 0 else "red");
		pass
	pass
	def checkProc(self, *_):
		if self.child_proc.poll() is not None:
			self.run_button.config(bg = "light green" if self.child_proc.returncode == 0 else "red");
		else:
			self.run_button.config(bg = "yellow");
			self.frame.after(1000, self.checkProc)
		pass
	pass
pass

class CharType:
	SPACE  = 1 << 0;
	WORD   = 1 << 1;
	SYMBOL = 1 << 2;
	
	def __new__(self, c: str):
		if c.isspace(): return CharType.SPACE;
		if c.isalnum(): return CharType.WORD;
		if c in "-_": return CharType.SYMBOL | CharType.WORD;
		if c.isprintable(): return CharType.SYMBOL;
	pass
	
	@staticmethod
	def base(c): 
		if c.isspace(): return CharType.SPACE;
		if c.isalnum(): return CharType.WORD;
		if c in "-_": return CharType.SYMBOL;
		if c.isprintable(): return CharType.SYMBOL;
	pass
pass
def detectWordBoundary(text: str, current_index: int) -> tuple[int, int]:
	if not text: return (0, 0);
	if current_index < 0: current_index = 0;
	if current_index >= len(text): current_index = len(text) - 1;
	
	c = text[current_index];
	
	char_type = CharType(c);
	if c in "_-": char_type = CharType.SYMBOL;
	
	for start in reversed(range(current_index)):
		if CharType(text[start]) & char_type == 0: 
			start += 1;
			break;
		pass
	else:
		start = 0;
	pass
	for end in range(current_index + 1, len(text)):
		if CharType(text[end]) & char_type == 0: 
			break;
		pass
	else:
		end = len(text);
	pass
	
	return (start, end);
pass
class SmartEntry(ttk.Entry):
	def __init__(self, master, var: tk.StringVar, *args, **kwargs):
		self.var = var;
		ttk.Entry.__init__(self, master, *args, **kwargs, textvariable = var);
		self.openfile   = tk.Button(self, text = "📄", takefocus = False, command = self.commandOpenfile  );
		self.openfolder = tk.Button(self, text = "📁", takefocus = False, command = self.commandOpenfolder);
		self.openfolder.pack(side = tk.RIGHT);
		self.openfile  .pack(side = tk.RIGHT);
		
		self.bind("<Double-Button-1>"    , self.onDoubleClick   );
		self.bind("<ButtonRelease-1>"    , self.onB1Release     );
		self.bind("<B1-Motion>"          , self.onDrag          );
		self.bind("<Left>"               , self.onLeft          );
		self.bind("<Right>"              , self.onRight         );
		self.bind("<Control-Left>"       , self.onCtrlLeft      );
		self.bind("<Control-Right>"      , self.onCtrlRight     );
		self.bind("<Shift-Left>"         , self.onShiftLeft     );
		self.bind("<Shift-Right>"        , self.onShiftRight    );
		self.bind("<Control-Shift-Left>" , self.onCtrlShiftLeft );
		self.bind("<Control-Shift-Right>", self.onCtrlShiftRight);
		self.dragging_double_anchor = None;
	pass
	
	def commandOpenfile(self):
		path = self.get();
		if path.startswith("."): path = cwd + "/" + path;
		path = filedialog.askopenfilename(initialdir = os.path.dirname(path), initialfile = path);
		if not path: return;
		if os.path.normpath(path).startswith(os.path.normpath(cwd)): path = "./" + os.path.relpath(path, cwd);
		self.var.set(path);
	pass
	def commandOpenfolder(self):
		path = self.get();
		if path.startswith("."): path = cwd + "/" + path;
		path = filedialog.askdirectory(initialdir = path);
		if not path: return;
		if os.path.normpath(path).startswith(os.path.normpath(cwd)): path = "./" + os.path.relpath(path, cwd);
		self.var.set(path);
	pass
	
	def indexAtEvent(self, event): return self.index(f"@{event.x}");
	
	def getPrevStep(self, index: int = None) -> int: 
		if index is None: index = self.index(tk.INSERT);
		return detectWordBoundary(self.get(), index - 1)[0];
	pass
	def getNextStep(self, index: int = None) -> int: 
		if index is None: index = self.index(tk.INSERT);
		return detectWordBoundary(self.get(), index)[1];
	pass
	
	def onDoubleClick(self, event):
		idx = self.indexAtEvent(event);
		(start, end) = detectWordBoundary(self.get(), idx);
		self.selection_range(start, end);
		self.icursor(end);
		self.dragging_double_anchor = (start, end);
		return "break";
	pass
	
	def onB1Release(self, event):
		self.dragging_double_anchor = None;
	pass
	
	def onDrag(self, event):
		if self.dragging_double_anchor is None: return;
		idx = self.indexAtEvent(event);
		(start, end) = detectWordBoundary(self.get(), idx)
		(sel_start, sel_end) = (self.index(tk.SEL_FIRST), self.index(tk.SEL_LAST));
		(anchor_start, anchor_end) = self.dragging_double_anchor;
		idx = None;
		if anchor_start < start: (idx, start) = (end  , anchor_start);
		if anchor_end   > end  : (idx, end  ) = (start, anchor_end  );
		if idx is None:
			if start != self.index(tk.SEL_FIRST): idx = start;
			#	if end   != self.index(tk.SEL_LAST ): idx = end  ;
			else: idx = end;
		pass
		
		self.selection_range(start, end);
		self.icursor(idx);
		return "break";
	pass
	
	def onLeft(self, event):
		if not self.select_present(): return;
		idx = self.index(tk.SEL_FIRST);
		self.select_clear();
		self.icursor(idx);
		return "break";
	pass
	def onRight(self, event):
		if not self.select_present(): return;
		idx = self.index(tk.SEL_LAST);
		self.select_clear();
		self.icursor(idx);
		return "break";
	pass
	
	def onCtrlLeft(self, event):
		if self.select_present(): return self.onLeft(event);
		idx = self.getPrevStep();
		self.icursor(idx);
		return "break";
	pass
	def onCtrlRight(self, event):
		if self.select_present(): return self.onRight(event);
		idx = self.getNextStep();
		self.icursor(idx);
		return "break";
	pass
	
	def onShiftLeft(self, event):
		idx = self.index(tk.INSERT);
		if self.select_present(): 
			end = self.index(tk.SEL_LAST);
			if idx == end: end = self.index(tk.SEL_FIRST);
		else: end = self.index(tk.INSERT);
		idx = start = idx - 1;
		if end < start: (start, end) = (end, start);
		self.select_range(start, end);
		self.icursor(idx);
		return "break";
	pass
	def onShiftRight(self, event):
		idx = self.index(tk.INSERT);
		if self.select_present(): 
			start = self.index(tk.SEL_FIRST);
			if idx == start: start = self.index(tk.SEL_LAST);
		else: start = self.index(tk.INSERT);
		idx = end = idx + 1;
		if end < start: (start, end) = (end, start);
		self.select_range(start, end);
		self.icursor(idx);
		return "break";
	pass
	
	def onCtrlShiftLeft(self, event):
		idx = self.index(tk.INSERT);
		if self.select_present(): 
			end = self.index(tk.SEL_LAST);
			if idx == end: end = self.index(tk.SEL_FIRST);
		else: end = self.index(tk.INSERT);
		idx = start = self.getPrevStep(idx);
		if end < start: (start, end) = (end, start);
		self.select_range(start, end);
		self.icursor(idx);
		return "break";
	pass
	def onCtrlShiftRight(self, event):
		idx = self.index(tk.INSERT);
		if self.select_present(): 
			start = self.index(tk.SEL_FIRST);
			if idx == start: start = self.index(tk.SEL_LAST);
		else: start = self.index(tk.INSERT);
		idx = end = self.getNextStep(idx);
		if end < start: (start, end) = (end, start);
		self.select_range(start, end);
		self.icursor(idx);
		return "break";
	pass
pass



window = tk.Tk();
frame = tk.Frame(window);
frame.place(relheight = 1, relwidth = 1);

commands: list[Command] = [];
def addCommand(*args):
	command = Command(*args);
	commands.append(command);
	command.frame.pack(fill = tk.X);
	return command;
pass

def setGUI(config):
	for child in list(frame.children.values()): child.destroy();
	for args in config: addCommand(*args);
pass
def loadConfig():
	path = filedialog.askopenfilename(filetypes = [("JSON", "*.json"), ("Any", "*")], title = "Load Config", initialdir = __actual_dir__ + "/" + "./RunnerConfigs/");
	if not path: return;
	loadConfigFromPath(path);
pass
def loadConfigFromPath(path: str):
	with open(path) as file: config = json.load(file);
	assert type(config) is list;
	assert all(type(args) is list for args in config);
	assert all(type(arg) is str for args in config for arg in args);
	setGUI(config);
pass
def storeConfig():
	config = [[en.var.get() for en in command.entries] for command in commands];
	path = filedialog.asksaveasfilename(filetypes = [("JSON", "*.json"), ("Any", "*")], title = "Store Config", initialdir = __actual_dir__ + "/" + "./RunnerConfigs/");
	if not path: return;
	with open(path, "w") as file: json.dump(config, file);
pass

add_button = ttk.Button(window, text = "Add", command = addCommand);
add_button.place(x = 10, width = 100, rely = 1, anchor = tk.SW);

load_button = ttk.Button(window, text = "Load", command = loadConfig);
load_button.place(x = 120, width = 100, rely = 1, anchor = tk.SW);
add_button = ttk.Button(window, text = "Store", command = storeConfig);
add_button.place(x = 230, width = 100, rely = 1, anchor = tk.SW);



#	dbg_button = ttk.Button(window, text = "Debug", command = lambda: print("Nothing to debug", sep = "\n"));
dbg_button = ttk.Button(window, text = "Debug", command = lambda: print(sys.stdout, sep = "\n"));
dbg_button.place(relx = 1, width = 100, rely = 1, anchor = tk.SE);

cwd = "D:/Personal/nastava/projekt";
os.chdir(cwd);
initial = [
	[sys.executable, "./Scripts/Clean.py"],
	[sys.executable, "./Scripts/Compile.py"],
	["./Targets/Decode/Build/BJpegDecode.exe", "./Temp/Zugpsitze_mountain.jpg", "./Temp/Zugpsitze_mountain.rgba", ],
	["./Scripts/RgbDisplay/a.exe", "./Temp/Zugpsitze_mountain.rgba", ],
	[sys.executable, "./Scripts/JPG_to_JPGDEF.py", "./Temp/Zugpsitze_mountain.jpg", "./Temp/Zugpsitze_mountain.def.jpg", ],
	["./Targets/Encode/Build/BJpegEncode.exe", "./Temp/Zugpsitze_mountain.rgba", "./Temp/Zugpsitze_mountain.def.jpg", "./Temp/Zugpsitze_mountain.out.jpg", "122"],
];

if len(sys.argv) == 1:
	setGUI(initial);
elif len(sys.argv) == 2:
	loadConfigFromPath(sys.argv[1]);
else:
	raise Exception;
pass


window.geometry("1500x400");

window.mainloop();
