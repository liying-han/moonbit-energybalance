///|
pub struct DutyReport {
  unit_id : String
  inlet_id : String
  outlet_id : String
  inlet_temperature : Double
  outlet_temperature : Double
  molar_flow : Double
  duty : Double
  service_hint : String
} derive(Debug)

///|
pub fn service_hint(duty : Double) -> String {
  if duty > 0.0 {
    "heating"
  } else if duty < 0.0 {
    "cooling"
  } else {
    "adiabatic"
  }
}

///|
pub fn duty_report(
  unit_id~ : String,
  inlet : Stream,
  outlet : Stream,
) -> DutyReport {
  let duty = heat_duty(inlet, outlet)
  {
    unit_id,
    inlet_id: inlet.id,
    outlet_id: outlet.id,
    inlet_temperature: inlet.temperature,
    outlet_temperature: outlet.temperature,
    molar_flow: inlet.molar_flow(),
    duty,
    service_hint: service_hint(duty),
  }
}

///|
pub fn DutyReport::summary(self : DutyReport) -> String {
  "\{self.unit_id}: \{self.service_hint} \{self.inlet_id}->\{self.outlet_id}, duty=\{self.duty.round()} W"
}

///|
pub fn balance_summary(result : BalanceResult) -> String {
  "Hin=\{result.inlet_enthalpy_flow.round()} W, Hout=\{result.outlet_enthalpy_flow.round()} W, Q=\{result.heat.round()} W, residual=\{result.residual.round()} W"
}

///|
pub fn exchanger_summary(result : HeatExchangerResult) -> String {
  "HX duty=\{result.duty.round()} W, LMTD=\{result.lmtd.round()} K, UA=\{result.ua.round()} W/K"
}

///|
pub fn utility_summary(result : UtilityEstimate) -> String {
  "\{result.name}: duty=\{result.duty.round()} W, flow=\{result.required_flow} mol/s"
}
