# Phase11 independent call and scope review

Read-only review by the checker investigator. No static blocker was found for
the supported generated-module and finite compiler-data contracts below. This
review inspected source and retained reports; it launched no additional compiler
or timing job and does not replace root's combined integration gates.

## Maintained choice derivative v4

Reviewed helper:
`selfhost/build/phase11/call-maintained-02/project/tools/development/equality.mjs`,
SHA-256 `ae8ce25736a144d3a3c930adc266deec91650fe359452c38940445e2618af54a`.
The derivative API is
`a9b79c2e1f7d25853bcc39de922903c8f952c1702227de369c10370530fedc29`.

The transform verifies the runtime prefix, exact choice-helper bodies, top-level
module shape and exports. It accepts only saturated choices with two literal
`run_clo` arrows. The replacement evaluates the condition once, selects one arrow
without executing either body, and invokes it through the original `run_tail`
trampoline boundary. Nested choices preserve their surrounding source order.
This avoids the discarded closure wrapper without introducing direct recursive
calls or changing the exported ABI.

Protected dependency checks reject parameter and destructuring shadows, nested
protected declarations, rebinding, member calls and first-class uses. Nonliteral
thunks remain unchanged. Versions 1–3 bypass the choice transform; the version4
path retains the prior native-string equality guards. The protocol is restricted
to the recognized generated module, not arbitrary JavaScript.

The inspected `call-maintained-02` evidence records:

- `attempt/validation-001/report.json`: all 21 maintained observations pass,
  retaining the same 12 known exact TypeScript differences.
- `current-tests-01/report.json`: all 14 groups pass, including the new mutation
  guards and dynamic-thunk fallback.
- `replay-01/report.json`: current v4 derivation verification and authentic v1
  release, v2 derivation and v3 release replays pass with verified inputs. The
  v3 result reproduces the Phase10 installed API exactly.

The failed `call-maintained-01` helper-generation attempt remains preserved. Its
integration script used JavaScript replacement-string expansion on literal
`$'` text; the corrected preparer uses replacement callbacks (the maintained
equality insertion itself uses source slicing/concatenation). The reviewed
helper does not retain that failure. These are derivative and replay checks,
not a new B1 bootstrap or self-hosting fixed-point claim.

## Source offload scope guard

Reviewed `scope-guard-02/project/src/front/families.bend`, function
`f_scope_reference`, and the actual checked candidate
`scope-guard-checked-01` (API
`ec6f34f64473f470feab005764bc56d38bac6a796aacee8e2637ffaa3227ef59`).
All abbreviated evidence paths here are under `selfhost/build/phase11/`.

For finite well-formed compiler data, the nested `f_choose` computes the same
predicate as `quant == 3 && (bound present || definition is ADT)`. It avoids the
definition lookup unless the quantifier is offload and no local binding already
determines the refusal. The earlier quantifier-2 path, later lexical/reference
resolution, datatype lookup and error text retain their existing order.

`scope-guard-controls-01/report.json` records exact baseline results for all 56
rows: 24 direct input combinations and four public source families, each run on
both variants. The direct cases cover quantifiers 0/1/2/3, absent/present local
binding, and Def/ADT/missing definitions. Public families parse, load and check;
their definition-lookup counts decrease by 16/32/64/128 for sizes 4/8/16/32.
These instrumented counts establish avoided work, not time or allocation gains.
The genuine checked workflow separately passes its maintained 21 observations
with 12 inherited exact differences.

Two malformed raw null-book controls explicitly change demand: an ordinary local
reference now returns its variable, and a locally bound offload now returns its
refusal, where the eager baseline threw during an unnecessary lookup. These
differences are preserved in `rawBoundary`; arbitrary malformed raw API values
are outside the finite typed-data equivalence claim. No additional boundary
probe or production edit was performed by this reviewer.
