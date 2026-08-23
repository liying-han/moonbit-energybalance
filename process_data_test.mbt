///|
test "process snapshots and scenario matrices are exportable" {
  let feed = process_water_stream(id="feed", molar_flow=2.0, temperature=300.0)
  let hot = feed.with_temperature(340.0)
  let snapshot = snapshot_stream(feed)
  let delta = snapshot_delta(snapshot, snapshot_stream(hot))
  assert_true(delta.temperature == 40.0)
  assert_true(snapshots_csv([snapshot]).contains("component_count"))
  let matrix = evaluate_scenario_matrix(300.0, [1.0, 2.0], [320.0, 340.0])
  assert_true(scenario_matrix_point_count(matrix) == 4)
  assert_true(matrix.maximum_duty > matrix.minimum_duty)
  assert_true(scenario_matrix_is_monotonic_in_temperature(matrix))
}
