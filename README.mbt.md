# moonbit-energybalance

moonbit-energybalance is a MoonBit library for process energy calculations:
enthalpy flow, heat duty, phase change, heat exchangers, utilities, reaction
heat, psychrometrics, steam properties, network propagation, and equipment
sizing helpers.

It is designed for process-model prototypes, teaching examples, equipment
screening, and reusable MoonBit numerical workflows. The calculation basis is
explicit: temperature is K unless a function name says _c, pressure is kPa
unless stated otherwise, molar flow is mol/s, molar enthalpy is J/mol, mass
enthalpy is kJ/kg, and duty is W.

## Core capabilities

- Thermodynamic primitives: constant, linear, and polynomial Cp(T), explicit
  reference states, formation enthalpy, latent-heat events, and unit helpers.
- Streams and balances: pure or mixed streams, enthalpy and heat-capacity flow,
  steady-state balances, validation reports, snapshots, and CSV exports.
- Equipment: heaters, coolers, mixers, splitters, flash vaporization, LMTD/UA,
  effectiveness-NTU, pinch targets, heat recovery, and equipment sizing.
- Property estimates: moist-air humidity ratio, enthalpy, dew point, wet bulb,
  steam states and interpolation tables, and common water transport properties.
- Process analysis: reaction stoichiometry and duty, kinetics, recycle
  convergence, network propagation, scheduling, sensitivity, uncertainty,
  dynamic lumped heating, utility cost estimates, and operating-envelope
  scanning with Pareto selection, ramp planning, and CSV reporting.

The correlations are deterministic screening models. Their assumptions and
validity ranges are documented in
[docs/engineering-notes.md](docs/engineering-notes.md); they are not a
replacement for certified property packages or detailed design codes.

## Quick start

Construct a stream and evaluate its sensible duty:

```mbt check
///|
test "README sensible heater example" {
  let water = water_liquid()
  let feed = Stream::pure(
    id="feed",
    substance=water,
    molar_flow=2.0,
    temperature=293.15,
  )
  let hot = feed.with_temperature(333.15)
  inspect(heat_duty(feed, hot).round(), content="6024")
}
```

The runnable demo is in cmd/main. The library has no runtime configuration and
no network or file-system dependency.

## CLI

Run the demo:

```bash
moon run cmd/main
```

Run the deterministic native benchmark:

```bash
moon run --target native benchmarks
```

The benchmark prints its workload, iteration count, checksum, average duty,
and average balance residual. A captured run and the exact environment are in
[docs/benchmarks/results.md](docs/benchmarks/results.md).

## Architecture

The root package is the public facade. Files are organized by domain:
types/substance/stream form the thermodynamic core; balance,
unit_operations, and heat_exchanger provide process operations; psychrometrics,
steam_*, and fluid_properties provide property estimates; reaction_*,
network*, sensitivity, uncertainty, dynamics, and operating_costs provide
analysis layers. operating_envelope provides constraint-aware process
windows, grid evaluation, multi-objective selection, and operating plans.
cmd/main is the usage demo and benchmarks is an independent native executable.

## Tests

The test suite covers normal calculations and boundary behavior including empty
mixtures, invalid fractions and temperatures, equal-temperature LMTD, latent
heat crossings, near-singular utility calculations, missing network inputs,
non-convergent recycle factors, capped kinetics, and zero-duration dynamics.
Operating-envelope tests also cover invalid constraints, empty selections,
duplicate points, feasibility projection, interpolation, Pareto selection,
reverse ramps, and deterministic report exports.

```bash
moon fmt --check
moon check --target all --deny-warn
moon test --target all --deny-warn
moon coverage analyze
```

## CI

GitHub Actions checks formatting, all MoonBit targets, warnings, tests,
coverage, generated interface drift, and the native benchmark. The workflow
installs the current stable MoonBit CLI on each runner.

## License

Apache-2.0. See [LICENSE](LICENSE).
