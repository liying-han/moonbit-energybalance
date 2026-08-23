///|
pub(all) enum EnvelopeStatus {
  Feasible
  Infeasible
  InvalidInput
} derive(Debug, Eq)

///|
pub(all) enum ObjectiveDirection {
  Minimize
  Maximize
} derive(Debug, Eq)

///|
pub struct OperatingConstraints {
  minimum_temperature_k : Double
  maximum_temperature_k : Double
  minimum_flow_kg_per_s : Double
  maximum_flow_kg_per_s : Double
  minimum_pressure_kpa : Double
  maximum_pressure_kpa : Double
  minimum_duty_w : Double
  maximum_duty_w : Double
  maximum_cost_per_h : Double
} derive(Debug)

///|
pub struct OperatingPoint {
  temperature_k : Double
  flow_kg_per_s : Double
  pressure_kpa : Double
  duty_w : Double
  cost_per_h : Double
  emissions_kg_per_h : Double
  score : Double
  status : EnvelopeStatus
} derive(Debug)

///|
pub struct EnvelopeSummary {
  point_count : Int
  feasible_count : Int
  infeasible_count : Int
  minimum_duty_w : Double
  maximum_duty_w : Double
  minimum_cost_per_h : Double
  maximum_cost_per_h : Double
  average_temperature_k : Double
  average_flow_kg_per_s : Double
} derive(Debug)

///|
pub struct OperatingEnvelope {
  points : Array[OperatingPoint]
  constraints : OperatingConstraints
  summary : EnvelopeSummary
} derive(Debug)

///|
pub struct EnvelopeSelection {
  point : OperatingPoint
  objective_value : Double
  rank : Int
  explanation : String
} derive(Debug)

///|
pub struct RampPlan {
  points : Array[OperatingPoint]
  total_time_s : Double
  total_energy_j : Double
  maximum_step_temperature_k : Double
  maximum_step_flow_kg_per_s : Double
  valid : Bool
} derive(Debug)

///|
pub fn OperatingConstraints::new(
  minimum_temperature_k~ : Double,
  maximum_temperature_k~ : Double,
  minimum_flow_kg_per_s~ : Double,
  maximum_flow_kg_per_s~ : Double,
  minimum_pressure_kpa~ : Double,
  maximum_pressure_kpa~ : Double,
  minimum_duty_w~ : Double,
  maximum_duty_w~ : Double,
  maximum_cost_per_h~ : Double,
) -> OperatingConstraints {
  {
    minimum_temperature_k,
    maximum_temperature_k,
    minimum_flow_kg_per_s,
    maximum_flow_kg_per_s,
    minimum_pressure_kpa,
    maximum_pressure_kpa,
    minimum_duty_w,
    maximum_duty_w,
    maximum_cost_per_h,
  }
}

///|
pub fn standard_operating_constraints() -> OperatingConstraints {
  OperatingConstraints::new(
    minimum_temperature_k=273.15,
    maximum_temperature_k=573.15,
    minimum_flow_kg_per_s=0.0,
    maximum_flow_kg_per_s=100.0,
    minimum_pressure_kpa=1.0,
    maximum_pressure_kpa=5000.0,
    minimum_duty_w=-1.0e8,
    maximum_duty_w=1.0e8,
    maximum_cost_per_h=1.0e6,
  )
}

///|
pub fn operating_constraints_are_valid(
  constraints : OperatingConstraints,
) -> Bool {
  constraints.minimum_temperature_k > 0.0 &&
  constraints.maximum_temperature_k >= constraints.minimum_temperature_k &&
  constraints.minimum_flow_kg_per_s >= 0.0 &&
  constraints.maximum_flow_kg_per_s >= constraints.minimum_flow_kg_per_s &&
  constraints.minimum_pressure_kpa > 0.0 &&
  constraints.maximum_pressure_kpa >= constraints.minimum_pressure_kpa &&
  constraints.maximum_duty_w >= constraints.minimum_duty_w &&
  constraints.maximum_cost_per_h >= 0.0
}

///|
pub fn clamp_operating_temperature(
  value : Double,
  constraints : OperatingConstraints,
) -> Double {
  value
  .max(constraints.minimum_temperature_k)
  .min(constraints.maximum_temperature_k)
}

///|
pub fn clamp_operating_flow(
  value : Double,
  constraints : OperatingConstraints,
) -> Double {
  value
  .max(constraints.minimum_flow_kg_per_s)
  .min(constraints.maximum_flow_kg_per_s)
}

///|
pub fn clamp_operating_pressure(
  value : Double,
  constraints : OperatingConstraints,
) -> Double {
  value
  .max(constraints.minimum_pressure_kpa)
  .min(constraints.maximum_pressure_kpa)
}

///|
pub fn operating_point_status(
  temperature_k : Double,
  flow_kg_per_s : Double,
  pressure_kpa : Double,
  duty_w : Double,
  cost_per_h : Double,
  constraints : OperatingConstraints,
) -> EnvelopeStatus {
  if !operating_constraints_are_valid(constraints) ||
    temperature_k != temperature_k ||
    flow_kg_per_s != flow_kg_per_s ||
    pressure_kpa != pressure_kpa ||
    duty_w != duty_w ||
    cost_per_h != cost_per_h {
    InvalidInput
  } else if temperature_k >= constraints.minimum_temperature_k &&
    temperature_k <= constraints.maximum_temperature_k &&
    flow_kg_per_s >= constraints.minimum_flow_kg_per_s &&
    flow_kg_per_s <= constraints.maximum_flow_kg_per_s &&
    pressure_kpa >= constraints.minimum_pressure_kpa &&
    pressure_kpa <= constraints.maximum_pressure_kpa &&
    duty_w >= constraints.minimum_duty_w &&
    duty_w <= constraints.maximum_duty_w &&
    cost_per_h <= constraints.maximum_cost_per_h {
    Feasible
  } else {
    Infeasible
  }
}

///|
pub fn operating_point(
  temperature_k : Double,
  flow_kg_per_s : Double,
  pressure_kpa : Double,
  duty_w : Double,
  cost_per_h : Double,
  emissions_kg_per_h : Double,
  score : Double,
  constraints : OperatingConstraints,
) -> OperatingPoint {
  {
    temperature_k,
    flow_kg_per_s,
    pressure_kpa,
    duty_w,
    cost_per_h,
    emissions_kg_per_h,
    score,
    status: operating_point_status(
      temperature_k, flow_kg_per_s, pressure_kpa, duty_w, cost_per_h, constraints,
    ),
  }
}

///|
pub fn operating_point_is_feasible(point : OperatingPoint) -> Bool {
  point.status == Feasible
}

///|
pub fn operating_point_is_invalid(point : OperatingPoint) -> Bool {
  point.status == InvalidInput
}

///|
pub fn operating_point_energy_kwh(point : OperatingPoint) -> Double {
  point.duty_w.abs() / 1000.0
}

///|
pub fn operating_point_specific_duty(point : OperatingPoint) -> Double {
  if point.flow_kg_per_s <= 0.0 {
    0.0
  } else {
    point.duty_w / point.flow_kg_per_s
  }
}

///|
pub fn operating_point_specific_cost(point : OperatingPoint) -> Double {
  if point.flow_kg_per_s <= 0.0 {
    0.0
  } else {
    point.cost_per_h / point.flow_kg_per_s
  }
}

