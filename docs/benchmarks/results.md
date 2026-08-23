# Benchmark results

The repository benchmark is a deterministic functional workload, not a
synthetic loop. Each iteration creates a water stream, runs a heater and
cooler, closes a steady-state balance, and evaluates a heat-exchanger UA.
The checksum changes with the iteration count and is asserted by tests.

Command:

    moon run --target native benchmarks

Environment used for this capture:

- Windows PowerShell
- Moon 0.1.20260807 (4da23f8, 2026-08-07)
- moonc 0.10.7+bc794d341 (2026-08-11)
- 10,000 iterations

Captured output:

    moonbit-energybalance benchmark
    workload=water-heater-cooler-exchanger, iterations=10000, checksum=18825000, residual=-4.547473508864641e-10
    average duty: 1506 W
    average residual: -4.5474735088646414e-14 W

One end-to-end PowerShell measurement of the same command was 345 ms. That
number includes MoonBit build/cache overhead and is therefore useful as a
reproducibility reference, not as a portable hardware-normalized throughput
claim. Re-run the command on the target machine before comparing performance.
