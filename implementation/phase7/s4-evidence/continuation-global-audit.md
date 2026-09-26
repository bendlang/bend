# S4 global continuation and tag-dispatch challenge

Read-only census of the frozen 423-migration A02 source at
`selfhost/build/phase7/s4/attempt-a02/snapshot/src`, using exactly the 59
`compiler.json` modules. No compiler, test, prototype, or production edit was
run for this audit. The snapshot contains 1,450 definitions and 799 laws.

## Boundary savings outside the frontend

There is an additional small simplification pool, but not another clean
1,000-line tranche. Thirty nonrecursive helpers outside `front/` and `load/`
have one lexical production occurrence that is an entire function or existing
block result. Their boundary ceiling is **216 nonblank lines** before local
bindings, or **140** after one binding per original argument. This is a source
budget, not an approved deletion list or an execution-equivalence proof.

The inline Python census masked comments/string/character literals, excluded
formal parameters, computed recursive SCCs, and excluded the frozen 288-name
external-root set from `frontend-book-inventory.json`. It required exactly one
identifier occurrence, not merely one caller. For direct-result classification,
the helper call's matching closing parenthesis had to end the expression;
`j_escape_char(c) ++ j_escape(t)` therefore does not qualify. Recursion excluded
863 definitions. Local shadowing, dynamically constructed external names and
source-order visibility still require individual review.

| Placement | All modules: helpers | Boundary ceiling | After argument bindings | Outside front/load: helpers | Outside ceiling | Outside after bindings |
|---|---:|---:|---:|---:|---:|---:|
| Entire function result | 33 | 227 | 159 | 24 | 167 | 115 |
| Existing block result | 17 | 147 | 79 | 6 | 49 | 25 |
| Inline `case` result | 5 | 26 | 6 | 5 | 26 | 6 |
| Nested expression / branch | 179 | 1,014 | 629 | 133 | 704 | 412 |

These are **nonblank** counts; blank lines and signature packing earn no
credit. For a standalone result call, the ceiling is remaining law lines plus
definition-header/`@unsafe` lines plus the replaced call line. The helper body
is retained. Subtract one local per argument; an inline case retains its case
line and gets no replaced-call-line credit. Existing compact native typed
headers consequently yield little or no saving. Omitting negative candidates
gives 12 rather than 6 lines for inline cases and 425 rather than 412 for
outside-front/load nested candidates.

The **140** direct-result lines are additional to any frontend-only census;
three positive inline-case candidates could add **12**, with more syntax work.
The 133 nested/branch helpers are not a clean migration: introducing locals
inside lazy branches, preserving expression order, and retaining native tail
behavior need separate work. Even crediting every positive outside-front/load
candidate yields only **577** lines under this binding model, versus 946
before bindings. These are upper budgets for this particular boundary-removal
scheme, not a bound on all possible compiler redesigns.

The named S4-B inventory overlaps `f_dt`, `f_dx` and `f_loaded_result` in this
census (4, 4 and 5 binding-adjusted lines respectively). The inventory's
legacy-loader unit is a proposal, not authorization to remove its public
contract. Excluding all front/load helpers above also excludes the earlier
frontend continuation pool; adding that pool again would double count.
The census uses the post-migration snapshot, so the 423 removed laws are never
credited again. The evolving 205/195-line B budget must use its own exact units.

## Small ranked starting set

All paths/line numbers below refer to the frozen snapshot. Each has a remaining
law and a single direct-result production call. The five-row total is only
**25 nonblank lines**, retaining every body and binding every argument once.

| Helper and sole caller | Source | Law lines | Header + unsafe | Call removed | Locals | Net |
|---|---|---:|---:|---:|---:|---:|
| `kp_float_text` from `kp_float_show` | `core/pretty.bend:312` | 3 | 2 | 1 | 1 | 5 |
| `index_child_list` from `index_child` | `core/index.bend:44` | 4 | 2 | 1 | 2 | 5 |
| `check_open_message` from `check_open` | `check/kernel.bend:921` | 3 | 2 | 1 | 1 | 5 |
| `sp_finish` from `specialize_book` | `check/specialize.bend:543` | 3 | 2 | 1 | 1 | 5 |
| `dr_verdict` from `driver_report` | `driver/report.bend:64` | 3 | 2 | 1 | 1 | 5 |

These retain formatted-text sharing, the index child selection, the counted
open-goal result, the completed specialization state, and unsafe-name ordering,
respectively. Do not substitute the formatted string or state expression at
every use. Use fresh local names, retain quantities and original argument
order, and avoid capturing caller variables with sequential bindings. Moving
a body earlier can expose new forward references; any required replacement
law must be charged. `check_lam_done` and `check_definition_type` are similar
five-line opportunities but touch more sensitive checker sequencing and are
lower priorities. No speedup follows from the static counts alone.

## Stronger representation hypothesis: typed tag dispatch

The accessor-only S0 pool is not a complete measure of representation cost.
The same 59 modules contain **505** direct `String.eq(tg(...` / `f_eq(tg(...`
comparison sites and **64** literal tags passed to `kt`. A tag enumeration
could replace repeated string tests and nested conditional dispatch while
retaining the existing term fields. This is a credible *concept and byte*
simplification hypothesis, deserving a bounded pilot; it is not disproved by
the unsuccessful full-sum line budget. These are syntactic sites, not runtime
counts or independently removable lines.

Two representative dispatchers show the distinction:

* `check/kernel.bend:625`, `infer_node`, contains 11 tag tests and a default in
  12 body lines. A normal enum match needs a match line and 12 arms (at least
  13 lines with inline arms, or 25 with separate arm/body lines). It removes
  string-tag tests and conditional-helper syntax, but retains all inference
  branches, checks and error behavior. Destructuring a full term variant can
  simplify some fields, but does not remove these algorithms.
* `back/js/emit.bend:238`, `j_expr_on`, contains 15 string comparisons and a
  default on **one** body line. A readable match has at least 17 body lines.
  It should substantially shorten this long expression in bytes and make
  dispatch clearer; it does not reduce physical LOC. The caller at line 224
  already computes `tg(t)` once for that dispatcher. Its lambda-cache guard,
  tail flag, annotation behavior, erasure and intrinsic handling remain.

`back/js/choice.bend` already recognizes the compiler's ordinary conditional
helper shape and lowers eligible literal thunk arms to direct conditionals.
Removing source `kc` syntax therefore does not automatically remove runtime
closure allocations; measure the emitted result. Matching the existing
`String` tag is also not equivalent to matching a small enum for free.

A typed-tag pilot must price the enum, constructor/accessor changes, all
administrative tags and generic tree walks, plus the public raw-term boundary.
A permanent semantic converter hidden in the host would violate this phase's
scope. A full core sum can additionally remove positional-child conventions,
but expands generic walkers and compatibility adapters. Any helper boundaries
merged into variant arms overlap this report's continuation savings and must
not be credited twice. Neither representative supplies a funded route to the
remaining roughly 6,000-line reduction. The supported conclusion is **small
additional continuation savings and a worthwhile, unmeasured typed-dispatch
research hypothesis**, not impossibility of an architectural improvement.
