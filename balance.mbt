///|
pub fn BalanceTerms::BalanceTerms(
  heat? : Double = 0.0,
  shaft_work? : Double = 0.0,
  kinetic? : Double = 0.0,
  potential? : Double = 0.0,
) -> BalanceTerms {
  { heat, shaft_work, kinetic, potential }
}

///|
pub fn enthalpy_flow_sum(streams : Array[Stream]) -> Double {
  let mut total = 0.0
  for stream in streams {
    total += stream.enthalpy_flow()
  }
  total
}

///|
pub fn steady_state_balance(
  inlets : Array[Stream],
  outlets : Array[Stream],
  terms? : BalanceTerms = BalanceTerms(),
) -> BalanceResult {
  let hin = enthalpy_flow_sum(inlets)
  let hout = enthalpy_flow_sum(outlets)
  let residual = hin +
    terms.heat -
    terms.shaft_work +
    terms.kinetic +
    terms.potential -
    hout
  {
    inlet_enthalpy_flow: hin,
    outlet_enthalpy_flow: hout,
    heat: terms.heat,
    shaft_work: terms.shaft_work,
    residual,
  }
}

///|
pub fn required_heat(
  inlets : Array[Stream],
  outlets : Array[Stream],
  shaft_work? : Double = 0.0,
  kinetic? : Double = 0.0,
  potential? : Double = 0.0,
) -> Double {
  enthalpy_flow_sum(outlets) -
  enthalpy_flow_sum(inlets) +
  shaft_work -
  kinetic -
  potential
}

///|
pub fn is_balanced(
  result : BalanceResult,
  tolerance? : Double = 1.0e-6,
) -> Bool {
  result.residual.abs() <= tolerance
}