///|
pub fn operating_point_margin_temperature(
  point : OperatingPoint,
  constraints : OperatingConstraints,
) -> Double {
  (point.temperature_k - constraints.minimum_temperature_k).min(
    constraints.maximum_temperature_k - point.temperature_k,
  )
}

///|
pub fn operating_point_margin_flow(
  point : OperatingPoint,
  constraints : OperatingConstraints,
) -> Double {
  (point.flow_kg_per_s - constraints.minimum_flow_kg_per_s).min(
    constraints.maximum_flow_kg_per_s - point.flow_kg_per_s,
  )
}

///|
pub fn operating_point_margin_pressure(
  point : OperatingPoint,
  constraints : OperatingConstraints,
) -> Double {
  (point.pressure_kpa - constraints.minimum_pressure_kpa).min(
    constraints.maximum_pressure_kpa - point.pressure_kpa,
  )
}

///|
pub fn operating_point_margin_duty(
  point : OperatingPoint,
  constraints : OperatingConstraints,
) -> Double {
  (point.duty_w - constraints.minimum_duty_w).min(
    constraints.maximum_duty_w - point.duty_w,
  )
}

///|
pub fn operating_point_margin_cost(
  point : OperatingPoint,
  constraints : OperatingConstraints,
) -> Double {
  constraints.maximum_cost_per_h - point.cost_per_h
}

///|
pub fn operating_point_minimum_margin(
  point : OperatingPoint,
  constraints : OperatingConstraints,
) -> Double {
  operating_point_margin_temperature(point, constraints)
  .min(operating_point_margin_flow(point, constraints))
  .min(operating_point_margin_pressure(point, constraints))
  .min(operating_point_margin_duty(point, constraints))
  .min(operating_point_margin_cost(point, constraints))
}

///|
pub fn normalized_operating_score(
  point : OperatingPoint,
  constraints : OperatingConstraints,
) -> Double {
  let temperature_range = (constraints.maximum_temperature_k -
  constraints.minimum_temperature_k).max(1.0e-12)
  let flow_range = (constraints.maximum_flow_kg_per_s -
  constraints.minimum_flow_kg_per_s).max(1.0e-12)
  let pressure_range = (constraints.maximum_pressure_kpa -
  constraints.minimum_pressure_kpa).max(1.0e-12)
  let temperature_score = (
      point.temperature_k - constraints.minimum_temperature_k
    ) /
    temperature_range
  let flow_score = (point.flow_kg_per_s - constraints.minimum_flow_kg_per_s) /
    flow_range
  let pressure_score = (point.pressure_kpa - constraints.minimum_pressure_kpa) /
    pressure_range
  (temperature_score + flow_score + pressure_score) / 3.0
}

///|
pub fn default_operating_point(
  constraints : OperatingConstraints,
) -> OperatingPoint {
  let temperature = (
      constraints.minimum_temperature_k + constraints.maximum_temperature_k
    ) /
    2.0
  let flow = (
      constraints.minimum_flow_kg_per_s + constraints.maximum_flow_kg_per_s
    ) /
    2.0
  let pressure = (
      constraints.minimum_pressure_kpa + constraints.maximum_pressure_kpa
    ) /
    2.0
  operating_point(temperature, flow, pressure, 0.0, 0.0, 0.0, 0.0, constraints)
}

///|
pub fn empty_envelope(constraints : OperatingConstraints) -> OperatingEnvelope {
  {
    points: [],
    constraints,
    summary: {
      point_count: 0,
      feasible_count: 0,
      infeasible_count: 0,
      minimum_duty_w: 0.0,
      maximum_duty_w: 0.0,
      minimum_cost_per_h: 0.0,
      maximum_cost_per_h: 0.0,
      average_temperature_k: 0.0,
      average_flow_kg_per_s: 0.0,
    },
  }
}

///|
fn envelope_summary(points : Array[OperatingPoint]) -> EnvelopeSummary {
  if points.length() == 0 {
    {
      point_count: 0,
      feasible_count: 0,
      infeasible_count: 0,
      minimum_duty_w: 0.0,
      maximum_duty_w: 0.0,
      minimum_cost_per_h: 0.0,
      maximum_cost_per_h: 0.0,
      average_temperature_k: 0.0,
      average_flow_kg_per_s: 0.0,
    }
  } else {
    let mut feasible = 0
    let mut minimum_duty = points[0].duty_w
    let mut maximum_duty = points[0].duty_w
    let mut minimum_cost = points[0].cost_per_h
    let mut maximum_cost = points[0].cost_per_h
    let mut total_temperature = 0.0
    let mut total_flow = 0.0
    for point in points {
      if operating_point_is_feasible(point) {
        feasible += 1
      }
      minimum_duty = minimum_duty.min(point.duty_w)
      maximum_duty = maximum_duty.max(point.duty_w)
      minimum_cost = minimum_cost.min(point.cost_per_h)
      maximum_cost = maximum_cost.max(point.cost_per_h)
      total_temperature += point.temperature_k
      total_flow += point.flow_kg_per_s
    }
    {
      point_count: points.length(),
      feasible_count: feasible,
      infeasible_count: points.length() - feasible,
      minimum_duty_w: minimum_duty,
      maximum_duty_w: maximum_duty,
      minimum_cost_per_h: minimum_cost,
      maximum_cost_per_h: maximum_cost,
      average_temperature_k: total_temperature / points.length().to_double(),
      average_flow_kg_per_s: total_flow / points.length().to_double(),
    }
  }
}

///|
pub fn make_operating_envelope(
  points : Array[OperatingPoint],
  constraints : OperatingConstraints,
) -> OperatingEnvelope {
  { points, constraints, summary: envelope_summary(points) }
}

///|
pub fn envelope_point_count(envelope : OperatingEnvelope) -> Int {
  envelope.points.length()
}

///|
pub fn envelope_feasible_count(envelope : OperatingEnvelope) -> Int {
  envelope.summary.feasible_count
}

///|
pub fn envelope_is_empty(envelope : OperatingEnvelope) -> Bool {
  envelope.points.length() == 0
}

///|
pub fn envelope_has_feasible_point(envelope : OperatingEnvelope) -> Bool {
  envelope.summary.feasible_count > 0
}

///|
pub fn envelope_feasible_fraction(envelope : OperatingEnvelope) -> Double {
  if envelope.points.length() == 0 {
    0.0
  } else {
    envelope.summary.feasible_count.to_double() /
    envelope.points.length().to_double()
  }
}

///|
pub fn envelope_average_score(envelope : OperatingEnvelope) -> Double {
  if envelope.points.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for point in envelope.points {
      total += point.score
    }
    total / envelope.points.length().to_double()
  }
}

///|
pub fn envelope_average_margin(envelope : OperatingEnvelope) -> Double {
  if envelope.points.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for point in envelope.points {
      total += operating_point_minimum_margin(point, envelope.constraints)
    }
    total / envelope.points.length().to_double()
  }
}

///|
pub fn envelope_total_energy_kwh(envelope : OperatingEnvelope) -> Double {
  let mut total = 0.0
  for point in envelope.points {
    total += operating_point_energy_kwh(point)
  }
  total
}

///|
pub fn envelope_total_cost(envelope : OperatingEnvelope) -> Double {
  let mut total = 0.0
  for point in envelope.points {
    total += point.cost_per_h
  }
  total
}

