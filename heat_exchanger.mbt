///|
pub(all) enum FlowArrangement {
  CounterCurrent
  Parallel
} derive(Debug, Eq)

///|
fn safe_lmtd(delta_a : Double, delta_b : Double) -> Double {
  if delta_a <= 0.0 || delta_b <= 0.0 {
    0.0
  } else if (delta_a - delta_b).abs() < 1.0e-9 {
    (delta_a + delta_b) / 2.0
  } else {
    (delta_a - delta_b) / @math.ln(delta_a / delta_b)
  }
}

///|
pub fn lmtd(
  hot_in_temperature : Double,
  hot_out_temperature : Double,
  cold_in_temperature : Double,
  cold_out_temperature : Double,
  arrangement? : FlowArrangement = CounterCurrent,
) -> Double {
  match arrangement {
    CounterCurrent =>
      safe_lmtd(
        hot_in_temperature - cold_out_temperature,
        hot_out_temperature - cold_in_temperature,
      )
    Parallel =>
      safe_lmtd(
        hot_in_temperature - cold_in_temperature,
        hot_out_temperature - cold_out_temperature,
      )
  }
}

///|
pub fn exchanger_ua(duty : Double, lmtd_value : Double) -> Double {
  if lmtd_value == 0.0 {
    0.0
  } else {
    duty.abs() / lmtd_value
  }
}

///|
pub fn parallel_lmtd(
  hot_in_temperature : Double,
  hot_out_temperature : Double,
  cold_in_temperature : Double,
  cold_out_temperature : Double,
) -> Double {
  lmtd(
    hot_in_temperature,
    hot_out_temperature,
    cold_in_temperature,
    cold_out_temperature,
    arrangement=Parallel,
  )
}

///|
pub fn effectiveness_ntu(
  counter_current~ : Bool,
  c_min : Double,
  c_max : Double,
  ua : Double,
) -> Double {
  if c_min <= 0.0 || c_max <= 0.0 {
    0.0
  } else {
    let cr = c_min / c_max
    let ntu = ua / c_min
    if counter_current {
      if (1.0 - cr).abs() < 1.0e-9 {
        ntu / (1.0 + ntu)
      } else {
        let e = @math.exp(-(1.0 - cr) * ntu)
        (1.0 - e) / (1.0 - cr * e)
      }
    } else {
      (1.0 - @math.exp(-(1.0 + cr) * ntu)) / (1.0 + cr)
    }
  }
}

///|
pub fn heat_exchanger(
  hot_in : Stream,
  hot_out_temperature : Double,
  cold_in : Stream,
  cold_out_temperature : Double,
  arrangement? : FlowArrangement = CounterCurrent,
) -> HeatExchangerResult {
  let hot_out = hot_in
    .with_temperature(hot_out_temperature)
    .with_id("\{hot_in.id}-out")
  let cold_out = cold_in
    .with_temperature(cold_out_temperature)
    .with_id("\{cold_in.id}-out")
  let hot_duty = heat_duty(hot_in, hot_out)
  let cold_duty = heat_duty(cold_in, cold_out)
  let exchanged = (cold_duty.abs() + hot_duty.abs()) / 2.0
  let approach = lmtd(
    hot_in.temperature,
    hot_out.temperature,
    cold_in.temperature,
    cold_out.temperature,
    arrangement~,
  )
  let c_hot = hot_in.heat_capacity_flow()
  let c_cold = cold_in.heat_capacity_flow()
  let max_recoverable = c_hot.min(c_cold) *
    (hot_in.temperature - cold_in.temperature).abs()
  {
    hot_out,
    cold_out,
    duty: exchanged,
    lmtd: approach,
    ua: exchanger_ua(exchanged, approach),
    heat_recovery_fraction: if max_recoverable == 0.0 {
      0.0
    } else {
      exchanged / max_recoverable
    },
  }
}
