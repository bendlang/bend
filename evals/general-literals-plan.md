# General literal plan

Status: Steps 1 to 5 are complete. The next item is the `Word` study in
"Future actions". It waits for the user.

## Task

Make the compact `Lit` node one general mechanism.
This is an internal representation change only.
Do not add syntax. Do not change what a program means, prints, or rejects.
Add every literal type that does not put correctness at risk
and does not need a change to `bend2/bend.lean`.
The general form must make the code smaller because it has fewer cases.
Do not get a smaller size from dense formatting.

## What went wrong in the first attempt

Commit `29a75aea` added user-overloadable literals (`T.literal`).
That is a new language feature. It is not this task.
It did not change the `Lit` node, and it added code.
Two of its changes fit this task: the removal of `lit_full`,
and the `while` loop in `term_unapply`.

## The principle

A literal is a closed value of a base type. It stores its host value and its type.
It unfolds one constructor layer at a time where a term head is read.
The fields of that layer can be literals again.

The current code has the unfold, but it finds the type through special cases:
`k === undefined`, `typeof v`, and a head constructor that the checker computes.
The principle removes those special cases:

1. `Lit` is `{ $: "Lit", k, v }`. `k` is the base type name: `Nat`, `String`, `U32` or `F32`.
   The tag is always present. It is the same kind of name as `ADT.k`.
2. `lit_step` and the printer select their behavior by `k` only.
3. The checker fast path becomes one rule:
   `Lit(k, v)` checks against the base type `k`. It does not compute a head constructor.
4. `u32_to_term` returns `Lit(U32, n)`.
   Then `Char` (`Chr{U32}`) and each character that a String unfolds get compact storage.
   This needs no new case.
5. Each reader tests `k === "Nat"` (or another type name).
   It does not test `k === undefined && typeof v === "number"`.

## Correctness contract

`bend2/bend.lean` line 110: "Literals are base.bend constructors, not calculus."
The Lean model sees only the constructor tree.
Thus the Lean proof stays valid while these four invariants stay true:

1. Meaning: each `Lit` means exactly one closed tree of base constructors.
   Repeated `lit_step` makes the same tree as the baseline makes.
2. Typing: the fast check accepts `Lit(k, v)` only against the base type `k`.
   Each `v` that the parser accepts makes a tree of that type.
3. Equality: two `Lit` nodes are equal only when `k` and `v` are equal.
   The encoding is injective. F32 stores bits, so equality is on bits, as with the tree.
4. Reading: each reader of a term head unfolds a `Lit` before it reads the head.
   The readers are `term_compare`, `term_descend`, the `MAT` frame in weak-head
   normalization, `parse_patt`, infer-err, and the compiler's `term_force`.

Stop a change if it makes one of these invariants uncertain.
Record the issue, and continue only with work that does not depend on it.

## Types in scope

| Type | Now | After |
| --- | --- | --- |
| Nat, String | `Lit`, no tag | `Lit`, tag `Nat` or `String` |
| U32, F32 | `Lit`, tag | no change |
| Char | `Chr{U32{32-bit Word chain}}` | `Chr{Lit(U32)}` |
| Char in an unfolded String | full Word chain | `Lit(U32)` |

Out of scope:

1. List, Tuple, Array: the spine already has one node for each element.
   A compact form saves nothing and needs element types.
2. Bool, Unit: the value is already one node.
3. Word (`Word.Con<p>`): the type has a Nat index.
   A fast check needs index reasoning. That is a correctness risk.

## Items to verify before editing

1. Is the `ADT.k` of Base's Nat, String, U32 and F32 the plain name?
   The new check rule must accept the same terms as the `ctrs_find` rule.
2. Does a reader need a `Ctr` from `u32_to_term` without `term_force` or `term_strip`?
   Audit `bend2/bend.ts` and `bend2/comp.ts`. `u32_from_term` already accepts `Lit`.
3. Does the compiler emit the same C and JS for `Chr{Lit(U32)}`?
4. `lit_chain` (surrogates, code points past U+10FFFF) calls `u32_to_term`.
   A `Lit(U32)` holds any 32-bit value, so this is expected to be safe. Confirm it.

## Steps