///|
pub fn envelope_total_emissions(envelope : OperatingEnvelope) -> Double {
  let mut total = 0.0
  for point in envelope.points {
    total += point.emissions_kg_per_h
  }
  total
}

///|
pub fn envelope_feasible_points(
  envelope : OperatingEnvelope,
) -> Array[OperatingPoint] {
  let result : Array[OperatingPoint] = []
  for point in envelope.points {
    if operating_point_is_feasible(point) {
      result.push(point)
    }
  }
  result
}

///|
pub fn envelope_infeasible_points(
  envelope : OperatingEnvelope,
) -> Array[OperatingPoint] {
  let result : Array[OperatingPoint] = []
  for point in envelope.points {
    if !operating_point_is_feasible(point) {
      result.push(point)
    }
  }
  result
}

///|
pub fn envelope_invalid_points(
  envelope : OperatingEnvelope,
) -> Array[OperatingPoint] {
  let result : Array[OperatingPoint] = []
  for point in envelope.points {
    if operating_point_is_invalid(point) {
      result.push(point)
    }
  }
  result
}

///|
pub fn envelope_points_with_minimum_margin(
  envelope : OperatingEnvelope,
  margin : Double,
) -> Array[OperatingPoint] {
  let result : Array[OperatingPoint] = []
  let threshold = margin.max(0.0)
  for point in envelope.points {
    if operating_point_minimum_margin(point, envelope.constraints) >= threshold {
      result.push(point)
    }
  }
  result
}

///|
pub fn envelope_points_in_temperature_band(
  envelope : OperatingEnvelope,
  lower_k : Double,
  upper_k : Double,
) -> Array[OperatingPoint] {
  let result : Array[OperatingPoint] = []
  let lower = lower_k.min(upper_k)
  let upper = lower_k.max(upper_k)
  for point in envelope.points {
    if point.temperature_k >= lower && point.temperature_k <= upper {
      result.push(point)
    }
  }
  result
}

///|
pub fn envelope_points_in_flow_band(
  envelope : OperatingEnvelope,
  lower_kg_per_s : Double,
  upper_kg_per_s : Double,
) -> Array[OperatingPoint] {
  let result : Array[OperatingPoint] = []
  let lower = lower_kg_per_s.min(upper_kg_per_s)
  let upper = lower_kg_per_s.max(upper_kg_per_s)
  for point in envelope.points {
    if point.flow_kg_per_s >= lower && point.flow_kg_per_s <= upper {
      result.push(point)
    }
  }
  result
}

///|
pub fn envelope_best_by(
  envelope : OperatingEnvelope,
  direction : ObjectiveDirection,
  objective : (OperatingPoint) -> Double,
) -> OperatingPoint? {
  let candidates = envelope_feasible_points(envelope)
  if candidates.length() == 0 {
    None
  } else {
    let mut best = candidates[0]
    let mut best_value = objective(best)
    for point in candidates {
      let value = objective(point)
      let better = match direction {
        Minimize => value < best_value
        Maximize => value > best_value
      }
      if better {
        best = point
        best_value = value
      }
    }
    Some(best)
  }
}

///|
pub fn envelope_best_by_cost(envelope : OperatingEnvelope) -> OperatingPoint? {
  envelope_best_by(envelope, Minimize, fn(point) { point.cost_per_h })
}

///|
pub fn envelope_best_by_duty(envelope : OperatingEnvelope) -> OperatingPoint? {
  envelope_best_by(envelope, Minimize, fn(point) { point.duty_w.abs() })
}

///|
pub fn envelope_best_by_emissions(
  envelope : OperatingEnvelope,
) -> OperatingPoint? {
  envelope_best_by(envelope, Minimize, fn(point) { point.emissions_kg_per_h })
}

///|
pub fn envelope_best_by_margin(envelope : OperatingEnvelope) -> OperatingPoint? {
  envelope_best_by(envelope, Maximize, fn(point) {
    operating_point_minimum_margin(point, envelope.constraints)
  })
}

///|
pub fn select_operating_point(
  envelope : OperatingEnvelope,
  direction : ObjectiveDirection,
  objective : (OperatingPoint) -> Double,
  explanation : String,
) -> EnvelopeSelection? {
  match envelope_best_by(envelope, direction, objective) {
    None => None
    Some(point) =>
      Some({ point, objective_value: objective(point), rank: 1, explanation })
  }
}

///|
pub fn select_lowest_cost(envelope : OperatingEnvelope) -> EnvelopeSelection? {
  select_operating_point(
    envelope,
    Minimize,
    fn(point) { point.cost_per_h },
    "lowest feasible operating cost",
  )
}

///|
pub fn select_lowest_duty(envelope : OperatingEnvelope) -> EnvelopeSelection? {
  select_operating_point(
    envelope,
    Minimize,
    fn(point) { point.duty_w.abs() },
    "lowest absolute thermal duty",
  )
}

///|
pub fn select_safest_margin(envelope : OperatingEnvelope) -> EnvelopeSelection? {
  select_operating_point(
    envelope,
    Maximize,
    fn(point) { operating_point_minimum_margin(point, envelope.constraints) },
    "largest minimum constraint margin",
  )
}

///|
pub fn point_dominates(
  first : OperatingPoint,
  second : OperatingPoint,
  minimize_cost : Bool,
  minimize_duty : Bool,
  minimize_emissions : Bool,
) -> Bool {
  if !operating_point_is_feasible(first) || !operating_point_is_feasible(second) {
    false
  } else {
    let cost_better = !minimize_cost || first.cost_per_h <= second.cost_per_h
    let duty_better = !minimize_duty ||
      first.duty_w.abs() <= second.duty_w.abs()
    let emissions_better = !minimize_emissions ||
      first.emissions_kg_per_h <= second.emissions_kg_per_h
    let one_strict = (minimize_cost && first.cost_per_h < second.cost_per_h) ||
      (minimize_duty && first.duty_w.abs() < second.duty_w.abs()) ||
      (
        minimize_emissions &&
        first.emissions_kg_per_h < second.emissions_kg_per_h
      )
    cost_better && duty_better && emissions_better && one_strict
  }
}

///|
pub fn envelope_pareto_frontier(
  envelope : OperatingEnvelope,
  minimize_cost : Bool,
  minimize_duty : Bool,
  minimize_emissions : Bool,
) -> Array[OperatingPoint] {
  let candidates = envelope_feasible_points(envelope)
  let result : Array[OperatingPoint] = []
  for candidate in candidates {
    let mut dominated = false
    for other in candidates {
      if point_dominates(
          other, candidate, minimize_cost, minimize_duty, minimize_emissions,
        ) {
        dominated = true
      }
    }
    if !dominated {
      result.push(candidate)
    }
  }
  result
}

///|
pub fn pareto_frontier_count(envelope : OperatingEnvelope) -> Int {
  envelope_pareto_frontier(envelope, true, true, true).length()
}

///|
pub fn operating_point_cost_score(
  point : OperatingPoint,
  cost_scale : Double,
) -> Double {
  point.cost_per_h / cost_scale.abs().max(1.0e-12)
}

///|
pub fn operating_point_duty_score(
  point : OperatingPoint,
  duty_scale : Double,
) -> Double {
  point.duty_w.abs() / duty_scale.abs().max(1.0e-12)
}

