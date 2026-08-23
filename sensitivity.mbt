///|
pub struct SensitivityPoint {
  target_temperature : Double
  duty : Double
  derivative : Double
  relative_derivative : Double
} derive(Debug)

///|
pub struct SensitivitySweep {
  points : Array[SensitivityPoint]
  minimum_duty : Double
  maximum_duty : Double
} derive(Debug)

///|
pub fn heater_duty_sensitivity(
  inlet : Stream,
  target_temperature : Double,
  step : Double,
) -> SensitivityPoint {
  let outlet = inlet.with_temperature(target_temperature)
  let duty = heat_duty(inlet, outlet)
  if step <= 0.0 {
    { target_temperature, duty, derivative: 0.0, relative_derivative: 0.0 }
  } else {
    let plus = heat_duty(
      inlet,
      inlet.with_temperature(target_temperature + step),
    )
    let minus = heat_duty(
      inlet,
      inlet.with_temperature(target_temperature - step),
    )
    let derivative = (plus - minus) / (2.0 * step)
    let relative_derivative = if duty.abs() < 1.0e-12 {
      0.0
    } else {
      derivative * target_temperature / duty
    }
    { target_temperature, duty, derivative, relative_derivative }
  }
}

///|
pub fn heater_sensitivity_table(
  inlet : Stream,
  target_temperatures : Array[Double],
  step : Double,
) -> Array[SensitivityPoint] {
  let points : Array[SensitivityPoint] = []
  for temperature in target_temperatures {
    points.push(heater_duty_sensitivity(inlet, temperature, step))
  }
  points
}

///|
pub fn sensitivity_at_temperature(
  substance : Substance,
  temperature : Double,
  step : Double,
) -> Double {
  if step <= 0.0 {
    0.0
  } else {
    (
      substance.enthalpy_at(temperature + step) -
      substance.enthalpy_at(temperature - step)
    ) /
    (2.0 * step)
  }
}

///|
pub fn flow_sensitivity(inlet : Stream, target_temperature : Double) -> Double {
  heat_duty(inlet, inlet.with_temperature(target_temperature)) /
  inlet.molar_flow().max(1.0e-12)
}

///|
pub fn target_temperature_for_duty(
  inlet : Stream,
  target_duty : Double,
  lower_temperature : Double,
  upper_temperature : Double,
) -> Double {
  let mut low = lower_temperature.min(upper_temperature)
  let mut high = lower_temperature.max(upper_temperature)
  for _ in 0..<64 {
    let middle = (low + high) / 2.0
    let duty = heat_duty(inlet, inlet.with_temperature(middle))
    if duty < target_duty {
      low = middle
    } else {
      high = middle
    }
  }
  (low + high) / 2.0
}

///|
pub fn sweep_heater_targets(
  inlet : Stream,
  start_temperature : Double,
  end_temperature : Double,
  step : Double,
) -> SensitivitySweep {
  let points : Array[SensitivityPoint] = []
  if step > 0.0 {
    let mut temperature = start_temperature
    for _ in 0..<1000 {
      if temperature > end_temperature + 1.0e-12 {
        break
      }
      points.push(heater_duty_sensitivity(inlet, temperature, step / 10.0))
      temperature += step
    }
  }
  if points.length() == 0 {
    { points, minimum_duty: 0.0, maximum_duty: 0.0 }
  } else {
    let mut minimum = points[0].duty
    let mut maximum = points[0].duty
    for point in points {
      minimum = minimum.min(point.duty)
      maximum = maximum.max(point.duty)
    }
    { points, minimum_duty: minimum, maximum_duty: maximum }
  }
}

///|
pub fn duty_curvature(
  inlet : Stream,
  target_temperature : Double,
  step : Double,
) -> Double {
  if step <= 0.0 {
    0.0
  } else {
    let center = heat_duty(inlet, inlet.with_temperature(target_temperature))
    let plus = heat_duty(
      inlet,
      inlet.with_temperature(target_temperature + step),
    )
    let minus = heat_duty(
      inlet,
      inlet.with_temperature(target_temperature - step),
    )
    (plus - 2.0 * center + minus) / (step * step)
  }
}

///|
pub fn finite_difference(
  value_minus : Double,
  value_plus : Double,
  step : Double,
) -> Double {
  if step <= 0.0 {
    0.0
  } else {
    (value_plus - value_minus) / (2.0 * step)
  }
}
