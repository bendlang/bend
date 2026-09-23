# General literal plan

Next action: measure a checked-function candidate against the baseline.

## Current state

1. Complete: create `feature/general-literals` from `feature/U32-to-Nat`.
2. Baseline commit: `aa823c0a558caaf1e702ec53060ab1905d71aa4b`.
3. Complete: commit the plan and establish the selected literal test baseline.
4. Complete: the user authorized edits to `bend2/bend.ts` for this task.

## Objective

Support more types through literal syntax. Use one common mechanism where possible.
Find the smallest change that fully meets this objective.
Reduce total implementation code. Preserve correctness and readable code.

## Mandatory correctness rule

**THE AGENT MUST ONLY MAKE CHANGES THAT DO NOT PUT CORRECTNESS AT RISK.**

Correctness has priority over code size, generality, performance, and completion.
Do not trade correctness for any of these objectives.

1. Establish why a proposed change preserves correctness before editing implementation code. State the affected rules and the reason they remain valid.
2. Use read-only analysis when that reason is not clear. Do not implement an uncertain change to see whether tests pass.
3. Preserve all existing checking requirements. Do not bypass a check, weaken a rejection rule, or add an unproved trusted shortcut.
4. Use tests to check the reasoning. Passing tests alone do not establish correctness.
5. Stop a candidate if its correctness cannot be established. Record the unresolved issue. Continue only with work that does not depend on that issue.

The permission to edit `bend2/bend.ts` does not relax this rule.
The request to try a general framework does not relax this rule.
An incomplete feature is preferable to a change that puts correctness at risk.

A general framework is a candidate. Test it before a decision about its size.
Do not reject it only because its first version adds code.
Do not accept a smaller change that omits required behavior.

## Constraints

1. Keep implementation changes in existing files. Do not add modules, test files, or dependencies. This requested plan is the only new tracked file.
2. Preserve existing programs, literal values, errors, and constructor meanings unless the user approves a specific change.
3. Preserve dependent checking, affine use checks, equality, termination checks, and constructor pattern checks.
4. Keep syntax in the parser. Keep runtime representation in the compiler. Do not add a second parser in the CLI or compiler.
5. The user permits edits to `bend2/bend.ts` for this task. Keep changes within the agreed literal scope.

Use ASD-STE100 Simplified Technical English for this plan and progress reports.
Apply the `i-have-adhd` skill throughout the task.
Keep technical names and commands exact.

## Step 1: Establish the baseline

1. Trace parsing, compact storage, checking, equality, matching, printing, and compilation for each current literal form.
2. Record the relevant tests and their baseline results. Use WSL Ubuntu-24.04 for local Bend runs, as specified in the existing local plans.
3. Measure lines, nonblank lines, and bytes for affected implementation files. Use `ttok` if available. Count prelude additions in the implementation total.
4. Measure the cyclomatic complexity of functions before changes. Use the project configuration if present. Otherwise, use the skill rules and report manual counts when necessary.
5. Record unavailable tools and test backends. Do not report an unavailable check as a pass.

## Step 2: Define complete behavior

1. Specify how a program selects the literal type. Check explicit namespace selection first. Define default behavior and nested expression scope.
2. Specify the library contract. Demonstrate at least two additional types through the same mechanism. Use numeric and text examples to test generality.
3. Specify ranges and precision. Do not pass a rounded F32 value as the original decimal value. Reject unsupported values through a defined rule.
4. Specify patterns and printing. Preserve existing structural literal patterns. Do not treat an arbitrary conversion function as an inverse or a constructor pattern.
5. Specify parameterized types and affine values. Check every contained term. State which forms the mechanism supports and why.

Record concrete source examples and their exact ordinary-term meaning before implementation.
Include invalid examples with expected rejection behavior.
Do not equate more literal syntax with new native runtime types.

## Step 3: Build and compare candidates

1. Establish the correctness argument for the candidate. Then implement the smallest complete candidate in the canonical files. Investigate reuse of `parse_term_ns` and ordinary checked functions.
2. Test whether a shared literal representation can replace existing cases. Keep compact storage where expansion would cause excessive work.
3. Compare the candidate with the baseline. Include removed code, added code, helper functions, library definitions, and backend changes.
4. Revise the candidate when a simpler design can remove conditions or duplicate paths. Do not use dense formatting to reduce the line count.
5. Keep the smallest complete candidate that passes correctness checks. If no candidate meets the requirements, record the evidence and the unresolved design issue.

