///|
pub struct ReactionBalance {
  inlet : Array[SpeciesRate]
  outlet : Array[SpeciesRate]
  extent_mol_per_s : Double
  duty_w : Double
  mass_residual_kg_per_s : Double
} derive(Debug)

///|
pub fn reaction_balance(
  inlet : Array[SpeciesRate],
  terms : Array[ReactionTerm],
  requested_extent : Double,
) -> ReactionBalance {
  let outlet = apply_reaction(inlet, terms, requested_extent)
  let extent = limiting_reaction_extent(inlet, terms).min(
    requested_extent.max(0.0),
  )
  {
    inlet,
    outlet: outlet.copy(),
    extent_mol_per_s: extent,
    duty_w: reaction_duty(terms, extent),
    mass_residual_kg_per_s: reaction_mass_flow(outlet) -
    reaction_mass_flow(inlet),
  }
}

///|
pub fn reaction_is_mass_balanced(
  terms : Array[ReactionTerm],
  tolerance : Double,
) -> Bool {
  let mut mass = 0.0
  for term in terms {
    mass += term.coefficient * term.species.molar_mass
  }
  mass.abs() <= tolerance
}

///|
pub fn reaction_conversion_for_species(
  inlet : Array[SpeciesRate],
  outlet : Array[SpeciesRate],
  species_id : String,
) -> Double {
  let before = species_rate(inlet, species_id)
  let after = species_rate(outlet, species_id)
  if before <= 0.0 {
    0.0
  } else {
    ((before - after) / before).max(0.0).min(1.0)
  }
}

///|
pub fn reaction_outlet_temperature(
  inlet_temperature : Double,
  heat_capacity_flow_w_per_k : Double,
  duty_w : Double,
) -> Double {
  if heat_capacity_flow_w_per_k.abs() < 1.0e-12 {
    inlet_temperature
  } else {
    inlet_temperature - duty_w / heat_capacity_flow_w_per_k
  }
}

///|
pub fn adiabatic_reaction_temperature(
  inlet_temperature : Double,
  inlet_heat_capacity_flow : Double,
  terms : Array[ReactionTerm],
  extent_mol_per_s : Double,
) -> Double {
  reaction_outlet_temperature(
    inlet_temperature,
    inlet_heat_capacity_flow,
    reaction_duty(terms, extent_mol_per_s),
  )
}

///|
pub fn reaction_selectivity(
  outlet : Array[SpeciesRate],
  desired_id : String,
  byproduct_id : String,
) -> Double {
  let desired = species_rate(outlet, desired_id)
  let byproduct = species_rate(outlet, byproduct_id)
  if desired + byproduct <= 0.0 {
    0.0
  } else {
    desired / (desired + byproduct)
  }
}

///|
pub fn reaction_yield(
  inlet : Array[SpeciesRate],
  outlet : Array[SpeciesRate],
  reactant_id : String,
  product_id : String,
  product_coefficient : Double,
  reactant_coefficient : Double,
) -> Double {
  let reacted = species_rate(inlet, reactant_id) -
    species_rate(outlet, reactant_id)
  let produced = species_rate(outlet, product_id) -
    species_rate(inlet, product_id)
  if reacted <= 0.0 || reactant_coefficient <= 0.0 {
    0.0
  } else {
    (produced /
    reacted *
    reactant_coefficient /
    product_coefficient.max(1.0e-12)).max(0.0)
  }
}
