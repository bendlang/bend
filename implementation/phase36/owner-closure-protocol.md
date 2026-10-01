# Explicit final-image owner closure

`selfhost/tools/performance/phase36/owner-close.py` accepts five positional inputs:

```text
FINAL_ATTEMPT FINAL_CATALOG_BUNDLE FINAL_COHORT_DIRECTORY MAPPING_JSON NEW_REPORT_JSON
```

The mapping is an object with these exact keys: `guardcolf`, `guardscope`,
`error`, `array`, `producerfixture`, `producerreviewed`; add `selector` when the
frozen producer source contains the selector extension. Values are completed
`report.json` paths, absolute or relative to the repository root. The program
does not execute any compiler or tests. Failed audits produce an incomplete
report at the new output path; retries require another output path.

This supplements the inherited final gate audit. It requires one checked B1
attempt/API/runtime/Base/driver identity throughout the catalog and fixture
emissions, checked/type-accepted/successful source observations, unchanged
artifact hashes, and the actual complete-root purity gate in frozen source.
Historical attempt identities verify their frozen sources rather than requiring
their original live source paths to remain unchanged.

Each owner result must consume the final candidate module for its intended
fixture. Guard diagnostic controls must descend from the checked-cohort adapter,
whose candidate receipt binds the final ray module and whose tested `partial`
module is listed in the owner inputs. A saved-output optimizer prototype cannot
substitute for that checked adapter. The producer/selector diagnostic parents
must name the final raw candidate emission. Identity edges through manifests,
emission receipts and diagnostic parents are rehashed, including a final pass
over every observed artifact. Named gate kinds and expected nonempty observation
counts are explicit, not inferred merely from a `pass` boolean.

The tool intentionally does not install a release, compare live canonical source
against the final snapshot, or replace inherited broad semantic controls. The
existing final canonical/conformance audit remains responsible for those tasks.
It was prepared without execution; root must retain any audit failures and
successor fixes rather than weakening a gate to make closure green.
