///|
test "operating envelope evaluates constraints and summaries" {
  let constraints = OperatingConstraints::new(
    minimum_temperature_k=300.0,
    maximum_temperature_k=400.0,
    minimum_flow_kg_per_s=0.0,
    maximum_flow_kg_per_s=10.0,
    minimum_pressure_kpa=100.0,
    maximum_pressure_kpa=500.0,
    minimum_duty_w=-10000.0,
    maximum_duty_w=1.0e6,
    maximum_cost_per_h=100.0,
  )
  let feasible = operating_point(
    350.0, 4.0, 250.0, 1000.0, 20.0, 3.0, 0.0, constraints,
  )
  let infeasible = operating_point(
    450.0, 4.0, 250.0, 1000.0, 20.0, 3.0, 0.0, constraints,
  )
  let envelope = make_operating_envelope([feasible, infeasible], constraints)
  inspect(envelope_point_count(envelope), content="2")
  inspect(envelope_feasible_count(envelope), content="1")
  inspect(envelope_is_empty(envelope), content="false")
  inspect(envelope_status_is_consistent(envelope), content="true")
  inspect(envelope_validate(envelope), content="true")
}

///|
test "operating envelope selects weighted and pareto points" {
  let constraints = standard_operating_constraints()
  let first = operating_point(
    320.0, 2.0, 100.0, 500.0, 10.0, 2.0, 0.0, constraints,
  )
  let second = operating_point(
    340.0, 3.0, 120.0, 800.0, 20.0, 4.0, 0.0, constraints,
  )
  let envelope = make_operating_envelope([first, second], constraints)
  let cheapest = envelope_best_by_cost(envelope)
  inspect(cheapest is Some(_), content="true")
  inspect(
    envelope_pareto_frontier(envelope, true, true, true).length(),
    content="1",
  )
  let weighted = envelope_best_weighted(
    envelope, 2.0, 1.0, 1.0, 20.0, 1000.0, 4.0,
  )
  inspect(weighted is Some(_), content="true")
  let selected = select_lowest_cost(envelope)
  inspect(selected is Some(_), content="true")
}

///|
test "operating envelope scanning and exports are deterministic" {
  let constraints = OperatingConstraints::new(
    minimum_temperature_k=300.0,
    maximum_temperature_k=400.0,
    minimum_flow_kg_per_s=0.0,
    maximum_flow_kg_per_s=10.0,
    minimum_pressure_kpa=100.0,
    maximum_pressure_kpa=500.0,
    minimum_duty_w=-10000.0,
    maximum_duty_w=1.0e6,
    maximum_cost_per_h=100.0,
  )
  let envelope = scan_operating_envelope(
    [300.0, 350.0],
    [1.0, 2.0],
    [100.0],
    fn(temperature, flow, pressure) {
      combined_duty_model(temperature, flow, pressure, 360.0, 4200.0, 0.8)
    },
    fn(_, flow, _, duty) { linear_cost_model(flow, duty, 0.1, 0.2) },
    fn(_, _, _, duty) { linear_emissions_model(duty, 0.5) },
    constraints,
  )
  inspect(envelope_point_count(envelope), content="4")
  inspect(envelope_feasible_count(envelope), content="4")
  inspect(envelope_csv_line_count(envelope_csv(envelope)), content="5")
  inspect(envelope_quality_index(envelope) > 0.0, content="true")
  inspect(envelope_values_are_finite(envelope), content="true")
}

///|
test "operating envelope ramp and projection handle boundaries" {
  let constraints = standard_operating_constraints()
  let outside = operating_point(
    -10.0, -2.0, -1.0, 5.0, 2.0, 1.0, 0.0, constraints,
  )
  let projected = envelope_project_to_constraints(
    make_operating_envelope([outside], constraints),
  )
  inspect(envelope_feasible_count(projected), content="1")
  let plan = ramp_plan(projected.points, 2.0, 1.0)
  inspect(plan.valid, content="true")
  inspect(ramp_plan_is_monotonic_temperature(plan, true), content="true")
  inspect(envelope_trim_invalid(projected).points.length(), content="1")
  inspect(envelope_take_feasible(projected, 0).length(), content="0")
}

