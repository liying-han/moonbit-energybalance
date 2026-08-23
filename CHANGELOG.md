# Changelog

## 0.2.2

- Documented the operating-envelope API, its screening assumptions, and its
  boundary-test coverage.

## 0.2.1

- Added operating-window scanning, feasibility filtering, Pareto selection,
  ramp planning, constraint projection, and CSV reporting for process
  operating points.
- Added boundary coverage for envelope validation, scan grids, projections,
  selections, and ramp plans.

## 0.2.0

- Added explicit unit conversions, thermodynamic integration helpers, and
  physical input contracts.
- Added moist-air psychrometrics, steam state/table estimates, water transport
  properties, and air-conditioning reports.
- Added stoichiometric reaction heat, limiting-reactant conversion, kinetics,
  recycle fixed-point solving, directed stream-network propagation, and unit
  scheduling.
- Added pinch targets, heat-recovery matching, equipment sizing, dynamic
  lumped thermal response, sensitivity, uncertainty, operating costs, and
  deterministic case-study exports.
- Added process audits, CSV-like report exports, edge-case tests, a native
  benchmark executable, coverage checks, and all-target CI.

## 0.1.0

- Added explicit thermodynamic basis with kelvin, molar flow, molar enthalpy,
  and watt duty conventions.
- Added constant, linear, and polynomial heat-capacity models.
- Added phase-change enthalpy events for melting, freezing, vaporization, and
  condensation.
- Added pure and mixture streams with enthalpy-flow and heat-capacity-flow
  helpers.
- Added steady-state balance helpers for heat, shaft work, kinetic, and
  potential terms.
- Added heat-exchanger utilities for counter-current and parallel LMTD, UA, and
  effectiveness-NTU estimates.
- Added heater, cooler, mixer, splitter, flash-vaporization, steam, and cooling
  water utility helpers.
- Added catalog substances for water, steam, ice, nitrogen, methane, and generic
  engineering estimates.
- Added CLI demo, README checked example, and CI across Linux, macOS, and
  Windows.
