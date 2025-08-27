import subprocess;

class ProcessGroup:
	def __init__(self, *processes: subprocess.Popen):
		
		self.processes = []
		self.add(processes);
	pass
	def add(self, process: subprocess.Popen):
		if isinstance(process, subprocess.Popen): self.processes.append(process);
		else: 
			for p in process: self.add(p); #	assume iter[Popen]
		pass
	pass
	def clear(self): return self.processes.clear();
	
	def waitAll(self):
		for p in self.processes:
			if p.wait() != 0:
				failed = True;
				for pp in self.processes: pp.terminate();
				return p;
			pass
		pass
	pass
	def waitAllCheck(self):
		if p := self.waitAll(): raise Exception(str(p.args));
	pass
pass