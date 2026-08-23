///|
pub struct StreamSnapshot {
  id : String
  temperature : Double
  molar_flow : Double
  enthalpy_flow : Double
  heat_capacity_flow : Double
  component_count : Int
} derive(Debug)

///|
pub struct StreamAggregate {
  count : Int
  total_molar_flow : Double
  total_enthalpy_flow : Double
  weighted_temperature : Double
  total_heat_capacity_flow : Double
} derive(Debug)

///|
pub fn snapshot_stream(stream : Stream) -> StreamSnapshot {
  {
    id: stream.id,
    temperature: stream.temperature,
    molar_flow: stream.molar_flow(),
    enthalpy_flow: stream.enthalpy_flow(),
    heat_capacity_flow: stream.heat_capacity_flow(),
    component_count: stream.component_count(),
  }
}

///|
pub fn snapshot_streams(streams : Array[Stream]) -> Array[StreamSnapshot] {
  let snapshots : Array[StreamSnapshot] = []
  for stream in streams {
    snapshots.push(snapshot_stream(stream))
  }
  snapshots
}

///|
pub fn aggregate_streams(streams : Array[Stream]) -> StreamAggregate {
  let mut total_flow = 0.0
  let mut total_enthalpy = 0.0
  let mut weighted_temperature = 0.0
  let mut heat_capacity = 0.0
  for stream in streams {
    let flow = stream.molar_flow().max(0.0)
    total_flow += flow
    total_enthalpy += stream.enthalpy_flow()
    weighted_temperature += stream.temperature * flow
    heat_capacity += stream.heat_capacity_flow()
  }
  {
    count: streams.length(),
    total_molar_flow: total_flow,
    total_enthalpy_flow: total_enthalpy,
    weighted_temperature: if total_flow <= 0.0 {
      0.0
    } else {
      weighted_temperature / total_flow
    },
    total_heat_capacity_flow: heat_capacity,
  }
}

///|
pub fn snapshot_csv_header() -> String {
  "id,temperature,molar_flow,enthalpy_flow,heat_capacity_flow,component_count"
}

///|
pub fn snapshot_csv_row(snapshot : StreamSnapshot) -> String {
  "\{snapshot.id},\{snapshot.temperature},\{snapshot.molar_flow},\{snapshot.enthalpy_flow},\{snapshot.heat_capacity_flow},\{snapshot.component_count}"
}

///|
pub fn snapshots_csv(snapshots : Array[StreamSnapshot]) -> String {
  let mut output = snapshot_csv_header() + "\n"
  for snapshot in snapshots {
    output = output + snapshot_csv_row(snapshot) + "\n"
  }
  output
}

///|
pub fn snapshot_delta(
  first : StreamSnapshot,
  second : StreamSnapshot,
) -> StreamSnapshot {
  {
    id: second.id,
    temperature: second.temperature - first.temperature,
    molar_flow: second.molar_flow - first.molar_flow,
    enthalpy_flow: second.enthalpy_flow - first.enthalpy_flow,
    heat_capacity_flow: second.heat_capacity_flow - first.heat_capacity_flow,
    component_count: second.component_count - first.component_count,
  }
}

///|
pub fn snapshot_relative_change(first : Double, second : Double) -> Double {
  if first.abs() < 1.0e-12 {
    0.0
  } else {
    (second - first) / first.abs()
  }
}

///|
pub fn process_total_heat_capacity(streams : Array[Stream]) -> Double {
  let mut total = 0.0
  for stream in streams {
    total += stream.heat_capacity_flow()
  }
  total
}

///|
pub fn process_total_mass_flow(
  streams : Array[Stream],
  molar_mass_g_per_mol : Double,
) -> Double {
  molar_flow_to_mass_flow(
    aggregate_streams(streams).total_molar_flow,
    molar_mass_g_per_mol,
  )
}

///|
pub fn process_temperature_range(streams : Array[Stream]) -> (Double, Double) {
  if streams.length() == 0 {
    (0.0, 0.0)
  } else {
    let mut low = streams[0].temperature
    let mut high = streams[0].temperature
    for stream in streams {
      low = low.min(stream.temperature)
      high = high.max(stream.temperature)
    }
    (low, high)
  }
}

///|
pub fn process_isothermal(streams : Array[Stream], tolerance : Double) -> Bool {
  let (low, high) = process_temperature_range(streams)
  (high - low).abs() <= tolerance.abs()
}
