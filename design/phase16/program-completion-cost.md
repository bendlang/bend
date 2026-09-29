# Measure the bounded whole-program completion entry

Compare accepted wave7 against isolated program-completion source01. Both use
the identical assembled wave7 compiler source and unchanged pinned TypeScript,
Base, runtime and v5 derivation. This isolates the program-stage ownership
change from qualified-pattern and constructor-note changes in wave8, and from
the active contextual parser and compact literal experiments.

Review the complete changed host set before execution: only typed-driver.mjs
may differ. The advertised ABI2 calls Bend's program entry, uses its materialized
book, and skips separate host TODO/specialization calls. ABI0/1 behavior remains
available; unknown/missing2 refuses. The10 independent actual-host route controls
and8 direct semantic/operation controls pass. No source validation, import,
oracle, reference or output work is omitted. Count reduction is not a speedup.

Use the existing strict matrix-v2 tool, CPU0, fresh processes, 4MiB stack and
4GiB heap, serial order TS/B/C/C/B/TS. Bind exact host patch, APIs, caches,
source and toolchain. Include checking and trust reporting, exclude emission;
validated Bend Base caches are reused while TS checks Base normally. OS caches
are not flushed. All intentional compiler/archive jobs must finish and agents
must acknowledge the exclusive window before starting.

Retain every sample and failure. Require complete successful outcomes and equal
unsafe-definition sets before ratios. Report both request and process time,
memory and per-sample variability. Two samples per image are a bounded comparison,
not a precision guarantee. Interpret differences below3% cautiously. This does
not establish final wave8 performance or emitted-program speed. Final release
still requires its own combined-image gates and controlled timing.
