///|
fn reaction_close(
  actual : Double,
  expected : Double,
  tolerance : Double,
) -> Bool {
  (actual - expected).abs() <= tolerance
}

///|
test "reaction heat and limiting extent use stoichiometric coefficients" {
  let methane = ReactionSpecies::ReactionSpecies(
    id="methane",
    molar_mass=16.04,
    formation_enthalpy_kj_per_mol=-74.85,
  )
  let oxygen = ReactionSpecies::ReactionSpecies(
    id="oxygen",
    molar_mass=32.0,
    formation_enthalpy_kj_per_mol=0.0,
  )
  let carbon_dioxide = ReactionSpecies::ReactionSpecies(
    id="carbon-dioxide",
    molar_mass=44.01,
    formation_enthalpy_kj_per_mol=-393.51,
  )
  let water = ReactionSpecies::ReactionSpecies(
    id="water-vapor",
    molar_mass=18.015,
    formation_enthalpy_kj_per_mol=-241.826,
  )
  let terms = [
    ReactionTerm::ReactionTerm(species=methane, coefficient=-1.0),
    ReactionTerm::ReactionTerm(species=oxygen, coefficient=-2.0),
    ReactionTerm::ReactionTerm(species=carbon_dioxide, coefficient=1.0),
    ReactionTerm::ReactionTerm(species=water, coefficient=2.0),
  ]
  assert_true(reaction_close(reaction_enthalpy(terms), -802.31, 0.01))
  let available = [
    SpeciesRate::SpeciesRate(species=methane, molar_flow=3.0),
    SpeciesRate::SpeciesRate(species=oxygen, molar_flow=4.0),
  ]
  assert_true(
    reaction_close(limiting_reaction_extent(available, terms), 2.0, 1.0e-12),
  )
  assert_true(reaction_close(reaction_duty(terms, 2.0), -1604620.0, 10.0))
}

///|
test "reaction application preserves nonreactive species and clamps extent" {
  let a = ReactionSpecies::ReactionSpecies(
    id="a",
    molar_mass=10.0,
    formation_enthalpy_kj_per_mol=0.0,
  )
  let b = ReactionSpecies::ReactionSpecies(
    id="b",
    molar_mass=20.0,
    formation_enthalpy_kj_per_mol=0.0,
  )
  let terms = [
    ReactionTerm::ReactionTerm(species=a, coefficient=-1.0),
    ReactionTerm::ReactionTerm(species=b, coefficient=1.0),
  ]
  let rates = apply_reaction(
    [
      SpeciesRate::SpeciesRate(species=a, molar_flow=2.0),
      SpeciesRate::SpeciesRate(species=b, molar_flow=3.0),
    ],
    terms,
    5.0,
  )
  assert_true(reaction_close(species_rate(rates, "a"), 0.0, 1.0e-12))
  assert_true(reaction_close(species_rate(rates, "b"), 5.0, 1.0e-12))
}

///|
test "network propagation preserves split flow and reports missing inputs" {
  let source = process_water_stream(
    id="feed",
    molar_flow=10.0,
    temperature=300.0,
  )
  let connections = [
    NetworkConnection::NetworkConnection(
      source_id="feed",
      target_id="heater",
      fraction=1.0,
    ),
    NetworkConnection::NetworkConnection(
      source_id="heater",
      target_id="product-a",
      fraction=0.4,
    ),
    NetworkConnection::NetworkConnection(
      source_id="heater",
      target_id="product-b",
      fraction=0.6,
    ),
    NetworkConnection::NetworkConnection(
      source_id="missing",
      target_id="orphan",
      fraction=1.0,
    ),
  ]
  let result = propagate_network(source, connections, 12)
  assert_true(result.streams.length() == 4)
  assert_true(
    reaction_close(stream_rate(result.streams, "product-a"), 4.0, 1.0e-12),
  )
  assert_true(
    reaction_close(
      network_flow_residual(result, source.molar_flow()),
      0.0,
      1.0e-12,
    ),
  )
  assert_true(result.unresolved_connections == 1)
}

///|
test "recycle fixed point reports convergence and nonconvergence" {
  let converged = solve_recycle_temperature(300.0, 0.5, 48, 1.0e-8)
  assert_true(converged.converged)
  assert_true(reaction_close(converged.value, 600.0, 1.0e-6))
  let stopped = solve_recycle_temperature(300.0, 1.1, 8, 1.0e-12)
  assert_true(!stopped.converged)
}
