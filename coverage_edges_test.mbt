///|
test "unit and property helpers cover zero and reverse branches" {
  assert_true(pa_to_kpa(1000.0) == 1.0)
  assert_true(mass_flow_to_molar_flow(1.0, 0.0) == 0.0)
  assert_true(kelvin_range(273.15, 373.15))
  assert_true(!kelvin_range(0.0, 373.15))
  assert_true(celsius_delta_to_kelvin_delta(-5.0) == -5.0)
  assert_true(kelvin_delta_to_celsius_delta(5.0) == 5.0)
  assert_true(liters_per_minute_to_cubic_meters_per_second(60000.0) == 1.0)
  assert_true(cubic_meters_per_second_to_liters_per_minute(1.0) == 60000.0)
  assert_true(kilowatt_to_watt(2.0) == 2000.0)
  assert_true(watt_to_kilowatt(2000.0) == 2.0)
  assert_true(ice_solid().enthalpy_at(260.0) < 0.0)
  assert_true(
    generic_substance(id="x", name="X", cp=10.0).enthalpy_at(300.0) > 0.0,
  )
  assert_true(
    water_liquid().with_formation_enthalpy(-100.0).enthalpy_at(298.15) == -100.0,
  )
}

///|
test "thermo integrals cover empty and zero-width profiles" {
  let water = water_liquid()
  assert_true(average_heat_capacity(water, 300.0, 300.0) > 0.0)
  assert_true(sensible_heat(water, 2.0, 300.0, 310.0) > 0.0)
  assert_true(phase_change_heat(water, 1.0, 300.0, 380.0) > 0.0)
  assert_true(total_molar_heat(water, 380.0, 300.0) < 0.0)
  assert_true(integrate_temperature_profile(water, []).to_string() == "0")
  assert_true(weighted_heat_capacity([water], [2.0], 300.0) > 0.0)
  assert_true(weighted_enthalpy([water], [2.0], 300.0) > 0.0)
  assert_true(
    temperature_from_sensible_heat(water, 300.0, 753.0, 350.0) > 300.0,
  )
}

///|
test "stream, validation, and unit-operation empty branches are explicit" {
  let empty = Stream::mixture(id="empty", components=[], temperature=300.0)
  assert_true(empty.molar_flow() == 0.0)
  assert_true(empty.component_fraction("missing") == 0.0)
  assert_true(validate_stream(empty).length() == 1)
  assert_true(issue_count_for_streams([empty]) == 1)
  assert_true(mixer(id="mixed", [empty], 300.0).component_count() == 0)
  assert_true(steam_required(100.0, 0.0) == 0.0)
  assert_true(cooling_water_required(100.0, 0.0, 10.0) == 0.0)
  let utility = utility_estimate(
    name="test",
    duty=100.0,
    cp=4180.0,
    inlet_temperature=20.0,
    outlet_temperature=30.0,
  )
  assert_true(utility.required_flow > 0.0)
  assert_true(validate_temperature_range([280.0, 500.0], 290.0, 400.0) == 2)
  assert_true(validate_positive_values([1.0, 0.0, -1.0]) == 2)
  assert_true(!validate_monotonic([3.0, 2.0, 1.0], true))
}

///|
test "heat exchanger and utility screening handle infeasible cases" {
  assert_true(lmtd(300.0, 290.0, 310.0, 320.0) == 0.0)
  assert_true(exchanger_ua(1000.0, 0.0) == 0.0)
  assert_true(effectiveness_ntu(counter_current=true, 0.0, 10.0, 100.0) == 0.0)
  assert_true(
    chilled_water_utility(1000.0, 5.0, 5.0).required_mass_flow_kg_per_s == 0.0,
  )
  assert_true(
    thermal_oil_utility(1000.0, 5.0, 10.0, 0.0).required_mass_flow_kg_per_s ==
    0.0,
  )
  assert_true(select_utility(1000.0, []).name == "none")
  assert_true(pump_power_w(0.0, 100.0, 0.8) == 0.0)
  assert_true(pump_head_m(1000.0, 0.0) == 0.0)
  assert_true(compressor_power_w(0.0, 100.0, 200.0, 0.8, 1.4) == 0.0)
  assert_true(reynolds_number(1000.0, 1.0, 0.1, 0.0) == 0.0)
  assert_true(friction_factor(0.0, 0.01) == 0.0)
  assert_true(friction_factor(1000.0, 0.01) > 0.0)
  assert_true(heat_loss_to_ambient(10.0, 5.0, 20.0, 30.0) < 0.0)
  assert_true(exchanger_overdesign_area_m2(10.0, 0.1) > 10.0)
}

