# Phase14 derivation and usable-release validation

**All final helper and installed-release controls pass.** The installed and
relocated package both identify combined-01 API
`9136be92928eda4b3b8e9c99e4e35d62504a825b458ff237c514d4e99f21206b`.
Root owns integration and installation; these controls are separate from its full
frontend, backend, saved-history and controlled timing gates.

## Maintained derivation and authentic replay

`selfhost/build/phase14/helper-gates-01/report.json` is complete and passing.
The launcher uses unchanged maintained `equality.test.mjs` and `equality.mjs`,
bound to combined-01's genuine checked B1 and bootstrap report. Its precondition
is the combined 26-case focused gate, including four imported-law trust controls.

All **16 unchanged test groups** pass, including refusal of mutated protected
runtime/helper bindings, lazy branch demand, trampoline depth, provenance failures
and artifact drift. The tests deliberately create and remove temporary mutated
images; the maintained test source and completed assertions are preserved, not
presented as released compiler attempts.

All **five replay checks** pass: verification of the current combined version 5
derivative, authentic version 1/3/4 releases and the version 2 derivation. These
reuse Phase12's replay tool, original historical images and recorded lineage;
expected outputs are not regenerated from the current helper. They establish
exact reproducibility for those artifacts, not a compiler fixed point or arbitrary
transformation correctness.

Both supervised processes exit 0 with no spawn error, signal, timeout or output
overflow. The helper/test bytes equal the combined attempt's frozen copies, and
all recorded inputs remain unchanged after execution. CPU 2, Node 24.18.0,
4 MiB stack and 4 GiB heap are explicit. Consumed launchers and input identities
are retained with the results.

## Installed and relocated compiler

After root installed the validated combined API, the prepared runner executed
at `selfhost/build/phase14/release-smoke-01`. Its `launcher.json` is complete and
passing; `checks/report.json` records **42 passing checks**, 21 per package:

- Release integrity before and after, and the CLI version.
- Checking and interpretation for Base-U32, user `Clo.apply` and compact Nat.
- JS emission and actual execution of every emitted program.
- CPU C emission, actual Clang build and native execution of every program.

All expected program output matches. All child exits are 0 with no recorded spawn
error, signal, timeout or output overflow. The outer supervised launcher also
exits cleanly. Eighteen generated JS/C/native artifacts are retained across the
two packages; they are execution evidence, not a generated-code speed measurement.

The installed release manifest SHA-256 is
`7b39fc8af133881da4cfd6f6e2362388b7b32943470ea44a63fb12ef2737e70e`.
Clang16 is the existing pinned local toolchain, binary SHA-256
`8a3f27cb0d8904a46986cbcc6437c2049939204d1c9f7caa3898c36ba067c0e2`.
Its actual paths and include/library environment are recorded. The runner
inherits and verifies CPU 2 affinity; Node resources remain 4 MiB stack/4 GiB heap.

The copied package contains **127 required files**, exactly checked against its
original inputs. It includes no upstream checkout, creates none during the run,
and receives no `BEND_*` overrides. No ordinary package input, copied input or
fixture changes during validation. Historical absolute provenance remains data;
this demonstrates package relocation, not filesystem-access isolation.

## Runner origin and closure

The Phase12 42-check runner was adapted before installation, with its original
identity and prepared bytes retained under
`selfhost/build/phase14/release-smoke-prepare-01`. Changes are the Phase14 label,
explicit runtime API identity and fresh output directory, asserted CPU 2 affinity,
and explicit timeout/output-size outcome flags alongside existing exit, signal
and spawn guards. The new outer launcher captures supervision and requires root's
exact installed API identity. The same three program fixtures and 42 checks remain.

There were no failed helper or release-smoke launches in this workstream.
All producers are closed; the Phase14 evidence capsule can now capture these
reports, consumed tools, relocated files, generated programs and prerequisites.
No new self-reproduction, proof-kernel, GPU or throughput claim follows from this
release validation.
