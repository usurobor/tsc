# Repository Coherence CM — requirements

Stable parent requirement IDs. IDs are permanent; wording may sharpen. The
parent contract is [`CM.md`](./CM.md); the registry is [`ASPECTS.md`](./ASPECTS.md).

| ID | Requirement |
|---|---|
| `RCM-SNAPSHOT-001` | Every child receipt binds the same exact repository commit. |
| `RCM-SELECTION-001` | Every requested aspect either executes or is explicitly reported as unimplemented/incomplete. |
| `RCM-RECEIPT-001` | Every executed aspect returns an evidence-bound categorical receipt satisfying the generic envelope, including a `result_class` in `{PASS, DEFECT, INCOMPLETE, FAILED}` mapped from the child's own `status`. |
| `RCM-COVERAGE-001` | Every composite claim names exactly which aspects and profiles it covers. |
| `RCM-CONFLICT-001` | Cross-aspect disagreement is retained and surfaced, never averaged away. |
| `RCM-NO-AGGREGATE-001` | No scalar or parent verdict may erase a child finding. |
| `RCM-BOUNDARY-001` | Parent and child CMs measure only; repair and independent review remain separate invocations. |
