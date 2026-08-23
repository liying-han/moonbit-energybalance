///|
pub struct ScheduledUnit {
  id : String
  duration_h : Double
  predecessors : Array[String]
} derive(Debug)

///|
pub struct ScheduledEntry {
  id : String
  start_h : Double
  finish_h : Double
  slack_h : Double
} derive(Debug)

///|
pub struct ScheduleResult {
  entries : Array[ScheduledEntry]
  makespan_h : Double
  critical_unit_id : String
  feasible : Bool
} derive(Debug)

///|
pub fn ScheduledUnit::ScheduledUnit(
  id~ : String,
  duration_h~ : Double,
  predecessors~ : Array[String],
) -> ScheduledUnit {
  { id, duration_h: duration_h.max(0.0), predecessors }
}

///|
fn schedule_entry_for(
  entries : Array[ScheduledEntry],
  id : String,
) -> ScheduledEntry? {
  for entry in entries {
    if entry.id == id {
      return Some(entry)
    }
  }
  None
}

///|
fn schedule_has_id(ids : Array[String], id : String) -> Bool {
  for item in ids {
    if item == id {
      return true
    }
  }
  false
}

///|
pub fn schedule_network(units : Array[ScheduledUnit]) -> ScheduleResult {
  let entries : Array[ScheduledEntry] = []
  let mut feasible = true
  for unit in units {
    let mut start = 0.0
    for predecessor in unit.predecessors {
      match schedule_entry_for(entries, predecessor) {
        Some(entry) => start = start.max(entry.finish_h)
        None => feasible = false
      }
    }
    entries.push({
      id: unit.id,
      start_h: start,
      finish_h: start + unit.duration_h,
      slack_h: 0.0,
    })
  }
  let mut makespan = 0.0
  let mut critical = ""
  for entry in entries {
    if entry.finish_h >= makespan {
      makespan = entry.finish_h
      critical = entry.id
    }
  }
  let updated : Array[ScheduledEntry] = []
  for entry in entries {
    updated.push({ ..entry, slack_h: makespan - entry.finish_h })
  }
  {
    entries: updated,
    makespan_h: makespan,
    critical_unit_id: critical,
    feasible,
  }
}

///|
pub fn critical_entries(schedule : ScheduleResult) -> Array[ScheduledEntry] {
  let critical : Array[ScheduledEntry] = []
  for entry in schedule.entries {
    if entry.slack_h <= 1.0e-12 {
      critical.push(entry)
    }
  }
  critical
}

///|
pub fn schedule_duration(schedule : ScheduleResult, id : String) -> Double {
  match schedule_entry_for(schedule.entries, id) {
    Some(entry) => entry.finish_h - entry.start_h
    None => 0.0
  }
}

///|
pub fn schedule_contains_cycle(units : Array[ScheduledUnit]) -> Bool {
  let ids : Array[String] = []
  for unit in units {
    ids.push(unit.id)
  }
  for unit in units {
    for predecessor in unit.predecessors {
      if predecessor == unit.id || !schedule_has_id(ids, predecessor) {
        return true
      }
    }
  }
  false
}

///|
pub fn schedule_resource_hours(
  schedule : ScheduleResult,
  resource_count : Int,
) -> Double {
  if resource_count <= 0 {
    0.0
  } else {
    let mut total = 0.0
    for entry in schedule.entries {
      total += entry.finish_h - entry.start_h
    }
    total / resource_count.to_double()
  }
}

///|
pub fn schedule_entry_count(schedule : ScheduleResult) -> Int {
  schedule.entries.length()
}

///|
pub fn schedule_is_valid(schedule : ScheduleResult) -> Bool {
  schedule.feasible && !schedule_contains_cycle([])
}
