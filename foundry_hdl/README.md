# Foundry Systolic Array Simulation

This project simulates a 16x16 systolic-array matrix multiply accelerator for the Foundry transformer inference accelerator. It is pure RTL simulation, uses Icarus Verilog, and includes both the project RTL testbench and a standalone self-contained 16x16 systolic-array testbench.

## Prerequisites

macOS:

```bash
brew install icarus-verilog gtkwave python
python3 -m pip install numpy
```

Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y iverilog gtkwave python3 python3-numpy
```

## File Structure

- `rtl/pe.v` - Processing element used by the main systolic array RTL.
- `rtl/systolic_array.v` - Main 16x16 systolic array RTL.
- `tb/tb_systolic_array.v` - Existing project testbench for the RTL array.
- `tb/tb_systolic_16x16.v` - Self-contained 16x16 systolic array testbench — 3 test cases, runs standalone with no external dependencies.
- `verify.py` - Python verification helper for simulation output.
- `bench/bench_runner.py` - Repeated simulation benchmark runner.
- `Makefile` - Simulation, verification, benchmark, waveform, and cleanup targets.

## Usage

Run the existing project RTL testbench:

```bash
make sim
```

Run the standalone self-contained 16x16 testbench:

```bash
make sim16
```

Run the Python verification step against `result.txt`:

```bash
make verify
```

Run the full local validation flow:

```bash
make all
```

`make all` runs these targets in order:

```text
make sim
make sim16
make verify
```

Run a repeated simulation benchmark sweep:

```bash
make bench RUNS=5
```

Open the existing RTL testbench waveform:

```bash
make wave
```

Remove generated outputs:

```bash
make clean
```

## Standalone 16x16 Testbench

`tb/tb_systolic_16x16.v` contains its own inline `pe` and `systolic_array_core` modules, so it does not depend on files in `rtl/`. The Makefile target compiles and runs it as:

```bash
iverilog -g2012 -o build/sim16 tb/tb_systolic_16x16.v && vvp build/sim16
```

It runs three test cases:

- Identity matrix: `A` is identity, so `C = B`.
- Known values: `A[i][j] = i+1`, `B[i][j] = j+1`, so `C[i][j] = 16*(i+1)*(j+1)`.
- Pseudo-random values: deterministic signed INT8 inputs with expected results computed inside the testbench.

Expected successful output:

```text
=== Foundry Systolic Array Testbench ===
=== 16x16 INT8 Matrix Multiply ===

--- Test 1: Identity Matrix ---
Cycles: 46
PASS

--- Test 2: Known Values (A[i][j]=i+1, B[i][j]=j+1) ---
Cycles: 46
PASS

--- Test 3: Pseudo-random Values ---
Cycles: 46
PASS

=== ALL TESTS PASSED ===
Total cycles across all tests: 138
VCD written to systolic_16x16.vcd
```

## Generated Outputs

`make sim` generates:

- `sim.out` - Icarus simulation executable for the existing RTL testbench.
- `result.txt` - Row-major matrix results.
- `result.vcd` - Waveform for the existing RTL testbench.
- `bench.txt` - Cycle/timing metrics from the existing RTL testbench.

`make sim16` generates:

- `build/sim16` - Icarus simulation executable for the standalone 16x16 testbench.
- `systolic_16x16.vcd` - Waveform for the standalone 16x16 testbench.

## Notes on Skewing

- Each row input `A[i][k]` is delayed by `i` cycles.
- Each column input `B[k][j]` is delayed by `j` cycles.
- This creates a diagonal wavefront so `PE[i][j]` sees `A[i][k]` and `B[k][j]` in the same cycle.
- For the 16x16 standalone testbench, each test drains in 46 cycles: `N + N + N - 2` for `N = 16`.

## Benchmark Output

`bench.txt` is produced by the existing RTL testbench and includes:

- Total cycles
- First valid input cycle
- Last valid output cycle
- Total latency window
- MACs per cycle estimate
- Clock period used in simulation