///|
test "psychrometric and steam report boundaries are observable" {
  let dry = psychrometric_point(25.0, 0.0, 101.325)
  let wet = psychrometric_point(25.0, 1.0, 101.325)
  assert_true(dry.humidity_ratio == 0.0)
  assert_true(wet.humidity_ratio > 0.0)
  assert_true(wet_bulb_c(25.0, dry.humidity_ratio, 101.325) <= 25.0)
  assert_true(moist_air_density(25.0, 0.01, 101.325) > 0.0)
  assert_true(moist_air_specific_volume(25.0, 0.01, 101.325) > 0.0)
  assert_true(humidification_water_duty(1.0, 0.01, 0.02) > 0.0)
  assert_true(evaporative_cooling_duty(1.0, 30.0, 25.0, 0.01, 0.02) != 0.0)
  assert_true(steam_state(-60.0, 100.0).region == UnknownRegion)
  assert_true(steam_state_from_quality(100.0, 0.0).region == SaturatedLiquid)
  assert_true(steam_state_from_quality(100.0, 1.0).region == SaturatedVapor)
  assert_true(steam_mass_flow_for_duty(1000.0, 100.0, 0.5, 0.5) == 0.0)
  assert_true(!interpolate_table(1.0, 1.0, 1.0, 2.0, 1.0).valid)
  assert_true(tabulated_saturation_temperature_c(1.0).clamped)
  assert_true(table_quality_from_enthalpy(100.0, 100000.0).clamped)
}

///|
test "network, schedule, sensitivity, and uncertainty edge paths" {
  let source = process_water_stream(
    id="feed",
    molar_flow=1.0,
    temperature=300.0,
  )
  let disconnected = propagate_network(
    source,
    [
      NetworkConnection::NetworkConnection(
        source_id="x",
        target_id="y",
        fraction=1.0,
      ),
    ],
    0,
  )
  assert_true(disconnected.unresolved_connections == 1)
  assert_true(network_stream_count(disconnected) == 1)
  assert_true(schedule_network([]).makespan_h == 0.0)
  assert_true(
    schedule_contains_cycle([
      ScheduledUnit::ScheduledUnit(id="x", duration_h=1.0, predecessors=["x"]),
    ]),
  )
  assert_true(
    !schedule_network([
      ScheduledUnit::ScheduledUnit(id="x", duration_h=1.0, predecessors=[
        "missing",
      ]),
    ]).feasible,
  )
  assert_true(heater_duty_sensitivity(source, 330.0, 0.0).derivative == 0.0)
  assert_true(duty_curvature(source, 330.0, 0.0) == 0.0)
  assert_true(target_temperature_for_duty(source, 0.0, 300.0, 350.0) < 301.0)
  assert_true(relative_uncertainty_envelope(0.0, 0.1).low == 0.0)
  assert_true(uncertainty_margin(0.0, -1.0, 1.0) == 1.0)
  assert_true(
    !uncertainty_contains(2.0, relative_uncertainty_envelope(1.0, 0.1)),
  )
  assert_true(duty_sign_is_robust(relative_uncertainty_envelope(10.0, 0.1)))
}

///|
test "reports, exports, costs, dynamics, and case-study empty paths" {
  let stream = process_water_stream(
    id="feed",
    molar_flow=1.0,
    temperature=300.0,
  )
  let report = duty_report(
    unit_id="heater",
    stream,
    stream.with_temperature(320.0),
  )
  assert_true(duty_report_csv_row(report).contains("heater"))
  assert_true(report_json_like(report).contains("duty_w"))
  assert_true(export_line_count(streams_csv([stream])) == 2)
  assert_true(case_study_total_duty([]) == 0.0)
  assert_true(case_study_average_quality([]) == 0.0)
  assert_true(!case_study_has_positive_duty([]))
  assert_true(
    benchmark_checksum_is_stable(
      run_benchmark_workload(2),
      run_benchmark_workload(2),
      1.0e-9,
    ),
  )
  assert_true(benchmark_average_duty(run_benchmark_workload(0)) == 0.0)
  assert_true(benchmark_workload_name().contains("water"))
  assert_true(maintenance_cost_per_year(100.0, 0.1) > 0.0)
  assert_true(payback_years(100.0, 0.0) > 1.0e20)
  assert_true(net_present_value([100.0, -50.0], 0.1) > 0.0)
  assert_true(dynamic_average_temperature([]) == 0.0)
  assert_true(dynamic_peak_duty([]) == 0.0)
  assert_true(dynamic_summary([]) == "dynamic simulation: empty")
  assert_true(dynamic_is_monotonic([], true))
}
