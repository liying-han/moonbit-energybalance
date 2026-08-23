///|
test "dynamic thermal response approaches the target without overshoot" {
  let profile = simulate_lumped_heating(300.0, 340.0, 1000.0, 500.0, 5.0, 20)
  assert_true(profile.length() == 20)
  assert_true(profile[1].temperature_k > 300.0)
  assert_true(profile[19].temperature_k <= 340.0)
  assert_true(dynamic_energy(profile[0], profile[19]) > 0.0)
}

///|
test "dynamic integration handles zero duration and duty profiles" {
  assert_true(stable_time_step(0.0, 1000.0, 500.0) == 0.0)
  let points = integrate_duty_profile([0.0, 10.0, 20.0], [100.0, 200.0, 100.0])
  assert_true(points == 3000.0)
}
