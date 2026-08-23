///|
pub struct CaseStudyResult {
  id : String
  duty_w : Double
  mass_flow_kg_per_s : Double
  equipment_area_m2 : Double
  quality_score : Double
  summary : String
} derive(Debug)

///|
pub fn run_water_preheat_case(
  mass_flow_kg_per_s : Double,
  inlet_temperature_k : Double,
  outlet_temperature_k : Double,
) -> CaseStudyResult {
  let inlet = Stream::pure(
    id="water-case-in",
    substance=water_liquid(),
    molar_flow=mass_flow_to_molar_flow(mass_flow_kg_per_s, 18.015),
    temperature=inlet_temperature_k,
  )
  let outlet = inlet.with_temperature(outlet_temperature_k)
  let duty = heat_duty(inlet, outlet)
  let sizing = size_heater(duty, 30.0, 600.0, 0.85)
  let quality = energy_balance_quality(duty, duty, 1.0e-6)
  {
    id: "water-preheat",
    duty_w: duty,
    mass_flow_kg_per_s,
    equipment_area_m2: sizing.area_m2,
    quality_score: quality_score(quality),
    summary: "water-preheat duty={duty.round()} W, area={sizing.area_m2.round()} m2",
  }
}

///|
pub fn run_natural_gas_case(
  molar_flow_mol_per_s : Double,
  inlet_temperature_k : Double,
  outlet_temperature_k : Double,
) -> CaseStudyResult {
  let inlet = natural_gas_stream(
    id="natural-gas-in",
    molar_flow=molar_flow_mol_per_s,
    temperature=inlet_temperature_k,
  )
  let outlet = inlet.with_temperature(outlet_temperature_k)
  let duty = heat_duty(inlet, outlet)
  let sizing = size_heater(duty, 40.0, 80.0, 0.80)
  let quality = energy_balance_quality(
    enthalpy_flow_sum([inlet]),
    enthalpy_flow_sum([outlet]) - duty,
    1.0e-6,
  )
  {
    id: "natural-gas-heater",
    duty_w: duty,
    mass_flow_kg_per_s: molar_flow_to_mass_flow(molar_flow_mol_per_s, 20.0),
    equipment_area_m2: sizing.area_m2,
    quality_score: quality_score(quality),
    summary: "natural-gas-heater duty={duty.round()} W, area={sizing.area_m2.round()} m2",
  }
}

///|
pub fn run_air_drying_case(
  dry_air_mass_flow_kg_per_s : Double,
  inlet_temperature_c : Double,
  inlet_relative_humidity : Double,
  outlet_temperature_c : Double,
  outlet_relative_humidity : Double,
) -> CaseStudyResult {
  let inlet = psychrometric_point(
    inlet_temperature_c, inlet_relative_humidity, 101.325,
  )
  let outlet = psychrometric_point(
    outlet_temperature_c, outlet_relative_humidity, 101.325,
  )
  let report = air_conditioning_report(
    inlet, outlet, dry_air_mass_flow_kg_per_s,
  )
  {
    id: "air-drying",
    duty_w: report.cooling_duty_w,
    mass_flow_kg_per_s: dry_air_mass_flow_kg_per_s,
    equipment_area_m2: exchanger_area_m2(
      report.cooling_duty_w,
      250.0,
      15.0,
      0.95,
    ),
    quality_score: if report.condensate_kg_per_s >= 0.0 {
      100.0
    } else {
      0.0
    },
    summary: "air-drying duty={report.cooling_duty_w.round()} W, condensate={report.condensate_kg_per_s}",
  }
}

///|
pub fn case_study_summary(results : Array[CaseStudyResult]) -> String {
  let mut output = "case studies:\n"
  for result in results {
    output = output + "- " + result.id + ": " + result.summary + "\n"
  }
  output
}

///|
pub fn case_study_total_duty(results : Array[CaseStudyResult]) -> Double {
  let mut total = 0.0
  for result in results {
    total += result.duty_w
  }
  total
}

///|
pub fn case_study_average_quality(results : Array[CaseStudyResult]) -> Double {
  if results.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for result in results {
      total += result.quality_score
    }
    total / results.length().to_double()
  }
}

///|
pub fn case_study_has_positive_duty(results : Array[CaseStudyResult]) -> Bool {
  for result in results {
    if result.duty_w > 0.0 {
      return true
    }
  }
  false
}
