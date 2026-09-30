# Compare each general compiler step in one window

Freeze checked04 (complete local graph), checked05 (eager private returns with
force retained), checked06 (remove proved redundant private-result force), and
checked07 (direct local field reads) as separate modules. Generic installed17
and pinned TypeScript remain absolute references. No handwritten modules join
this compiler-only comparison. Each source is freshly checked against the
identical fixed row/pair source and distinct fold source; wrapper adaptation only
chooses the exported benchmark, not its generated body.

Two cases: unchanged canonical pair(p0), which executes the full 256x256 grid;
and one-array fold(n4096, seed17), exercising 32 modulo-indexed revisits of its
128-slot mutable array. Validate the latter against a separate BigInt/U32 oracle
on all six modules before timing. Bind each step's public/complete-state/event
controls, independent review and operation counters. All earlier failed builds,
guard-missing emissions, wrong harness expectations and measured04 stay intact.

Use the unchanged maintained `transfer` protocol on both cases: five fresh
samples per side, minimum three warm calls and one second, 300 ms timed target,
rotating serial CPU3 order. Import and first-call duration remain separately
recorded; every timed call checks its complete scalar result. Record all medians,
ranges and half drift, plus adjacent-stage ratios and absolute17/TS ratios.
Do not multiply ratios from separate windows. Diagnostic modules never enter
this plan. This does not measure frontend compile time or a generated compiler.

The coordinating root must grant the exclusive window after every producer has
closed. A new integration candidate must retain the conformance and independent
scope checks; the point of the ablation is to reject neutral or regressing
complexity rather than accumulate every proposed transformation.

Before checked07's renewed controls, adapt only the diagnostic observer: direct
private field reads remove the `project(Dp)` hook used to find final state.
Capture the four original Array handles at allocation instead, then compare all
physical backing arrays. With 256 even rows their logical final roles are the
original IDs 1=a, 2=b, 3=prev, 4=cur; the retained complete native schedule also
requires the final distance read from ID3. This observer does not depend on the
optimized operation surviving. Keep the first07 failed observer run and its
consumed tool. Production modules and timed modules remain byte-identical.
