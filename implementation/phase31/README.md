# Phase31: local data and self-hosted compiler speed

Agent-generated investigation started2026-09-30. Status: the isolated local-data
experiments passed; checked general integration is under validation. No new
compiler has replaced the installed Phase30 release yet.

- [Prospective campaign design](../../design/phase31/local-data-and-compiler-throughput.md)
- [Starting compiler and protected files](start-state.json)
- [Verified recovery of redundant synthetic files](verified-space-recovery.json)
- [Prior consolidated compiler](../phase30/release-17.md)

The investigation separates compiler throughput, development-loop turnaround and
compiled-program execution. No PR comment is part of this work.

## Evidence so far

- [Zig history and transferable lessons](../../design/phase31/zig-lessons.md)
- [Private setup and record-shell ladder](local-data-ladder.md)
- [Independent demand and alias review](local-data-independent-review.md)
- [Generated compiler ABI attribution](h-attribution.md)
- [Checked local-region integration](../../design/phase31/checked-local-regions.md)

The ladder confirms a large setup/private-call benefit and a separate modest Dp
shell benefit. Neither is a general compiler result until checked source passes
transfer gates. H17 spends about97% of its traced request inside generated code;
this diagnostic does not justify prioritizing another ABI cache.

## Retained integration attempts

01 passed the36 focused frontend observations and emitted a full private pair
graph. Static independent review found that Array-less Sigma graphs also need
Array-prototype marker guards, and that tree regions need the same guard.02 fixes
those omissions.03 additionally short-circuits irrelevant local-type provenance
checks; its emitted edit-distance bytes equal02 exactly.

The first actual02 execution failed before an oracle result: `localGuard` was
undefined. Root had edited runtime fragments without regenerating the embedded
`src/runtime.mjs` bundle.03 inherited those same unusable bytes. This packaging
error is preserved, not a semantic pass;36 frontend checks did not cover it.04
regenerates the runtime with the maintained builder before a fresh checked build.
No timing or installed release uses01–03.