///|
pub fn operating_point_emissions_score(
  point : OperatingPoint,
  emissions_scale : Double,
) -> Double {
  point.emissions_kg_per_h / emissions_scale.abs().max(1.0e-12)
}

///|
pub fn weighted_operating_score(
  point : OperatingPoint,
  cost_weight : Double,
  duty_weight : Double,
  emissions_weight : Double,
  cost_scale : Double,
  duty_scale : Double,
  emissions_scale : Double,
) -> Double {
  cost_weight.max(0.0) * operating_point_cost_score(point, cost_scale) +
  duty_weight.max(0.0) * operating_point_duty_score(point, duty_scale) +
  emissions_weight.max(0.0) *
  operating_point_emissions_score(point, emissions_scale)
}

///|
pub fn envelope_best_weighted(
  envelope : OperatingEnvelope,
  cost_weight : Double,
  duty_weight : Double,
  emissions_weight : Double,
  cost_scale : Double,
  duty_scale : Double,
  emissions_scale : Double,
) -> OperatingPoint? {
  envelope_best_by(envelope, Minimize, fn(point) {
    weighted_operating_score(
      point, cost_weight, duty_weight, emissions_weight, cost_scale, duty_scale,
      emissions_scale,
    )
  })
}

///|
pub fn scan_operating_envelope(
  temperatures_k : Array[Double],
  flows_kg_per_s : Array[Double],
  pressures_kpa : Array[Double],
  duty_model : (Double, Double, Double) -> Double,
  cost_model : (Double, Double, Double, Double) -> Double,
  emissions_model : (Double, Double, Double, Double) -> Double,
  constraints : OperatingConstraints,
) -> OperatingEnvelope {
  let points : Array[OperatingPoint] = []
  if !operating_constraints_are_valid(constraints) {
    return make_operating_envelope(points, constraints)
  }
  for temperature in temperatures_k {
    for flow in flows_kg_per_s {
      for pressure in pressures_kpa {
        let duty = duty_model(temperature, flow, pressure)
        let cost = cost_model(temperature, flow, pressure, duty)
        let emissions = emissions_model(temperature, flow, pressure, duty)
        let point = operating_point(
          temperature, flow, pressure, duty, cost, emissions, 0.0, constraints,
        )
        points.push({
          ..point,
          score: normalized_operating_score(point, constraints),
        })
      }
    }
  }
  make_operating_envelope(points, constraints)
}

///|
pub fn linear_duty_model(
  inlet_temperature_k : Double,
  target_temperature_k : Double,
  flow_kg_per_s : Double,
  heat_capacity_j_per_kg_k : Double,
) -> Double {
  flow_kg_per_s.max(0.0) *
  heat_capacity_j_per_kg_k.max(0.0) *
  (target_temperature_k - inlet_temperature_k)
}

///|
pub fn pressure_loss_duty(
  flow_kg_per_s : Double,
  pressure_kpa : Double,
  efficiency : Double,
) -> Double {
  flow_kg_per_s.max(0.0) *
  pressure_kpa.max(0.0) *
  1000.0 /
  efficiency.max(1.0e-12)
}

///|
pub fn combined_duty_model(
  temperature_k : Double,
  flow_kg_per_s : Double,
  pressure_kpa : Double,
  target_temperature_k : Double,
  heat_capacity_j_per_kg_k : Double,
  pump_efficiency : Double,
) -> Double {
  linear_duty_model(
    temperature_k, target_temperature_k, flow_kg_per_s, heat_capacity_j_per_kg_k,
  ) +
  pressure_loss_duty(flow_kg_per_s, pressure_kpa, pump_efficiency)
}

///|
pub fn linear_cost_model(
  flow_kg_per_s : Double,
  duty_w : Double,
  utility_price_per_kwh : Double,
  demand_charge_per_kw : Double,
) -> Double {
  duty_w.abs() / 1000.0 * utility_price_per_kwh.max(0.0) +
  flow_kg_per_s.max(0.0) * demand_charge_per_kw.max(0.0)
}

///|
pub fn carbon_cost_model(
  duty_w : Double,
  emission_factor_kg_per_kwh : Double,
  carbon_price_per_kg : Double,
) -> Double {
  duty_w.abs() /
  1000.0 *
  emission_factor_kg_per_kwh.max(0.0) *
  carbon_price_per_kg.max(0.0)
}

///|
pub fn linear_emissions_model(
  duty_w : Double,
  emission_factor_kg_per_kwh : Double,
) -> Double {
  duty_w.abs() / 1000.0 * emission_factor_kg_per_kwh.max(0.0)
}

///|
pub fn envelope_summary_text(summary : EnvelopeSummary) -> String {
  "points=" +
  summary.point_count.to_string() +
  ", feasible=" +
  summary.feasible_count.to_string() +
  ", infeasible=" +
  summary.infeasible_count.to_string() +
  ", duty=[" +
  summary.minimum_duty_w.to_string() +
  "," +
  summary.maximum_duty_w.to_string() +
  "]" +
  ", cost=[" +
  summary.minimum_cost_per_h.to_string() +
  "," +
  summary.maximum_cost_per_h.to_string() +
  "]"
}

///|
pub fn envelope_point_text(point : OperatingPoint) -> String {
  "T=" +
  point.temperature_k.to_string() +
  " K, flow=" +
  point.flow_kg_per_s.to_string() +
  " kg/s, P=" +
  point.pressure_kpa.to_string() +
  " kPa, duty=" +
  point.duty_w.to_string() +
  " W, cost=" +
  point.cost_per_h.to_string() +
  "/h"
}

///|
pub fn envelope_csv_header() -> String {
  "temperature_k,flow_kg_per_s,pressure_kpa,duty_w,cost_per_h,emissions_kg_per_h,score,status"
}

///|
pub fn envelope_status_text(status : EnvelopeStatus) -> String {
  match status {
    Feasible => "feasible"
    Infeasible => "infeasible"
    InvalidInput => "invalid"
  }
}

///|
pub fn envelope_csv_row(point : OperatingPoint) -> String {
  point.temperature_k.to_string() +
  "," +
  point.flow_kg_per_s.to_string() +
  "," +
  point.pressure_kpa.to_string() +
  "," +
  point.duty_w.to_string() +
  "," +
  point.cost_per_h.to_string() +
  "," +
  point.emissions_kg_per_h.to_string() +
  "," +
  point.score.to_string() +
  "," +
  envelope_status_text(point.status)
}

///|
pub fn envelope_csv(envelope : OperatingEnvelope) -> String {
  let mut output = envelope_csv_header() + "\n"
  for point in envelope.points {
    output = output + envelope_csv_row(point) + "\n"
  }
  output
}

///|
pub fn envelope_csv_line_count(csv : String) -> Int {
  if csv.length() == 0 {
    0
  } else {
    csv.split("\n").length() - 1
  }
}

///|
pub fn envelope_filter(
  envelope : OperatingEnvelope,
  predicate : (OperatingPoint) -> Bool,
) -> OperatingEnvelope {
  let points : Array[OperatingPoint] = []
  for point in envelope.points {
    if predicate(point) {
      points.push(point)
    }
  }
  make_operating_envelope(points, envelope.constraints)
}

