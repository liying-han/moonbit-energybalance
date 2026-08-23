///|
pub struct FluidProperties {
  temperature_c : Double
  density_kg_per_m3 : Double
  viscosity_pa_s : Double
  heat_capacity_j_per_kg_k : Double
  thermal_conductivity_w_per_m_k : Double
  vapor_pressure_kpa : Double
} derive(Debug)

///|
pub fn water_density_kg_per_m3(temperature_c : Double) -> Double {
  (1000.0 -
  0.3 * (temperature_c - 4.0) -
  0.000002 * (temperature_c - 4.0) * (temperature_c - 4.0)).max(850.0)
}

///|
pub fn water_viscosity_pa_s(temperature_c : Double) -> Double {
  let temperature_k = celsius_to_kelvin(temperature_c)
  if temperature_k <= 0.0 {
    0.001
  } else {
    0.001 * @math.exp(1700.0 * (1.0 / temperature_k - 1.0 / 293.15))
  }
}

///|
pub fn water_heat_capacity_j_per_kg_k(temperature_c : Double) -> Double {
  4180.0 + 0.25 * (temperature_c - 20.0)
}

///|
pub fn water_thermal_conductivity_w_per_m_k(temperature_c : Double) -> Double {
  (0.598 - 0.0015 * (temperature_c - 20.0)).max(0.45)
}

///|
pub fn water_properties(temperature_c : Double) -> FluidProperties {
  {
    temperature_c,
    density_kg_per_m3: water_density_kg_per_m3(temperature_c),
    viscosity_pa_s: water_viscosity_pa_s(temperature_c),
    heat_capacity_j_per_kg_k: water_heat_capacity_j_per_kg_k(temperature_c),
    thermal_conductivity_w_per_m_k: water_thermal_conductivity_w_per_m_k(
      temperature_c,
    ),
    vapor_pressure_kpa: saturation_pressure_kpa(temperature_c),
  }
}

///|
pub fn prandtl_number(fluid : FluidProperties) -> Double {
  if fluid.thermal_conductivity_w_per_m_k <= 0.0 {
    0.0
  } else {
    fluid.heat_capacity_j_per_kg_k *
    fluid.viscosity_pa_s /
    fluid.thermal_conductivity_w_per_m_k
  }
}

///|
pub fn reynolds_number_for_fluid(
  fluid : FluidProperties,
  velocity_m_per_s : Double,
  diameter_m : Double,
) -> Double {
  reynolds_number(
    fluid.density_kg_per_m3,
    velocity_m_per_s,
    diameter_m,
    fluid.viscosity_pa_s,
  )
}

///|
pub fn nusselt_dittus_boelter(
  reynolds : Double,
  prandtl : Double,
  exponent : Double,
) -> Double {
  if reynolds <= 0.0 || prandtl <= 0.0 {
    0.0
  } else {
    0.023 * @math.pow(reynolds, 0.8) * @math.pow(prandtl, exponent)
  }
}

///|
pub fn nusselt_laminar_constant_wall() -> Double {
  3.66
}

///|
pub fn pipe_heat_transfer_coefficient(
  diameter_m : Double,
  velocity_m_per_s : Double,
  fluid : FluidProperties,
) -> Double {
  if diameter_m <= 0.0 {
    0.0
  } else {
    let reynolds = reynolds_number_for_fluid(
      fluid, velocity_m_per_s, diameter_m,
    )
    let nusselt = if reynolds < 2300.0 {
      nusselt_laminar_constant_wall()
    } else {
      nusselt_dittus_boelter(reynolds, prandtl_number(fluid), 0.4)
    }
    nusselt * fluid.thermal_conductivity_w_per_m_k / diameter_m
  }
}

///|
pub fn convection_resistance_m2_k_per_w(
  heat_transfer_coefficient_w_per_m2_k : Double,
) -> Double {
  if heat_transfer_coefficient_w_per_m2_k <= 0.0 {
    0.0
  } else {
    1.0 / heat_transfer_coefficient_w_per_m2_k
  }
}

///|
pub fn overall_heat_transfer_coefficient(
  inside_h_w_per_m2_k : Double,
  wall_resistance_m2_k_per_w : Double,
  outside_h_w_per_m2_k : Double,
  fouling_resistance_m2_k_per_w : Double,
) -> Double {
  let total = convection_resistance_m2_k_per_w(inside_h_w_per_m2_k) +
    wall_resistance_m2_k_per_w.max(0.0) +
    convection_resistance_m2_k_per_w(outside_h_w_per_m2_k) +
    fouling_resistance_m2_k_per_w.max(0.0)
  if total <= 0.0 {
    0.0
  } else {
    1.0 / total
  }
}

///|
pub fn thermal_diffusivity_m2_per_s(fluid : FluidProperties) -> Double {
  if fluid.density_kg_per_m3 <= 0.0 || fluid.heat_capacity_j_per_kg_k <= 0.0 {
    0.0
  } else {
    fluid.thermal_conductivity_w_per_m_k /
    (fluid.density_kg_per_m3 * fluid.heat_capacity_j_per_kg_k)
  }
}

///|
pub fn mass_transfer_sherwood(reynolds : Double, schmidt : Double) -> Double {
  if reynolds <= 0.0 || schmidt <= 0.0 {
    0.0
  } else {
    0.023 * @math.pow(reynolds, 0.83) * @math.pow(schmidt, 0.33)
  }
}

///|
pub fn schmidt_number(
  viscosity_pa_s : Double,
  density_kg_per_m3 : Double,
  diffusivity_m2_per_s : Double,
) -> Double {
  if density_kg_per_m3 <= 0.0 || diffusivity_m2_per_s <= 0.0 {
    0.0
  } else {
    viscosity_pa_s / density_kg_per_m3 / diffusivity_m2_per_s
  }
}
