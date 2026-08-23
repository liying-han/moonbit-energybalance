///|
pub(all) enum AuditFindingCode {
  BalanceResidual
  InvalidStream
  EmptyInlet
  EmptyOutlet
  NegativeDuty
} derive(Debug, Eq)

///|
pub struct AuditFinding {
  code : AuditFindingCode
  message : String
  magnitude : Double
} derive(Debug)

///|
pub struct AuditReport {
  accepted : Bool
  finding_count : Int
  residual : Double
  findings : Array[AuditFinding]
} derive(Debug)

///|
pub fn audit_process(
  inlets : Array[Stream],
  outlets : Array[Stream],
  heat_duty_w : Double,
) -> AuditReport {
  let findings : Array[AuditFinding] = []
  if inlets.length() == 0 {
    findings.push({
      code: EmptyInlet,
      message: "no inlet stream",
      magnitude: 0.0,
    })
  }
  if outlets.length() == 0 {
    findings.push({
      code: EmptyOutlet,
      message: "no outlet stream",
      magnitude: 0.0,
    })
  }
  let validation = validate_process(inlets)
  for issue in validation.issues {
    findings.push({
      code: InvalidStream,
      message: issue.message,
      magnitude: 1.0,
    })
  }
  let result = steady_state_balance(
    inlets,
    outlets,
    terms=BalanceTerms(heat=heat_duty_w),
  )
  let residual = result.residual
  if residual.abs() > 1.0e-6 {
    findings.push({
      code: BalanceResidual,
      message: "energy balance residual exceeds tolerance",
      magnitude: residual.abs(),
    })
  }
  if heat_duty_w < 0.0 && inlets.length() == 0 {
    findings.push({
      code: NegativeDuty,
      message: "cooling duty has no inlet basis",
      magnitude: heat_duty_w.abs(),
    })
  }
  {
    accepted: findings.length() == 0,
    finding_count: findings.length(),
    residual,
    findings,
  }
}

///|
pub fn audit_has_code(report : AuditReport, code : AuditFindingCode) -> Bool {
  for finding in report.findings {
    if finding.code == code {
      return true
    }
  }
  false
}

///|
pub fn audit_summary(report : AuditReport) -> String {
  if report.accepted {
    "audit: accepted, residual=\{report.residual} W"
  } else {
    "audit: rejected, findings=\{report.finding_count}, residual=\{report.residual} W"
  }
}

///|
pub fn audit_maximum_magnitude(report : AuditReport) -> Double {
  let mut maximum = 0.0
  for finding in report.findings {
    maximum = maximum.max(finding.magnitude)
  }
  maximum
}

///|
pub fn audit_reports_accepted(reports : Array[AuditReport]) -> Bool {
  for report in reports {
    if !report.accepted {
      return false
    }
  }
  true
}

///|
pub fn audit_report_count_by_code(
  reports : Array[AuditReport],
  code : AuditFindingCode,
) -> Int {
  let mut total = 0
  for report in reports {
    for finding in report.findings {
      if finding.code == code {
        total += 1
      }
    }
  }
  total
}
