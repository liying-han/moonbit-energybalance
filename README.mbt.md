# moonbit-energybalance

`moonbit-energybalance` is a process-engineering library for steady-state
energy balance calculations in MoonBit. It focuses on enthalpy flow, heat duty,
phase change, heat exchangers, and utility estimates, complementing material
balance code instead of replacing it.

The library is explicit about basis and units. Temperatures are in kelvin,
molar heat capacities are in `J/mol/K`, molar enthalpies are in `J/mol`, flow
rates are in `mol/s`, and duties are in `W`.

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

## Scope

- Heat-capacity models: constant, linear, and polynomial `Cp(T)`.
- Enthalpy references: explicit reference temperature and optional formation
  enthalpy.
- Phase change: latent heat events with temperature and direction.
- Streams: pure and mixture streams with molar flow and composition.
- Steady energy equation: inlet/outlet enthalpy flow, heat, shaft work, kinetic
  and potential terms.
- Heat exchangers: stream duty, LMTD, UA, and effectiveness-NTU estimates.
- Utilities: steam, cooling water, chilled water, and generic service estimates.
- Unit operations: heater, cooler, mixer, splitter, flash vaporization, and heat
  exchanger adapters.

## Validation

Run the same checks used by CI:

```bash
moon fmt --check
moon check --deny-warn
moon info --deny-warn
moon test --deny-warn
```

## Source Note

This project is written from scratch for this repository. Engineering formulas
are standard steady-state thermodynamic relations; correlations are documented
in source comments only where a convention matters. Before implementation, the
Mooncakes package index was checked for `energy balance`, `enthalpy`, `heat
exchanger`, `thermodynamics`, and related Chinese terms; no mature MoonBit
package with the same process energy-balance scope was found.