///|
pub fn envelope_filter_feasible(
  envelope : OperatingEnvelope,
) -> OperatingEnvelope {
  envelope_filter(envelope, fn(point) { operating_point_is_feasible(point) })
}

///|
pub fn envelope_filter_positive_duty(
  envelope : OperatingEnvelope,
) -> OperatingEnvelope {
  envelope_filter(envelope, fn(point) { point.duty_w >= 0.0 })
}

///|
pub fn envelope_filter_negative_duty(
  envelope : OperatingEnvelope,
) -> OperatingEnvelope {
  envelope_filter(envelope, fn(point) { point.duty_w <= 0.0 })
}

///|
pub fn envelope_filter_cost(
  envelope : OperatingEnvelope,
  maximum_cost_per_h : Double,
) -> OperatingEnvelope {
  envelope_filter(envelope, fn(point) {
    point.cost_per_h <= maximum_cost_per_h.max(0.0)
  })
}

///|
pub fn envelope_filter_margin(
  envelope : OperatingEnvelope,
  minimum_margin : Double,
) -> OperatingEnvelope {
  envelope_filter(envelope, fn(point) {
    operating_point_minimum_margin(point, envelope.constraints) >=
    minimum_margin.max(0.0)
  })
}

///|
pub fn envelope_append(
  first : OperatingEnvelope,
  second : OperatingEnvelope,
) -> OperatingEnvelope {
  let points : Array[OperatingPoint] = []
  for point in first.points {
    points.push(point)
  }
  for point in second.points {
    points.push(point)
  }
  make_operating_envelope(points, first.constraints)
}

///|
pub fn envelope_take_feasible(
  envelope : OperatingEnvelope,
  limit : Int,
) -> Array[OperatingPoint] {
  let result : Array[OperatingPoint] = []
  if limit <= 0 {
    result
  } else {
    for point in envelope.points {
      if operating_point_is_feasible(point) && result.length() < limit {
        result.push(point)
      }
    }
    result
  }
}

///|
pub fn envelope_count_by_status(
  envelope : OperatingEnvelope,
  status : EnvelopeStatus,
) -> Int {
  let mut count = 0
  for point in envelope.points {
    if point.status == status {
      count += 1
    }
  }
  count
}

///|
pub fn envelope_status_is_consistent(envelope : OperatingEnvelope) -> Bool {
  for point in envelope.points {
    let expected = operating_point_status(
      point.temperature_k,
      point.flow_kg_per_s,
      point.pressure_kpa,
      point.duty_w,
      point.cost_per_h,
      envelope.constraints,
    )
    if expected != point.status {
      return false
    }
  }
  true
}

///|
pub fn envelope_recalculate_scores(
  envelope : OperatingEnvelope,
) -> OperatingEnvelope {
  let points : Array[OperatingPoint] = []
  for point in envelope.points {
    points.push({
      ..point,
      score: normalized_operating_score(point, envelope.constraints),
    })
  }
  make_operating_envelope(points, envelope.constraints)
}

///|
pub fn operating_point_with_cost(
  point : OperatingPoint,
  cost_per_h : Double,
  emissions_kg_per_h : Double,
  constraints : OperatingConstraints,
) -> OperatingPoint {
  operating_point(
    point.temperature_k,
    point.flow_kg_per_s,
    point.pressure_kpa,
    point.duty_w,
    cost_per_h,
    emissions_kg_per_h,
    point.score,
    constraints,
  )
}

///|
pub fn operating_point_with_duty(
  point : OperatingPoint,
  duty_w : Double,
  cost_per_h : Double,
  emissions_kg_per_h : Double,
  constraints : OperatingConstraints,
) -> OperatingPoint {
  operating_point(
    point.temperature_k,
    point.flow_kg_per_s,
    point.pressure_kpa,
    duty_w,
    cost_per_h,
    emissions_kg_per_h,
    point.score,
    constraints,
  )
}

///|
pub fn operating_point_with_process_state(
  point : OperatingPoint,
  temperature_k : Double,
  flow_kg_per_s : Double,
  pressure_kpa : Double,
  constraints : OperatingConstraints,
) -> OperatingPoint {
  operating_point(
    temperature_k,
    flow_kg_per_s,
    pressure_kpa,
    point.duty_w,
    point.cost_per_h,
    point.emissions_kg_per_h,
    point.score,
    constraints,
  )
}

///|
pub fn operating_point_distance(
  first : OperatingPoint,
  second : OperatingPoint,
) -> Double {
  let temperature = first.temperature_k - second.temperature_k
  let flow = first.flow_kg_per_s - second.flow_kg_per_s
  let pressure = first.pressure_kpa - second.pressure_kpa
  (temperature * temperature + flow * flow + pressure * pressure).sqrt()
}

///|
pub fn operating_point_weighted_distance(
  first : OperatingPoint,
  second : OperatingPoint,
  temperature_weight : Double,
  flow_weight : Double,
  pressure_weight : Double,
) -> Double {
  let temperature = first.temperature_k - second.temperature_k
  let flow = first.flow_kg_per_s - second.flow_kg_per_s
  let pressure = first.pressure_kpa - second.pressure_kpa
  (temperature * temperature * temperature_weight.max(0.0) +
  flow * flow * flow_weight.max(0.0) +
  pressure * pressure * pressure_weight.max(0.0)).sqrt()
}

///|
pub fn nearest_operating_point(
  envelope : OperatingEnvelope,
  target : OperatingPoint,
) -> OperatingPoint? {
  if envelope.points.length() == 0 {
    None
  } else {
    let mut nearest = envelope.points[0]
    let mut distance = operating_point_distance(nearest, target)
    for point in envelope.points {
      let candidate_distance = operating_point_distance(point, target)
      if candidate_distance < distance {
        nearest = point
        distance = candidate_distance
      }
    }
    Some(nearest)
  }
}

///|
pub fn nearest_feasible_operating_point(
  envelope : OperatingEnvelope,
  target : OperatingPoint,
) -> OperatingPoint? {
  let feasible = envelope_filter_feasible(envelope)
  nearest_operating_point(feasible, target)
}

///|
pub fn ramp_step_time_s(
  first : OperatingPoint,
  second : OperatingPoint,
  maximum_temperature_rate_k_per_s : Double,
  maximum_flow_rate_kg_per_s2 : Double,
) -> Double {
  let temperature_time = (second.temperature_k - first.temperature_k).abs() /
    maximum_temperature_rate_k_per_s.abs().max(1.0e-12)
  let flow_time = (second.flow_kg_per_s - first.flow_kg_per_s).abs() /
    maximum_flow_rate_kg_per_s2.abs().max(1.0e-12)
  temperature_time.max(flow_time)
}