1. Reset the branch code to `aa823c0a`.
   Keep only the `lit_full` removal and the `term_unapply` loop from `29a75aea`.
   Remove the GUIDE section, `parse_term_literal`, and the `T.literal` tests.
2. Measure the baseline: `ttok`, lines, and bytes from Git text.
   Save the demo outputs and their emitted C and JS.
   Measure memory and time as specified in "Memory and performance measurement".
3. Do the change in steps. Make one commit for each step. Run the tests after each step.
   1. Add the tag to every `Lit`, and change the readers to test `k`.
   2. Change the check fast path to compare the type name.
   3. Make `u32_to_term` return `Lit(U32)`.
   4. Make `lit_step` and the printer select by `k`.
      Use a table or a `switch`, whichever is smaller.
4. Verify:
   1. Run the literal tests on the interpreter, JS and C.
      Check and run all demos (see "Test scope").
   2. Compare the demo outputs and the emitted C and JS with the baseline, byte for byte.
      Explain each difference, or remove it.
   3. Measure memory and time again with the same procedure.
      Report the change for each case. Record a regression and its cause.
5. Run the `thermo-nuclear-code-quality-review` and `cyclomatic-complexity` skills.
   Fix their findings. Do not add files.
6. Commit when the total implementation code is smaller and all checks pass.

## Memory and performance measurement

The gates (`gates/perf.ts`, `gates/test.ts`) do not run on the available machines.
Measure locally in WSL with the demos, the benches and the existing tests.

1. Use `/usr/bin/time -v`. Record the maximum resident set size and the elapsed time.
2. Run each case three times. Record the median.
3. Measure the same cases before (Step 2) and after (Step 4) the change.
   Use the same machine and the same `ulimit`.
4. Cases:
   1. Checker: each `bench/checker/*/main.bend`, check only.
   2. Checker on literals: one test with many String and Char literals.
      Use an existing test if one fits. Otherwise, write the file in the scratchpad.
      Do not add it to the repository.
   3. Compiler and runtime: the `bench/runtime/*/main.bend` benches that run on
      the CPU in WSL, on JS and C. Include `lexer`, which reads strings.
   4. Demos: the `demos/pure_*` and `demos/proof_*` demos that run on the CPU.
   5. Tests: the literal tests only (filter below). Do not run the full suite:
      1436 tests take too long on this machine.
5. Record each case that cannot run, and the reason. Do not report it as a pass.
6. Record the results in this plan as a table: case, before, after, change.

## Test scope

The full suite (1436 tests) takes too long on this machine. Use a representative set:

1. The literal tests: the test names that match
   `literal|^proof_u32|^proof_f32|^printer_(u32|f32)|^parse_nat` (61 tests).
   Judge them as `gates/test.ts` does: check, interpreter, JS and C.
2. All demos: check each `.bend` file with `--check-only`.
   Run `main.bend` of `pure_*`, `proof_*` and `io_hello_world` on the interpreter,
   JS and C. Keep the emitted `.js` and `.c` for the byte comparison.
3. Copy each tree with `git archive` into `~/lit/<name>` in WSL.
   Do not use a Windows copy: its CRLF line endings change error snippets.
   Do not use `/tmp`: a WSL restart clears it.
4. The runner scripts are local tools. Do not add them to the repository.

## Future actions

1. Study whether `Word` can get the same compact literal form.
   `Word.Con<-p: Nat>` has a Nat index, so the fast check must also check the index.
   The study must answer these questions:
   1. Can a `Lit(Word)` carry its width, so the fast check compares the full type
      `Word.Con<p>` and not only the name?
   2. Does a compact `Word` make `U32` and `F32` steps smaller,
      for example `U32{Lit(Word, v)}` in place of the 32-bit chain?
   3. Does the compiler's word-pattern table still read complete words?
   4. Do the four invariants in "Correctness contract" stay true?
   Do this study only after this task is complete. Record the result in this plan.

## Constraints

1. Do not add files. Do not add dependencies.
2. Run Bend in WSL Ubuntu-24.04. Do not use SSH cluster runs or GPU work.
3. Do not change gate rules or expected output to hide a regression.
4. Use ASD-STE100 Simplified Technical English and the `i-have-adhd` skill.

## Baseline measurements (`aa823c0a`, Windows checkout)

