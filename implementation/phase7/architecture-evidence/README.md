# Architectural experiment evidence

See the [comparative report](../architecture-report.md) and the prospective
[design](../../../design/phase7/architectural_experiments.md). These are research
components and a separate full compiler candidate. None changes the default
compiler. Production source identity remains the S4 B02 baseline in
[baseline.json](baseline.json).

## Read the results

- [Checked output](checked-output/report.md): checked B1, direct execution controls,
  source accounting and separate verification/compile-preparation timing.
- [Semantic values](semantic-values/report.md): actual checked components,
  successive failing and corrected demand/quotation controls, scoped normalization
  timing and retained machinery.
- [Shared binding traversal](binding-schema/report.md): checked component,
  freshening/shift controls, replacement budget and the rejected runtime walker.
- [Independent semantic review](checked-output/semantic-values-independent-review.md):
  source review of immutable candidate05; later status belongs to the A02 report.
- [Research source counts](research-source-counts.json): prototypes, harnesses and
  snapshots kept separate from unchanged production source.

## Archive and integrity

[raw.tar.gz](raw.tar.gz) preserves every regular file in the raw experiment root
`selfhost/build/phase7/architecture/` at closure. [manifest.json](manifest.json)
lists each member's SHA-256 and size; [verification.json](verification.json)
records reopening the archive and checking every byte. No symlink, absolute
member path, duplicate member or `..` path is accepted. The archive contains:

- Baseline checked API/runtime/release inputs and final source/release integrity
  observations; the unchanged optimized default is bound by baseline hashes.
- A01's full project copy, genuine checked attempt, focused controls, nine pairs
  of emitted programs and eight fresh timing workers.
- A03's complete component build, successive controls, original/corrected frozen
  workload generators and both measurements. The first malformed-arity workload
  remains labelled unsuitable for the intended performance claim.
- All seven A02 component preparations/build/control attempts, both sets of
  candidate05 demand witnesses, final candidate07 residual probes and eight
  normalization benchmark workers. The final All-domain demand failure remains
  unresolved; the codomain probe times out on both variants. Setup failures and
  timed-out children remain failures in their original records.
- The final research source snapshot and cross-experiment integrity audit.

From the repository root, verify without extracting or executing archived code:

```sh
python3 implementation/phase7/architecture-evidence/preserve.py verify selfhost/build/phase7/architecture implementation/phase7/architecture-evidence
```

The second argument is the historical raw root; `verify` does not need it to
exist. After verification, extract into a new directory:

```sh
mkdir /tmp/bend-architecture-review
tar -xzf implementation/phase7/architecture-evidence/raw.tar.gz -C /tmp/bend-architecture-review
```

Members live below `raw/`. Historical absolute paths inside JSON are original
identities, not relocatable commands. Rebuild using new output directories and
the current checkout's absolute paths; do not overwrite preserved attempts.

## Execution dependencies and reconstruction

Use Node24.18.0, Linux `taskset` with CPU0 available, and the pinned upstream
checkout at `selfhost/.bootstrap/upstream`, revision
`6018e28ecc67cf1fffc0c20c64b11023474c2df8`. The
[compiler guide](../../../docs/BEND-IN-BEND.md#rebuild-the-default) describes
obtaining it. The archive does not contain Node, the OS or an entire upstream
Git checkout. Build records bind the consumed upstream Bend/TypeScript/Base
files by hash; this is not a claim of bit-reproducible timing on another machine.

A02 and A03 reports provide fresh-path component build/test/timing commands.
`build-component.mjs` checks the pinned revision, freezes source/tools, actually
checks the complete assembled component before emission, and records input
identities before/after. It is a checked stage0 experiment, not a B1 proof.

To rebuild A01, restore `raw/checked-project-01` into a fresh project directory.
Its `src/check/kernel.bend` equals the tracked `checked-output/candidate-01/kernel.bend`;
all other production modules retain baseline identities. Write a new development
config using that project's absolute path, the pinned upstream path, profile
`checked`, jobs `1`, and CPU `0`. Run the maintained
[workflow](../../../docs/PHASE5_DEVELOPMENT.md) `run` command with a new attempt
directory. The preserved `raw/checked-01.json` and attempt manifest record the
original config/commands. `prepare.py` is the original one-shot producer; it
intentionally refuses to replace its already tracked `candidate-01` directory.

With fresh candidate and baseline checked APIs, the direct controls and timing
entry points are:

```sh
taskset -c 0 node --stack-size=4096 --max-old-space-size=4096 implementation/phase7/architecture-evidence/checked-output/controls.mjs BASELINE_API CANDIDATE_API selfhost/src/runtime.mjs NEW_CONTROLS
node implementation/phase7/architecture-evidence/checked-output/timing.mjs BASELINE_API CANDIDATE_API selfhost/src/runtime.mjs NEW_TIMING
```

The baseline checked API is in `raw/baseline/checked-api.mjs`. Timing launches
its own serial CPU0 workers. Run only one compiler or measurement job at a time.
Controls must pass at the claimed boundary before reading performance as an
improvement. A passing archive verification proves preservation, not semantics.
