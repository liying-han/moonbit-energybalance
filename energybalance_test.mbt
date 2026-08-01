///|
fn close(actual : Double, expected : Double, tolerance : Double) -> Bool {
  (actual - expected).abs() <= tolerance
}

///|
test "constant cp sensible enthalpy" {
  let water = water_liquid()
  let cold = Stream::pure(
    id="cold",
    substance=water,
    molar_flow=1.5,
    temperature=298.15,
  )
  let hot = cold.with_temperature(318.15)
  assert_true(close(heat_duty(cold, hot), 2259.0, 1.0e-6))
}

///|
test "mixture heat capacity flow and composition" {
  let nitrogen = nitrogen_gas()
  let methane = methane_gas()
  let gas = Stream::mixture(
    id="fuel",
    components=[
      ComponentFlow::ComponentFlow(substance=nitrogen, molar_flow=3.0),
      ComponentFlow::ComponentFlow(substance=methane, molar_flow=1.0),
    ],
    temperature=350.0,
  )
  assert_true(close(gas.component_fraction("methane-gas"), 0.25, 1.0e-12))
  assert_true(gas.heat_capacity_flow() > 110.0)
}

///|
test "required heat closes balance" {
  let feed = Stream::pure(
    id="feed",
    substance=water_liquid(),
    molar_flow=2.0,
    temperature=300.0,
  )
  let product = feed.with_temperature(330.0)
  let q = required_heat([feed], [product])
  let result = steady_state_balance(
    [feed],
    [product],
    terms=BalanceTerms(heat=q),
  )
  assert_true(is_balanced(result))
}

///|
test "heat exchanger reports positive duty and UA" {
  let hot = Stream::pure(
    id="hot-water",
    substance=water_liquid(),
    molar_flow=2.0,
    temperature=360.0,
  )
  let cold = Stream::pure(
    id="cold-water",
    substance=water_liquid(),
    molar_flow=1.0,
    temperature=290.0,
  )
  let hx = heat_exchanger(hot, 330.0, cold, 350.0)
  assert_true(hx.duty > 4000.0)
  assert_true(hx.ua > 0.0)
  assert_true(hx.heat_recovery_fraction > 0.8)
}

///|
test "heater cooler and split preserve flows" {
  let feed = Stream::pure(
    id="feed",
    substance=water_liquid(),
    molar_flow=10.0,
    temperature=310.0,
  )
  let heated = heater(feed, 340.0)
  let cooled = cooler(heated.outlet, 300.0)
  let (a, b) = split(cooled.outlet, 0.35)
  assert_true(heated.duty > 0.0)
  assert_true(cooled.duty < 0.0)
  assert_true(close(a.molar_flow() + b.molar_flow(), feed.molar_flow(), 1.0e-9))
}

///|
test "flash vaporization creates vapor and liquid outlets" {
  let liquid = water_liquid()
  let vapor = water_vapor()
  let feed = Stream::pure(
    id="flash-feed",
    substance=liquid,
    molar_flow=5.0,
    temperature=373.15,
  )
  let result = flash_vaporize(feed, vapor, liquid, 0.2, 373.15)
  assert_true(close(result.vapor.molar_flow(), 1.0, 1.0e-12))
  assert_true(close(result.liquid.molar_flow(), 4.0, 1.0e-12))
}

///|
test "less common variants stay validated" {
  let ice = Substance::constant_cp(
      id="ice",
      name="Ice",
      phase=Solid,
      cp=37.6,
      reference_temperature=273.15,
    )
    .with_latent_heat(
      transition_temperature=273.15,
      heat=6010.0,
      direction=Melt,
    )
    .with_latent_heat(
      transition_temperature=273.15,
      heat=6010.0,
      direction=Freeze,
    )
  let custom = Substance::polynomial_cp(
    id="custom",
    name="Custom",
    phase=UnknownPhase,
    a=1.0,
    b=0.01,
    c=0.0,
    d=0.0,
    reference_temperature=300.0,
  )
  let lmtd = lmtd(380.0, 340.0, 300.0, 320.0, arrangement=Parallel)
  assert_true(ice.enthalpy_at(280.0) > 0.0)
  assert_true(custom.cp_model.cp_at(300.0) > 1.0)
  assert_true(lmtd > 0.0)
}
