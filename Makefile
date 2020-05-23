# Spreader: Container Terminal Operating System & Stowage Planning Engine
# Build and automation configuration

FLIX ?= flix
PYTHON ?= python3
NODE ?= node

.PHONY: all check build test lint clean check_dashes test-c test-python test-ts test-all run

all: check test-all

check:
	$(FLIX) check

build:
	$(FLIX) build

test:
	$(FLIX) test

test-c:
	$(MAKE) -C tools/c test
	$(MAKE) -C tools/c clean

test-python:
	$(PYTHON) tools/python/test_spreader_viz.py
	$(PYTHON) tools/python/test_generate_synth_baplie.py

test-ts:
	cd tools/ts && npx -p typescript tsc && node dist/test/client.test.js && rm -rf dist

test-all: test test-c test-python test-ts check_dashes

lint: check_dashes

check_dashes:
	$(PYTHON) tools/check_no_em_dashes.py

run:
	$(FLIX) run

clean:
	$(FLIX) clean
	rm -rf build __pycache__ tools/c/bin tools/c/src/*.o tools/ts/dist
