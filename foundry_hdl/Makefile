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
BUILD_DIR := build
SIM16_OUT := $(BUILD_DIR)/sim16

.PHONY: sim sim16 wave verify bench all clean $(BUILD_DIR)

sim:
	$(SIM) -g2012 -o $(OUT) $(RTL) $(TB)
	$(VVP) $(OUT)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

sim16: $(BUILD_DIR)
	iverilog -g2012 -o build/sim16 tb/tb_systolic_16x16.v && vvp build/sim16

wave:
	$(GTKWAVE) result.vcd

verify:
	$(PY) verify.py

bench:
	$(PY) bench/bench_runner.py --runs $(RUNS)

all: sim sim16 verify

clean:
	rm -f $(OUT) result.vcd result.txt bench.txt systolic_16x16.vcd
	rm -rf $(BUILD_DIR)
