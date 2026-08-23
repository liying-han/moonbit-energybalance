///|
pub struct DynamicThermalState {
  time_s : Double
  temperature_k : Double
  energy_j : Double
  duty_w : Double
} derive(Debug)

///|
pub fn stable_time_step(
  overall_u_w_per_k : Double,
  heat_capacity_j_per_k : Double,
  requested_step_s : Double,
) -> Double {
  if overall_u_w_per_k <= 0.0 ||
    heat_capacity_j_per_k <= 0.0 ||
    requested_step_s <= 0.0 {
    0.0
  } else {
    requested_step_s.min(0.5 * heat_capacity_j_per_k / overall_u_w_per_k)
  }
}

///|
pub fn thermal_time_constant_s(
  overall_u_w_per_k : Double,
  heat_capacity_j_per_k : Double,
) -> Double {
  if overall_u_w_per_k <= 0.0 {
    0.0
  } else {
    heat_capacity_j_per_k.max(0.0) / overall_u_w_per_k
  }
}

///|
pub fn dynamic_step(
  state : DynamicThermalState,
  target_temperature_k : Double,
  heat_capacity_j_per_k : Double,
  overall_u_w_per_k : Double,
  step_s : Double,
) -> DynamicThermalState {
  let duty = overall_u_w_per_k.max(0.0) *
    (target_temperature_k - state.temperature_k)
  let temperature = if heat_capacity_j_per_k <= 0.0 {
    state.temperature_k
  } else {
    state.temperature_k + duty / heat_capacity_j_per_k * step_s.max(0.0)
  }
  {
    time_s: state.time_s + step_s.max(0.0),
    temperature_k: temperature,
    energy_j: heat_capacity_j_per_k.max(0.0) * temperature,
    duty_w: duty,
  }
}

///|
pub fn simulate_lumped_heating(
  initial_temperature_k : Double,
  target_temperature_k : Double,
  heat_capacity_j_per_k : Double,
  overall_u_w_per_k : Double,
  step_s : Double,
  points : Int,
) -> Array[DynamicThermalState] {
  let states : Array[DynamicThermalState] = []
  let count = points.max(0)
  if count > 0 {
    let initial : DynamicThermalState = {
      time_s: 0.0,
      temperature_k: initial_temperature_k,
      energy_j: heat_capacity_j_per_k.max(0.0) * initial_temperature_k,
      duty_w: overall_u_w_per_k.max(0.0) *
      (target_temperature_k - initial_temperature_k),
    }
    states.push(initial)
    let mut current = initial
    for _ in 1..<count {
      current = dynamic_step(
        current, target_temperature_k, heat_capacity_j_per_k, overall_u_w_per_k,
        step_s,
      )
      if target_temperature_k >= initial_temperature_k {
        current = {
          ..current,
          temperature_k: current.temperature_k.min(target_temperature_k),
        }
      } else {
        current = {
          ..current,
          temperature_k: current.temperature_k.max(target_temperature_k),
        }
      }
      states.push(current)
    }
  }
  states
}

///|
pub fn dynamic_energy(
  first : DynamicThermalState,
  last : DynamicThermalState,
) -> Double {
  last.energy_j - first.energy_j
}

///|
pub fn integrate_duty_profile(
  times_s : Array[Double],
  duties_w : Array[Double],
) -> Double {
  let length = times_s.length().min(duties_w.length())
  if length < 2 {
    0.0
  } else {
    let mut total = 0.0
    for i in 0..<(length - 1) {
      let dt = (times_s[i + 1] - times_s[i]).max(0.0)
      total += dt * (duties_w[i] + duties_w[i + 1]) / 2.0
    }
    total
  }
}

///|
pub fn first_order_response(
  initial_value : Double,
  target_value : Double,
  time_s : Double,
  time_constant_s : Double,
) -> Double {
  if time_constant_s <= 0.0 {
    target_value
  } else {
    target_value +
    (initial_value - target_value) *
    @math.exp(-time_s.max(0.0) / time_constant_s)
  }
}

///|
pub fn response_time_to_fraction(
  time_constant_s : Double,
  fraction : Double,
) -> Double {
  let f = fraction.max(0.0).min(0.999999)
  if time_constant_s <= 0.0 {
    0.0
  } else {
    -time_constant_s * @math.ln(1.0 - f)
  }
}

///|
pub fn dynamic_peak_duty(states : Array[DynamicThermalState]) -> Double {
  let mut peak = 0.0
  for state in states {
    peak = peak.max(state.duty_w.abs())
  }
  peak
}

///|
pub fn dynamic_average_temperature(
  states : Array[DynamicThermalState],
) -> Double {
  if states.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for state in states {
      total += state.temperature_k
    }
    total / states.length().to_double()
  }
}

///|
pub fn dynamic_temperature_error(
  state : DynamicThermalState,
  target_temperature_k : Double,
) -> Double {
  state.temperature_k - target_temperature_k
}

///|
pub fn dynamic_summary(states : Array[DynamicThermalState]) -> String {
  if states.length() == 0 {
    "dynamic simulation: empty"
  } else {
    let last = states[states.length() - 1]
    "dynamic simulation: duration=\{last.time_s} s, temperature=\{last.temperature_k} K, peak duty=\{dynamic_peak_duty(states)} W"
  }
}

///|
pub fn dynamic_is_monotonic(
  states : Array[DynamicThermalState],
  increasing : Bool,
) -> Bool {
  if states.length() < 2 {
    true
  } else {
    let mut valid = true
    for i in 0..<(states.length() - 1) {
      if increasing && states[i + 1].temperature_k < states[i].temperature_k {
        valid = false
      }
      if !increasing && states[i + 1].temperature_k > states[i].temperature_k {
        valid = false
      }
    }
    valid
  }
}
