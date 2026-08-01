///|
pub(all) enum Phase {
  Solid
  Liquid
  Vapor
  UnknownPhase
} derive(Debug, Eq)

///|
pub(all) enum CpModel {
  Constant(Double)
  Linear(Double, Double)
  Polynomial(Double, Double, Double, Double)
} derive(Debug)

///|
pub(all) enum PhaseChangeDirection {
  Melt
  Freeze
  Vaporize
  Condense
} derive(Debug, Eq)

///|
pub struct LatentHeat {
  transition_temperature : Double
  heat : Double
  direction : PhaseChangeDirection
} derive(Debug)

///|
pub struct Substance {
  id : String
  name : String
  phase : Phase
  cp_model : CpModel
  reference_temperature : Double
  formation_enthalpy : Double
  latent_heats : Array[LatentHeat]
} derive(Debug)

///|
pub struct ComponentFlow {
  substance : Substance
  molar_flow : Double
} derive(Debug)

///|
pub struct Stream {
  id : String
  temperature : Double
  components : Array[ComponentFlow]
} derive(Debug)

///|
pub struct BalanceTerms {
  heat : Double
  shaft_work : Double
  kinetic : Double
  potential : Double
} derive(Debug)

///|
pub struct BalanceResult {
  inlet_enthalpy_flow : Double
  outlet_enthalpy_flow : Double
  heat : Double
  shaft_work : Double
  residual : Double
} derive(Debug)

///|
pub struct HeatExchangerResult {
  hot_out : Stream
  cold_out : Stream
  duty : Double
  lmtd : Double
  ua : Double
  heat_recovery_fraction : Double
} derive(Debug)

///|
pub struct UtilityEstimate {
  name : String
  duty : Double
  required_flow : Double
  inlet_temperature : Double
  outlet_temperature : Double
} derive(Debug)

///|
pub struct HeaterResult {
  outlet : Stream
  duty : Double
} derive(Debug)

///|
pub struct FlashResult {
  vapor : Stream
  liquid : Stream
  duty : Double
  vapor_fraction : Double
} derive(Debug)
