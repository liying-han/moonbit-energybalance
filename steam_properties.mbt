///|
pub(all) enum SteamRegion {
  CompressedLiquid
  SaturatedLiquid
  TwoPhase
  SaturatedVapor
  SuperheatedVapor
  UnknownRegion
} derive(Debug, Eq)

///|
pub struct SteamState {
  temperature_c : Double
  pressure_kpa : Double
  enthalpy_kj_per_kg : Double
  entropy_kj_per_kg_k : Double
  specific_volume_m3_per_kg : Double
  quality : Double
  region : SteamRegion
} derive(Debug)

///|
pub struct SteamTableResult {
  value : Double
  lower_bound : Double
  upper_bound : Double
  clamped : Bool
  valid : Bool
} derive(Debug)

///|
fn saturation_temperature_from_pressure(pressure_kpa : Double) -> Double {
  if pressure_kpa <= 0.0 {
    0.0
  } else {
    let alpha = @math.ln(pressure_kpa / 0.61078)
    237.3 * alpha / (17.27 - alpha)
  }
}

///|
pub fn steam_saturation_temperature_c(pressure_kpa : Double) -> Double {
  saturation_temperature_from_pressure(pressure_kpa)
}

///|
fn steam_saturation_pressure_kpa(temperature_c : Double) -> Double {
  0.61078 * @math.exp(17.27 * temperature_c / (temperature_c + 237.3))
}

///|
pub fn steam_latent_heat_kj_per_kg(temperature_c : Double) -> Double {
  (2501.0 - 2.36 * temperature_c).max(0.0)
}

///|
pub fn saturated_liquid_enthalpy_kj_per_kg(temperature_c : Double) -> Double {
  4.18 * temperature_c
}

///|
pub fn saturated_vapor_enthalpy_kj_per_kg(temperature_c : Double) -> Double {
  saturated_liquid_enthalpy_kj_per_kg(temperature_c) +
  steam_latent_heat_kj_per_kg(temperature_c)
}

///|
pub fn saturated_liquid_entropy_kj_per_kg_k(temperature_c : Double) -> Double {
  let temperature_k = celsius_to_kelvin(temperature_c)
  if temperature_k <= 0.0 {
    0.0
  } else {
    4.18 * @math.ln(temperature_k / 273.15)
  }
}

///|
pub fn saturated_liquid_specific_volume_m3_per_kg(
  temperature_c : Double,
) -> Double {
  (0.001 + 0.0000003 * temperature_c).max(0.0005)
}

///|
pub fn saturated_vapor_specific_volume_m3_per_kg(
  temperature_c : Double,
  pressure_kpa : Double,
) -> Double {
  let pressure_pa = kpa_to_pa(pressure_kpa)
  let temperature_k = celsius_to_kelvin(temperature_c)
  if pressure_pa <= 0.0 || temperature_k <= 0.0 {
    0.0
  } else {
    0.4615 * temperature_k / pressure_pa * 1000.0
  }
}

