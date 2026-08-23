///|
test "fluid properties and heat transfer correlations are bounded" {
  let water = water_properties(80.0)
  assert_true(water.density_kg_per_m3 > 900.0)
  assert_true(water.viscosity_pa_s > 0.0)
  assert_true(prandtl_number(water) > 0.0)
  assert_true(nusselt_dittus_boelter(10000.0, 0.7, 0.4) > 0.0)
  assert_true(pipe_heat_transfer_coefficient(0.1, 2.0, water) > 0.0)
}

///|
test "equipment sizing returns conservative positive areas and volumes" {
  let heater = size_heater(20000.0, 30.0, 500.0, 0.85)
  assert_true(heater.area_m2 > 0.0)
  assert_true(heater.design_duty_w > heater.process_duty_w)
  let tank = size_tank(0.02, 120.0, 0.25)
  assert_true(tank.volume_m3 > 0.0)
  assert_true(tank.working_volume_m3 < tank.volume_m3)
  assert_true(agitator_power_w(2.0, 0.5, 1.0, 0.7) > 0.0)
}

///|
test "case studies produce reproducible report scores" {
  let water = run_water_preheat_case(5.0, 298.15, 348.15)
  let gas = run_natural_gas_case(10.0, 300.0, 900.0)
  assert_true(water.duty_w > 0.0)
  assert_true(gas.duty_w > 0.0)
  assert_true(water.quality_score >= 0.0 && water.quality_score <= 100.0)
  assert_true(case_study_summary([water, gas]).contains("water-preheat"))
}
