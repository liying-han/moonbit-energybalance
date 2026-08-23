///|
pub struct HeaterSizing {
  process_duty_w : Double
  design_duty_w : Double
  area_m2 : Double
  overall_u_w_per_m2_k : Double
  approach_k : Double
} derive(Debug)

///|
pub struct TankSizing {
  working_volume_m3 : Double
  volume_m3 : Double
  diameter_m : Double
  height_m : Double
  residence_time_s : Double
} derive(Debug)

///|
pub struct PumpSizing {
  hydraulic_power_w : Double
  shaft_power_w : Double
  pressure_rise_pa : Double
  flow_m3_per_s : Double
} derive(Debug)

///|
pub fn size_heater(
  process_duty_w : Double,
  approach_k : Double,
  overall_u_w_per_m2_k : Double,
  design_efficiency : Double,
) -> HeaterSizing {
  let duty = process_duty_w.abs()
  let efficiency = design_efficiency.max(0.01).min(1.0)
  let design = duty / efficiency
  let area = exchanger_area_m2(
    design,
    overall_u_w_per_m2_k.max(0.0),
    approach_k.max(0.0),
    1.0,
  )
  {
    process_duty_w: duty,
    design_duty_w: design,
    area_m2: area,
    overall_u_w_per_m2_k,
    approach_k,
  }
}

///|
pub fn size_tank(
  volumetric_flow_m3_per_s : Double,
  residence_time_s : Double,
  working_fraction : Double,
) -> TankSizing {
  let working = volumetric_flow_m3_per_s.max(0.0) * residence_time_s.max(0.0)
  let fraction = working_fraction.max(0.05).min(0.95)
  let volume = working / fraction
  let height = @math.pow(volume * 4.0 / @math.PI, 1.0 / 3.0) * 2.0
  let diameter = @math.pow(volume * 4.0 / (@math.PI * height.max(1.0e-12)), 0.5)
  {
    working_volume_m3: working,
    volume_m3: volume,
    diameter_m: diameter,
    height_m: height,
    residence_time_s,
  }
}

///|
pub fn size_pump(
  flow_m3_per_s : Double,
  pressure_rise_pa : Double,
  density_kg_per_m3 : Double,
  efficiency : Double,
) -> PumpSizing {
  let hydraulic = if density_kg_per_m3 <= 0.0 {
    0.0
  } else {
    flow_m3_per_s.max(0.0) *
    pressure_rise_pa.max(0.0) *
    density_kg_per_m3 /
    density_kg_per_m3
  }
  let shaft = if efficiency <= 0.0 {
    0.0
  } else {
    hydraulic / efficiency.min(1.0)
  }
  {
    hydraulic_power_w: hydraulic,
    shaft_power_w: shaft,
    pressure_rise_pa,
    flow_m3_per_s,
  }
}

///|
pub fn agitator_power_w(
  density_kg_per_m3 : Double,
  impeller_diameter_m : Double,
  rotational_speed_per_s : Double,
  power_number : Double,
) -> Double {
  power_number.max(0.0) *
  density_kg_per_m3.max(0.0) *
  rotational_speed_per_s.max(0.0) *
  rotational_speed_per_s.max(0.0) *
  rotational_speed_per_s.max(0.0) *
  impeller_diameter_m.max(0.0) *
  impeller_diameter_m.max(0.0) *
  impeller_diameter_m.max(0.0) *
  impeller_diameter_m.max(0.0) *
  impeller_diameter_m.max(0.0)
}

///|
pub fn vessel_wall_area_m2(diameter_m : Double, height_m : Double) -> Double {
  @math.PI * diameter_m.max(0.0) * height_m.max(0.0) +
  0.5 * @math.PI * diameter_m.max(0.0) * diameter_m.max(0.0)
}

///|
pub fn vessel_volume_m3(diameter_m : Double, height_m : Double) -> Double {
  0.25 *
  @math.PI *
  diameter_m.max(0.0) *
  diameter_m.max(0.0) *
  height_m.max(0.0)
}

///|
pub fn safety_factor_load(load_w : Double, factor : Double) -> Double {
  load_w.abs() * factor.max(1.0)
}

///|
pub fn parallel_equipment_count(
  required_capacity : Double,
  unit_capacity : Double,
) -> Int {
  if required_capacity <= 0.0 || unit_capacity <= 0.0 {
    0
  } else {
    let mut count = 0
    let mut capacity = 0.0
    for _ in 0..<10000 {
      if capacity >= required_capacity {
        break
      }
      count += 1
      capacity += unit_capacity
    }
    count
  }
}
