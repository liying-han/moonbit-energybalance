///|
fn pressure_table() -> Array[Double] {
  [10.0, 50.0, 100.0, 101.325, 200.0, 500.0, 1000.0, 2000.0]
}

///|
fn saturation_temperature_table() -> Array[Double] {
  [45.81, 81.32, 99.61, 100.0, 120.23, 151.83, 179.88, 212.38]
}

///|
fn table_bracket(values : Array[Double], target : Double) -> (Int, Int) {
  if values.length() < 2 {
    (0, 0)
  } else if target <= values[0] {
    (0, 1)
  } else if target >= values[values.length() - 1] {
    (values.length() - 2, values.length() - 1)
  } else {
    let mut lower = 0
    for i in 0..<(values.length() - 1) {
      if values[i] <= target && target <= values[i + 1] {
        lower = i
        break
      }
    }
    (lower, lower + 1)
  }
}

///|
pub fn tabulated_saturation_temperature_c(
  pressure_kpa : Double,
) -> SteamTableResult {
  let pressure = pressure_table()
  let temperatures = saturation_temperature_table()
  let (lower, upper) = table_bracket(pressure, pressure_kpa)
  interpolate_table(
    pressure[lower],
    temperatures[lower],
    pressure[upper],
    temperatures[upper],
    pressure_kpa,
  )
}

///|
pub fn tabulated_saturated_liquid_enthalpy(
  pressure_kpa : Double,
) -> SteamTableResult {
  let temperature = tabulated_saturation_temperature_c(pressure_kpa)
  let estimate = saturated_liquid_enthalpy_kj_per_kg(temperature.value)
  { ..temperature, value: estimate }
}

///|
pub fn tabulated_saturated_vapor_enthalpy(
  pressure_kpa : Double,
) -> SteamTableResult {
  let temperature = tabulated_saturation_temperature_c(pressure_kpa)
  let estimate = saturated_vapor_enthalpy_kj_per_kg(temperature.value)
  { ..temperature, value: estimate }
}

///|
pub fn table_quality_from_enthalpy(
  pressure_kpa : Double,
  enthalpy_kj_per_kg : Double,
) -> SteamTableResult {
  let liquid = tabulated_saturated_liquid_enthalpy(pressure_kpa)
  let vapor = tabulated_saturated_vapor_enthalpy(pressure_kpa)
  if vapor.value <= liquid.value {
    {
      value: 0.0,
      lower_bound: liquid.value,
      upper_bound: vapor.value,
      clamped: false,
      valid: false,
    }
  } else {
    let x = (enthalpy_kj_per_kg - liquid.value) / (vapor.value - liquid.value)
    {
      value: x.max(0.0).min(1.0),
      lower_bound: 0.0,
      upper_bound: 1.0,
      clamped: x < 0.0 || x > 1.0,
      valid: true,
    }
  }
}

///|
pub fn table_state_from_pressure_quality(
  pressure_kpa : Double,
  quality : Double,
) -> SteamState {
  let table = tabulated_saturation_temperature_c(pressure_kpa)
  let state = steam_state_from_quality(pressure_kpa, quality)
  { ..state, temperature_c: table.value }
}

///|
pub fn pressure_from_saturation_temperature_c(temperature_c : Double) -> Double {
  steam_saturation_pressure_kpa(temperature_c)
}

///|
pub fn saturated_water_density_kg_per_m3(temperature_c : Double) -> Double {
  let value = 1000.0 -
    0.3 * (temperature_c - 4.0) -
    0.000002 * (temperature_c - 4.0) * (temperature_c - 4.0)
  value.max(850.0)
}

///|
pub fn steam_density_kg_per_m3(
  temperature_c : Double,
  pressure_kpa : Double,
) -> Double {
  let volume = saturated_vapor_specific_volume_m3_per_kg(
    temperature_c, pressure_kpa,
  )
  if volume <= 0.0 {
    0.0
  } else {
    1.0 / volume
  }
}

///|
pub fn steam_volume_flow_m3_per_s(
  mass_flow_kg_per_s : Double,
  temperature_c : Double,
  pressure_kpa : Double,
) -> Double {
  mass_flow_kg_per_s *
  saturated_vapor_specific_volume_m3_per_kg(temperature_c, pressure_kpa)
}

///|
pub fn condensate_recovery_heat_kj_per_kg(
  pressure_kpa : Double,
  condensate_temperature_c : Double,
) -> Double {
  let saturation = steam_saturation_temperature_c(pressure_kpa)
  saturated_liquid_enthalpy_kj_per_kg(saturation) -
  saturated_liquid_enthalpy_kj_per_kg(condensate_temperature_c)
}
