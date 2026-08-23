///|
pub fn ComponentFlow::ComponentFlow(
  substance~ : Substance,
  molar_flow~ : Double,
) -> ComponentFlow {
  { substance, molar_flow }
}

///|
pub fn Stream::pure(
  id~ : String,
  substance~ : Substance,
  molar_flow~ : Double,
  temperature~ : Double,
) -> Stream {
  { id, temperature, components: [{ substance, molar_flow }] }
}

///|
pub fn Stream::mixture(
  id~ : String,
  components~ : Array[ComponentFlow],
  temperature~ : Double,
) -> Stream {
  { id, temperature, components }
}

///|
pub fn Stream::with_temperature(self : Stream, temperature : Double) -> Stream {
  { ..self, temperature, }
}

///|
pub fn Stream::with_id(self : Stream, id : String) -> Stream {
  { ..self, id, }
}

///|
pub fn Stream::with_flow_factor(self : Stream, factor : Double) -> Stream {
  let components : Array[ComponentFlow] = []
  for component in self.components {
    components.push({
      substance: component.substance,
      molar_flow: component.molar_flow * factor.max(0.0),
    })
  }
  { ..self, components, }
}

///|
pub fn Stream::with_temperature_offset(self : Stream, delta : Double) -> Stream {
  { ..self, temperature: self.temperature + delta }
}

///|
pub fn Stream::component_count(self : Stream) -> Int {
  self.components.length()
}

///|
pub fn Stream::molar_flow(self : Stream) -> Double {
  let mut total = 0.0
  for component in self.components {
    total += component.molar_flow
  }
  total
}

///|
pub fn Stream::heat_capacity_flow(self : Stream) -> Double {
  let mut total = 0.0
  for component in self.components {
    total += component.molar_flow *
      component.substance.cp_model.cp_at(self.temperature)
  }
  total
}

///|
pub fn Stream::enthalpy_flow(self : Stream) -> Double {
  let mut total = 0.0
  for component in self.components {
    total += component.molar_flow *
      component.substance.enthalpy_at(self.temperature)
  }
  total
}

///|
pub fn Stream::component_fraction(
  self : Stream,
  substance_id : String,
) -> Double {
  let total = self.molar_flow()
  if total == 0.0 {
    0.0
  } else {
    let mut target = 0.0
    for component in self.components {
      if component.substance.id == substance_id {
        target += component.molar_flow
      }
    }
    target / total
  }
}

///|
pub fn heat_duty(inlet : Stream, outlet : Stream) -> Double {
  outlet.enthalpy_flow() - inlet.enthalpy_flow()
}
