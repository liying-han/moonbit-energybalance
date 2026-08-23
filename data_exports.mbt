///|
pub fn stream_csv_header() -> String {
  "stream_id,temperature_k,molar_flow_mol_per_s,component_count,enthalpy_flow_w"
}

///|
pub fn stream_csv_row(stream : Stream) -> String {
  "\{stream.id},\{stream.temperature},\{stream.molar_flow()},\{stream.component_count()},\{stream.enthalpy_flow()}"
}

///|
pub fn streams_csv(streams : Array[Stream]) -> String {
  let mut output = stream_csv_header() + "\n"
  for stream in streams {
    output = output + stream_csv_row(stream) + "\n"
  }
  output
}

///|
pub fn scenario_result_csv_header() -> String {
  "scenario_id,duty_w,description"
}

///|
pub fn scenario_result_csv_row(result : ScenarioResult) -> String {
  "\{result.id},\{result.duty},\{result.description}"
}

///|
pub fn scenario_results_csv(results : Array[ScenarioResult]) -> String {
  let mut output = scenario_result_csv_header() + "\n"
  for result in results {
    output = output + scenario_result_csv_row(result) + "\n"
  }
  output
}

///|
pub fn balance_result_csv_header() -> String {
  "inlet_enthalpy_flow_w,outlet_enthalpy_flow_w,heat_w,shaft_work_w,residual_w"
}

///|
pub fn balance_result_csv_row(result : BalanceResult) -> String {
  "\{result.inlet_enthalpy_flow},\{result.outlet_enthalpy_flow},\{result.heat},\{result.shaft_work},\{result.residual}"
}

///|
pub fn utility_csv_row(result : UtilityEstimate) -> String {
  "\{result.name},\{result.duty},\{result.required_flow},\{result.inlet_temperature},\{result.outlet_temperature}"
}

///|
pub fn duty_report_csv_row(report : DutyReport) -> String {
  "\{report.unit_id},\{report.inlet_id},\{report.outlet_id},\{report.inlet_temperature},\{report.outlet_temperature},\{report.molar_flow},\{report.duty},\{report.service_hint}"
}

///|
pub fn exchanger_csv_row(result : HeatExchangerResult) -> String {
  "\{result.hot_out.id},\{result.cold_out.id},\{result.duty},\{result.lmtd},\{result.ua},\{result.heat_recovery_fraction}"
}

///|
pub fn csv_escape(value : String) -> String {
  if value.contains(",") {
    "[" + value + "]"
  } else {
    value
  }
}

///|
pub fn csv_join(values : Array[String]) -> String {
  values.join(",")
}

///|
pub fn report_json_like(report : DutyReport) -> String {
  "{unit_id: \{report.unit_id}, duty_w: \{report.duty}, service: \{report.service_hint}}"
}

///|
pub fn export_line_count(csv : String) -> Int {
  if csv.length() == 0 {
    0
  } else {
    csv.split("\n").length() - 1
  }
}
