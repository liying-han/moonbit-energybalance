///|
pub struct NetworkConnection {
  source_id : String
  target_id : String
  fraction : Double
} derive(Debug)

///|
pub struct NetworkResult {
  streams : Array[Stream]
  terminal_ids : Array[String]
  iterations : Int
  converged : Bool
  unresolved_connections : Int
} derive(Debug)

///|
pub struct ConvergenceResult {
  value : Double
  iterations : Int
  residual : Double
  converged : Bool
} derive(Debug)

///|
pub fn NetworkConnection::NetworkConnection(
  source_id~ : String,
  target_id~ : String,
  fraction~ : Double,
) -> NetworkConnection {
  { source_id, target_id, fraction: fraction.max(0.0) }
}

///|
fn network_find_stream(streams : Array[Stream], id : String) -> Stream? {
  for stream in streams {
    if stream.id == id {
      return Some(stream)
    }
  }
  None
}

///|
fn network_has_id(ids : Array[String], id : String) -> Bool {
  for item in ids {
    if item == id {
      return true
    }
  }
  false
}

///|
pub fn network_terminal_ids(
  connections : Array[NetworkConnection],
) -> Array[String] {
  let sources : Array[String] = []
  for connection in connections {
    if !network_has_id(sources, connection.source_id) {
      sources.push(connection.source_id)
    }
  }
  let terminals : Array[String] = []
  for connection in connections {
    if !network_has_id(sources, connection.target_id) &&
      !network_has_id(terminals, connection.target_id) {
      terminals.push(connection.target_id)
    }
  }
  terminals
}

///|
pub fn propagate_network(
  source : Stream,
  connections : Array[NetworkConnection],
  max_iterations : Int,
) -> NetworkResult {
  let streams : Array[Stream] = [source]
  let limit = max_iterations.max(1)
  let mut iterations = 0
  let mut converged = false
  for _ in 0..<limit {
    iterations += 1
    let mut added = false
    for connection in connections {
      match network_find_stream(streams, connection.source_id) {
        Some(input) =>
          if network_find_stream(streams, connection.target_id) is None {
            streams.push(
              input
              .with_flow_factor(connection.fraction)
              .with_id(connection.target_id),
            )
            added = true
          }
        None => ()
      }
    }
    if !added {
      converged = true
      break
    }
  }
  let mut unresolved = 0
  for connection in connections {
    if network_find_stream(streams, connection.source_id) is None {
      unresolved += 1
    }
  }
  {
    streams,
    terminal_ids: network_terminal_ids(connections),
    iterations,
    converged,
    unresolved_connections: unresolved,
  }
}

///|
pub fn stream_rate(streams : Array[Stream], id : String) -> Double {
  match network_find_stream(streams, id) {
    Some(stream) => stream.molar_flow()
    None => 0.0
  }
}

///|
pub fn network_terminal_flow(result : NetworkResult) -> Double {
  let mut total = 0.0
  for id in result.terminal_ids {
    total += stream_rate(result.streams, id)
  }
  total
}

///|
pub fn network_flow_residual(
  result : NetworkResult,
  source_flow : Double,
) -> Double {
  network_terminal_flow(result) - source_flow
}

///|
pub fn solve_recycle_temperature(
  feed_temperature : Double,
  recycle_gain : Double,
  max_iterations : Int,
  tolerance : Double,
) -> ConvergenceResult {
  let mut value = feed_temperature
  let mut residual = 1.0e30
  let mut iterations = 0
  let mut converged = false
  for _ in 0..<max_iterations.max(1) {
    let next = feed_temperature + recycle_gain * value
    residual = (next - value).abs()
    value = next
    iterations += 1
    if residual <= tolerance.max(0.0) {
      converged = true
      break
    }
  }
  { value, iterations, residual, converged }
}

///|
pub fn network_energy_residual(
  inlets : Array[Stream],
  outlets : Array[Stream],
) -> Double {
  enthalpy_flow_sum(inlets) - enthalpy_flow_sum(outlets)
}

///|
pub fn network_stream_count(result : NetworkResult) -> Int {
  result.streams.length()
}
