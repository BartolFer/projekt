
.DEFAULT_GOAL = all
.PHONY: compile clean ide run

clean:
	python Clean.py

run: compile
	@Build/a.exe

all: compile
compile:
	@echo build
	python ./Compile.py
ide:
	@echo zzc
	python ./Compile.py

