///|
pub struct HeatingCase {
  id : String
  feed : Stream
  target_temperature : Double
} derive(Debug)

///|
pub struct CoolingCase {
  id : String
  feed : Stream
  target_temperature : Double
} derive(Debug)

///|
pub struct ExchangerCase {
  id : String
  hot_in : Stream
  hot_out_temperature : Double
  cold_in : Stream
  cold_out_temperature : Double
  arrangement : FlowArrangement
} derive(Debug)

///|
pub struct ScenarioResult {
  id : String
  duty : Double
  description : String
} derive(Debug)

///|
pub fn HeatingCase::HeatingCase(
  id~ : String,
  feed~ : Stream,
  target_temperature~ : Double,
) -> HeatingCase {
  { id, feed, target_temperature }
}

///|
pub fn CoolingCase::CoolingCase(
  id~ : String,
  feed~ : Stream,
  target_temperature~ : Double,
) -> CoolingCase {
  { id, feed, target_temperature }
}

///|
pub fn ExchangerCase::ExchangerCase(
  id~ : String,
  hot_in~ : Stream,
  hot_out_temperature~ : Double,
  cold_in~ : Stream,
  cold_out_temperature~ : Double,
  arrangement? : FlowArrangement = CounterCurrent,
) -> ExchangerCase {
  {
    id,
    hot_in,
    hot_out_temperature,
    cold_in,
    cold_out_temperature,
    arrangement,
  }
}

///|
pub fn run_heating_case(case : HeatingCase) -> ScenarioResult {
  let result = heater(case.feed, case.target_temperature)
  {
    id: case.id,
    duty: result.duty,
    description: duty_report(unit_id=case.id, case.feed, result.outlet).summary(),
  }
}

///|
pub fn run_cooling_case(case : CoolingCase) -> ScenarioResult {
  let result = cooler(case.feed, case.target_temperature)
  {
    id: case.id,
    duty: result.duty,
    description: duty_report(unit_id=case.id, case.feed, result.outlet).summary(),
  }
}

///|
pub fn run_exchanger_case(case : ExchangerCase) -> ScenarioResult {
  let result = heat_exchanger(
    case.hot_in,
    case.hot_out_temperature,
    case.cold_in,
    case.cold_out_temperature,
    arrangement=case.arrangement,
  )
  { id: case.id, duty: result.duty, description: exchanger_summary(result) }
}

///|
pub fn total_scenario_duty(results : Array[ScenarioResult]) -> Double {
  let mut total = 0.0
  for result in results {
    total += result.duty
  }
  total
}
