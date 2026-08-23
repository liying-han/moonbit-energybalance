///|
pub struct ThermalStreamTarget {
  id : String
  supply_c : Double
  target_c : Double
  heat_capacity_flow_kw_per_k : Double
} derive(Debug)

///|
pub struct PinchTargets {
  hot_target_c : Double
  cold_target_c : Double
  minimum_hot_utility_kw : Double
  minimum_cold_utility_kw : Double
  total_hot_duty_kw : Double
  total_cold_duty_kw : Double
} derive(Debug)

///|
pub struct HeatRecoveryMatch {
  hot_id : String
  cold_id : String
  duty_kw : Double
  hot_outlet_c : Double
  cold_outlet_c : Double
  feasible : Bool
} derive(Debug)

///|
pub fn ThermalStreamTarget::ThermalStreamTarget(
  id~ : String,
  supply_c~ : Double,
  target_c~ : Double,
  heat_capacity_flow_kw_per_k~ : Double,
) -> ThermalStreamTarget {
  { id, supply_c, target_c, heat_capacity_flow_kw_per_k }
}

///|
pub fn hot_stream_duty_kw(stream : ThermalStreamTarget) -> Double {
  if stream.supply_c <= stream.target_c ||
    stream.heat_capacity_flow_kw_per_k <= 0.0 {
    0.0
  } else {
    (stream.supply_c - stream.target_c) * stream.heat_capacity_flow_kw_per_k
  }
}

///|
pub fn cold_stream_duty_kw(stream : ThermalStreamTarget) -> Double {
  if stream.target_c <= stream.supply_c ||
    stream.heat_capacity_flow_kw_per_k <= 0.0 {
    0.0
  } else {
    (stream.target_c - stream.supply_c) * stream.heat_capacity_flow_kw_per_k
  }
}

///|
pub fn pinch_targets(
  hot_streams : Array[ThermalStreamTarget],
  cold_streams : Array[ThermalStreamTarget],
  minimum_approach_c : Double,
) -> PinchTargets {
  let mut hot_duty = 0.0
  let mut cold_duty = 0.0
  let mut hot_target = -1.0e30
  let mut cold_target = -1.0e30
  for stream in hot_streams {
    hot_duty += hot_stream_duty_kw(stream)
    hot_target = hot_target.max(stream.supply_c)
  }
  for stream in cold_streams {
    cold_duty += cold_stream_duty_kw(stream)
    cold_target = cold_target.max(stream.target_c)
  }
  {
    hot_target_c: hot_target + minimum_approach_c / 2.0,
    cold_target_c: cold_target - minimum_approach_c / 2.0,
    minimum_hot_utility_kw: (cold_duty - hot_duty).max(0.0),
    minimum_cold_utility_kw: (hot_duty - cold_duty).max(0.0),
    total_hot_duty_kw: hot_duty,
    total_cold_duty_kw: cold_duty,
  }
}

///|
pub fn match_heat_streams(
  hot : ThermalStreamTarget,
  cold : ThermalStreamTarget,
  minimum_approach_c : Double,
) -> HeatRecoveryMatch {
  let hot_duty = hot_stream_duty_kw(hot)
  let cold_duty = cold_stream_duty_kw(cold)
  let duty = hot_duty.min(cold_duty)
  let feasible = hot.supply_c - cold.supply_c >= minimum_approach_c &&
    duty > 0.0
  let hot_drop = if hot.heat_capacity_flow_kw_per_k <= 0.0 {
    0.0
  } else {
    duty / hot.heat_capacity_flow_kw_per_k
  }
  let cold_rise = if cold.heat_capacity_flow_kw_per_k <= 0.0 {
    0.0
  } else {
    duty / cold.heat_capacity_flow_kw_per_k
  }
  {
    hot_id: hot.id,
    cold_id: cold.id,
    duty_kw: if feasible {
      duty
    } else {
      0.0
    },
    hot_outlet_c: hot.supply_c - hot_drop,
    cold_outlet_c: cold.supply_c + cold_rise,
    feasible,
  }
}

///|
pub fn exchanger_area_m2(
  duty_w : Double,
  overall_u_w_per_m2_k : Double,
  lmtd_k : Double,
  correction_factor : Double,
) -> Double {
  let denominator = overall_u_w_per_m2_k * lmtd_k * correction_factor
  if denominator <= 0.0 {
    0.0
  } else {
    duty_w.abs() / denominator
  }
}

///|
pub fn exchanger_overdesign_area_m2(
  required_area_m2 : Double,
  overdesign_fraction : Double,
) -> Double {
  required_area_m2.max(0.0) * (1.0 + overdesign_fraction.max(0.0))
}

///|
pub fn heat_recovery_fraction(
  recovered_duty_kw : Double,
  available_hot_duty_kw : Double,
) -> Double {
  if available_hot_duty_kw <= 0.0 {
    0.0
  } else {
    (recovered_duty_kw / available_hot_duty_kw).max(0.0).min(1.0)
  }
}

///|
pub fn utility_target_after_recovery(
  process_duty_kw : Double,
  recovered_duty_kw : Double,
) -> Double {
  (process_duty_kw - recovered_duty_kw).max(0.0)
}
