///|
fn design_close(actual : Double, expected : Double, tolerance : Double) -> Bool {
  (actual - expected).abs() <= tolerance
}

///|
test "utility design selects services and calculates flow" {
  let steam = steam_utility(10.0, 180.0, 120.0)
  let cooling = cooling_water_utility(-8000.0, 25.0, 35.0)
  assert_true(steam.duty_w > 0.0)
  assert_true(steam.required_mass_flow_kg_per_s > 0.0)
  assert_true(cooling.required_mass_flow_kg_per_s > 0.0)
  assert_true(select_utility(12000.0, [steam, cooling]).name == steam.name)
}

///|
test "pump compressor and pipe estimates remain finite at boundaries" {
  assert_true(pump_power_w(1000.0, 100000.0, 0.7) > 0.0)
  assert_true(compressor_power_w(2.0, 101.325, 500.0, 0.75, 1.4) > 0.0)
  assert_true(pipe_velocity_m_per_s(0.0, 0.1) == 0.0)
  assert_true(pipe_velocity_m_per_s(1.0, 0.0) == 0.0)
  assert_true(pressure_drop_pa(1000.0, 0.05, 10.0, 0.02, 0.001) > 0.0)
}

///|
test "pinch analysis matches hot and cold targets" {
  let hot = [
    ThermalStreamTarget::ThermalStreamTarget(
      id="hot",
      supply_c=180.0,
      target_c=80.0,
      heat_capacity_flow_kw_per_k=2.0,
    ),
  ]
  let cold = [
    ThermalStreamTarget::ThermalStreamTarget(
      id="cold",
      supply_c=20.0,
      target_c=140.0,
      heat_capacity_flow_kw_per_k=1.5,
    ),
  ]
  let targets = pinch_targets(hot, cold, 10.0)
  assert_true(targets.hot_target_c > targets.cold_target_c)
  assert_true(targets.minimum_hot_utility_kw >= 0.0)
  assert_true(targets.minimum_cold_utility_kw >= 0.0)
  assert_true(design_close(targets.total_hot_duty_kw, 200.0, 1.0e-9))
}

///|
test "validation report identifies duplicate ids and bad composition" {
  let water = water_liquid()
  let streams = [
    Stream::pure(id="same", substance=water, molar_flow=-1.0, temperature=300.0),
    Stream::mixture(id="same", components=[], temperature=0.0),
  ]
  let report = validate_process(streams)
  assert_true(report.issue_count >= 3)
  assert_true(!report.valid)
  assert_true(report.has_code(DuplicateStreamId))
  assert_true(report.has_code(NegativeFlowValue))
}
