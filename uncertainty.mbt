///|
pub struct UncertaintyEnvelope {
  nominal : Double
  low : Double
  high : Double
  relative_half_width : Double
} derive(Debug)

///|
pub fn relative_uncertainty_envelope(
  nominal : Double,
  relative_uncertainty : Double,
) -> UncertaintyEnvelope {
  let relative = relative_uncertainty.abs()
  let half_width = nominal.abs() * relative
  {
    nominal,
    low: nominal - half_width,
    high: nominal + half_width,
    relative_half_width: relative,
  }
}

///|
pub fn duty_uncertainty_envelope(
  inlet : Stream,
  target_temperature : Double,
  flow_relative_uncertainty : Double,
  cp_relative_uncertainty : Double,
) -> UncertaintyEnvelope {
  let nominal = heat_duty(inlet, inlet.with_temperature(target_temperature))
  let relative = flow_relative_uncertainty.abs() + cp_relative_uncertainty.abs()
  relative_uncertainty_envelope(nominal, relative)
}

///|
pub fn combine_uncertainties(
  first_relative : Double,
  second_relative : Double,
) -> Double {
  let first = first_relative.abs()
  let second = second_relative.abs()
  (first * first + second * second).sqrt()
}

///|
pub fn propagated_product_uncertainty(
  first_value : Double,
  first_relative_uncertainty : Double,
  second_value : Double,
  second_relative_uncertainty : Double,
) -> UncertaintyEnvelope {
  let nominal = first_value * second_value
  relative_uncertainty_envelope(
    nominal,
    combine_uncertainties(
      first_relative_uncertainty, second_relative_uncertainty,
    ),
  )
}

///|
pub fn propagated_sum_uncertainty(
  first_value : Double,
  first_absolute_uncertainty : Double,
  second_value : Double,
  second_absolute_uncertainty : Double,
) -> UncertaintyEnvelope {
  let nominal = first_value + second_value
  let absolute = combine_uncertainties(
    first_absolute_uncertainty, second_absolute_uncertainty,
  )
  let relative = if nominal.abs() < 1.0e-12 {
    0.0
  } else {
    absolute / nominal.abs()
  }
  relative_uncertainty_envelope(nominal, relative)
}

///|
pub fn worst_case_interval(
  values : Array[Double],
  relative_uncertainty : Double,
) -> UncertaintyEnvelope {
  let mut nominal = 0.0
  for value in values {
    nominal += value
  }
  relative_uncertainty_envelope(nominal, relative_uncertainty)
}

///|
pub fn uncertainty_margin(
  nominal : Double,
  low : Double,
  high : Double,
) -> Double {
  let absolute = (high - low).abs() / 2.0
  if nominal == 0.0 {
    absolute
  } else {
    absolute / nominal.abs() * nominal.abs()
  }
}

///|
pub fn uncertainty_contains(
  value : Double,
  envelope : UncertaintyEnvelope,
) -> Bool {
  value >= envelope.low && value <= envelope.high
}

///|
pub fn duty_sign_is_robust(envelope : UncertaintyEnvelope) -> Bool {
  (envelope.low > 0.0 && envelope.high > 0.0) ||
  (envelope.low < 0.0 && envelope.high < 0.0) ||
  envelope.nominal == 0.0
}
