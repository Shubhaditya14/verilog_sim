import argparse
from statistics import mean
import subprocess


def parse_bench(path):
    data = {}
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or "=" not in line:
                continue
            k, v = line.split("=", 1)
            data[k.strip()] = v.strip()
    return data


def run_once():
    subprocess.run(["make", "sim"], check=True)
    return parse_bench("bench.txt")


def main():
    parser = argparse.ArgumentParser(description="Run multiple sims and summarize bench.txt")
    parser.add_argument("--runs", type=int, default=5, help="number of simulation runs")
    args = parser.parse_args()

    latencies = []
    macs_per_cycle = []
    for r in range(args.runs):
        bench = run_once()
        latencies.append(int(bench["latency_cycles"]))
        macs_per_cycle.append(float(bench["macs_per_cycle"]))
        print(
            f"Run {r+1}/{args.runs}: latency={latencies[-1]} cycles, "
            f"macs/cycle={macs_per_cycle[-1]:.2f}"
        )

    print("\nSummary")
    print(f"runs={args.runs}")
    print(f"latency_cycles_avg={mean(latencies):.2f}")
    print(f"macs_per_cycle_avg={mean(macs_per_cycle):.2f}")


if __name__ == "__main__":
    main()
