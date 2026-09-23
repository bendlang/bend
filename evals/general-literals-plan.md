# General literal plan

Status: complete, including the `Word` study.

## Task

Make the compact `Lit` node one general mechanism: an internal change only,
with no new syntax and no change to what a program means, prints or rejects.
Add every literal type that does not risk correctness or need a change to
`bend2/bend.lean`. The code must get smaller because it has fewer cases.

## Design

A literal is one node that holds a closed value of its Base type `k`:
`{ k: "Nat" | "U32" | "F32"; v: number } | { k: "String"; v: string }`.
It unfolds one constructor layer at a time where a term head is read,
and the fields of a layer can be literals again (`Chr{Lit(U32)}`).
Every reader selects by `k`. Check-lit accepts `Lit(k, v)` at Base's type `k`.

## Correctness contract

`bend2/bend.lean` models literals as their constructor trees
("Literals are base.bend constructors, not calculus"), so the proof holds
while these invariants hold:

1. Meaning: each `Lit` means one closed tree of Base constructors.
   `lit_step` gives the same tree that `main` parses.
2. Typing: the fast check accepts `Lit(k, v)` only at Base's type `k`.
   Base loads with the empty namespace, and each head constructor of Nat,
   String, U32 and F32 is declared by that type alone, so this accepts the
   terms the old `ctrs_find` rule accepted.
3. Equality: two `Lit` nodes are equal only when `k` and `v` are equal.
4. Reading: each reader of a term head unfolds a `Lit` first (`term_compare`,
   `term_descend`, the `MAT` frame, `parse_patt`, infer-err, the compiler's
   `term_force`; `u32_from_term` reads a U32 `Lit` directly).

Out of scope: List, Tuple and Array (the spine is already one node per
element), Bool and Unit (already one node), Word (see below).

## Result against `main` (`6a77e124`)

Code: `bend2/bend.ts` 43431 → 43307 tokens, 3976 → 3954 lines; `bend2/comp.ts`
62163 → 62207 tokens (`lit_call`). `lit_full`, `u32_to_term` and `lit_chain`
are gone, and no literal step is copied with `term_higher`.

Checks: 303 representative tests (literal, char, string, escape, pattern,
printer, parse, eval, halt) and the demos give the results of `main`, with
byte-identical emitted JS and C. `tsc` shows the same 4 errors as `main`.

Speed and memory: CPU time (user + sys) and peak memory, median of 8 rounds
that rotate the trees; the control benches vary by 1–3%.

| Case | Time | Memory |
| --- | ---: | ---: |
| 5000 Char literals: run / C emit | −75% / −69% | −75% / −78% |
| 500 Strings + 200 String proofs: run / C emit | −57% / −65% | −17% / −72% |
| 2500 U32 + 1000 F32 literals: run / C emit | −74% / −69% | −73% / −77% |
| `app_slash_boss_3d/PROOF` check | −3% | −63% |
| `pure_hvm5_mini/PROOF` check | −9% | −6% |
| `pure_par_sort` check | −20% | −2% |
| `raytrace` C emit | −39% | −23% |
| checker benches `trees_400`, `proofs_3200` | −2%, 0% | 0%, −1% |

The literal programs are scratch files, not in the repository. A wider
wall-clock run (7 rounds) showed the same shape: runtime bench C emit −7% to
−27%, demo checks mostly −10% to −25%. Most of the gain on normal programs
comes from U32 and F32 literals in `base.bend`, which `main` builds as full
chains at parse time. The runtime is unchanged: the emitted code is the same.

A per-literal cache of word steps was measured on top of the final code and
gained nothing, so there is none.

Remaining finding: `term_check` has cyclomatic complexity 51 (56 before).
A split is a checker restructure outside this task.

## The `Word` study: do not add a Word literal

`Word(n)` is a `def`: `Word(0n)` is `Word.Nil`, `Word(1n+p)` is `Word.Con<p>`,
and a word is least significant bit first.

1. Width: possible. `{ k: "Word"; v; w }` has type `Word.Con<w-1>`, and the
   fast check compares `nat_from_term(p)` with `w - 1`. But it is a third
   variant, a new field and a second condition in check-lit, for a check
   that never fires: no program checks a word against a type.
2. Steps: `U32{Lit(Word, v, 32)}` removes `word_to_term`, but each bit read
   then costs three nodes (a `WCon`, a `Bool`, a new `Lit`), not two.
3. Readers: `u32_from_term` reads the chain through `term_strip`, which does
   not unfold, so it needs a `Word` case too (invariant 4).
4. Invariants: 1 and 3 hold with masked bits; 2 and 4 need the new cases above.

Evidence: counts of `lit_step` per type and call chain (instrumented copy).
The checker benches unfold no literal. In the checker, U32 unfolds come from
`term_compare` against computed values and `Word.*` functions: they read all
32 bits, so a lazy word only adds nodes. In the compiler, 75% of U32 unfolds
(`pure_hvm5_mini`: 4443 of 5955) came from `term_const`, which unfolded a
literal only to find every node constant.

Action taken instead: `term_const` answers "constant" for a
`Lit` at once (invariant 1), except a Nat past the cap (`lit_call`, now the
one place for that rule). Emitted C and JS are byte-identical (303 tests,
demos, 8 programs). C emit, 9 alternating runs: `litheavy.bend` −65% time,
−54% memory; the other 7 programs within noise.

## Method

1. Run Bend in WSL Ubuntu-24.04 only. No cluster, no GPU. No file splits.
2. The gates do not run here. Test a representative set, not the full suite:
   the wide filter
   `literal|^proof_u32|^proof_f32|^printer_|^parse_|^eval_|^halt_|char|chr|string|str_|surrog|unicode|escape|pattern|patt`,
   judged as `gates/test.ts` does, plus all demos.
3. Make the tree with Windows Git (`git stash create`), then `git archive` it in
   WSL into `~/lit/<name>`. WSL Git has no `core.autocrlf`.
4. Merge stdout and stderr into one pipe, as the gate does.
5. Measure the trees in rotating rounds, never one tree after the other, and
   compare CPU time (user + sys): wall time varies by ±10–15% here.
