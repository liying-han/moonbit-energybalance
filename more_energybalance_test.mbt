///|
test "scenario runners produce summaries" {
  let feed = process_water_stream(
    id="process-water",
    molar_flow=4.0,
    temperature=298.15,
  )
  let heating = HeatingCase::HeatingCase(
    id="preheater",
    feed~,
    target_temperature=330.0,
  )
  let cooling = CoolingCase::CoolingCase(
    id="trim-cooler",
    feed=feed.with_temperature(360.0),
    target_temperature=320.0,
  )
  let h = run_heating_case(heating)
  let c = run_cooling_case(cooling)
  assert_true(h.duty > 0.0)
  assert_true(c.duty < 0.0)
  assert_true(total_scenario_duty([h, c]) < 0.0)
}

///|
test "natural gas pseudo stream has three components" {
  let gas = natural_gas_stream(
    id="fuel-gas",
    molar_flow=10.0,
    temperature=310.0,
  )
  assert_eq(gas.components.length(), 3)
  assert_true(gas.component_fraction("methane-gas") > 0.89)
}

///|
test "validation catches bad stream and fraction" {
  let bad = Stream::mixture(id="bad", components=[], temperature=0.0)
  assert_true(has_issues(validate_stream(bad)))
  assert_true(has_issues(validate_fraction(1.2)))
}

///|
test "report summaries are stable enough for demos" {
  let feed = air_stream(id="air-in", molar_flow=3.0, temperature=290.0)
  let out = feed.with_temperature(310.0)
  let report = duty_report(unit_id="air-heater", feed, out)
  assert_true(report.summary().contains("air-heater"))
  assert_true(service_hint(report.duty) == "heating")
}