| File | Lines | Nonblank lines | Bytes |
| --- | ---: | ---: | ---: |
| `bend2/bend.ts` | 3961 | 3751 | 140472 |
| `bend2/comp.ts` | 6354 | 5726 | 189152 |
| `bend2/base.bend` | 3006 | 2485 | 69329 |

`bend2/bend.ts`: 43242 tokens by `ttok`. The cap is 43300.
Measure again from Git text in Step 2.

## Evidence log

### Step 1 (complete)

Changes kept from `29a75aea`:

1. `lit_full` is removed. `parse_patt` and the compiler's `term_force` call `lit_step`.
   Each field of the step is again a term that goes through the same entry point.
2. `term_unapply` uses a `while` loop over `App` nodes. The result is the same.

Size, from Git text (`ttok`):

| File | Baseline | Step 1 | Change |
| --- | ---: | ---: | ---: |
| `bend2/bend.ts` tokens | 43179 | 43011 | −168 |
| `bend2/bend.ts` lines | 3961 | 3938 | −23 |
| `bend2/comp.ts` tokens | 62168 | 62168 | 0 |

Checks:

1. Literal tests: 61 / 61 pass on the baseline and on Step 1.
2. Demos: all check results, run outputs, emitted JS and emitted C are
   byte-identical to the baseline.
3. `tsc` (7.0.2, `bend2/pack/tsconfig.json`): the same four errors as the baseline.
   They are in `bend.ts` (`parse_term_*`, `TLD.v`) and `docs/gen_*.ts` (module `canvas`).
   Step 1 adds no error.

The demo times from this run are not valid measurements:
the two trees ran at the same time. Step 2 measures them again.

### Items verified before Step 3

1. Base loads with the empty namespace (`book_load(book, BASE_BEND, "", ..)`),
   so the `ADT.k` of Base's types is the plain name.
   Each head constructor of Nat, String, U32 and F32 (`Zero`, `Succ`, `SNil`,
   `SCon`, `U32`, `F32`) is declared by that type alone in `base.bend`.
   Thus "T is Base's type k" accepts exactly the terms that the old
   `ctrs_find` rule accepted.
2. Each reader of a U32 field unfolds it first (`u32_from_term`, the compiler's
   `term_force`, `lit_step`). `u32_from_term` already accepts a `Lit`.
3. and 4. are confirmed by the byte comparison: the emitted C and JS are identical,
   and the surrogate tests in the wide set pass.

### Step 3 (complete)

Deviation from the plan: sub-steps 3.1, 3.2 and 3.4 are one commit (`90b643f3`).
A required tag makes the old check condition fail for Nat and String,
so the tag and the new check rule cannot be separate correct commits.

1. `90b643f3`: `Lit` is a discriminated union.
   `{ k: "Nat" | "U32" | "F32"; v: number } | { k: "String"; v: string }`.
   The type states invariant 1. `lit_step`, the printer, `nat_from_term`,
   `parse_term_num` and the compiler's `term_force` select by `k`.
   `typeof v` and `k === undefined` are gone.
   Check-lit is one condition: `t_wnf.k === tm.k && book.tlds[tm.k]?.b === true`.
2. `00609397`: `u32_to_term` is removed. `'a'`, each character that a String
   unfolds, and the compiler's large-Nat `U32.to_nat` argument use `Lit("U32", n)`.
   Char gets compact storage with no new case.
3. `c34bc099`: comment wrap from the review.

Checks after each commit:

1. Literal tests: 61 / 61.
2. Wide set (303 tests: literal, char, string, escape, pattern, printer, parse,
   eval, halt): 303 / 303 on the baseline and on `00609397`. Each test has the
   same result. All 224 emitted JS and C files are byte-identical.
3. Demos and `litheavy.bend`: outputs, emitted JS and emitted C byte-identical.
4. `tsc`: the same four errors as the baseline. No new error.

Runner notes (local tools only):

1. Merge stdout and stderr into one pipe, as the gate does. Two pipes change
   the order of messages and move a test's error into the next test's section.
2. Make the tree with Windows Git (`git stash create`), then `git archive` in WSL.
   WSL Git has no `core.autocrlf`, so its stash keeps CRLF from the checkout.

### Step 4 (complete): size, memory and time

Size, from Git text (`aa823c0a` to `c34bc099`):

