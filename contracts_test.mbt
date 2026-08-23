///|
test "public contracts reject invalid process boundaries" {
  let water = water_liquid()
  let stream = process_water_stream(
    id="feed",
    molar_flow=1.0,
    temperature=300.0,
  )
  assert_true(stream_is_physically_valid(stream))
  assert_true(substance_is_physically_valid(water, 300.0))
  assert_true(!fraction_array_is_valid([0.2, 0.2], 1.0e-9))
  assert_true(
    heat_exchanger_temperatures_valid(400.0, 350.0, 300.0, 330.0, 10.0),
  )
  assert_true(
    duty_direction_is_consistent(stream, stream.with_temperature(320.0), true),
  )
  assert_true(conservation_is_closed(10.0, 10.0 + 1.0e-10, 1.0e-6))
}
