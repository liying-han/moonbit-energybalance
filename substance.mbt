///|
pub fn Substance::constant_cp(
  id~ : String,
  name~ : String,
  phase~ : Phase,
  cp~ : Double,
  reference_temperature~ : Double,
) -> Substance {
  {
    id,
    name,
    phase,
    cp_model: Constant(cp),
    reference_temperature,
    formation_enthalpy: 0.0,
    latent_heats: [],
  }
}

///|
pub fn Substance::linear_cp(
  id~ : String,
  name~ : String,
  phase~ : Phase,
  a~ : Double,
  b~ : Double,
  reference_temperature~ : Double,
) -> Substance {
  {
    id,
    name,
    phase,
    cp_model: Linear(a, b),
    reference_temperature,
    formation_enthalpy: 0.0,
    latent_heats: [],
  }
}

///|
pub fn Substance::polynomial_cp(
  id~ : String,
  name~ : String,
  phase~ : Phase,
  a~ : Double,
  b~ : Double,
  c~ : Double,
  d~ : Double,
  reference_temperature~ : Double,
) -> Substance {
  {
    id,
    name,
    phase,
    cp_model: Polynomial(a, b, c, d),
    reference_temperature,
    formation_enthalpy: 0.0,
    latent_heats: [],
  }
}

///|
pub fn Substance::with_formation_enthalpy(
  self : Substance,
  value : Double,
) -> Substance {
  { ..self, formation_enthalpy: value }
}

///|
pub fn Substance::with_latent_heat(
  self : Substance,
  transition_temperature~ : Double,
  heat~ : Double,
  direction~ : PhaseChangeDirection,
) -> Substance {
  let event : LatentHeat = { transition_temperature, heat, direction }
  let events = self.latent_heats.copy()
  events.push(event)
  { ..self, latent_heats: events }
}

///|
pub fn CpModel::cp_at(self : CpModel, temperature : Double) -> Double {
  match self {
    Constant(cp) => cp
    Linear(a, b) => a + b * temperature
    Polynomial(a, b, c, d) =>
      a +
      b * temperature +
      c * temperature * temperature +
      d * temperature * temperature * temperature
  }
}

///|
pub fn CpModel::integral(self : CpModel, t0 : Double, t1 : Double) -> Double {
  match self {
    Constant(cp) => cp * (t1 - t0)
    Linear(a, b) => a * (t1 - t0) + 0.5 * b * (t1 * t1 - t0 * t0)
    Polynomial(a, b, c, d) =>
      a * (t1 - t0) +
      0.5 * b * (t1 * t1 - t0 * t0) +
      c / 3.0 * (t1 * t1 * t1 - t0 * t0 * t0) +
      0.25 * d * (t1 * t1 * t1 * t1 - t0 * t0 * t0 * t0)
  }
}

///|
fn crosses_temperature(t0 : Double, t1 : Double, marker : Double) -> Bool {
  if t1 >= t0 {
    t0 < marker && marker <= t1
  } else {
    t1 <= marker && marker < t0
  }
}

///|
fn latent_sign(direction : PhaseChangeDirection, warming : Bool) -> Double {
  match direction {
    Melt | Vaporize => if warming { 1.0 } else { -1.0 }
    Freeze | Condense => if warming { -1.0 } else { 1.0 }
  }
}

///|
pub fn Substance::sensible_enthalpy_change(
  self : Substance,
  from_temperature : Double,
  to_temperature : Double,
) -> Double {
  self.cp_model.integral(from_temperature, to_temperature)
}

///|
pub fn Substance::phase_change_enthalpy_change(
  self : Substance,
  from_temperature : Double,
  to_temperature : Double,
) -> Double {
  let warming = to_temperature >= from_temperature
  let mut total = 0.0
  for item in self.latent_heats {
    if crosses_temperature(
        from_temperature,
        to_temperature,
        item.transition_temperature,
      ) {
      total += item.heat * latent_sign(item.direction, warming)
    }
  }
  total
}

///|
pub fn Substance::enthalpy_at(self : Substance, temperature : Double) -> Double {
  self.formation_enthalpy +
  self.sensible_enthalpy_change(self.reference_temperature, temperature) +
  self.phase_change_enthalpy_change(self.reference_temperature, temperature)
}
