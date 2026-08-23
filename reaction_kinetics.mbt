///|
pub(all) enum KineticModel {
  FirstOrder(rate_constant~ : Double)
  SecondOrder(rate_constant~ : Double)
  Arrhenius(pre_exponential~ : Double, activation_energy_j_per_mol~ : Double)
} derive(Debug)

///|
pub struct KineticPoint {
  time_s : Double
  concentration : Double
  conversion : Double
  rate_mol_per_m3_s : Double
} derive(Debug)

///|
pub fn arrhenius_rate_constant(
  activation_energy_j_per_mol : Double,
  reference_temperature_k : Double,
  temperature_k : Double,
) -> Double {
  if reference_temperature_k <= 0.0 || temperature_k <= 0.0 {
    0.0
  } else {
    @math.exp(
      -activation_energy_j_per_mol /
      8.314462618 *
      (1.0 / temperature_k - 1.0 / reference_temperature_k),
    )
  }
}

///|
pub fn kinetic_rate_constant(
  model : KineticModel,
  temperature_k : Double,
) -> Double {
  match model {
    FirstOrder(rate_constant~) => rate_constant.max(0.0)
    SecondOrder(rate_constant~) => rate_constant.max(0.0)
    Arrhenius(pre_exponential~, activation_energy_j_per_mol~) =>
      pre_exponential.max(0.0) *
      arrhenius_rate_constant(
        activation_energy_j_per_mol, 298.15, temperature_k,
      )
  }
}

///|
pub fn reaction_rate(
  model : KineticModel,
  concentration : Double,
  temperature_k : Double,
) -> Double {
  let c = concentration.max(0.0)
  match model {
    FirstOrder(..) => kinetic_rate_constant(model, temperature_k) * c
    SecondOrder(..) => kinetic_rate_constant(model, temperature_k) * c * c
    Arrhenius(..) => kinetic_rate_constant(model, temperature_k) * c
  }
}

///|
pub fn cstr_conversion(
  model : KineticModel,
  residence_time_s : Double,
  temperature_k : Double,
) -> Double {
  let tau = residence_time_s.max(0.0)
  let k = kinetic_rate_constant(model, temperature_k)
  match model {
    FirstOrder(..) => (1.0 - @math.exp(-k * tau)).max(0.0).min(1.0)
    SecondOrder(..) => (k * tau / (1.0 + k * tau)).max(0.0).min(1.0)
    Arrhenius(..) => (1.0 - @math.exp(-k * tau)).max(0.0).min(1.0)
  }
}

///|
pub fn pfr_conversion(
  model : KineticModel,
  residence_time_s : Double,
  temperature_k : Double,
) -> Double {
  let tau = residence_time_s.max(0.0)
  let k = kinetic_rate_constant(model, temperature_k)
  match model {
    FirstOrder(..) => (1.0 - @math.exp(-k * tau)).max(0.0).min(1.0)
    SecondOrder(..) => (k * tau / (1.0 + k * tau)).max(0.0).min(1.0)
    Arrhenius(..) => (1.0 - @math.exp(-k * tau)).max(0.0).min(1.0)
  }
}

///|
pub fn residence_time_for_conversion(
  model : KineticModel,
  conversion : Double,
  temperature_k : Double,
) -> Double {
  let x = conversion.max(0.0).min(0.999999)
  let k = kinetic_rate_constant(model, temperature_k)
  if k <= 0.0 {
    0.0
  } else {
    match model {
      FirstOrder(..) | Arrhenius(..) => -@math.ln(1.0 - x) / k
      SecondOrder(..) => x / (k * (1.0 - x))
    }
  }
}

///|
pub fn kinetic_profile(
  model : KineticModel,
  initial_concentration : Double,
  temperature_k : Double,
  step_s : Double,
  points : Int,
) -> Array[KineticPoint] {
  let profile : Array[KineticPoint] = []
  let count = points.max(0)
  for i in 0..<count {
    let time = step_s.max(0.0) * i.to_double()
    let conversion = pfr_conversion(model, time, temperature_k)
    let concentration = initial_concentration.max(0.0) * (1.0 - conversion)
    profile.push({
      time_s: time,
      concentration,
      conversion,
      rate_mol_per_m3_s: reaction_rate(model, concentration, temperature_k),
    })
  }
  profile
}

///|
pub fn kinetic_half_life(
  model : KineticModel,
  temperature_k : Double,
) -> Double {
  residence_time_for_conversion(model, 0.5, temperature_k)
}