Do not preserve an added layer only because it already works.
Do not remove required behavior to obtain a smaller diff.
Count test and documentation changes separately. Report the total diff as well.

## Step 4: Verify behavior

1. Extend existing Bend tests. Preserve the `#|` expected-output convention. Cover new types, explicit selection, defaults, nesting, and invalid conversions.
2. Run existing literal tests. Include custom constructor declarations, malformed patterns, large naturals, long strings, Unicode edge cases, U32 limits, and F32 bit behavior.
3. Verify dependent equality, structural descent, and affine use checks. Include rejection cases that could expose an unsound shortcut.
4. Compare interpreter, JS, and C outputs where available. Check relevant performance cases for literal expansion and compiler work.
5. Run required repository gates where available. Record baseline failures separately. Report unavailable cluster or GPU checks as remaining verification work.

Use local checks first. Do not change gate rules or expected output to conceal a regression.
The existing local plans prohibit SSH cluster runs and GPU work.
Record that limit before any attempt to run those checks.

## Step 5: Review and fix the implementation

1. Run the `thermo-nuclear-code-quality-review` skill on the complete branch diff against the baseline commit.
2. Fix its findings. Remove unnecessary layers, duplicate helpers, scattered conditions, and unclear type boundaries.
3. Run the `cyclomatic-complexity` skill. Report each changed function with its before and after count.
4. Fix complexity findings in existing files. Recheck affected behavior after each material correction.
5. Repeat the relevant review after fixes. Record remaining findings and their reasons.

The agent must perform the reviews and work on their findings.
A list of recommendations alone does not complete this step.
The only exception to the code quality review is file extraction: do not create more files.
Use smaller functions within existing files when appropriate.
Apply all other review requirements.

## Completion conditions

1. The common mechanism supports the specified additional types. Its syntax, checking, patterns, and printing follow the recorded contract.
2. Total implementation code is smaller than the baseline. The reduction is structural and readable.
3. Each implementation change has an explicit correctness argument and passes the applicable checks. No unresolved correctness risk or failure remains.
4. Both reviews are complete. The agent has fixed actionable findings. No implementation files were added.
5. This plan records measurements, test results, remaining verification limits, and the final design. Commit the implementation after verification.

Do not claim completion if any condition remains unmet.

## Evidence log

The worktree was clean before branch creation.
The new branch starts at the baseline commit above.
The plan is under `evals/` because `gates/repo.ts` excludes that directory from its file allow list.
The implementation has not changed.

The existing `Lit` node stores String, Nat, U32, and F32 values.
`lit_step` exposes constructor structure.
`term_compare` compares compact payloads or exposes a constructor step.
The checker only gives trusted base constructors its fast literal check.
Other declarations must check the exposed constructor structure.

`parse_term_ns` currently selects operator names from explicit syntax.
It does not perform general type inference or convert literal values.
The compiler expands compact literals and treats large Nat values separately.
These paths are candidates for investigation, not approved shortcuts.

### Baseline measurements

| File | Lines | Nonblank lines | Bytes |
| --- | ---: | ---: | ---: |
| `bend2/bend.ts` | 3961 | 3751 | 140472 |
| `bend2/comp.ts` | 6354 | 5726 | 189152 |
| `bend2/base.bend` | 3006 | 2485 | 69329 |

`bend2/bend.ts` contains 43242 tokens according to `ttok`.
Its repository limit is 43300 tokens.
Line and byte counts above use the current Windows checkout.
Use Git text for final comparisons to avoid line-ending differences.

The selected baseline passes 18 interpreter checks, three JS checks, and three C checks.
The checks include literal values, patterns, limits, invalid constructors, and structural descent.
The C runtime reserves more virtual memory than the limit used for Bun.
Run C binaries outside that limit. Do not change the runtime for this test setup.

### Candidate A: an ordinary literal function

Declare `T.literal` to select literal conversion in the namespace `T`.
For example, `(42 : Distance)` means `Distance.literal(42)`.
Similarly, `("abc" : Label)` means `Label.literal("abc")`.
Each function declares its input type and result type through ordinary Bend syntax.
The function can accept one of the existing compact literal types.
Its input is the existing value, not unrounded source text.

