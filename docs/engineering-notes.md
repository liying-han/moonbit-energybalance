# Engineering notes

The package is intended for transparent screening calculations. Every public
result uses explicit units in its field or function name where a unit could be
ambiguous.

## Property models

- Constant, linear, and polynomial heat-capacity models integrate analytically.
  Formation enthalpy is an additive reference term.
- Latent heat events use a directional, half-open crossing rule. Heating and
  cooling therefore have opposite signs at a transition.
- Moist-air functions use a Magnus saturation-pressure correlation and the
  standard humidity-ratio and moist-air enthalpy relations. Pressure is kPa and
  humidity ratio is kg water per kg dry air.
- Steam helpers are deliberately lightweight estimators. Saturation uses a
  Magnus-type relation, liquid enthalpy uses a linear fit, and vapor enthalpy
  uses a temperature-dependent latent-heat fit. The table helpers interpolate
  between the checked-in pressure points and report clamping explicitly.
- Water transport properties are smooth engineering estimates suitable for
  preliminary sizing, not certification.

## Process models

Steady-state balances use the sign convention

    H_in + Q - W_shaft + W_kinetic + W_potential - H_out = residual

Positive heat duty means heat is added to the process. A negative duty is a
cooling load. Network propagation is a directed stream-graph helper: it
propagates a source once through each reachable connection and reports missing
inputs rather than silently inventing them. Recycle temperature solving is an
explicit fixed-point iteration and reports non-convergence.

## Numerical behavior

Boundary-oriented APIs clamp fractions and qualities to their physical ranges,
return zero for non-positive denominators where a safe estimate is meaningful,
and expose validation or convergence results when a number cannot be trusted.
Callers should still validate inputs with validate_process and the relevant
contract helpers before using a result in a design decision.

## Operating envelopes

Operating points combine temperature, mass flow, pressure, duty, operating
cost, and emissions into one auditable record. OperatingConstraints defines
the admissible window; scan_operating_envelope evaluates a deterministic grid
of candidate states; envelope_best_weighted and envelope_pareto_frontier
support cost/duty/emissions trade-offs; ramp_plan estimates the time and
energy required to move between selected states. CSV exports preserve the
calculation basis for downstream review.

Envelope selection is a screening aid rather than an automatic control
signal. The package reports invalid inputs and infeasible points explicitly,
and projection helpers clamp process states only when the caller requests
that behavior.

## Scope limits

The package does not provide certified steam tables, electrolyte or
multi-component equation-of-state calculations, reaction equilibrium, detailed
hydraulics, or mechanical design code. Those are integration points for a
future property-package adapter; the current API keeps the approximations
visible so they can be replaced without changing stream and balance concepts.
