///|
pub struct PsychrometricPoint {
  dry_bulb_c : Double
  relative_humidity : Double
  humidity_ratio : Double
  enthalpy_kj_per_kg_dry : Double
  dew_point_c : Double
} derive(Debug)

///|
pub struct AirConditioningReport {
  inlet : PsychrometricPoint
  outlet : PsychrometricPoint
  dry_air_mass_flow_kg_per_s : Double
  cooling_duty_w : Double
  sensible_duty_w : Double
  latent_duty_w : Double
  condensate_kg_per_s : Double
  sensible_heat_ratio : Double
} derive(Debug)

///|
pub fn psychrometric_point(
  dry_bulb_c : Double,
  relative_humidity : Double,
  pressure_kpa : Double,
) -> PsychrometricPoint {
  let humidity_ratio = humidity_ratio_from_relative_humidity(
    dry_bulb_c, relative_humidity, pressure_kpa,
  )
  {
    dry_bulb_c,
    relative_humidity: relative_humidity.max(0.0).min(1.0),
    humidity_ratio,
    enthalpy_kj_per_kg_dry: moist_air_enthalpy_kj_per_kg_dry(
      dry_bulb_c, humidity_ratio,
    ),
    dew_point_c: dew_point_c(dry_bulb_c, humidity_ratio, pressure_kpa),
  }
}

///|
pub fn point_from_humidity_ratio(
  dry_bulb_c : Double,
  humidity_ratio : Double,
  pressure_kpa : Double,
) -> PsychrometricPoint {
  let ratio = humidity_ratio.max(0.0)
  {
    dry_bulb_c,
    relative_humidity: relative_humidity_from_ratio(
      dry_bulb_c, ratio, pressure_kpa,
    ),
    humidity_ratio: ratio,
    enthalpy_kj_per_kg_dry: moist_air_enthalpy_kj_per_kg_dry(dry_bulb_c, ratio),
    dew_point_c: dew_point_c(dry_bulb_c, ratio, pressure_kpa),
  }
}

///|
pub fn air_conditioning_report(
  inlet : PsychrometricPoint,
  outlet : PsychrometricPoint,
  dry_air_mass_flow_kg_per_s : Double,
) -> AirConditioningReport {
  let total = dry_air_mass_flow_kg_per_s.max(0.0) *
    (outlet.enthalpy_kj_per_kg_dry - inlet.enthalpy_kj_per_kg_dry) *
    1000.0
  let sensible = dry_air_mass_flow_kg_per_s.max(0.0) *
    (outlet.dry_bulb_c - inlet.dry_bulb_c) *
    moist_air_cp_kj_per_kg_k(inlet.humidity_ratio) *
    1000.0
  let latent = total - sensible
  let shr = if total.abs() < 1.0e-12 { 0.0 } else { sensible / total }
  {
    inlet,
    outlet,
    dry_air_mass_flow_kg_per_s,
    cooling_duty_w: total,
    sensible_duty_w: sensible,
    latent_duty_w: latent,
    condensate_kg_per_s: (dry_air_mass_flow_kg_per_s *
    (inlet.humidity_ratio - outlet.humidity_ratio)).max(0.0),
    sensible_heat_ratio: shr,
  }
}

///|
pub fn mix_air_points(
  first : PsychrometricPoint,
  first_mass_flow_kg_per_s : Double,
  second : PsychrometricPoint,
  second_mass_flow_kg_per_s : Double,
) -> PsychrometricPoint {
  let first_flow = first_mass_flow_kg_per_s.max(0.0)
  let second_flow = second_mass_flow_kg_per_s.max(0.0)
  let total = first_flow + second_flow
  if total <= 0.0 {
    first
  } else {
    let ratio = (
        first.humidity_ratio * first_flow + second.humidity_ratio * second_flow
      ) /
      total
    let enthalpy = (
        first.enthalpy_kj_per_kg_dry * first_flow +
        second.enthalpy_kj_per_kg_dry * second_flow
      ) /
      total
    let temperature = (enthalpy - 2501.0 * ratio) / (1.006 + 1.86 * ratio)
    point_from_humidity_ratio(temperature, ratio, 101.325)
  }
}

///|
pub fn heating_coil_point(
  inlet : PsychrometricPoint,
  target_temperature_c : Double,
) -> PsychrometricPoint {
  point_from_humidity_ratio(target_temperature_c, inlet.humidity_ratio, 101.325)
}

///|
pub fn humidification_point(
  inlet : PsychrometricPoint,
  target_humidity_ratio : Double,
) -> PsychrometricPoint {
  point_from_humidity_ratio(inlet.dry_bulb_c, target_humidity_ratio, 101.325)
}

///|
pub fn dehumidification_point(
  inlet : PsychrometricPoint,
  target_relative_humidity : Double,
) -> PsychrometricPoint {
  let saturated_ratio = humidity_ratio_from_relative_humidity(
    inlet.dry_bulb_c,
    target_relative_humidity,
    101.325,
  )
  point_from_humidity_ratio(
    inlet.dry_bulb_c,
    saturated_ratio.min(inlet.humidity_ratio),
    101.325,
  )
}

///|
pub fn sensible_heat_ratio(
  sensible_duty_w : Double,
  total_duty_w : Double,
) -> Double {
  if total_duty_w.abs() < 1.0e-12 {
    0.0
  } else {
    sensible_duty_w / total_duty_w
  }
}

///|
pub fn coil_bypass_factor(
  inlet_temperature_c : Double,
  outlet_temperature_c : Double,
  apparatus_dew_point_c : Double,
) -> Double {
  let denominator = inlet_temperature_c - apparatus_dew_point_c
  if denominator.abs() < 1.0e-12 {
    0.0
  } else {
    ((outlet_temperature_c - apparatus_dew_point_c) / denominator)
    .max(0.0)
    .min(1.0)
  }
}

///|
pub fn coil_contact_factor(bypass_factor : Double) -> Double {
  1.0 - bypass_factor.max(0.0).min(1.0)
}

///|
pub fn moisture_removal_rate(
  inlet_ratio : Double,
  outlet_ratio : Double,
  dry_air_mass_flow_kg_per_s : Double,
) -> Double {
  (inlet_ratio - outlet_ratio).max(0.0) * dry_air_mass_flow_kg_per_s.max(0.0)
}

///|
pub fn air_heater_duty_w(
  inlet : PsychrometricPoint,
  outlet_temperature_c : Double,
  dry_air_mass_flow_kg_per_s : Double,
) -> Double {
  let outlet = heating_coil_point(inlet, outlet_temperature_c)
  dry_air_mass_flow_kg_per_s.max(0.0) *
  (outlet.enthalpy_kj_per_kg_dry - inlet.enthalpy_kj_per_kg_dry) *
  1000.0
}

///|
pub fn air_mixing_enthalpy(
  points : Array[PsychrometricPoint],
  flows : Array[Double],
) -> Double {
  let length = points.length().min(flows.length())
  let mut total_flow = 0.0
  let mut total_enthalpy = 0.0
  for i in 0..<length {
    let flow = flows[i].max(0.0)
    total_flow += flow
    total_enthalpy += flow * points[i].enthalpy_kj_per_kg_dry
  }
  if total_flow <= 0.0 {
    0.0
  } else {
    total_enthalpy / total_flow
  }
}
