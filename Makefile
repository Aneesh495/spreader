# Spreader: Container Terminal Operating System & Stowage Planning Engine
# Build and automation configuration

FLIX ?= flix
PYTHON ?= python3
CC ?= clang
CFLAGS ?= -std=c11 -Wall -Wextra -Wpedantic -O3

.PHONY: all check build test lint clean check_dashes run demo

all: check test

check:
	$(FLIX) check

build:
	$(FLIX) build

test:
	$(FLIX) test

lint: check_dashes

check_dashes:
	$(PYTHON) tools/check_no_em_dashes.py

run:
	$(FLIX) run

demo:
	$(FLIX) run -- --demo

clean:
	$(FLIX) clean
	rm -rf build __pycache__ tools/c/build
