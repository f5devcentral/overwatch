when RULE_INIT {
  #debug logging flag
  set debug 0
}
 
when HTTP_REQUEST {
  # get LTM policy matched rule and chosen ASM security policy
  set policy [POLICY::names matched]
  if { $debug } {
    log local0. "Matched policy [POLICY::names matched]"
    log local0. "Matched rule in policy [POLICY::rules matched]"
    log local0. "ASM policy [ASM::policy] enforcing"
  }
}
 
when ASM_REQUEST_DONE {
  # define custom violation conditions
  # user-defined violation: VIOLATION_TOO_MANY_VIOLATIONS
  set violationName "VIOLATION_TOO_MANY_VIOLATIONS"
  if {[ASM::violation count] > 20 and [ASM::severity] eq "Error"} {
    ASM::raise $violationName
  }
  # user-defined violation: X
  # debug logging
  if { $debug } {
    log local0. "SupportID: [ASM::support_id];"
    log local0. "Request Status: [ASM::status];"
    log local0. "Severity: [ASM::severity];"
    log local0. "ClientIP: [ASM::client_ip];"
    log local0. "Number Violations: [ASM::violation count]"
    log local0. "Violations Names: [ASM::violation names];"
    log local0. "Attack Types: [ASM::violation attack_types];"
    log local0. "Violation details: [ASM::violation details];"
  }
}

when ASM_REQUEST_VIOLATION {
  if { $debug } {
    log local0. "SupportID: [ASM::support_id];"
    log local0. "Request Status: [ASM::status];"
    log local0. "Severity: [ASM::severity];"
    log local0. "ClientIP: [ASM::client_ip];"
    log local0. "Number Violations: [ASM::violation count]"
    log local0. "Violations Names: [ASM::violation names];"
    log local0. "Attack Types: [ASM::violation attack_types];"
    log local0. "Violation details: [ASM::violation details];"
  }
}

when ASM_RESPONSE_VIOLATION {
  if { $debug } {
    log local0. "SupportID: [ASM::support_id];"
    log local0. "Request Status: [ASM::status];"
    log local0. "Severity: [ASM::severity];"
    log local0. "ClientIP: [ASM::client_ip];"
    log local0. "Number Violations: [ASM::violation count]"
    log local0. "Violations Names: [ASM::violation names];"
    log local0. "Attack Types: [ASM::violation attack_types];"
    log local0. "Violation details: [ASM::violation details];"
  }
}

when ASM_REQUEST_BLOCKING {
  if { $debug } {
    log local0. "SupportID: [ASM::support_id];"
    log local0. "Request Status: [ASM::status];"
    log local0. "Severity: [ASM::severity];"
    log local0. "ClientIP: [ASM::client_ip];"
    log local0. "Number Violations: [ASM::violation count]"
    log local0. "Violations Names: [ASM::violation names];"
    log local0. "Attack Types: [ASM::violation attack_types];"
    log local0. "Violation details: [ASM::violation details];"
  }
}