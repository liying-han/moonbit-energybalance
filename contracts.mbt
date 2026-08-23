///|
pub fn stream_is_physically_valid(stream : Stream) -> Bool {
  validate_stream(stream).length() == 0
}

///|
pub fn substance_is_physically_valid(
  substance : Substance,
  temperature : Double,
) -> Bool {
  valid_absolute_temperature(temperature) &&
  substance.cp_model.cp_at(temperature) > 0.0
}

///|
pub fn heat_exchanger_temperatures_valid(
  hot_in_c : Double,
  hot_out_c : Double,
  cold_in_c : Double,
  cold_out_c : Double,
  minimum_approach_c : Double,
) -> Bool {
  hot_in_c >= hot_out_c &&
  cold_out_c >= cold_in_c &&
  hot_in_c - cold_out_c >= minimum_approach_c &&
  hot_out_c - cold_in_c >= minimum_approach_c
}

///|
pub fn heat_capacity_flow_is_valid(value : Double) -> Bool {
  value >= 0.0
}

///|
pub fn fraction_array_is_valid(
  values : Array[Double],
  tolerance : Double,
) -> Bool {
  let mut total = 0.0
  for value in values {
    if value < 0.0 {
      return false
    }
    total += value
  }
  (total - 1.0).abs() <= tolerance.abs()
}

///|
pub fn network_fraction_sum_is_valid(
  fractions : Array[Double],
  tolerance : Double,
) -> Bool {
  let mut total = 0.0
  for fraction in fractions {
    if fraction < 0.0 || fraction > 1.0 {
      return false
    }
    total += fraction
  }
  (total - 1.0).abs() <= tolerance.abs()
}

///|
pub fn safe_required_heat(
  inlets : Array[Stream],
  outlets : Array[Stream],
  shaft_work_w : Double,
  kinetic_w : Double,
  potential_w : Double,
) -> Double? {
  if inlets.length() == 0 || outlets.length() == 0 {
    None
  } else {
    Some(
      required_heat(
        inlets,
        outlets,
        shaft_work=shaft_work_w,
        kinetic=kinetic_w,
        potential=potential_w,
      ),
    )
  }
}

///|
pub fn duty_direction_is_consistent(
  inlet : Stream,
  outlet : Stream,
  expected_heating : Bool,
) -> Bool {
  let duty = heat_duty(inlet, outlet)
  if expected_heating {
    duty >= 0.0
  } else {
    duty <= 0.0
  }
}

///|
pub fn numerical_guard(
  value : Double,
  lower : Double,
  upper : Double,
) -> Double {
  value.max(lower.min(upper)).min(upper.max(lower))
}

///|
pub fn positive_or_zero(value : Double) -> Double {
  value.max(0.0)
}

///|
pub fn normalized_fraction(value : Double) -> Double {
  value.max(0.0).min(1.0)
}

///|
pub fn absolute_or_floor(value : Double, floor : Double) -> Double {
  value.abs().max(floor.abs())
}

///|
pub fn valid_temperature_pair(first : Double, second : Double) -> Bool {
  valid_absolute_temperature(first) && valid_absolute_temperature(second)
}

///|
pub fn valid_pressure_pair(first_kpa : Double, second_kpa : Double) -> Bool {
  first_kpa > 0.0 && second_kpa > 0.0
}

///|
pub fn valid_flow_pair(first : Double, second : Double) -> Bool {
  first >= 0.0 && second >= 0.0
}

///|
pub fn conservation_error(before : Double, after : Double) -> Double {
  (after - before).abs()
}

///|
pub fn conservation_is_closed(
  before : Double,
  after : Double,
  tolerance : Double,
) -> Bool {
  conservation_error(before, after) <= tolerance.abs()
}
