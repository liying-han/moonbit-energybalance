///|
pub struct UtilityDesign {
  name : String
  duty_w : Double
  required_mass_flow_kg_per_s : Double
  inlet_temperature_c : Double
  outlet_temperature_c : Double
  cost_index : Double
} derive(Debug)

///|
pub fn steam_utility(
  mass_flow_kg_per_s : Double,
  inlet_temperature_c : Double,
  outlet_temperature_c : Double,
) -> UtilityDesign {
  let duty = mass_flow_kg_per_s.max(0.0) *
    (
      saturated_vapor_enthalpy_kj_per_kg(outlet_temperature_c) -
      saturated_liquid_enthalpy_kj_per_kg(inlet_temperature_c)
    ) *
    1000.0
  {
    name: "medium-pressure steam",
    duty_w: duty,
    required_mass_flow_kg_per_s: mass_flow_kg_per_s.max(0.0),
    inlet_temperature_c,
    outlet_temperature_c,
    cost_index: 1.0,
  }
}

///|
pub fn cooling_water_utility(
  duty_w : Double,
  inlet_temperature_c : Double,
  outlet_temperature_c : Double,
) -> UtilityDesign {
  let delta = (outlet_temperature_c - inlet_temperature_c).abs()
  let flow = if delta <= 0.0 { 0.0 } else { duty_w.abs() / (4180.0 * delta) }
  {
    name: "cooling water",
    duty_w: -duty_w.abs(),
    required_mass_flow_kg_per_s: flow,
    inlet_temperature_c,
    outlet_temperature_c,
    cost_index: 0.2,
  }
}

///|
pub fn chilled_water_utility(
  duty_w : Double,
  inlet_temperature_c : Double,
  outlet_temperature_c : Double,
) -> UtilityDesign {
  let delta = (outlet_temperature_c - inlet_temperature_c).abs()
  let flow = if delta <= 0.0 { 0.0 } else { duty_w.abs() / (4180.0 * delta) }
  {
    name: "chilled water",
    duty_w: -duty_w.abs(),
    required_mass_flow_kg_per_s: flow,
    inlet_temperature_c,
    outlet_temperature_c,
    cost_index: 0.8,
  }
}

///|
pub fn thermal_oil_utility(
  duty_w : Double,
  inlet_temperature_c : Double,
  outlet_temperature_c : Double,
  cp_j_per_kg_k : Double,
) -> UtilityDesign {
  let delta = (outlet_temperature_c - inlet_temperature_c).abs()
  let flow = if delta <= 0.0 || cp_j_per_kg_k <= 0.0 {
    0.0
  } else {
    duty_w.abs() / (cp_j_per_kg_k * delta)
  }
  {
    name: "thermal oil",
    duty_w: duty_w.abs(),
    required_mass_flow_kg_per_s: flow,
    inlet_temperature_c,
    outlet_temperature_c,
    cost_index: 0.6,
  }
}

///|
pub fn utility_cost_index(design : UtilityDesign) -> Double {
  design.required_mass_flow_kg_per_s * design.cost_index
}

///|
pub fn select_utility(
  duty_w : Double,
  candidates : Array[UtilityDesign],
) -> UtilityDesign {
  if candidates.length() == 0 {
    {
      name: "none",
      duty_w: 0.0,
      required_mass_flow_kg_per_s: 0.0,
      inlet_temperature_c: 0.0,
      outlet_temperature_c: 0.0,
      cost_index: 0.0,
    }
  } else {
    let mut selected = candidates[0]
    let mut best_score = 1.0e30
    for candidate in candidates {
      let matches = if duty_w >= 0.0 {
        candidate.duty_w >= 0.0
      } else {
        candidate.duty_w <= 0.0
      }
      let score = if matches { utility_cost_index(candidate) } else { 1.0e30 }
      if score < best_score {
        best_score = score
        selected = candidate
      }
    }
    selected
  }
}

