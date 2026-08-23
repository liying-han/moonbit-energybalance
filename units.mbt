///|
pub fn celsius_to_kelvin(temperature_c : Double) -> Double {
  temperature_c + 273.15
}

///|
pub fn kelvin_to_celsius(temperature_k : Double) -> Double {
  temperature_k - 273.15
}

///|
pub fn bar_to_kpa(pressure_bar : Double) -> Double {
  pressure_bar * 100.0
}

///|
pub fn kpa_to_bar(pressure_kpa : Double) -> Double {
  pressure_kpa / 100.0
}

///|
pub fn pa_to_kpa(pressure_pa : Double) -> Double {
  pressure_pa / 1000.0
}

///|
pub fn kpa_to_pa(pressure_kpa : Double) -> Double {
  pressure_kpa * 1000.0
}

///|
pub fn valid_absolute_temperature(temperature_k : Double) -> Bool {
  temperature_k > 0.0
}

///|
pub fn kelvin_range(lower_k : Double, upper_k : Double) -> Bool {
  valid_absolute_temperature(lower_k) &&
  valid_absolute_temperature(upper_k) &&
  upper_k >= lower_k
}

///|
pub fn molar_flow_to_mass_flow(
  molar_flow_mol_per_s : Double,
  molar_mass_g_per_mol : Double,
) -> Double {
  molar_flow_mol_per_s * molar_mass_g_per_mol / 1000.0
}

///|
pub fn mass_flow_to_molar_flow(
  mass_flow_kg_per_s : Double,
  molar_mass_g_per_mol : Double,
) -> Double {
  if molar_mass_g_per_mol <= 0.0 {
    0.0
  } else {
    mass_flow_kg_per_s * 1000.0 / molar_mass_g_per_mol
  }
}

///|
pub fn celsius_delta_to_kelvin_delta(delta_c : Double) -> Double {
  delta_c
}

///|
pub fn kelvin_delta_to_celsius_delta(delta_k : Double) -> Double {
  delta_k
}

///|
pub fn liters_per_minute_to_cubic_meters_per_second(value : Double) -> Double {
  value / 60000.0
}

///|
pub fn cubic_meters_per_second_to_liters_per_minute(value : Double) -> Double {
  value * 60000.0
}

///|
pub fn kilojoule_per_kg_to_joule_per_kg(value : Double) -> Double {
  value * 1000.0
}

///|
pub fn joule_per_kg_to_kilojoule_per_kg(value : Double) -> Double {
  value / 1000.0
}

///|
pub fn kilowatt_to_watt(value : Double) -> Double {
  value * 1000.0
}

///|
pub fn watt_to_kilowatt(value : Double) -> Double {
  value / 1000.0
}
