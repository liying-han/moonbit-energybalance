///|
pub enum ValidationIssue {
  NegativeFlow(String)
  EmptyStream(String)
  NonPositiveTemperature(String)
  InvalidFraction(Double)
} derive(Debug)

///|
pub fn validate_stream(stream : Stream) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []
  if stream.components.length() == 0 {
    issues.push(EmptyStream(stream.id))
  }
  if stream.temperature <= 0.0 {
    issues.push(NonPositiveTemperature(stream.id))
  }
  for component in stream.components {
    if component.molar_flow < 0.0 {
      issues.push(NegativeFlow(stream.id))
    }
  }
  issues
}

///|
pub fn validate_fraction(value : Double) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []
  if value < 0.0 || value > 1.0 {
    issues.push(InvalidFraction(value))
  }
  issues
}

///|
pub fn has_issues(issues : Array[ValidationIssue]) -> Bool {
  issues.length() > 0
}

///|
pub fn issue_count_for_streams(streams : Array[Stream]) -> Int {
  let mut total = 0
  for stream in streams {
    total += validate_stream(stream).length()
  }
  total
}