| File | Tokens | Lines | Nonblank | Bytes |
| --- | ---: | ---: | ---: | ---: |
| `bend2/bend.ts` | 43179 → 42988 (−191) | 3961 → 3931 (−30) | 3751 → 3724 | 136511 → 135861 |
| `bend2/comp.ts` | 62168 → 62164 (−4) | 6354 → 6354 | 5726 → 5726 | 182804 → 182772 |

Diff of `bend2/`: 53 insertions, 83 deletions. No test or documentation change.

Method: WSL, `/usr/bin/time`, median of 5 rounds. The rounds alternate the
two trees (ABBAB..). A first run with all baseline rounds first showed +5% to
+30% on everything, including byte-identical C binaries: that was machine drift,
not the change. With alternation, the identical binaries (`rt.*.par`) vary by up
to ±15%. Treat a time change inside ±15% as noise.

Results (full table: 120 cases; the rest are inside the noise):

| Case | Time before → after | Memory before → after |
| --- | --- | --- |
| `litheavy.bend` check | 1.16 s → 0.23 s (−80%) | 431 MB → 121 MB (−72%) |
| `litheavy.bend` interpreter | 1.68 s → 0.87 s (−48%) | 700 MB → 180 MB (−74%) |
| `litheavy.bend` build (C + JS + clang) | 7.27 s → 6.66 s (−8%) | 1767 MB → 714 MB (−60%) |
| `litheavy.bend` C emit only (15 runs) | 2.88 s → 2.27 s (−21%) | 1081 MB → 616 MB (−43%) |
| `pure_hvm5_mini` build | 5.27 s → 5.70 s (noise) | 260 MB → 211 MB (−19%) |
| `pure_hvm5_mini` check | 0.18 s → 0.16 s | 99 MB → 87 MB (−12%) |
| checker benches (5) | −3% to +7% (noise) | −0.2% to +1.8% |
| runtime benches, C binary (16) | ±15% (noise; same binary) | same |
| C emit only, 4 normal programs (15 runs) | 0.0% | −0.2% to −0.6% |

`litheavy.bend` is a scratch program (not in the repository): 5000 Char
literals, 500 String literals of 24 characters, 2500 U32 literals, and 200
proofs `{String.append("..", "..") == ".." : String}` that unfold String
literals during the check. The gain comes from `Chr{Lit(U32)}`: each character
is one node, not a 65-node Word chain, where the checker and the compiler
unfold a String.

Normal programs have few Char literals, so their time does not change.
The build-time spread in the 5-round table comes from clang and noise:
the C emit step alone is 0.0% on the same programs.

All outputs, emitted JS and emitted C of the measured cases are byte-identical
(`tests.literal.out` differs only in its timing line).

### Step 5 (complete)

Thermo-nuclear review (the user excluded file splits for this repo):

1. No structural regression. The diff removes two helpers (`lit_full`,
   `u32_to_term`) and all `typeof v` and `k === undefined` special cases.
2. Fixed: one header comment line was 78 characters. Rewrapped.
3. Kept, with reason: the `Lit` overloads need one internal cast. They enforce
   the type and value pairing at each call.
4. Kept, with reason: `u32_from_term` keeps `w0.v as U32`. Its `k` is a `Name`
   from `comp.ts` (`adt.k`), so the union cannot narrow there. The cast is not new.
5. Kept, with reason: `word_to_term` has one caller (`lit_step`). Inlining the
   32-bit loop makes `lit_step` harder to read.

Cyclomatic complexity (lizard 1.x through `uvx`; manual where lizard does not
find the function):

| Function | Before | After |
| --- | ---: | ---: |
| `term_check` | 56 | 51 |
| `nat_from_term` | 11 | 10 |
| `term_show_sugar_str` | 8 | 8 |
| `lit_step` | 6 | 6 |
| `term_unapply` (manual) | 3 | 2 |
| `parse_term_num` literal fold condition (manual) | 4 terms | 3 terms |
| `comp.ts` `term_force` condition (manual) | 3 terms | 2 terms |
| `lit_full` | 4 | removed |
| `u32_to_term` | 1 | removed |

Remaining finding: `term_check` is 51, far above 15. It is the core checker.
A split is a checker restructure outside the literal scope. This change
lowers it by 5 and adds no branch.
