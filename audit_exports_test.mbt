///|
test "process audit captures balance and validation findings" {
  let feed = process_water_stream(id="feed", molar_flow=2.0, temperature=300.0)
  let product = feed.with_temperature(330.0)
  let q = required_heat([feed], [product])
  let report = audit_process([feed], [product], q)
  assert_true(report.accepted)
  assert_true(report.finding_count == 0)
  let broken = audit_process([feed], [], 0.0)
  assert_true(!broken.accepted)
  assert_true(broken.finding_count > 0)
}

///|
test "stream and result exports contain stable headers" {
  let stream = process_water_stream(
    id="feed",
    molar_flow=2.0,
    temperature=300.0,
  )
  assert_true(stream_csv_header().contains("stream_id"))
  assert_true(stream_csv_row(stream).contains("feed"))
  let result = run_heating_case(
    HeatingCase::HeatingCase(id="heater", feed=stream, target_temperature=330.0),
  )
  assert_true(scenario_result_csv_row(result).contains("heater"))
}

///|
test "benchmark workload is deterministic and scales iterations" {
  let small = run_benchmark_workload(10)
  let large = run_benchmark_workload(100)
  assert_true(small.iterations == 10)
  assert_true(large.iterations == 100)
  assert_true(small.checksum != 0.0)
  assert_true(large.checksum != small.checksum)
  assert_true(benchmark_summary(small).contains("iterations=10"))
}
