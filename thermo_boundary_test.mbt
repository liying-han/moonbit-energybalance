///|
fn close_value(actual : Double, expected : Double, tolerance : Double) -> Bool {
  (actual - expected).abs() <= tolerance
}

///|
test "temperature and pressure conversions preserve engineering units" {
  assert_true(close_value(celsius_to_kelvin(25.0), 298.15, 1.0e-9))
  assert_true(close_value(kelvin_to_celsius(298.15), 25.0, 1.0e-9))
  assert_true(close_value(bar_to_kpa(1.0), 100.0, 1.0e-9))
  assert_true(close_value(kpa_to_bar(100.0), 1.0, 1.0e-9))
  assert_true(valid_absolute_temperature(0.1))
  assert_true(!valid_absolute_temperature(0.0))
}

///|
test "heat capacity integral is reversible and average is bounded" {
  let water = water_liquid()
  let forward = water.sensible_enthalpy_change(300.0, 350.0)
  let backward = water.sensible_enthalpy_change(350.0, 300.0)
  assert_true(close_value(forward, 3765.0, 1.0e-9))
  assert_true(close_value(forward + backward, 0.0, 1.0e-9))
  assert_true(
    close_value(average_heat_capacity(water, 300.0, 350.0), 75.3, 1.0e-9),
  )
}

///|
test "latent heat uses half open crossing boundaries" {
  let water = water_liquid()
  let up_to_boiling = water.phase_change_enthalpy_change(300.0, 373.15)
  let above_boiling = water.phase_change_enthalpy_change(300.0, 373.16)
  assert_true(close_value(up_to_boiling, 40650.0, 1.0e-9))
  assert_true(close_value(above_boiling, 40650.0, 1.0e-9))
  assert_true(
    close_value(
      water.phase_change_enthalpy_change(373.16, 300.0),
      -40650.0,
      1.0e-9,
    ),
  )
}

///|
test "psychrometric humidity conversions round trip" {
  let ratio = humidity_ratio_from_relative_humidity(25.0, 0.60, 101.325)
  let relative = relative_humidity_from_ratio(25.0, ratio, 101.325)
  assert_true(ratio > 0.0)
  assert_true(close_value(relative, 0.60, 1.0e-9))
  assert_true(dew_point_c(25.0, ratio, 101.325) < 25.0)
}

///|
test "steam property estimator classifies saturation and superheat" {
  let saturated = steam_state(100.0, 101.325)
  let superheated = steam_state(150.0, 101.325)
  assert_true(saturated.region == TwoPhase)
  assert_true(saturated.quality >= 0.0 && saturated.quality <= 1.0)
  assert_true(superheated.region == SuperheatedVapor)
  assert_true(superheated.enthalpy_kj_per_kg > saturated.enthalpy_kj_per_kg)
}
