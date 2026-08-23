///|
fn analysis_close(
  actual : Double,
  expected : Double,
  tolerance : Double,
) -> Bool {
  (actual - expected).abs() <= tolerance
}

///|
test "heater duty sensitivity matches heat capacity flow" {
  let feed = process_water_stream(id="feed", molar_flow=2.0, temperature=300.0)
  let point = heater_duty_sensitivity(feed, 340.0, 0.01)
  assert_true(analysis_close(point.derivative, 150.6, 1.0e-6))
  assert_true(point.relative_derivative > 0.0)
  let table = heater_sensitivity_table(feed, [320.0, 340.0, 360.0], 0.1)
  assert_true(table.length() == 3)
  assert_true(table[0].duty < table[1].duty && table[1].duty < table[2].duty)
}

///|
test "finite difference handles zero step and uncertainty envelope" {
  let feed = process_water_stream(id="feed", molar_flow=1.0, temperature=300.0)
  let zero = heater_duty_sensitivity(feed, 330.0, 0.0)
  assert_true(zero.derivative == 0.0)
  let envelope = duty_uncertainty_envelope(feed, 330.0, 0.05, 0.10)
  assert_true(envelope.low < envelope.nominal)
  assert_true(envelope.high > envelope.nominal)
  assert_true(envelope.relative_half_width > 0.0)
}

///|
test "scenario sweep keeps deterministic ordering and extrema" {
  let feed = process_water_stream(id="feed", molar_flow=1.0, temperature=300.0)
  let sweep = sweep_heater_targets(feed, 310.0, 350.0, 10.0)
  assert_true(sweep.points.length() == 5)
  assert_true(analysis_close(sweep.minimum_duty, sweep.points[0].duty, 1.0e-12))
  assert_true(analysis_close(sweep.maximum_duty, sweep.points[4].duty, 1.0e-12))
  assert_true(sweep.maximum_duty > sweep.minimum_duty)
}
