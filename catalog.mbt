///|
pub fn water_liquid() -> Substance {
  Substance::constant_cp(
    id="water-liquid",
    name="Water liquid",
    phase=Liquid,
    cp=75.3,
    reference_temperature=298.15,
  ).with_latent_heat(
    transition_temperature=373.15,
    heat=40650.0,
    direction=Vaporize,
  )
}

///|
pub fn water_vapor() -> Substance {
  Substance::constant_cp(
    id="water-vapor",
    name="Water vapor",
    phase=Vapor,
    cp=33.6,
    reference_temperature=373.15,
  ).with_latent_heat(
    transition_temperature=373.15,
    heat=40650.0,
    direction=Condense,
  )
}

///|
pub fn nitrogen_gas() -> Substance {
  Substance::linear_cp(
    id="nitrogen-gas",
    name="Nitrogen gas",
    phase=Vapor,
    a=27.2,
    b=0.0042,
    reference_temperature=298.15,
  )
}

///|
pub fn methane_gas() -> Substance {
  Substance::linear_cp(
    id="methane-gas",
    name="Methane gas",
    phase=Vapor,
    a=19.9,
    b=0.0502,
    reference_temperature=298.15,
  )
}

///|
pub fn ice_solid() -> Substance {
  Substance::constant_cp(
    id="ice-solid",
    name="Ice",
    phase=Solid,
    cp=37.6,
    reference_temperature=273.15,
  )
  .with_latent_heat(transition_temperature=273.15, heat=6010.0, direction=Melt)
  .with_latent_heat(
    transition_temperature=273.15,
    heat=6010.0,
    direction=Freeze,
  )
}

///|
pub fn generic_substance(
  id~ : String,
  name~ : String,
  cp~ : Double,
) -> Substance {
  Substance::constant_cp(
    id~,
    name~,
    phase=UnknownPhase,
    cp~,
    reference_temperature=298.15,
  )
}
