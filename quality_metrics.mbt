///|
pub(all) enum QualityGrade {
  Excellent
  Acceptable
  Warning
  Rejected
} derive(Debug, Eq)

///|
pub struct QualityResult {
  inlet : Double
  outlet : Double
  absolute_error : Double
  relative_error : Double
  tolerance : Double
  accepted : Bool
} derive(Debug)

///|
pub fn absolute_error(actual : Double, expected : Double) -> Double {
  (actual - expected).abs()
}

///|
pub fn relative_error(actual : Double, expected : Double) -> Double {
  let denominator = expected.abs().max(1.0e-12)
  (actual - expected).abs() / denominator
}

///|
pub fn energy_balance_quality(
  inlet : Double,
  outlet : Double,
  tolerance : Double,
) -> QualityResult {
  let error = absolute_error(outlet, inlet)
  {
    inlet,
    outlet,
    absolute_error: error,
    relative_error: relative_error(outlet, inlet),
    tolerance: tolerance.abs(),
    accepted: error <= tolerance.abs(),
  }
}

///|
pub fn quality_grade(result : QualityResult) -> QualityGrade {
  if result.absolute_error <= result.tolerance {
    Excellent
  } else if result.relative_error <= 0.01 {
    Acceptable
  } else if result.relative_error <= 0.05 {
    Warning
  } else {
    Rejected
  }
}

///|
pub fn weighted_error(
  errors : Array[Double],
  weights : Array[Double],
) -> Double {
  let length = errors.length().min(weights.length())
  let mut numerator = 0.0
  let mut denominator = 0.0
  for i in 0..<length {
    let weight = weights[i].abs()
    numerator += weight * errors[i].abs()
    denominator += weight
  }
  if denominator <= 0.0 {
    0.0
  } else {
    numerator / denominator
  }
}

///|
pub fn tolerance_for_scale(
  scale : Double,
  relative_tolerance : Double,
  absolute_floor : Double,
) -> Double {
  scale.abs() * relative_tolerance.abs() + absolute_floor.abs()
}

///|
pub fn within_tolerance(
  actual : Double,
  expected : Double,
  tolerance : Double,
) -> Bool {
  absolute_error(actual, expected) <= tolerance.abs()
}

///|
pub fn maximum_relative_error(
  actual : Array[Double],
  expected : Array[Double],
) -> Double {
  let length = actual.length().min(expected.length())
  let mut maximum = 0.0
  for i in 0..<length {
    maximum = maximum.max(relative_error(actual[i], expected[i]))
  }
  maximum
}

///|
pub fn convergence_quality(
  residual : Double,
  tolerance : Double,
) -> QualityGrade {
  let error = residual.abs()
  if error <= tolerance.abs() {
    Excellent
  } else if error <= tolerance.abs() * 10.0 {
    Acceptable
  } else if error <= tolerance.abs() * 100.0 {
    Warning
  } else {
    Rejected
  }
}

///|
pub fn quality_score(result : QualityResult) -> Double {
  if result.relative_error <= 0.0 {
    100.0
  } else {
    (100.0 / (1.0 + result.relative_error * 100.0)).max(0.0).min(100.0)
  }
}

///|
pub fn quality_summary(result : QualityResult) -> String {
  "error=\{result.absolute_error}, relative=\{result.relative_error}, tolerance=\{result.tolerance}, accepted=\{result.accepted}"
}
