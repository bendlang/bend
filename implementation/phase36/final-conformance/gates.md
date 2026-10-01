# Phase35 final gate closure

Correctness closure: PASS.

| Gate | Status | Observed scope |
|---|---|---|
| checked-build-focused | passed | {"probes":36} |
| frontend-main | passed | {"exact":3026,"statuses":{"observed":497,"pass":2525,"fail":4},"candidateWorkers":1,"heapMb":1024,"rssLimitMb":1024} |
| frontend-broader | passed | {"exact":196,"statuses":{"observed":1,"pass":195},"candidateWorkers":1,"heapMb":1024,"rssLimitMb":1024} |
| backend-pilot | passed | {"exact":81,"counts":{"pass":69,"not-applicable":8,"fail":4}} |
| primitive | passed | {"totalScalarChecks":56205,"observations":58} |
| worker | passed | {"scalarChecks":3759,"observations":14} |
| nested | passed | {"checks":144,"observations":null} |
| primitive-guards | passed | {"guards":1129,"observations":25} |
| upstream-selected | passed | {"probes":15} |
| corpus | passed | {"libraries":23,"points":127} |
| worker-admission | passed | {"guards":40,"executionWitnesses":2} |
| component | passed | {"observations":22} |
| hvm | passed | {"stdoutBytes":42} |
| phase35-owner-controls | passed | {"groups":15} |
| installed-ordinary-relocated-cli | passed | {"checks":42} |

Canonical source: matches the checked attempt.

A broader-report override selects a separately preserved retry receipt; it does not relax scope, checked-attempt identity, exact agreement, worker health or memory checks.

Fresh frontend/backend workers are serial with 1024 MiB V8 heap allowances and 4 MiB stacks. Heap limits are not RSS limits; root supervises process-tree memory separately. Retained reference acquisitions keep their original resource provenance.

Installation, installed verification and 42 CLI checks remain separate post-install actions. Measurement/regression admission and independent release review remain separate decisions. All missing/invalid reports and exact errors are retained in gates.json.
