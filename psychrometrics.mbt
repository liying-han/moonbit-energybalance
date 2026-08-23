///|
pub fn saturation_pressure_kpa(temperature_c : Double) -> Double {
  let exponent = 17.625 * temperature_c / (temperature_c + 243.04)
  0.61094 * @math.exp(exponent)
}

///|
pub fn saturation_pressure_pa(temperature_c : Double) -> Double {
  saturation_pressure_kpa(temperature_c) * 1000.0
}

///|
pub fn humidity_ratio_from_vapor_pressure(
  vapor_pressure_kpa : Double,
  total_pressure_kpa : Double,
) -> Double {
  if vapor_pressure_kpa <= 0.0 || total_pressure_kpa <= vapor_pressure_kpa {
    0.0
  } else {
    0.62198 * vapor_pressure_kpa / (total_pressure_kpa - vapor_pressure_kpa)
  }
}

///|
pub fn vapor_pressure_from_humidity_ratio(
  humidity_ratio : Double,
  total_pressure_kpa : Double,
) -> Double {
  if humidity_ratio <= 0.0 || total_pressure_kpa <= 0.0 {
    0.0
  } else {
    total_pressure_kpa * humidity_ratio / (0.62198 + humidity_ratio)
  }
}

///|
pub fn humidity_ratio_from_relative_humidity(
  dry_bulb_c : Double,
  relative_humidity : Double,
  total_pressure_kpa : Double,
) -> Double {
  let rh = relative_humidity.max(0.0).min(1.0)
  humidity_ratio_from_vapor_pressure(
    saturation_pressure_kpa(dry_bulb_c) * rh,
    total_pressure_kpa,
  )
}

///|
pub fn relative_humidity_from_ratio(
  dry_bulb_c : Double,
  humidity_ratio : Double,
  total_pressure_kpa : Double,
) -> Double {
  let saturation = saturation_pressure_kpa(dry_bulb_c)
  if saturation <= 0.0 {
    0.0
  } else {
    (vapor_pressure_from_humidity_ratio(humidity_ratio, total_pressure_kpa) /
    saturation)
    .max(0.0)
    .min(1.0)
  }
}

///|
pub fn moist_air_enthalpy_kj_per_kg_dry(
  dry_bulb_c : Double,
  humidity_ratio : Double,
) -> Double {
  1.006 * dry_bulb_c + humidity_ratio * (2501.0 + 1.86 * dry_bulb_c)
}

///|
pub fn moist_air_enthalpy_from_rh(
  dry_bulb_c : Double,
  relative_humidity : Double,
  total_pressure_kpa : Double,
) -> Double {
  let ratio = humidity_ratio_from_relative_humidity(
    dry_bulb_c, relative_humidity, total_pressure_kpa,
  )
  moist_air_enthalpy_kj_per_kg_dry(dry_bulb_c, ratio)
}

///|
pub fn dew_point_c(
  dry_bulb_c : Double,
  humidity_ratio : Double,
  total_pressure_kpa : Double,
) -> Double {
  let vapor = vapor_pressure_from_humidity_ratio(
    humidity_ratio, total_pressure_kpa,
  )
  if vapor <= 0.0 {
    -50.0.min(dry_bulb_c)
  } else {
    let alpha = @math.ln(vapor / 0.61094)
    (243.04 * alpha / (17.625 - alpha)).min(dry_bulb_c)
  }
}

///|
pub fn moist_air_density(
  dry_bulb_c : Double,
  humidity_ratio : Double,
  total_pressure_kpa : Double,
) -> Double {
  let temperature_k = celsius_to_kelvin(dry_bulb_c)
  if temperature_k <= 0.0 || total_pressure_kpa <= 0.0 {
    0.0
  } else {
    let dry_pressure_pa = kpa_to_pa(
      vapor_pressure_from_humidity_ratio(humidity_ratio, total_pressure_kpa),
    )
    let total_pressure_pa = kpa_to_pa(total_pressure_kpa)
    let vapor_pressure_pa = dry_pressure_pa
    (total_pressure_pa - vapor_pressure_pa) / (287.055 * temperature_k) +
    vapor_pressure_pa / (461.495 * temperature_k)
  }
}

///|
pub fn moist_air_specific_volume(
  dry_bulb_c : Double,
  humidity_ratio : Double,
  total_pressure_kpa : Double,
) -> Double {
  let density = moist_air_density(
    dry_bulb_c, humidity_ratio, total_pressure_kpa,
  )
  if density <= 0.0 {
    0.0
  } else {
    (1.0 + humidity_ratio) / density
  }
}

///|
pub fn moist_air_cp_kj_per_kg_k(humidity_ratio : Double) -> Double {
  1.006 + humidity_ratio.max(0.0) * 1.86
}

///|
pub fn wet_bulb_c(
  dry_bulb_c : Double,
  humidity_ratio : Double,
  total_pressure_kpa : Double,
) -> Double {
  let dew = dew_point_c(dry_bulb_c, humidity_ratio, total_pressure_kpa)
  let lower = dew.min(dry_bulb_c)
  let upper = dry_bulb_c.max(lower)
  let target = moist_air_enthalpy_kj_per_kg_dry(dry_bulb_c, humidity_ratio)
  let mut low = lower
  let mut high = upper
  for _ in 0..<48 {
    let middle = (low + high) / 2.0
    let saturated_ratio = humidity_ratio_from_relative_humidity(
      middle, 1.0, total_pressure_kpa,
    )
    let psychrometric_enthalpy = moist_air_enthalpy_kj_per_kg_dry(
      middle, saturated_ratio,
    )
    if psychrometric_enthalpy > target {
      high = middle
    } else {
      low = middle
    }
  }
  (low + high) / 2.0
}

///|
pub fn moisture_mass_flow(
  dry_air_mass_flow_kg_per_s : Double,
  humidity_ratio : Double,
) -> Double {
  dry_air_mass_flow_kg_per_s * humidity_ratio.max(0.0)
}

///|
pub fn humidification_water_duty(
  dry_air_mass_flow_kg_per_s : Double,
  from_ratio : Double,
  to_ratio : Double,
) -> Double {
  dry_air_mass_flow_kg_per_s * (to_ratio - from_ratio).max(0.0)
}

///|
pub fn evaporative_cooling_duty(
  dry_air_mass_flow_kg_per_s : Double,
  from_temperature_c : Double,
  to_temperature_c : Double,
  from_ratio : Double,
  to_ratio : Double,
) -> Double {
  let from_h = moist_air_enthalpy_kj_per_kg_dry(from_temperature_c, from_ratio)
  let to_h = moist_air_enthalpy_kj_per_kg_dry(to_temperature_c, to_ratio)
  dry_air_mass_flow_kg_per_s * (to_h - from_h) * 1000.0
}
