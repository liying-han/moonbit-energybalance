///|
pub struct RankineCycleResult {
  boiler_duty_w : Double
  turbine_work_w : Double
  pump_work_w : Double
  condenser_duty_w : Double
  net_work_w : Double
  thermal_efficiency : Double
  steam_quality_at_turbine_exit : Double
} derive(Debug)

///|
pub struct TurbineExpansionResult {
  inlet_enthalpy_kj_per_kg : Double
  outlet_enthalpy_kj_per_kg : Double
  specific_work_kj_per_kg : Double
  outlet_quality : Double
  outlet_temperature_c : Double
} derive(Debug)

///|
pub fn turbine_expand(
  inlet : SteamState,
  outlet_pressure_kpa : Double,
  isentropic_efficiency : Double,
) -> TurbineExpansionResult {
  let outlet_saturated = steam_state_from_quality(outlet_pressure_kpa, 1.0)
  let ideal_drop = (inlet.enthalpy_kj_per_kg -
  outlet_saturated.enthalpy_kj_per_kg).max(0.0)
  let work = ideal_drop * isentropic_efficiency.max(0.0).min(1.0)
  let outlet_h = inlet.enthalpy_kj_per_kg - work
  let quality = table_quality_from_enthalpy(outlet_pressure_kpa, outlet_h).value
  let outlet = steam_state_from_quality(outlet_pressure_kpa, quality)
  {
    inlet_enthalpy_kj_per_kg: inlet.enthalpy_kj_per_kg,
    outlet_enthalpy_kj_per_kg: outlet_h,
    specific_work_kj_per_kg: work,
    outlet_quality: quality,
    outlet_temperature_c: outlet.temperature_c,
  }
}

///|
pub fn boiler_duty_w(
  mass_flow_kg_per_s : Double,
  feedwater : SteamState,
  steam : SteamState,
) -> Double {
  mass_flow_kg_per_s.max(0.0) *
  (steam.enthalpy_kj_per_kg - feedwater.enthalpy_kj_per_kg) *
  1000.0
}

///|
pub fn condenser_duty_w(
  mass_flow_kg_per_s : Double,
  turbine_exit : SteamState,
  saturated_liquid : SteamState,
) -> Double {
  mass_flow_kg_per_s.max(0.0) *
  (saturated_liquid.enthalpy_kj_per_kg - turbine_exit.enthalpy_kj_per_kg) *
  1000.0
}

///|
pub fn feedwater_pump_work_w(
  mass_flow_kg_per_s : Double,
  pressure_rise_kpa : Double,
  density_kg_per_m3 : Double,
  efficiency : Double,
) -> Double {
  if density_kg_per_m3 <= 0.0 || efficiency <= 0.0 {
    0.0
  } else {
    mass_flow_kg_per_s.max(0.0) *
    kpa_to_pa(pressure_rise_kpa) /
    density_kg_per_m3 /
    efficiency.min(1.0)
  }
}

///|
pub fn rankine_cycle(
  boiler_temperature_c : Double,
  condenser_pressure_kpa : Double,
  mass_flow_kg_per_s : Double,
  turbine_efficiency : Double,
  pump_efficiency : Double,
) -> RankineCycleResult {
  let boiler_pressure = condenser_pressure_kpa.max(1.0) * 100.0
  let steam = steam_state(boiler_temperature_c, boiler_pressure)
  let condensate = steam_state_from_quality(condenser_pressure_kpa, 0.0)
  let expansion = turbine_expand(
    steam, condenser_pressure_kpa, turbine_efficiency,
  )
  let feedwater = steam_state_from_quality(boiler_pressure, 0.0)
  let boiler_duty = boiler_duty_w(mass_flow_kg_per_s, feedwater, steam)
  let turbine_work = mass_flow_kg_per_s.max(0.0) *
    expansion.specific_work_kj_per_kg *
    1000.0
  let pump_work = feedwater_pump_work_w(
    mass_flow_kg_per_s,
    boiler_pressure - condenser_pressure_kpa,
    saturated_water_density_kg_per_m3(condensate.temperature_c),
    pump_efficiency,
  )
  let condenser_duty = condenser_duty_w(
    mass_flow_kg_per_s,
    steam_state_from_quality(condenser_pressure_kpa, expansion.outlet_quality),
    condensate,
  )
  let net = turbine_work - pump_work
  {
    boiler_duty_w: boiler_duty,
    turbine_work_w: turbine_work,
    pump_work_w: pump_work,
    condenser_duty_w: condenser_duty.abs(),
    net_work_w: net,
    thermal_efficiency: if boiler_duty <= 0.0 {
      0.0
    } else {
      net / boiler_duty
    },
    steam_quality_at_turbine_exit: expansion.outlet_quality,
  }
}

///|
pub fn cycle_heat_rate_j_per_j(cycle : RankineCycleResult) -> Double {
  if cycle.net_work_w <= 0.0 {
    0.0
  } else {
    cycle.boiler_duty_w / cycle.net_work_w
  }
}

///|
pub fn cycle_capacity_factor(
  cycle : RankineCycleResult,
  operating_hours : Double,
  period_hours : Double,
) -> Double {
  let availability = if cycle.net_work_w > 0.0 { 1.0 } else { 0.0 }
  if period_hours <= 0.0 {
    0.0
  } else {
    availability * (operating_hours / period_hours).max(0.0).min(1.0)
  }
}