///|
pub fn ramp_plan(
  points : Array[OperatingPoint],
  maximum_temperature_rate_k_per_s : Double,
  maximum_flow_rate_kg_per_s2 : Double,
) -> RampPlan {
  if points.length() == 0 {
    {
      points,
      total_time_s: 0.0,
      total_energy_j: 0.0,
      maximum_step_temperature_k: 0.0,
      maximum_step_flow_kg_per_s: 0.0,
      valid: false,
    }
  } else {
    let mut total_time = 0.0
    let mut total_energy = 0.0
    let mut maximum_temperature_step = 0.0
    let mut maximum_flow_step = 0.0
    let mut valid = true
    for index in 0..<points.length() {
      total_energy += points[index].duty_w.abs()
      if !operating_point_is_feasible(points[index]) {
        valid = false
      }
      if index > 0 {
        let previous = points[index - 1]
        let current = points[index]
        let temperature_step = (current.temperature_k - previous.temperature_k).abs()
        let flow_step = (current.flow_kg_per_s - previous.flow_kg_per_s).abs()
        maximum_temperature_step = maximum_temperature_step.max(
          temperature_step,
        )
        maximum_flow_step = maximum_flow_step.max(flow_step)
        total_time += ramp_step_time_s(
          previous, current, maximum_temperature_rate_k_per_s, maximum_flow_rate_kg_per_s2,
        )
      }
    }
    {
      points,
      total_time_s: total_time,
      total_energy_j: total_energy,
      maximum_step_temperature_k: maximum_temperature_step,
      maximum_step_flow_kg_per_s: maximum_flow_step,
      valid,
    }
  }
}

///|
pub fn ramp_plan_is_monotonic_temperature(
  plan : RampPlan,
  increasing : Bool,
) -> Bool {
  if plan.points.length() < 2 {
    true
  } else {
    for index in 0..<(plan.points.length() - 1) {
      let first = plan.points[index].temperature_k
      let second = plan.points[index + 1].temperature_k
      if increasing && second < first {
        return false
      }
      if !increasing && second > first {
        return false
      }
    }
    true
  }
}

///|
pub fn ramp_plan_is_monotonic_flow(plan : RampPlan, increasing : Bool) -> Bool {
  if plan.points.length() < 2 {
    true
  } else {
    for index in 0..<(plan.points.length() - 1) {
      let first = plan.points[index].flow_kg_per_s
      let second = plan.points[index + 1].flow_kg_per_s
      if increasing && second < first {
        return false
      }
      if !increasing && second > first {
        return false
      }
    }
    true
  }
}

///|
pub fn ramp_plan_summary(plan : RampPlan) -> String {
  "steps=" +
  plan.points.length().to_string() +
  ", time_s=" +
  plan.total_time_s.to_string() +
  ", energy_j=" +
  plan.total_energy_j.to_string() +
  ", valid=" +
  plan.valid.to_string()
}

///|
pub fn envelope_rank_by_cost(
  envelope : OperatingEnvelope,
  point : OperatingPoint,
) -> Int {
  if !operating_point_is_feasible(point) {
    0
  } else {
    let mut rank = 1
    for candidate in envelope.points {
      if operating_point_is_feasible(candidate) &&
        candidate.cost_per_h < point.cost_per_h {
        rank += 1
      }
    }
    rank
  }
}

///|
pub fn envelope_rank_by_duty(
  envelope : OperatingEnvelope,
  point : OperatingPoint,
) -> Int {
  if !operating_point_is_feasible(point) {
    0
  } else {
    let mut rank = 1
    for candidate in envelope.points {
      if operating_point_is_feasible(candidate) &&
        candidate.duty_w.abs() < point.duty_w.abs() {
        rank += 1
      }
    }
    rank
  }
}

///|
pub fn envelope_rank_by_margin(
  envelope : OperatingEnvelope,
  point : OperatingPoint,
) -> Int {
  if !operating_point_is_feasible(point) {
    0
  } else {
    let target_margin = operating_point_minimum_margin(
      point,
      envelope.constraints,
    )
    let mut rank = 1
    for candidate in envelope.points {
      if operating_point_is_feasible(candidate) &&
        operating_point_minimum_margin(candidate, envelope.constraints) >
        target_margin {
        rank += 1
      }
    }
    rank
  }
}

///|
pub fn envelope_selection_from_point(
  envelope : OperatingEnvelope,
  point : OperatingPoint,
  explanation : String,
) -> EnvelopeSelection {
  {
    point,
    objective_value: point.score,
    rank: envelope_rank_by_cost(envelope, point),
    explanation,
  }
}

///|
pub fn envelope_selection_is_valid(selection : EnvelopeSelection) -> Bool {
  selection.rank > 0 && operating_point_is_feasible(selection.point)
}

///|
pub fn envelope_selection_text(selection : EnvelopeSelection) -> String {
  "rank=" +
  selection.rank.to_string() +
  ", objective=" +
  selection.objective_value.to_string() +
  ", " +
  selection.explanation
}

///|
pub fn envelope_operating_window(
  envelope : OperatingEnvelope,
) -> (Double, Double, Double, Double) {
  if envelope.points.length() == 0 {
    (0.0, 0.0, 0.0, 0.0)
  } else {
    let mut minimum_temperature = envelope.points[0].temperature_k
    let mut maximum_temperature = envelope.points[0].temperature_k
    let mut minimum_flow = envelope.points[0].flow_kg_per_s
    let mut maximum_flow = envelope.points[0].flow_kg_per_s
    for point in envelope.points {
      minimum_temperature = minimum_temperature.min(point.temperature_k)
      maximum_temperature = maximum_temperature.max(point.temperature_k)
      minimum_flow = minimum_flow.min(point.flow_kg_per_s)
      maximum_flow = maximum_flow.max(point.flow_kg_per_s)
    }
    (minimum_temperature, maximum_temperature, minimum_flow, maximum_flow)
  }
}

///|
pub fn envelope_pressure_window(
  envelope : OperatingEnvelope,
) -> (Double, Double) {
  if envelope.points.length() == 0 {
    (0.0, 0.0)
  } else {
    let mut lower = envelope.points[0].pressure_kpa
    let mut upper = envelope.points[0].pressure_kpa
    for point in envelope.points {
      lower = lower.min(point.pressure_kpa)
      upper = upper.max(point.pressure_kpa)
    }
    (lower, upper)
  }
}

///|
pub fn envelope_duty_window(envelope : OperatingEnvelope) -> (Double, Double) {
  (envelope.summary.minimum_duty_w, envelope.summary.maximum_duty_w)
}

///|
pub fn envelope_cost_window(envelope : OperatingEnvelope) -> (Double, Double) {
  (envelope.summary.minimum_cost_per_h, envelope.summary.maximum_cost_per_h)
}

///|
pub fn envelope_contains_temperature(
  envelope : OperatingEnvelope,
  temperature_k : Double,
) -> Bool {
  let window = envelope_operating_window(envelope)
  temperature_k >= window.0 && temperature_k <= window.1
}

///|
pub fn envelope_contains_flow(
  envelope : OperatingEnvelope,
  flow_kg_per_s : Double,
) -> Bool {
  let window = envelope_operating_window(envelope)
  flow_kg_per_s >= window.2 && flow_kg_per_s <= window.3
}

///|
pub fn envelope_contains_pressure(
  envelope : OperatingEnvelope,
  pressure_kpa : Double,
) -> Bool {
  let window = envelope_pressure_window(envelope)
  pressure_kpa >= window.0 && pressure_kpa <= window.1
}

///|
pub fn envelope_duty_span(envelope : OperatingEnvelope) -> Double {
  envelope.summary.maximum_duty_w - envelope.summary.minimum_duty_w
}

///|
pub fn envelope_cost_span(envelope : OperatingEnvelope) -> Double {
  envelope.summary.maximum_cost_per_h - envelope.summary.minimum_cost_per_h
}