///|
pub fn pump_power_w(
  mass_flow_kg_per_s : Double,
  pressure_rise_pa : Double,
  efficiency : Double,
) -> Double {
  if mass_flow_kg_per_s <= 0.0 || pressure_rise_pa <= 0.0 || efficiency <= 0.0 {
    0.0
  } else {
    mass_flow_kg_per_s * pressure_rise_pa / efficiency.min(1.0)
  }
}

///|
pub fn pump_head_m(
  pressure_rise_pa : Double,
  density_kg_per_m3 : Double,
) -> Double {
  if density_kg_per_m3 <= 0.0 {
    0.0
  } else {
    pressure_rise_pa / (density_kg_per_m3 * 9.80665)
  }
}

///|
pub fn compressor_power_w(
  mass_flow_kg_per_s : Double,
  inlet_pressure_kpa : Double,
  outlet_pressure_kpa : Double,
  efficiency : Double,
  heat_capacity_ratio : Double,
) -> Double {
  if mass_flow_kg_per_s <= 0.0 ||
    inlet_pressure_kpa <= 0.0 ||
    outlet_pressure_kpa <= inlet_pressure_kpa ||
    efficiency <= 0.0 ||
    heat_capacity_ratio <= 1.0 {
    0.0
  } else {
    let exponent = (heat_capacity_ratio - 1.0) / heat_capacity_ratio
    let pressure_ratio = outlet_pressure_kpa / inlet_pressure_kpa
    let specific = heat_capacity_ratio /
      (heat_capacity_ratio - 1.0) *
      287.0 *
      celsius_to_kelvin(20.0) *
      @math.pow(pressure_ratio, exponent)
    mass_flow_kg_per_s * specific / efficiency.min(1.0)
  }
}

///|
pub fn pipe_cross_section_m2(diameter_m : Double) -> Double {
  if diameter_m <= 0.0 {
    0.0
  } else {
    0.25 * @math.PI * diameter_m * diameter_m
  }
}

///|
pub fn pipe_velocity_m_per_s(
  volumetric_flow_m3_per_s : Double,
  diameter_m : Double,
) -> Double {
  let area = pipe_cross_section_m2(diameter_m)
  if area <= 0.0 || volumetric_flow_m3_per_s <= 0.0 {
    0.0
  } else {
    volumetric_flow_m3_per_s / area
  }
}

///|
pub fn reynolds_number(
  density_kg_per_m3 : Double,
  velocity_m_per_s : Double,
  diameter_m : Double,
  viscosity_pa_s : Double,
) -> Double {
  if viscosity_pa_s <= 0.0 {
    0.0
  } else {
    density_kg_per_m3 * velocity_m_per_s * diameter_m / viscosity_pa_s
  }
}

///|
pub fn friction_factor(reynolds : Double, roughness_ratio : Double) -> Double {
  if reynolds <= 0.0 {
    0.0
  } else if reynolds < 2300.0 {
    64.0 / reynolds
  } else {
    let argument = roughness_ratio / 3.7 + 5.74 / @math.pow(reynolds, 0.9)
    0.25 / @math.pow(@math.log10(argument), 2.0)
  }
}

///|
pub fn pressure_drop_pa(
  density_kg_per_m3 : Double,
  diameter_m : Double,
  length_m : Double,
  roughness_m : Double,
  viscosity_pa_s : Double,
) -> Double {
  let velocity = pipe_velocity_m_per_s(1.0, diameter_m)
  let reynolds = reynolds_number(
    density_kg_per_m3, velocity, diameter_m, viscosity_pa_s,
  )
  let factor = friction_factor(reynolds, roughness_m / diameter_m.max(1.0e-12))
  factor *
  length_m.max(0.0) /
  diameter_m.max(1.0e-12) *
  density_kg_per_m3 *
  velocity *
  velocity /
  2.0
}

///|
pub fn heat_loss_to_ambient(
  area_m2 : Double,
  overall_u_w_per_m2_k : Double,
  process_temperature_c : Double,
  ambient_temperature_c : Double,
) -> Double {
  area_m2.max(0.0) *
  overall_u_w_per_m2_k.max(0.0) *
  (process_temperature_c - ambient_temperature_c)
}
