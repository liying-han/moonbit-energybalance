///|
pub(all) enum ProcessIssueCode {
  EmptyProcess
  DuplicateStreamId
  NegativeFlowValue
  InvalidTemperatureValue
  EmptyComponentList
  InvalidComposition
} derive(Debug, Eq)

///|
pub struct ProcessIssue {
  code : ProcessIssueCode
  stream_id : String
  message : String
} derive(Debug)

///|
pub struct ProcessValidationReport {
  valid : Bool
  issue_count : Int
  issues : Array[ProcessIssue]
} derive(Debug)

///|
pub fn ProcessValidationReport::has_code(
  self : ProcessValidationReport,
  code : ProcessIssueCode,
) -> Bool {
  for issue in self.issues {
    if issue.code == code {
      return true
    }
  }
  false
}

///|
fn validation_id_seen(ids : Array[String], id : String) -> Bool {
  for current in ids {
    if current == id {
      return true
    }
  }
  false
}

///|
fn stream_component_sum(stream : Stream) -> Double {
  let mut total = 0.0
  for component in stream.components {
    total += component.molar_flow
  }
  total
}

///|
pub fn validate_process(streams : Array[Stream]) -> ProcessValidationReport {
  let issues : Array[ProcessIssue] = []
  let ids : Array[String] = []
  if streams.length() == 0 {
    issues.push({
      code: EmptyProcess,
      stream_id: "",
      message: "the process contains no streams",
    })
  }
  for stream in streams {
    if validation_id_seen(ids, stream.id) {
      issues.push({
        code: DuplicateStreamId,
        stream_id: stream.id,
        message: "stream id is repeated",
      })
    } else {
      ids.push(stream.id)
    }
    if stream.components.length() == 0 {
      issues.push({
        code: EmptyComponentList,
        stream_id: stream.id,
        message: "stream has no components",
      })
    }
    if stream.temperature <= 0.0 {
      issues.push({
        code: InvalidTemperatureValue,
        stream_id: stream.id,
        message: "temperature must be above absolute zero",
      })
    }
    for component in stream.components {
      if component.molar_flow < 0.0 {
        issues.push({
          code: NegativeFlowValue,
          stream_id: stream.id,
          message: "component flow cannot be negative",
        })
      }
    }
    let total = stream_component_sum(stream)
    if total > 0.0 {
      let mut fraction_sum = 0.0
      for component in stream.components {
        fraction_sum += component.molar_flow / total
      }
      if (fraction_sum - 1.0).abs() > 1.0e-9 {
        issues.push({
          code: InvalidComposition,
          stream_id: stream.id,
          message: "component fractions do not close to one",
        })
      }
    }
  }
  { valid: issues.length() == 0, issue_count: issues.length(), issues }
}

///|
pub fn validation_summary(report : ProcessValidationReport) -> String {
  if report.valid {
    "process validation: valid"
  } else {
    "process validation: {report.issue_count} issue(s)"
  }
}

///|
pub fn validate_temperature_range(
  temperatures : Array[Double],
  lower_k : Double,
  upper_k : Double,
) -> Int {
  let mut errors = 0
  for temperature in temperatures {
    if temperature < lower_k || temperature > upper_k {
      errors += 1
    }
  }
  errors
}

///|
pub fn validate_positive_values(values : Array[Double]) -> Int {
  let mut errors = 0
  for value in values {
    if value <= 0.0 {
      errors += 1
    }
  }
  errors
}

///|
pub fn validate_monotonic(values : Array[Double], increasing : Bool) -> Bool {
  if values.length() < 2 {
    true
  } else {
    let mut valid = true
    for i in 0..<(values.length() - 1) {
      if increasing && values[i + 1] < values[i] {
        valid = false
      }
      if !increasing && values[i + 1] > values[i] {
        valid = false
      }
    }
    valid
  }
}

///|
pub fn validation_issue_count(reports : Array[ProcessValidationReport]) -> Int {
  let mut total = 0
  for report in reports {
    total += report.issue_count
  }
  total
}

///|
pub fn all_processes_valid(reports : Array[ProcessValidationReport]) -> Bool {
  for report in reports {
    if !report.valid {
      return false
    }
  }
  true
}