///|
pub fn envelope_temperature_span(envelope : OperatingEnvelope) -> Double {
  let window = envelope_operating_window(envelope)
  window.1 - window.0
}

///|
pub fn envelope_flow_span(envelope : OperatingEnvelope) -> Double {
  let window = envelope_operating_window(envelope)
  window.3 - window.2
}

///|
pub fn envelope_is_single_point(envelope : OperatingEnvelope) -> Bool {
  envelope.points.length() == 1
}

///|
pub fn envelope_has_invalid_input(envelope : OperatingEnvelope) -> Bool {
  envelope_count_by_status(envelope, InvalidInput) > 0
}

///|
pub fn envelope_all_feasible(envelope : OperatingEnvelope) -> Bool {
  envelope.points.length() > 0 &&
  envelope.summary.feasible_count == envelope.points.length()
}

///|
pub fn envelope_all_valid(envelope : OperatingEnvelope) -> Bool {
  envelope_count_by_status(envelope, InvalidInput) == 0
}

///|
pub fn envelope_quality_index(envelope : OperatingEnvelope) -> Double {
  let feasible = envelope_feasible_fraction(envelope)
  let margin = envelope_average_margin(envelope)
  let span = envelope_temperature_span(envelope).max(1.0)
  feasible * (1.0 + margin / span)
}

///|
pub fn envelope_stability_index(envelope : OperatingEnvelope) -> Double {
  if envelope.points.length() == 0 {
    0.0
  } else {
    let mut stable = 0
    for point in envelope.points {
      if operating_point_minimum_margin(point, envelope.constraints) >= 0.0 {
        stable += 1
      }
    }
    stable.to_double() / envelope.points.length().to_double()
  }
}

///|
pub fn envelope_cost_per_feasible_point(envelope : OperatingEnvelope) -> Double {
  if envelope.summary.feasible_count == 0 {
    0.0
  } else {
    envelope_total_cost(envelope) / envelope.summary.feasible_count.to_double()
  }
}

///|
pub fn envelope_emissions_per_feasible_point(
  envelope : OperatingEnvelope,
) -> Double {
  if envelope.summary.feasible_count == 0 {
    0.0
  } else {
    envelope_total_emissions(envelope) /
    envelope.summary.feasible_count.to_double()
  }
}

///|
pub fn envelope_select_by_target(
  envelope : OperatingEnvelope,
  target_temperature_k : Double,
  target_flow_kg_per_s : Double,
) -> OperatingPoint? {
  let target = operating_point(
    target_temperature_k,
    target_flow_kg_per_s,
    envelope.constraints.minimum_pressure_kpa,
    0.0,
    0.0,
    0.0,
    0.0,
    envelope.constraints,
  )
  nearest_feasible_operating_point(envelope, target)
}

///|
pub fn envelope_interpolate_temperature(
  first : OperatingPoint,
  second : OperatingPoint,
  temperature_k : Double,
  constraints : OperatingConstraints,
) -> OperatingPoint {
  let denominator = second.temperature_k - first.temperature_k
  let fraction = if denominator.abs() < 1.0e-12 {
    0.0
  } else {
    (temperature_k - first.temperature_k) / denominator
  }
  operating_point(
    temperature_k,
    first.flow_kg_per_s +
    fraction * (second.flow_kg_per_s - first.flow_kg_per_s),
    first.pressure_kpa + fraction * (second.pressure_kpa - first.pressure_kpa),
    first.duty_w + fraction * (second.duty_w - first.duty_w),
    first.cost_per_h + fraction * (second.cost_per_h - first.cost_per_h),
    first.emissions_kg_per_h +
    fraction * (second.emissions_kg_per_h - first.emissions_kg_per_h),
    first.score + fraction * (second.score - first.score),
    constraints,
  )
}

///|
pub fn envelope_interpolate_flow(
  first : OperatingPoint,
  second : OperatingPoint,
  flow_kg_per_s : Double,
  constraints : OperatingConstraints,
) -> OperatingPoint {
  let denominator = second.flow_kg_per_s - first.flow_kg_per_s
  let fraction = if denominator.abs() < 1.0e-12 {
    0.0
  } else {
    (flow_kg_per_s - first.flow_kg_per_s) / denominator
  }
  envelope_interpolate_temperature(
    first,
    second,
    first.temperature_k +
    fraction * (second.temperature_k - first.temperature_k),
    constraints,
  )
}

///|
pub fn envelope_weighted_average(
  points : Array[OperatingPoint],
  weights : Array[Double],
  constraints : OperatingConstraints,
) -> OperatingPoint {
  if points.length() == 0 {
    default_operating_point(constraints)
  } else {
    let length = points.length().min(weights.length())
    if length == 0 {
      default_operating_point(constraints)
    } else {
      let mut total_weight = 0.0
      let mut temperature = 0.0
      let mut flow = 0.0
      let mut pressure = 0.0
      let mut duty = 0.0
      let mut cost = 0.0
      let mut emissions = 0.0
      for index in 0..<length {
        let weight = weights[index].max(0.0)
        total_weight += weight
        temperature += weight * points[index].temperature_k
        flow += weight * points[index].flow_kg_per_s
        pressure += weight * points[index].pressure_kpa
        duty += weight * points[index].duty_w
        cost += weight * points[index].cost_per_h
        emissions += weight * points[index].emissions_kg_per_h
      }
      if total_weight <= 0.0 {
        default_operating_point(constraints)
      } else {
        operating_point(
          temperature / total_weight,
          flow / total_weight,
          pressure / total_weight,
          duty / total_weight,
          cost / total_weight,
          emissions / total_weight,
          0.0,
          constraints,
        )
      }
    }
  }
}

///|
pub fn envelope_center(envelope : OperatingEnvelope) -> OperatingPoint {
  let weights : Array[Double] = []
  for _ in envelope.points {
    weights.push(1.0)
  }
  envelope_weighted_average(envelope.points, weights, envelope.constraints)
}

///|
pub fn envelope_distance_from_center(
  envelope : OperatingEnvelope,
  point : OperatingPoint,
) -> Double {
  operating_point_distance(envelope_center(envelope), point)
}

///|
pub fn envelope_center_is_feasible(envelope : OperatingEnvelope) -> Bool {
  operating_point_is_feasible(envelope_center(envelope))
}

///|
pub fn envelope_trim_invalid(envelope : OperatingEnvelope) -> OperatingEnvelope {
  envelope_filter(envelope, fn(point) { !operating_point_is_invalid(point) })
}

///|
pub fn envelope_trim_infeasible(
  envelope : OperatingEnvelope,
) -> OperatingEnvelope {
  envelope_filter_feasible(envelope)
}

///|
pub fn envelope_retain_best_cost(
  envelope : OperatingEnvelope,
  limit : Int,
) -> Array[OperatingPoint] {
  let result : Array[OperatingPoint] = []
  let remaining = envelope_feasible_points(envelope)
  let count = limit.max(0).min(remaining.length())
  for index in 0..<count {
    let mut best_index = index
    let mut best_cost = remaining[index].cost_per_h
    for candidate_index in index..<remaining.length() {
      if remaining[candidate_index].cost_per_h < best_cost {
        best_index = candidate_index
        best_cost = remaining[candidate_index].cost_per_h
      }
    }
    let chosen = remaining[index]
    remaining[index] = remaining[best_index]
    remaining[best_index] = chosen
    result.push(remaining[index])
  }
  result
}

