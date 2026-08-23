///|
fn main {
  let result = @energy.run_benchmark_workload(10000)
  println("moonbit-energybalance benchmark")
  println(@energy.benchmark_summary(result))
  println("average duty: \{@energy.benchmark_average_duty(result)} W")
  println("average residual: \{@energy.benchmark_average_residual(result)} W")
}
