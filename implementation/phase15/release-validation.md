# Phase15 release validation

The final `combined-02` candidate passes **16 maintained helper groups** and
**five authentic version1–5 replays** after verifying its **36 passing focused
cases**. After root installation, **all 42 ordinary and relocated release
checks pass** against the same selected API. Release integrity passes before
and after each group, with no changed release input or fixture.

The tested derived API is
`b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d`;
the untouched checked B1 is
`32ec77a35982f29d5e6f405a74236fdbff72810b8960459f1e26f4e3c126c1c9`.
Evidence: `selfhost/build/phase15/helper-gates-01/report.json`,
`tests-report.json`, and `replay/report.json`. Both supervised commands completed
with exit0 and no error, signal, timeout or output overflow. All bound inputs and
the final checked attempt were reverified after completion.

The tools adapt the retained Phase14 gates with unchanged oracles and resource
limits. The helper launcher now requires the final **36-case** focused gate to
have passed. It takes the checked attempt and a fresh output path as arguments,
verifies the checked B1 and guarded derivative, binds unchanged maintained helper
and test bytes, then runs the same **16 helper groups** and **five authentic
version1–5 replays**. Repository-relative historical replay inputs are resolved
from the repository root regardless of the launcher's caller directory.

The smoke launcher takes the installed project, fresh output path and expected
API SHA256. It verifies that exact API before launching the same **42 checks**:
21 in the ordinary checkout and 21 in a copied release without an upstream
checkout. Each location verifies release integrity before and after, checks the
CLI version, and checks/interprets/emits/runs three fixtures through JavaScript
and actual native CPU execution. The fixtures cover Base U32, a user definition
named `Clo.apply`, and compact Nat boundaries. Imported-law behavior and the new
parser/import witnesses remain covered by the separate frontend/backend gates.

Both launchers use CPU2, Node24.18.0, a 4MiB stack and 4GiB heap. The smoke runner
uses the preserved Clang16 toolchain and records exact stdout/stderr, all copied
release inputs, output identities and before/after integrity. It checks spawn
errors, signals, timeouts and output overflow in addition to process exit status.
All `BEND_*`, `NODE_OPTIONS` and `NODE_PATH` overrides are removed. Relocation
establishes operation without a copied/supplied upstream checkout, not OS-level
filesystem isolation or a universal portability claim.

Commands, with absolute arguments or paths relative to the current directory:

```sh
node selfhost/tools/performance/phase15/helper-gates.mjs CHECKED_ATTEMPT NEW_OUTPUT
node selfhost/tools/performance/phase15/release-smoke-launch.mjs SELFHOST_PROJECT NEW_OUTPUT EXPECTED_API_SHA256
```

No production/default compiler change is performed by these tools. The release
must already be installed by root before the smoke command runs. Both helper and installed smoke outcomes are complete. There is no failed helper
or release smoke attempt in this phase.

## Installed and relocated outcome

`selfhost/build/phase15/release-smoke-01/launcher.json` and
`checks/report.json` record all 42 passing steps against installed API
`b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d`.
All child launches are clean: no spawn error, signal, timeout or output overflow.
Actual inherited CPU affinity is exactly2. The copied package neither contains
nor creates an upstream checkout. Ordinary/relocated release files and original
fixtures retain their exact hashes.

All six interpreter executions, six emitted JavaScript executions and six native
executions produce their exact fixture outputs. The 18 emitted program artifacts
(JavaScript, C and native binary for each fixture/location) have retained
identities, together with every command and stdout/stderr file. The Base case
prints42; the user-owned `Clo.apply` case prints `False{}`; the Nat case matches
its complete declared oracle.

These results establish the recorded helper/version compatibility and normal/
relocated CLI behavior on the named Linux/Node/Clang setup. They do not establish
GPU/kernel behavior, a new self-hosted fixed point or general OS portability.
The final frontend and backend inventories are reported separately. All owned
validation producers and tools are closed for root's final evidence freeze.