///|
pub fn envelope_retain_best_duty(
  envelope : OperatingEnvelope,
  limit : Int,
) -> Array[OperatingPoint] {
  let result : Array[OperatingPoint] = []
  let remaining = envelope_feasible_points(envelope)
  let count = limit.max(0).min(remaining.length())
  for index in 0..<count {
    let mut best_index = index
    let mut best_duty = remaining[index].duty_w.abs()
    for candidate_index in index..<remaining.length() {
      if remaining[candidate_index].duty_w.abs() < best_duty {
        best_index = candidate_index
        best_duty = remaining[candidate_index].duty_w.abs()
      }
    }
    let chosen = remaining[index]
    remaining[index] = remaining[best_index]
    remaining[best_index] = chosen
    result.push(remaining[index])
  }
  result
}

///|
pub fn envelope_retain_best_margin(
  envelope : OperatingEnvelope,
  limit : Int,
) -> Array[OperatingPoint] {
  let result : Array[OperatingPoint] = []
  let remaining = envelope_feasible_points(envelope)
  let count = limit.max(0).min(remaining.length())
  for index in 0..<count {
    let mut best_index = index
    let mut best_margin = operating_point_minimum_margin(
      remaining[index],
      envelope.constraints,
    )
    for candidate_index in index..<remaining.length() {
      let candidate_margin = operating_point_minimum_margin(
        remaining[candidate_index],
        envelope.constraints,
      )
      if candidate_margin > best_margin {
        best_index = candidate_index
        best_margin = candidate_margin
      }
    }
    let chosen = remaining[index]
    remaining[index] = remaining[best_index]
    remaining[best_index] = chosen
    result.push(remaining[index])
  }
  result
}

///|
pub fn envelope_merge_points(
  points : Array[OperatingPoint],
  constraints : OperatingConstraints,
) -> OperatingEnvelope {
  let unique : Array[OperatingPoint] = []
  for point in points {
    let mut duplicate = false
    for existing in unique {
      if operating_point_distance(point, existing) < 1.0e-12 {
        duplicate = true
      }
    }
    if !duplicate {
      unique.push(point)
    }
  }
  make_operating_envelope(unique, constraints)
}

///|
pub fn envelope_remove_duplicates(
  envelope : OperatingEnvelope,
) -> OperatingEnvelope {
  envelope_merge_points(envelope.points, envelope.constraints)
}

///|
pub fn envelope_is_duplicate_free(envelope : OperatingEnvelope) -> Bool {
  envelope.points.length() ==
  envelope_remove_duplicates(envelope).points.length()
}

///|
pub fn operating_point_values_are_finite(point : OperatingPoint) -> Bool {
  point.temperature_k == point.temperature_k &&
  point.flow_kg_per_s == point.flow_kg_per_s &&
  point.pressure_kpa == point.pressure_kpa &&
  point.duty_w == point.duty_w &&
  point.cost_per_h == point.cost_per_h &&
  point.emissions_kg_per_h == point.emissions_kg_per_h &&
  point.score == point.score
}

///|
pub fn envelope_values_are_finite(envelope : OperatingEnvelope) -> Bool {
  for point in envelope.points {
    if !operating_point_values_are_finite(point) {
      return false
    }
  }
  true
}

///|
pub fn envelope_validate(envelope : OperatingEnvelope) -> Bool {
  operating_constraints_are_valid(envelope.constraints) &&
  envelope_status_is_consistent(envelope) &&
  envelope_values_are_finite(envelope) &&
  envelope.summary.point_count == envelope.points.length()
}

///|
pub fn envelope_validation_message(envelope : OperatingEnvelope) -> String {
  if !operating_constraints_are_valid(envelope.constraints) {
    "invalid operating constraints"
  } else if !envelope_status_is_consistent(envelope) {
    "point status does not match constraints"
  } else if !envelope_values_are_finite(envelope) {
    "non-finite point value"
  } else if envelope.summary.point_count != envelope.points.length() {
    "summary count does not match points"
  } else {
    "valid operating envelope"
  }
}

///|
pub fn envelope_project_to_constraints(
  envelope : OperatingEnvelope,
) -> OperatingEnvelope {
  let points : Array[OperatingPoint] = []
  for point in envelope.points {
    let projected = operating_point_with_process_state(
      point,
      clamp_operating_temperature(point.temperature_k, envelope.constraints),
      clamp_operating_flow(point.flow_kg_per_s, envelope.constraints),
      clamp_operating_pressure(point.pressure_kpa, envelope.constraints),
      envelope.constraints,
    )
    points.push(projected)
  }
  make_operating_envelope(points, envelope.constraints)
}

///|
pub fn envelope_project_and_recalculate(
  envelope : OperatingEnvelope,
) -> OperatingEnvelope {
  envelope_recalculate_scores(envelope_project_to_constraints(envelope))
}

///|
pub fn envelope_feasibility_report(envelope : OperatingEnvelope) -> String {
  envelope_summary_text(envelope.summary) +
  ", quality=" +
  envelope_quality_index(envelope).to_string() +
  ", stability=" +
  envelope_stability_index(envelope).to_string()
}

///|
pub fn envelope_operating_cost_report(envelope : OperatingEnvelope) -> String {
  "total_cost_per_h=" +
  envelope_total_cost(envelope).to_string() +
  ", cost_per_feasible_point=" +
  envelope_cost_per_feasible_point(envelope).to_string() +
  ", total_emissions_kg_per_h=" +
  envelope_total_emissions(envelope).to_string()
}

///|
pub fn envelope_energy_report(envelope : OperatingEnvelope) -> String {
  "total_energy_kwh=" +
  envelope_total_energy_kwh(envelope).to_string() +
  ", duty_span_w=" +
  envelope_duty_span(envelope).to_string() +
  ", average_duty_w=" +
  ((envelope.summary.minimum_duty_w + envelope.summary.maximum_duty_w) / 2.0).to_string()
}

///|
pub fn envelope_report(envelope : OperatingEnvelope) -> String {
  envelope_feasibility_report(envelope) +
  "\n" +
  envelope_operating_cost_report(envelope) +
  "\n" +
  envelope_energy_report(envelope)
}

///|
pub fn operating_point_to_csv(point : OperatingPoint) -> String {
  envelope_csv_row(point)
}

///|
pub fn envelope_to_rows(envelope : OperatingEnvelope) -> Array[String] {
  let rows : Array[String] = []
  for point in envelope.points {
    rows.push(envelope_csv_row(point))
  }
  rows
}

///|
pub fn envelope_from_points(
  points : Array[OperatingPoint],
  constraints : OperatingConstraints,
) -> OperatingEnvelope {
  make_operating_envelope(points, constraints)
}

///|
pub fn envelope_recompute_status(
  envelope : OperatingEnvelope,
) -> OperatingEnvelope {
  let points : Array[OperatingPoint] = []
  for point in envelope.points {
    points.push(
      operating_point(
        point.temperature_k,
        point.flow_kg_per_s,
        point.pressure_kpa,
        point.duty_w,
        point.cost_per_h,
        point.emissions_kg_per_h,
        point.score,
        envelope.constraints,
      ),
    )
  }
  make_operating_envelope(points, envelope.constraints)
}
