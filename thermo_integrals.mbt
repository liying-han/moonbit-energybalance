///|
pub fn average_heat_capacity(
  substance : Substance,
  from_temperature : Double,
  to_temperature : Double,
) -> Double {
  let delta = to_temperature - from_temperature
  if delta.abs() < 1.0e-12 {
    substance.cp_model.cp_at(from_temperature)
  } else {
    substance.sensible_enthalpy_change(from_temperature, to_temperature) / delta
  }
}

///|
pub fn sensible_heat(
  substance : Substance,
  molar_flow : Double,
  from_temperature : Double,
  to_temperature : Double,
) -> Double {
  molar_flow *
  substance.sensible_enthalpy_change(from_temperature, to_temperature)
}

///|
pub fn phase_change_heat(
  substance : Substance,
  molar_flow : Double,
  from_temperature : Double,
  to_temperature : Double,
) -> Double {
  molar_flow *
  substance.phase_change_enthalpy_change(from_temperature, to_temperature)
}

///|
pub fn total_molar_heat(
  substance : Substance,
  from_temperature : Double,
  to_temperature : Double,
) -> Double {
  substance.sensible_enthalpy_change(from_temperature, to_temperature) +
  substance.phase_change_enthalpy_change(from_temperature, to_temperature)
}

///|
pub fn enthalpy_change_with_formation(
  substance : Substance,
  from_temperature : Double,
  to_temperature : Double,
) -> Double {
  substance.enthalpy_at(to_temperature) -
  substance.enthalpy_at(from_temperature)
}

///|
pub fn integrate_temperature_profile(
  substance : Substance,
  points : Array[Double],
) -> Double {
  if points.length() < 2 {
    0.0
  } else {
    let mut total = 0.0
    for i in 0..<(points.length() - 1) {
      total += substance.sensible_enthalpy_change(points[i], points[i + 1])
      total += substance.phase_change_enthalpy_change(points[i], points[i + 1])
    }
    total
  }
}

///|
pub fn weighted_heat_capacity(
  substances : Array[Substance],
  weights : Array[Double],
  temperature : Double,
) -> Double {
  let length = substances.length().min(weights.length())
  let mut total = 0.0
  for i in 0..<length {
    total += weights[i] * substances[i].cp_model.cp_at(temperature)
  }
  total
}

///|
pub fn weighted_enthalpy(
  substances : Array[Substance],
  weights : Array[Double],
  temperature : Double,
) -> Double {
  let length = substances.length().min(weights.length())
  let mut total = 0.0
  for i in 0..<length {
    total += weights[i] * substances[i].enthalpy_at(temperature)
  }
  total
}

///|
pub fn temperature_from_sensible_heat(
  substance : Substance,
  from_temperature : Double,
  heat_per_mole : Double,
  upper_temperature : Double,
) -> Double {
  let target = substance.enthalpy_at(from_temperature) + heat_per_mole
  let mut low = from_temperature.min(upper_temperature)
  let mut high = from_temperature.max(upper_temperature)
  for _ in 0..<64 {
    let middle = (low + high) / 2.0
    if substance.enthalpy_at(middle) < target {
      low = middle
    } else {
      high = middle
    }
  }
  (low + high) / 2.0
}
