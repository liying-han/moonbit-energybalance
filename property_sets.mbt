///|
pub fn carbon_dioxide_gas() -> Substance {
  Substance::polynomial_cp(
    id="carbon-dioxide-gas",
    name="Carbon dioxide gas",
    phase=Vapor,
    a=22.26,
    b=0.05981,
    c=-0.00003501,
    d=0.000000007469,
    reference_temperature=298.15,
  )
}

///|
pub fn oxygen_gas() -> Substance {
  Substance::linear_cp(
    id="oxygen-gas",
    name="Oxygen gas",
    phase=Vapor,
    a=25.48,
    b=0.0152,
    reference_temperature=298.15,
  )
}

///|
pub fn air_pseudo_component() -> Substance {
  Substance::linear_cp(
    id="air",
    name="Dry air pseudo-component",
    phase=Vapor,
    a=28.11,
    b=0.00197,
    reference_temperature=298.15,
  )
}

///|
pub fn ethanol_liquid() -> Substance {
  Substance::constant_cp(
    id="ethanol-liquid",
    name="Ethanol liquid",
    phase=Liquid,
    cp=112.4,
    reference_temperature=298.15,
  ).with_latent_heat(
    transition_temperature=351.45,
    heat=38600.0,
    direction=Vaporize,
  )
}

///|
pub fn benzene_liquid() -> Substance {
  Substance::constant_cp(
    id="benzene-liquid",
    name="Benzene liquid",
    phase=Liquid,
    cp=136.1,
    reference_temperature=298.15,
  ).with_latent_heat(
    transition_temperature=353.25,
    heat=30720.0,
    direction=Vaporize,
  )
}

///|
pub fn toluene_liquid() -> Substance {
  Substance::constant_cp(
    id="toluene-liquid",
    name="Toluene liquid",
    phase=Liquid,
    cp=155.5,
    reference_temperature=298.15,
  ).with_latent_heat(
    transition_temperature=383.75,
    heat=33300.0,
    direction=Vaporize,
  )
}

///|
pub fn process_water_stream(
  id~ : String,
  molar_flow~ : Double,
  temperature~ : Double,
) -> Stream {
  Stream::pure(id~, substance=water_liquid(), molar_flow~, temperature~)
}

///|
pub fn air_stream(
  id~ : String,
  molar_flow~ : Double,
  temperature~ : Double,
) -> Stream {
  Stream::pure(id~, substance=air_pseudo_component(), molar_flow~, temperature~)
}

///|
pub fn natural_gas_stream(
  id~ : String,
  molar_flow~ : Double,
  temperature~ : Double,
) -> Stream {
  Stream::mixture(
    id~,
    components=[
      ComponentFlow(substance=methane_gas(), molar_flow=molar_flow * 0.90),
      ComponentFlow(substance=nitrogen_gas(), molar_flow=molar_flow * 0.05),
      ComponentFlow(
        substance=carbon_dioxide_gas(),
        molar_flow=molar_flow * 0.05,
      ),
    ],
    temperature~,
  )
}
