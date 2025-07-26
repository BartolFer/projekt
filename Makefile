
.DEFAULT_GOAL = all
.PHONY: compile Compile clean Clean ide Ide run Run

Run: run
run:
	python "./Scripts/Runner.py"

Clean: clean
clean:
	python ./Scripts/Clean.py

Compile: compile
compile:
	@echo build
	python ./Compile.py

Ide: ide
ide:
	@echo zzc
	python "./ZZC/zzc.py" "./Targets/Ide/"

