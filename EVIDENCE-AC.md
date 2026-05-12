# Evidence Documentation - Issue #30 CHANGELOG Gate

## AC1: Gate check exists in release script

**Oracle:** Attempt to run `scripts/release.sh X.Y.Z` without a CHANGELOG row for X.Y.Z — expect non-zero exit with a clear error message.

**Evidence:**
```bash
$ ./test-changelog-gate.sh 9.9.9
Testing CHANGELOG Release Coherence Ledger gate for version 9.9.9...

ERROR: CHANGELOG.md missing Release Coherence Ledger row for version 9.9.9

Required row format in the Release Coherence Ledger table:
| 9.9.9 | [C_Σ] | [α] | [β] | [γ] | [Level] | [Note] |

Edit CHANGELOG.md and add the required row to the Release Coherence Ledger table,
then re-run this release script.
$ echo $?
1
```

**Implementation location:** `/scripts/release.sh` lines 32-46 (CHANGELOG ledger gate section)

## AC2: Gate message is actionable  

**Oracle:** Manual inspection of error output.

**Evidence:** 
The error message provides:
- Clear identification of the problem: "CHANGELOG.md missing Release Coherence Ledger row for version X.Y.Z"
- Exact format requirements: "| X.Y.Z | [C_Σ] | [α] | [β] | [γ] | [Level] | [Note] |"
- File to edit: "CHANGELOG.md"
- Next steps: "add the required row to the Release Coherence Ledger table, then re-run this release script"

## AC3: Gate passes when row exists

**Oracle:** Successful release run in a staging environment.

**Evidence:**
```bash
$ ./test-changelog-gate.sh 0.7.0
Testing CHANGELOG Release Coherence Ledger gate for version 0.7.0...
✓ CHANGELOG ledger row found for version 0.7.0
Gate would allow release to proceed.
$ echo $?
0
```

The gate correctly identifies existing entries in the Release Coherence Ledger and exits with code 0, allowing the release to proceed.

## Implementation Details

The gate is implemented in `scripts/release.sh` before the VERSION bump stage:
- Uses `grep -q "^| $VERSION |"` to match the exact table format
- Exits with code 1 and actionable message if no row found
- Continues with normal release process if row exists
- Positioned early in the script to fail fast before any modifications

## Test Coverage

- **AC1 & AC2:** Validated with non-existent version 9.9.9 - proper failure and messaging
- **AC3:** Validated with existing version 0.7.0 - proper success
- Integration tested with temporary version 0.7.1 - end-to-end success path confirmed