1. Keep current behavior when the namespace has no `literal` declaration.
2. Convert literal leaves reached by the existing operator namespace traversal. Preserve its boundaries at named calls and already selected operator namespaces.
3. Pass explicit type arguments before the literal argument. Do not infer missing arguments or select a conversion by runtime type.
4. Check the generated function application normally. Reject a converted pattern through the existing constructor-pattern rule.
5. Print the resulting value through existing constructor printing. Do not infer an inverse conversion.

Characters, lists, tuples, and some strings become constructor terms during parsing.
Apply the same conversion to constructor terms. This avoids dependence on compact storage.
The conversion passes the entire term once. The checker checks all contained variables normally.
Use `((a, b) : T)` to select a namespace for an entire tuple.
Named function calls remain traversal boundaries, including the `Array.new` call used by array construction syntax.
Do not add syntax-origin flags to the core term representation.

### Correctness argument before Candidate A

The parser only adds ordinary `Ref` and `App` terms.
It passes a compact literal or constructor term once as the conversion argument.
It does not add a core term form, a trusted type, or a checker exception.
The existing checker checks each argument against the function declaration.
It also checks the result against the surrounding expected type.
The normal rules still check affine use, dependent arguments, and recursive descent.
The numeric parser retains its existing limits and F32 rounding.
The pattern parser still rejects function applications.
No new runtime representation or compiler operation is required.

Literal conversion is active only when the selected namespace declares `literal`.
The repository has no existing `literal` declaration.
The new convention is explicit library opt-in.
This argument permits the parser candidate. It does not permit checker shortcuts or automatic pattern inversion.

The manual baseline complexity count for `parse_term_ns` is 11.
It includes the three-way namespace guard and the fixed-operator conjunction.
Refactor that function if the candidate touches it.

### Correctness argument before removal of `lit_full`

The user permits removal of the exported helper if the replacement is safe.
Its two callers are `parse_patt` and the compiler's `term_force`.

For a valid literal, `lit_step` returns the same first constructor as `lit_full`.
Its remaining compact children represent exactly the remaining constructor trees.
Make `parse_patt` expose that first constructor before its existing switch.
Its recursive field checks then expose each child through the same entry point.
Constructor lookup, arity checks, and variable checks remain in place.
This change does not add a recursive call around the existing pattern recursion.

The compiler reads term heads through `term_force` or `term_strip`.
The audit covered constructor fields, constant detection, ownership traversal, folding, and both emitters.
Each field goes through those entry points before its term kind is used.
The word-pattern table reads complete words. `lit_step` already exposes complete words for U32 and F32.
The large-Nat conversion remains in `term_force` with its current threshold.
The memo table still stores each exposed constructor.

This replacement removes a duplicate expansion path.
It does not change literal values, constructor layouts, or checking rules.
Verify exact diagnostics, constructor-pattern behavior, generated outputs, and long-literal handling after the change.

### Correctness argument before simplification of `term_unapply`

The literal and operator selectors both use `term_unapply`.
Replace its infinite loop and switch with a loop over `App` nodes.
Each iteration collects the same argument and selects the same function child.
Both versions stop at the first non-`App` node and reverse the argument list once.
The return type and the returned term references remain the same.
The manual complexity count decreases from 3 to 2.

### Rejected candidate: generic literal builders

`word_to_term`, `u32_to_term`, and `lit_step` construct only `Ctr` and `Lit` nodes.
They construct no binder, variable, or function body.
Their output is therefore valid for either term body representation.
Make their TypeScript body parameter generic. Preserve all runtime operations.
Then remove `term_higher` calls around these closed constructor results.
`term_higher` only copied those constructors and retained their literal children.
Removing that copy preserves the constructor fields, values, and source spans.
The compiler's generated large-Nat application also contains only a reference and closed constructors.
It requires no binder conversion.

This change removes redundant tree traversal. It does not change a checking or reduction rule.
Use TypeScript checks to verify the generic boundaries.

The candidate was tested and removed. It did not improve the size result.
The final implementation keeps the existing builder signatures and `term_higher` calls.

### Correctness argument before field destructuring

Destructure the literal fields in `lit_step` as `v`, `k`, and `s`.
The function only reads these fields. It does not modify the input object.
All field values, branch conditions, constructor arguments, and spans remain identical.
This is a local readability change to the shared literal expansion function.
