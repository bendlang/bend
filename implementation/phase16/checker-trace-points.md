# Preserve the real binder and proof occurrence

The [trace design](../../design/phase16/checker-trace-points.md) now passes all
**15 paired controls exactly** in `checker-trace-checks-09`, including the eight
original selected rows and the repeated/nested note boundaries. The unchanged
integration04 baseline has ten differences in this selection. All primitive
outcomes are unchanged. The genuine checked/v5 build and focused36 also pass.

Local binder quantity errors now enter the existing DTrace at their Bind; a
non-equation rewrite enters it at the proof term. The local kind check uses the
available Bind as its immediate error site, while retaining the original failing
terms/context. The existing note predicate additionally checks source identity
when both terms have origins. Nested unrelated failures keep their own site/note.
The diagnostic trail retains the original terms behind this explicit site, so
unlocated callers keep a fallback. No source searching or second checker is added.

Closing order is deliberately unchanged: the corrected erased-binder witness
does not justify reversing it. There is one new shared kind-site helper; existing
kind checks call it with their original type term. The first source07 build
correctly rejected a stale forward law for check_let_done. Source08 corrected
that law and fixed eight of ten differences, but the renderer uses DTrail rather
than the separate site slot. Source09 prepends the explicit site to that existing
trail; all fifteen observations become exact. Every failed attempt remains saved.

Evidence under `selfhost/build/phase16/`: `checker-trace-controls-01` (invalid
parallel syntax), `checker-trace-controls-02` (corrected), baseline01–03,
source/build07–09, and checks08–09. The final delta is integrated into wave4-build02.
The separate F32 literal-versus-constructor note distinction is still open.
