///|
pub struct CostEstimate {
  name : String
  annual_cost : Double
  annual_energy_kwh : Double
  annual_emissions_kg : Double
  utility_flow_kg_per_s : Double
} derive(Debug)

///|
pub fn utility_operating_cost(
  utility : UtilityDesign,
  operating_hours_per_year : Double,
  unit_cost_per_kwh : Double,
) -> Double {
  utility.required_mass_flow_kg_per_s.abs() *
  utility.duty_w.abs() /
  utility.required_mass_flow_kg_per_s.max(1.0e-12) /
  1000.0 *
  operating_hours_per_year.max(0.0) *
  unit_cost_per_kwh.max(0.0)
}

///|
pub fn utility_energy_kwh_per_year(
  utility : UtilityDesign,
  operating_hours_per_year : Double,
) -> Double {
  utility.duty_w.abs() / 1000.0 * operating_hours_per_year.max(0.0)
}

///|
pub fn utility_emissions_kg_per_h(
  utility : UtilityDesign,
  emission_factor_kg_per_kwh : Double,
) -> Double {
  utility.duty_w.abs() / 1000.0 * emission_factor_kg_per_kwh.max(0.0)
}

///|
pub fn annualized_capital_cost(
  capital_cost : Double,
  interest_rate : Double,
  lifetime_years : Int,
  operating_hours_per_year : Double,
) -> Double {
  if lifetime_years <= 0 || operating_hours_per_year <= 0.0 {
    0.0
  } else {
    let rate = interest_rate.max(0.0)
    let years = lifetime_years.to_double()
    let recovery = if rate == 0.0 {
      1.0 / years
    } else {
      rate * @math.pow(1.0 + rate, years) / (@math.pow(1.0 + rate, years) - 1.0)
    }
    capital_cost.abs() * recovery
  }
}

///|
pub fn total_annual_cost(
  annualized_capital : Double,
  utility_cost_per_hour : Double,
  operating_hours_per_year : Double,
) -> Double {
  annualized_capital.max(0.0) +
  utility_cost_per_hour.max(0.0) * operating_hours_per_year.max(0.0)
}

///|
pub fn maintenance_cost_per_year(
  capital_cost : Double,
  maintenance_fraction : Double,
) -> Double {
  capital_cost.abs() * maintenance_fraction.max(0.0)
}

///|
pub fn contingency_cost(base_cost : Double, fraction : Double) -> Double {
  base_cost.abs() * fraction.max(0.0)
}

///|
pub fn inflation_adjusted_cost(
  base_cost : Double,
  inflation_rate : Double,
  years : Int,
) -> Double {
  base_cost.abs() *
  @math.pow(1.0 + inflation_rate.max(-0.99), years.max(0).to_double())
}

///|
pub fn discount_factor(discount_rate : Double, year : Int) -> Double {
  1.0 / @math.pow(1.0 + discount_rate.max(-0.99), year.max(0).to_double())
}

///|
pub fn net_present_value(
  cash_flows : Array[Double],
  discount_rate : Double,
) -> Double {
  let mut total = 0.0
  for i, cash_flow in cash_flows {
    total += cash_flow * discount_factor(discount_rate, i)
  }
  total
}

///|
pub fn payback_years(
  initial_investment : Double,
  annual_saving : Double,
) -> Double {
  if annual_saving <= 0.0 {
    1.0e30
  } else {
    initial_investment.abs() / annual_saving
  }
}

///|
pub fn levelized_cost(
  capital_cost : Double,
  annual_operating_cost : Double,
  annual_output_kwh : Double,
  lifetime_years : Int,
) -> Double {
  if annual_output_kwh <= 0.0 || lifetime_years <= 0 {
    0.0
  } else {
    (
      capital_cost.abs() / lifetime_years.to_double() +
      annual_operating_cost.abs()
    ) /
    annual_output_kwh
  }
}

///|
pub fn service_cost_estimate(
  utility : UtilityDesign,
  operating_hours_per_year : Double,
  unit_cost_per_kwh : Double,
  emission_factor_kg_per_kwh : Double,
) -> CostEstimate {
  let annual_energy = utility_energy_kwh_per_year(
    utility, operating_hours_per_year,
  )
  {
    name: utility.name,
    annual_cost: annual_energy * unit_cost_per_kwh.max(0.0),
    annual_energy_kwh: annual_energy,
    annual_emissions_kg: annual_energy * emission_factor_kg_per_kwh.max(0.0),
    utility_flow_kg_per_s: utility.required_mass_flow_kg_per_s,
  }
}

///|
pub fn least_cost_heating_service(
  duty_w : Double,
  candidates : Array[UtilityDesign],
  operating_hours_per_year : Double,
  unit_cost_per_kwh : Double,
) -> CostEstimate {
  let selected : CostEstimate = {
    name: "none",
    annual_cost: 1.0e30,
    annual_energy_kwh: 0.0,
    annual_emissions_kg: 0.0,
    utility_flow_kg_per_s: 0.0,
  }
  let mut best = selected
  for candidate in candidates {
    if candidate.duty_w >= duty_w {
      let estimate = service_cost_estimate(
        candidate, operating_hours_per_year, unit_cost_per_kwh, 0.2,
      )
      if estimate.annual_cost < best.annual_cost {
        best = estimate
      }
    }
  }
  best
}

///|
pub fn cost_saving_percent(
  reference_cost : Double,
  improved_cost : Double,
) -> Double {
  if reference_cost.abs() < 1.0e-12 {
    0.0
  } else {
    (reference_cost - improved_cost) / reference_cost.abs() * 100.0
  }
}

///|
pub fn emissions_saving_kg(
  reference : CostEstimate,
  improved : CostEstimate,
) -> Double {
  reference.annual_emissions_kg - improved.annual_emissions_kg
}

///|
pub fn cost_summary(estimate : CostEstimate) -> String {
  "\{estimate.name}: annual cost=\{estimate.annual_cost}, energy=\{estimate.annual_energy_kwh} kWh, emissions=\{estimate.annual_emissions_kg} kg"
}