///|
test "operating envelope rejects invalid input and empty selections" {
  let invalid = OperatingConstraints::new(
    minimum_temperature_k=400.0,
    maximum_temperature_k=300.0,
    minimum_flow_kg_per_s=2.0,
    maximum_flow_kg_per_s=1.0,
    minimum_pressure_kpa=0.0,
    maximum_pressure_kpa=1.0,
    minimum_duty_w=10.0,
    maximum_duty_w=-10.0,
    maximum_cost_per_h=-1.0,
  )
  inspect(operating_constraints_are_valid(invalid), content="false")
  let empty = empty_envelope(invalid)
  inspect(envelope_point_count(empty), content="0")
  inspect(envelope_best_by_cost(empty) is None, content="true")
  inspect(envelope_best_by_duty(empty) is None, content="true")
  inspect(envelope_best_by_emissions(empty) is None, content="true")
  inspect(select_lowest_cost(empty) is None, content="true")
  inspect(envelope_total_energy_kwh(empty), content="0")
}

///|
test "operating envelope filters and duplicate handling preserve meaning" {
  let constraints = standard_operating_constraints()
  let first = operating_point(
    310.0, 1.0, 100.0, 100.0, 5.0, 1.0, 0.0, constraints,
  )
  let second = operating_point(
    360.0, 2.0, 200.0, -200.0, 10.0, 2.0, 0.0, constraints,
  )
  let envelope = make_operating_envelope([first, first, second], constraints)
  let unique = envelope_remove_duplicates(envelope)
  inspect(unique.points.length(), content="2")
  inspect(envelope_is_duplicate_free(unique), content="true")
  inspect(envelope_filter_positive_duty(unique).points.length(), content="1")
  inspect(envelope_filter_negative_duty(unique).points.length(), content="1")
  inspect(
    envelope_points_in_temperature_band(unique, 300.0, 320.0).length(),
    content="1",
  )
  inspect(envelope_points_in_flow_band(unique, 1.0, 1.5).length(), content="1")
  inspect(envelope_append(unique, unique).points.length(), content="4")
}

///|
test "operating envelope interpolation and ranking are deterministic" {
  let constraints = standard_operating_constraints()
  let first = operating_point(
    300.0, 1.0, 100.0, 100.0, 20.0, 1.0, 0.0, constraints,
  )
  let second = operating_point(
    400.0, 3.0, 300.0, 500.0, 40.0, 3.0, 0.0, constraints,
  )
  let envelope = make_operating_envelope([first, second], constraints)
  let middle = envelope_interpolate_temperature(
    first, second, 350.0, constraints,
  )
  inspect(middle.flow_kg_per_s, content="2")
  inspect(middle.duty_w, content="300")
  inspect(envelope_rank_by_cost(envelope, first), content="1")
  inspect(envelope_rank_by_duty(envelope, second), content="2")
  let average = envelope_weighted_average(
    [first, second],
    [1.0, 1.0],
    constraints,
  )
  inspect(average.temperature_k, content="350")
  inspect(envelope_center(envelope).flow_kg_per_s, content="2")
}

///|
test "operating envelope reports and ramp plans cover reverse operation" {
  let constraints = standard_operating_constraints()
  let hot = operating_point(
    400.0, 5.0, 300.0, 2000.0, 30.0, 4.0, 0.0, constraints,
  )
  let cold = operating_point(
    300.0, 1.0, 100.0, -500.0, 8.0, 1.0, 0.0, constraints,
  )
  let envelope = make_operating_envelope([hot, cold], constraints)
  let plan = ramp_plan([hot, cold], 10.0, 1.0)
  inspect(ramp_plan_is_monotonic_temperature(plan, false), content="true")
  inspect(ramp_plan_is_monotonic_flow(plan, false), content="true")
  inspect(plan.total_time_s, content="10")
  inspect(envelope_pressure_window(envelope).0, content="100")
  inspect(envelope_pressure_window(envelope).1, content="300")
  inspect(envelope_report(envelope).contains("points=2"), content="true")
  inspect(
    envelope_operating_cost_report(envelope).contains("total_cost"),
    content="true",
  )
}
