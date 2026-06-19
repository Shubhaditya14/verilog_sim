# Foundry Systolic Array Simulation

This project simulates a 16x16 systolic-array matrix multiply accelerator for the Foundry transformer inference accelerator. It is pure RTL simulation (no synthesis) and uses Icarus Verilog on macOS.

## Prerequisites (macOS)

```bash
brew install icarus-verilog gtkwave python
python3 -m pip install numpy
```

## Run

From `foundry_hdl/`:

```bash
make sim
```

Expected output includes a PASS/FAIL message and generates:

- `result.txt` (row-major matrix results)
- `result.vcd` (waveform)
- `bench.txt` (cycle/timing metrics)

## Verify with Python

```bash
make verify
```

## All-in-one

```bash
make all
```

## Benchmark

The simulation also emits `bench.txt` with simple timing metrics. You can run a small benchmark sweep (repeat simulation N times) and summarize:

```bash
make bench RUNS=5
```

## Waveform

```bash
make wave
```

## Notes on Skewing

- Each row input `A[i][k]` is delayed by `i` cycles.
- Each column input `B[k][j]` is delayed by `j` cycles.
- This creates a diagonal wavefront so `PE[i][j]` sees `A[i][k]` and `B[k][j]` in the same cycle.

## Benchmark Output

`bench.txt` is produced by the testbench and includes:

- Total cycles
- First valid input cycle
- Last valid output cycle
- Total latency window
- MACs per cycle estimate
- Clock period used in simulation
