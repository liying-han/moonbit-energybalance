///|
pub fn heater(inlet : Stream, outlet_temperature : Double) -> HeaterResult {
  let outlet = inlet
    .with_temperature(outlet_temperature)
    .with_id("\{inlet.id}-heated")
  { outlet, duty: heat_duty(inlet, outlet) }
}

///|
pub fn cooler(inlet : Stream, outlet_temperature : Double) -> HeaterResult {
  let outlet = inlet
    .with_temperature(outlet_temperature)
    .with_id("\{inlet.id}-cooled")
  { outlet, duty: heat_duty(inlet, outlet) }
}

///|
pub fn mixer(
  id~ : String,
  streams : Array[Stream],
  temperature : Double,
) -> Stream {
  let components : Array[ComponentFlow] = []
  for stream in streams {
    for component in stream.components {
      components.push(component)
    }
  }
  Stream::mixture(id~, components~, temperature~)
}

///|
pub fn split(stream : Stream, first_fraction : Double) -> (Stream, Stream) {
  let first_components : Array[ComponentFlow] = []
  let second_components : Array[ComponentFlow] = []
  for component in stream.components {
    first_components.push({
      substance: component.substance,
      molar_flow: component.molar_flow * first_fraction,
    })
    second_components.push({
      substance: component.substance,
      molar_flow: component.molar_flow * (1.0 - first_fraction),
    })
  }
  (
    Stream::mixture(
      id="\{stream.id}-split-a",
      components=first_components,
      temperature=stream.temperature,
    ),
    Stream::mixture(
      id="\{stream.id}-split-b",
      components=second_components,
      temperature=stream.temperature,
    ),
  )
}

///|
pub fn flash_vaporize(
  feed : Stream,
  vapor_substance : Substance,
  liquid_substance : Substance,
  vapor_fraction : Double,
  temperature : Double,
) -> FlashResult {
  let total = feed.molar_flow()
  let vapor = Stream::pure(
    id="\{feed.id}-vapor",
    substance=vapor_substance,
    molar_flow=total * vapor_fraction,
    temperature~,
  )
  let liquid = Stream::pure(
    id="\{feed.id}-liquid",
    substance=liquid_substance,
    molar_flow=total * (1.0 - vapor_fraction),
    temperature~,
  )
  {
    vapor,
    liquid,
    duty: required_heat([feed], [vapor, liquid]),
    vapor_fraction,
  }
}

///|
pub fn steam_required(duty : Double, latent_heat : Double) -> Double {
  if latent_heat == 0.0 {
    0.0
  } else {
    duty.max(0.0) / latent_heat
  }
}

///|
pub fn cooling_water_required(
  duty : Double,
  cp : Double,
  delta_t : Double,
) -> Double {
  if cp == 0.0 || delta_t == 0.0 {
    0.0
  } else {
    duty.abs() / (cp * delta_t.abs())
  }
}

///|
pub fn utility_estimate(
  name~ : String,
  duty~ : Double,
  cp~ : Double,
  inlet_temperature~ : Double,
  outlet_temperature~ : Double,
) -> UtilityEstimate {
  {
    name,
    duty,
    required_flow: cooling_water_required(
      duty,
      cp,
      outlet_temperature - inlet_temperature,
    ),
    inlet_temperature,
    outlet_temperature,
  }
}
