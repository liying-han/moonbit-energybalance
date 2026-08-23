///|
test "air conditioning report calculates coil duty and mixing" {
  let inlet = psychrometric_point(30.0, 0.70, 101.325)
  let outlet = psychrometric_point(12.0, 0.90, 101.325)
  let report = air_conditioning_report(inlet, outlet, 2.0)
  assert_true(report.cooling_duty_w < 0.0)
  assert_true(report.condensate_kg_per_s > 0.0)
  let mixed = mix_air_points(inlet, 1.0, outlet, 1.0)
  assert_true(mixed.dry_bulb_c > outlet.dry_bulb_c)
}

///|
test "rankine cycle reports positive turbine work and efficiency" {
  let cycle = rankine_cycle(1000.0, 8.0, 0.10, 0.85, 0.80)
  assert_true(cycle.turbine_work_w > 0.0)
  assert_true(cycle.net_work_w > 0.0)
  assert_true(cycle.thermal_efficiency > 0.0 && cycle.thermal_efficiency < 1.0)
  assert_true(cycle.condenser_duty_w > 0.0)
}

///|
test "kinetics handles zero concentration and capped conversion" {
  let model = KineticModel::FirstOrder(rate_constant=0.4)
  assert_true(reaction_rate(model, 0.0, 350.0) == 0.0)
  assert_true(cstr_conversion(model, 100.0, 10.0) > 0.0)
  assert_true(cstr_conversion(model, 100.0, 1.0e9) <= 1.0)
  assert_true(arrhenius_rate_constant(100000.0, 500.0, 500.0) > 0.0)
}

///|
test "network schedule exposes critical path" {
  let units = [
    ScheduledUnit::ScheduledUnit(id="feed", duration_h=1.0, predecessors=[]),
    ScheduledUnit::ScheduledUnit(id="heater", duration_h=2.0, predecessors=[
      "feed",
    ]),
    ScheduledUnit::ScheduledUnit(id="cooler", duration_h=3.0, predecessors=[
      "heater",
    ]),
  ]
  let schedule = schedule_network(units)
  assert_true(schedule.makespan_h == 6.0)
  assert_true(schedule.critical_unit_id == "cooler")
}

///|
test "quality metrics distinguish exact and poor balances" {
  let exact = energy_balance_quality(100.0, 100.0, 1.0e-6)
  let poor = energy_balance_quality(100.0, 120.0, 1.0e-6)
  assert_true(exact.accepted)
  assert_true(!poor.accepted)
  assert_true(quality_grade(exact) == Excellent)
  assert_true(quality_grade(poor) == Rejected)
}
