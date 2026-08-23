///|
pub struct BenchmarkResult {
  workload : String
  iterations : Int
  checksum : Double
  total_duty_w : Double
  total_residual_w : Double
} derive(Debug)

///|
pub fn run_benchmark_workload(iterations : Int) -> BenchmarkResult {
  let count = iterations.max(0)
  let mut checksum = 0.0
  let mut total_duty = 0.0
  let mut total_residual = 0.0
  for i in 0..<count {
    let temperature = 300.0 + (i % 20).to_double()
    let feed = process_water_stream(
      id="bench-feed",
      molar_flow=2.0,
      temperature~,
    )
    let heated = heater(feed, temperature + 40.0)
    let cooled = cooler(heated.outlet, temperature + 10.0)
    let balance = steady_state_balance(
      [feed],
      [cooled.outlet],
      terms=BalanceTerms(heat=heated.duty + cooled.duty),
    )
    let exchanger = heat_exchanger(
      feed,
      temperature + 20.0,
      cooled.outlet,
      temperature + 15.0,
    )
    total_duty += heated.duty + cooled.duty
    total_residual += balance.residual
    checksum += heated.duty * 0.5 + cooled.duty * 0.25 + exchanger.ua * 0.125
  }
  {
    workload: "water-heater-cooler-exchanger",
    iterations: count,
    checksum,
    total_duty_w: total_duty,
    total_residual_w: total_residual,
  }
}

///|
pub fn benchmark_summary(result : BenchmarkResult) -> String {
  "workload=\{result.workload}, iterations=\{result.iterations}, checksum=\{result.checksum}, residual=\{result.total_residual_w}"
}

///|
pub fn benchmark_checksum_is_stable(
  first : BenchmarkResult,
  second : BenchmarkResult,
  tolerance : Double,
) -> Bool {
  first.iterations == second.iterations &&
  (first.checksum - second.checksum).abs() <= tolerance.abs()
}

///|
pub fn benchmark_average_duty(result : BenchmarkResult) -> Double {
  if result.iterations <= 0 {
    0.0
  } else {
    result.total_duty_w / result.iterations.to_double()
  }
}

///|
pub fn benchmark_average_residual(result : BenchmarkResult) -> Double {
  if result.iterations <= 0 {
    0.0
  } else {
    result.total_residual_w / result.iterations.to_double()
  }
}

///|
pub fn benchmark_workload_name() -> String {
  "water-heater-cooler-exchanger"
}
