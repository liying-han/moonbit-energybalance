// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "2515050243qyf/moonbit-energybalance"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/liying-han/moonbit-energybalance"

license = "Apache-2.0"

keywords = [
  "energy-balance",
  "enthalpy",
  "heat-exchanger",
  "thermodynamics",
  "process-engineering",
]

preferred_target = "wasm-gc"

description = "A MoonBit library for steady-state process energy balance, enthalpy flow, heat duty, phase change, and utility estimates."