///|
pub fn steam_state(temperature_c : Double, pressure_kpa : Double) -> SteamState {
  let saturation = steam_saturation_temperature_c(pressure_kpa)
  let liquid_h = saturated_liquid_enthalpy_kj_per_kg(saturation)
  let vapor_h = saturated_vapor_enthalpy_kj_per_kg(saturation)
  if pressure_kpa <= 0.0 || temperature_c < -50.0 {
    {
      temperature_c,
      pressure_kpa,
      enthalpy_kj_per_kg: 0.0,
      entropy_kj_per_kg_k: 0.0,
      specific_volume_m3_per_kg: 0.0,
      quality: 0.0,
      region: UnknownRegion,
    }
  } else if (temperature_c - saturation).abs() < 0.5 {
    let quality = 0.5
    {
      temperature_c,
      pressure_kpa,
      enthalpy_kj_per_kg: liquid_h + quality * (vapor_h - liquid_h),
      entropy_kj_per_kg_k: saturated_liquid_entropy_kj_per_kg_k(saturation) +
      quality,
      specific_volume_m3_per_kg: saturated_vapor_specific_volume_m3_per_kg(
        saturation, pressure_kpa,
      ) *
      quality,
      quality,
      region: TwoPhase,
    }
  } else if temperature_c < saturation {
    {
      temperature_c,
      pressure_kpa,
      enthalpy_kj_per_kg: saturated_liquid_enthalpy_kj_per_kg(temperature_c),
      entropy_kj_per_kg_k: saturated_liquid_entropy_kj_per_kg_k(temperature_c),
      specific_volume_m3_per_kg: saturated_liquid_specific_volume_m3_per_kg(
        temperature_c,
      ),
      quality: 0.0,
      region: CompressedLiquid,
    }
  } else {
    let superheat = temperature_c - saturation
    let enthalpy = vapor_h + 2.08 * superheat
    {
      temperature_c,
      pressure_kpa,
      enthalpy_kj_per_kg: enthalpy,
      entropy_kj_per_kg_k: saturated_liquid_entropy_kj_per_kg_k(saturation) +
      1.0 +
      2.08 *
      @math.ln(celsius_to_kelvin(temperature_c) / celsius_to_kelvin(saturation)),
      specific_volume_m3_per_kg: saturated_vapor_specific_volume_m3_per_kg(
        saturation, pressure_kpa,
      ) *
      celsius_to_kelvin(temperature_c) /
      celsius_to_kelvin(saturation),
      quality: 1.0,
      region: SuperheatedVapor,
    }
  }
}

///|
pub fn steam_state_from_quality(
  pressure_kpa : Double,
  quality : Double,
) -> SteamState {
  let temperature = steam_saturation_temperature_c(pressure_kpa)
  let x = quality.max(0.0).min(1.0)
  let liquid_h = saturated_liquid_enthalpy_kj_per_kg(temperature)
  let vapor_h = saturated_vapor_enthalpy_kj_per_kg(temperature)
  {
    temperature_c: temperature,
    pressure_kpa,
    enthalpy_kj_per_kg: liquid_h + x * (vapor_h - liquid_h),
    entropy_kj_per_kg_k: saturated_liquid_entropy_kj_per_kg_k(temperature) + x,
    specific_volume_m3_per_kg: saturated_liquid_specific_volume_m3_per_kg(
      temperature,
    ) +
    x * saturated_vapor_specific_volume_m3_per_kg(temperature, pressure_kpa),
    quality: x,
    region: if x == 0.0 {
      SaturatedLiquid
    } else if x == 1.0 {
      SaturatedVapor
    } else {
      TwoPhase
    },
  }
}

///|
pub fn steam_mass_flow_for_duty(
  duty_w : Double,
  pressure_kpa : Double,
  quality_in : Double,
  quality_out : Double,
) -> Double {
  let inlet = steam_state_from_quality(pressure_kpa, quality_in)
  let outlet = steam_state_from_quality(pressure_kpa, quality_out)
  let delta_h = (outlet.enthalpy_kj_per_kg - inlet.enthalpy_kj_per_kg) * 1000.0
  if delta_h.abs() < 1.0e-12 {
    0.0
  } else {
    duty_w / delta_h
  }
}

///|
pub fn interpolate_table(
  lower_x : Double,
  lower_y : Double,
  upper_x : Double,
  upper_y : Double,
  x : Double,
) -> SteamTableResult {
  if upper_x <= lower_x {
    {
      value: 0.0,
      lower_bound: lower_x,
      upper_bound: upper_x,
      clamped: false,
      valid: false,
    }
  } else {
    let clamped = x < lower_x || x > upper_x
    let bounded = x.max(lower_x).min(upper_x)
    let fraction = (bounded - lower_x) / (upper_x - lower_x)
    {
      value: lower_y + fraction * (upper_y - lower_y),
      lower_bound: lower_x,
      upper_bound: upper_x,
      clamped,
      valid: true,
    }
  }
}
