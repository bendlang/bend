# General literal plan

Status: complete up to `c45844d5` and the erasure pass after it.
The `Word` study below waits for the user.

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
   `lit_step` gives the same tree as `aa823c0a`.
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

## Result (`aa823c0a` to `32ddef5d`)

`bend2/bend.ts`: 43179 → 42861 tokens (`ttok`), 3961 → 3925 lines.
`bend2/comp.ts`: −4 tokens.
`lit_full`, `u32_to_term` and `lit_chain` are gone.

Checks: 303 representative tests (literal, char, string, escape, pattern,
printer, parse, eval, halt) pass as on the baseline, with byte-identical
emitted JS and C for all 224 builds, the demos and `litheavy.bend`.
`tsc` shows the same 4 errors as the baseline.

Measured in WSL, median of 5 rounds, alternating the two trees.
Identical C binaries vary by up to ±15%, so smaller time changes are noise.

| Case | Time | Memory |
| --- | --- | --- |
| `litheavy.bend` check | −80% | −72% |
| `litheavy.bend` interpreter | −48% | −74% |
| `litheavy.bend` C emit (15 runs) | −21% | −43% |
| `pure_hvm5_mini` build | noise | −19% |
| checker benches, runtime benches, other demos | noise (C emit 0.0%) | ±2% |

`litheavy.bend` is a scratch program: 5000 Char, 500 String and 2500 U32
literals, and 200 proofs that unfold String literals.
The gain comes from `Chr{Lit(U32)}`: one node per character, not 65.

Remaining finding: `term_check` has cyclomatic complexity 51 (56 before).
A split is a checker restructure outside this task.

## Future action: the `Word` study

Study whether `Word` can get the same compact form. `Word.Con<-p: Nat>` has a
Nat index, so the fast check must also check the index. Answer:

1. Can a `Lit(Word)` carry its width, so the fast check compares `Word.Con<p>`?
2. Does it make the U32 and F32 steps `U32{Lit(Word, v)}` in place of the chain?
3. Does the compiler's word-pattern table still read complete words?
4. Do the four invariants stay true?

## Method

1. Run Bend in WSL Ubuntu-24.04 only. No cluster, no GPU. No file splits.
2. The gates do not run here. Test a representative set, not the full suite:
   the wide filter
   `literal|^proof_u32|^proof_f32|^printer_|^parse_|^eval_|^halt_|char|chr|string|str_|surrog|unicode|escape|pattern|patt`,
   judged as `gates/test.ts` does, plus all demos.
3. Make the tree with Windows Git (`git stash create`), then `git archive` it in
   WSL into `~/lit/<name>`. WSL Git has no `core.autocrlf`.
4. Merge stdout and stderr into one pipe, as the gate does.
5. Measure the two trees in alternating rounds, never one tree after the other.
