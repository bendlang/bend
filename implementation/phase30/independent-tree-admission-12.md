# Independent actual tree compiler checks

The immutable checked attempt12 passes **31 independently authored synthetic
admission/refusal books and 96 execution observations** in
`review-tree-admission-12`. Its predecessor-header refactor also preserves the
existing scalar, ordinary-root and terminal admission controls. No compiler
change or harness correction was needed in these acquisitions.

The positive reference is deliberately different from Mandelbrot's sum. Its left
child receives `state+1`, its right child receives `state*3`, and its combination
is U32 subtraction. A separate recursive JavaScript arithmetic reference checks
depths 0, 1, 2, 3 and 5 with ordinary and wrapping states. A second case reverses
the subtraction. These distinguish child order and parent-state restoration
without depending on associative or commutative arithmetic.

Other admitted cases reuse one helper in the zero expression, both child
arguments and the combination; call a proved nested countdown from the zero
body; carry native Bool state; and carry maximum native Nat as unused state.
A raw successor callback retains its original scalar result, and a saved partial
observes a later change to the recursive owner's code. Helper declarations are
unique and the owner has one snapshot capture.

The refusals include extra/missing/erased child bindings, duplicate binders and
parent shadowing, a right child referring to the left parallel binder, direct
parent capture in the combination, wrong predecessor, partial/oversaturated
children, owner calls inside arguments or combination, helper-mediated owner
reentry, mutual helper cycles, unknown/foreign helpers, record state/results,
escaping combinations, labels and invalid native Nat identity. A shared closure
of 32 helpers spread across zero, left, right and combine is admitted; 33 is
refused. The independent depth-bound witness also refuses a long helper chain.
These checks use synthetic KDefs through the actual checked `j_library`, and do
not claim frontend acceptance of deliberately malformed books.

The new parameterized `review-tree-boundaries.mjs` passes **85 complete paired
observations** in each of two separate receipts:

- `review-tree-boundaries-01`: unchanged output versus both frozen generated-JS
  tree variants.
- `review-tree-boundaries-12`: checked ordinary-root attempt11 versus checked
  tree attempt12 on the original Mandelbrot program.

The cases install persistent `request`, `bounce`, `build` and `code` getters on
Number, BigInt, Boolean and Object prototypes; change all nine closure
descriptors' io/type/environment/bound metadata and code.call getters; and throw
or replace a leaf helper at copied-vector length reads 2, 3 and 5. Values, raw
error class/message and complete event order agree. The original 130-observation
suite and its modules remain unchanged. Stable host intrinsics, including the
private Array stack operations, remain the stated scope.

Because the common Nat header and body emitter changed, the following independent
regression acquisitions also ran against attempt12:

| Receipt | Synthetic books | Execution observations |
| --- | ---: | ---: |
| `review-scalar-compiler-admission-12` | 22 | 13 |
| `review-ordinary-root-admission-12` | 28 | 44 |
| `review-terminal-admission-12` | 41 | 88 |

All pass. These are overlapping targeted backend controls, not an aggregate
language-conformance percentage. Original-program oracles, existing tree
boundaries, depth sentinels and clean timings are separate parent-owned evidence.
