SHELL := /bin/bash
ROOT := $(CURDIR)

SIM ?= iverilog
VVP ?= vvp
PY ?= python3
GTKWAVE ?= gtkwave
RUNS ?= 5

RTL := rtl/pe.v rtl/systolic_array.v
TB := tb/tb_systolic_array.v
OUT := sim.out

.PHONY: sim wave verify bench all clean

sim:
	$(SIM) -g2012 -o $(OUT) $(RTL) $(TB)
	$(VVP) $(OUT)

wave:
	$(GTKWAVE) result.vcd

verify:
	$(PY) verify.py

bench:
	$(PY) bench/bench_runner.py --runs $(RUNS)

all: sim verify

clean:
	rm -f $(OUT) result.vcd result.txt bench.txt
