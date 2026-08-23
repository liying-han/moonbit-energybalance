///|
pub struct ScenarioPoint {
  flow : Double
  target_temperature : Double
  duty : Double
  area_m2 : Double
  quality_score : Double
} derive(Debug)

///|
pub struct ScenarioMatrix {
  points : Array[ScenarioPoint]
  minimum_duty : Double
  maximum_duty : Double
  minimum_area : Double
  maximum_area : Double
} derive(Debug)

///|
pub fn evaluate_scenario_point(
  inlet_temperature : Double,
  flow : Double,
  target_temperature : Double,
) -> ScenarioPoint {
  let stream = process_water_stream(
    id="matrix-feed",
    molar_flow=flow,
    temperature=inlet_temperature,
  )
  let duty = heat_duty(stream, stream.with_temperature(target_temperature))
  let sizing = size_heater(duty, 30.0, 500.0, 0.85)
  let quality = energy_balance_quality(duty, duty, 1.0e-6)
  {
    flow,
    target_temperature,
    duty,
    area_m2: sizing.area_m2,
    quality_score: quality_score(quality),
  }
}

///|
pub fn evaluate_scenario_matrix(
  inlet_temperature : Double,
  flows : Array[Double],
  targets : Array[Double],
) -> ScenarioMatrix {
  let points : Array[ScenarioPoint] = []
  for flow in flows {
    for target in targets {
      points.push(evaluate_scenario_point(inlet_temperature, flow, target))
    }
  }
  if points.length() == 0 {
    {
      points,
      minimum_duty: 0.0,
      maximum_duty: 0.0,
      minimum_area: 0.0,
      maximum_area: 0.0,
    }
  } else {
    let mut min_duty = points[0].duty
    let mut max_duty = points[0].duty
    let mut min_area = points[0].area_m2
    let mut max_area = points[0].area_m2
    for point in points {
      min_duty = min_duty.min(point.duty)
      max_duty = max_duty.max(point.duty)
      min_area = min_area.min(point.area_m2)
      max_area = max_area.max(point.area_m2)
    }
    {
      points,
      minimum_duty: min_duty,
      maximum_duty: max_duty,
      minimum_area: min_area,
      maximum_area: max_area,
    }
  }
}

///|
pub fn scenario_matrix_find_max_duty(matrix : ScenarioMatrix) -> ScenarioPoint? {
  if matrix.points.length() == 0 {
    None
  } else {
    let mut best = matrix.points[0]
    for point in matrix.points {
      if point.duty > best.duty {
        best = point
      }
    }
    Some(best)
  }
}

///|
pub fn scenario_matrix_find_min_area(matrix : ScenarioMatrix) -> ScenarioPoint? {
  if matrix.points.length() == 0 {
    None
  } else {
    let mut best = matrix.points[0]
    for point in matrix.points {
      if point.area_m2 < best.area_m2 {
        best = point
      }
    }
    Some(best)
  }
}

///|
pub fn scenario_matrix_csv_header() -> String {
  "flow,target_temperature,duty,area_m2,quality_score"
}

///|
pub fn scenario_matrix_csv_row(point : ScenarioPoint) -> String {
  "\{point.flow},\{point.target_temperature},\{point.duty},\{point.area_m2},\{point.quality_score}"
}

///|
pub fn scenario_matrix_csv(matrix : ScenarioMatrix) -> String {
  let mut output = scenario_matrix_csv_header() + "\n"
  for point in matrix.points {
    output = output + scenario_matrix_csv_row(point) + "\n"
  }
  output
}

///|
pub fn scenario_matrix_point_count(matrix : ScenarioMatrix) -> Int {
  matrix.points.length()
}

///|
pub fn scenario_matrix_average_quality(matrix : ScenarioMatrix) -> Double {
  if matrix.points.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for point in matrix.points {
      total += point.quality_score
    }
    total / matrix.points.length().to_double()
  }
}

///|
pub fn scenario_matrix_is_monotonic_in_temperature(
  matrix : ScenarioMatrix,
) -> Bool {
  let mut previous = -1.0e30
  for point in matrix.points {
    if point.duty < previous {
      return false
    }
    previous = point.duty
  }
  true
}
