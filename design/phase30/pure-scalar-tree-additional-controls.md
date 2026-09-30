# Additional scalar-tree public-boundary controls

Freeze these additional controls after the first successful tree acquisition
and before considering any production implementation. They do not change the
three modules, existing controls, counters or currently frozen timing plans.
Keep their separate execution receipt and full paired observations.

Independent static review found no counterexample, but identified inexpensive
coverage gaps in the initial 130 host observations:

1. Install persistent getter hooks for `request`, `bounce`, `build` and `code`
   on Number, BigInt and Boolean prototypes. Every hook records its ordered
   access and returns false; restore it before serializing observations. These
   hooks must cause the existing scalar guard to decline the tree path and keep
   the original public access sequence. Also cover Object prototype hooks to
   match the existing runtime guard suite.
2. For each owner/helper in the nine-name closure, alter `io`, `typeName`, the
   environment identity, the bound-vector identity or contents, and an own
   getter for `code.call`. Compare results/errors and complete event order.
   The guard must inspect descriptor shape without invoking a new getter.
3. On a saved successor partial, throw or replace a helper at copied-vector
   length reads 2, 3 and 5. The existing suite covers read 4. Keep original
   copied-vector behavior, captured callback and body scheduling.

Retain the standard-host-intrinsics scope explicitly. The private traversal
uses an ordinary JavaScript Array for inaccessible continuation storage;
arbitrary numeric Array prototype setters are outside this initial proof.
This is separate from the observable primitive runtime marker hooks above,
which the existing guard explicitly promises to reject.

No performance configuration or production source changes are authorized by
these additional controls. A failing case is evidence to preserve and resolve
before promoting this concept.
