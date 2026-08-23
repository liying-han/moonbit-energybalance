///|
test "utility cost and emissions analysis supports engineering decisions" {
  let steam = steam_utility(1.0, 120.0, 180.0)
  let cooling = cooling_water_utility(-10000.0, 25.0, 35.0)
  let steam_cost = utility_operating_cost(steam, 8000.0, 0.12)
  let cooling_cost = utility_operating_cost(cooling, 8000.0, 0.03)
  assert_true(steam_cost > 0.0)
  assert_true(cooling_cost > 0.0)
  assert_true(utility_emissions_kg_per_h(steam, 0.2) > 0.0)
  let capital = annualized_capital_cost(100000.0, 0.10, 10, 8000.0)
  assert_true(capital > 0.0)
  assert_true(total_annual_cost(capital, steam_cost, 8000.0) > capital)
}

///|
test "cost optimizer selects the least-cost compatible service" {
  let steam = steam_utility(1.0, 120.0, 180.0)
  let oil = thermal_oil_utility(20000.0, 200.0, 250.0, 2200.0)
  let selected = least_cost_heating_service(15000.0, [steam, oil], 8000.0, 0.10)
  assert_true(selected.name != "none")
  assert_true(selected.annual_cost > 0.0)
}
