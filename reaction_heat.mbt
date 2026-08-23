///|
pub struct ReactionSpecies {
  id : String
  molar_mass : Double
  formation_enthalpy_kj_per_mol : Double
} derive(Debug)

///|
pub struct ReactionTerm {
  species : ReactionSpecies
  coefficient : Double
} derive(Debug)

///|
pub struct SpeciesRate {
  species : ReactionSpecies
  molar_flow : Double
} derive(Debug)

///|
pub fn ReactionSpecies::ReactionSpecies(
  id~ : String,
  molar_mass~ : Double,
  formation_enthalpy_kj_per_mol~ : Double,
) -> ReactionSpecies {
  { id, molar_mass, formation_enthalpy_kj_per_mol }
}

///|
pub fn ReactionTerm::ReactionTerm(
  species~ : ReactionSpecies,
  coefficient~ : Double,
) -> ReactionTerm {
  { species, coefficient }
}

///|
pub fn SpeciesRate::SpeciesRate(
  species~ : ReactionSpecies,
  molar_flow~ : Double,
) -> SpeciesRate {
  { species, molar_flow }
}

///|
pub fn reaction_enthalpy(terms : Array[ReactionTerm]) -> Double {
  let mut total = 0.0
  for term in terms {
    total += term.coefficient * term.species.formation_enthalpy_kj_per_mol
  }
  total
}

///|
pub fn reaction_duty(
  terms : Array[ReactionTerm],
  extent_mol_per_s : Double,
) -> Double {
  reaction_enthalpy(terms) * extent_mol_per_s * 1000.0
}

///|
fn available_rate(rates : Array[SpeciesRate], id : String) -> (Bool, Double) {
  let mut found = false
  let mut rate = 0.0
  for item in rates {
    if item.species.id == id {
      found = true
      rate += item.molar_flow.max(0.0)
    }
  }
  (found, rate)
}

///|
pub fn limiting_reaction_extent(
  rates : Array[SpeciesRate],
  terms : Array[ReactionTerm],
) -> Double {
  let mut limiting = 1.0e30
  let mut has_reactant = false
  let mut missing_reactant = false
  for term in terms {
    if term.coefficient < 0.0 {
      has_reactant = true
      let (found, rate) = available_rate(rates, term.species.id)
      if !found {
        missing_reactant = true
      } else {
        limiting = limiting.min(rate / term.coefficient.abs())
      }
    }
  }
  if !has_reactant || missing_reactant {
    0.0
  } else {
    limiting.max(0.0)
  }
}

///|
pub fn reaction_conversion(
  initial_molar_flow : Double,
  coefficient : Double,
  extent_mol_per_s : Double,
) -> Double {
  if initial_molar_flow <= 0.0 || coefficient >= 0.0 {
    0.0
  } else {
    (extent_mol_per_s * coefficient.abs() / initial_molar_flow)
    .max(0.0)
    .min(1.0)
  }
}

///|
pub fn reaction_extent_for_conversion(
  initial_molar_flow : Double,
  coefficient : Double,
  conversion : Double,
) -> Double {
  if initial_molar_flow <= 0.0 || coefficient >= 0.0 {
    0.0
  } else {
    initial_molar_flow * conversion.max(0.0).min(1.0) / coefficient.abs()
  }
}

///|
pub fn reaction_heat_per_mass(
  terms : Array[ReactionTerm],
  extent_mol_per_s : Double,
  total_mass_flow_kg_per_s : Double,
) -> Double {
  if total_mass_flow_kg_per_s <= 0.0 {
    0.0
  } else {
    reaction_duty(terms, extent_mol_per_s) / total_mass_flow_kg_per_s
  }
}

///|
pub fn species_rate(rates : Array[SpeciesRate], id : String) -> Double {
  let (_, rate) = available_rate(rates, id)
  rate
}

///|
pub fn apply_reaction(
  rates : Array[SpeciesRate],
  terms : Array[ReactionTerm],
  requested_extent : Double,
) -> Array[SpeciesRate] {
  let extent = requested_extent
    .max(0.0)
    .min(limiting_reaction_extent(rates, terms))
  let output : Array[SpeciesRate] = []
  for rate in rates {
    let mut coefficient = 0.0
    for term in terms {
      if term.species.id == rate.species.id {
        coefficient += term.coefficient
      }
    }
    output.push({
      species: rate.species,
      molar_flow: (rate.molar_flow + coefficient * extent).max(0.0),
    })
  }
  for term in terms {
    let (found, _) = available_rate(rates, term.species.id)
    if !found && term.coefficient > 0.0 {
      output.push({
        species: term.species,
        molar_flow: term.coefficient * extent,
      })
    }
  }
  output
}

///|
pub fn reaction_mass_flow(rates : Array[SpeciesRate]) -> Double {
  let mut total = 0.0
  for rate in rates {
    total += molar_flow_to_mass_flow(rate.molar_flow, rate.species.molar_mass)
  }
  total
}

///|
pub fn species_rate_array_total(rates : Array[SpeciesRate]) -> Double {
  let mut total = 0.0
  for rate in rates {
    total += rate.molar_flow.max(0.0)
  }
  total
}
