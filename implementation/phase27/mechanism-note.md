# Phase27 source and generated-code structure

The final shared variant adds **58 physical Bend lines and eight definitions**
to the Phase26 compiler, plus **11 runtime lines and one JavaScript helper**.
It keeps the inline variant's recognizer and emitted-function contract. Sharing
the callback reduces duplicated generated logic; it does not reduce the total
compiler source relative to Phase26.

The [exact census](source-census.json) compares commit
`0f51c00cd040fb661d4544dc47530f2ba6cb3985` with the current source, verified
byte-for-byte against the immutable shared `attempt-02` snapshot. Inline counts
come from `attempt-01`. Only modules named by each `compiler.json` count as Bend
compiler source. Generated `compiler.bend`, compiler images, tests, documentation,
Base, upstream TypeScript and host tools are excluded. Runtime counts are separate.

| Canonical Bend source | Phase26 | Inline candidate | Shared candidate |
| --- | ---: | ---: | ---: |
| Physical lines | 15,886 | 15,948 | 15,944 |
| Nonblank lines | 13,562 | 13,616 | 13,612 |
| Bytes | 592,936 | 596,548 | 596,153 |
| Modules | 61 | 62 | 62 |
| `def` declarations | 1,718 | 1,726 | 1,726 |
| `law` declarations | 640 | 640 | 640 |
| `type` declarations | 68 | 68 | 68 |

Physical lines include comments and blanks; declaration counts use the same
anchored lexical patterns as Phase26. These are reproducible source measurements,
not a count or proof of semantic concepts. Both candidates add one lowering rule,
use the existing `Maybe` result and function representation, and introduce no
datatype or intermediate representation. The shared candidate is four Bend lines
and 395 bytes smaller than the inline candidate, with the same eight helpers.

## What is shared, and what remains per invocation

The recognizer still requires a single remaining constructor, an owned constructor
telescope with live fields, a literal non-lifted lambda arm and more leading
lambda slots than constructor fields. Other shapes use the original matcher.
The outer function retains arity one; later source arguments retain their demand
order. There is no argument raising or new public function descriptor.

Previously each accepted arm embedded the projection, copy and application-tail
logic inside its own generated callback. The final emission is schematically:

```js
matcher1p(name, fieldCount, originalArity,
  () => (0, function(a) { /* unchanged original lambda body */ }))
```

The shared `matcher1p` callback projects the scrutinee, reads the projected length,
then invokes the code factory. It preserves the projected-count mismatch fallback,
one `slice()` and the existing equal/less/more arity branches after slicing. This
also handles unusual slice return values without changing field/property-read
order. The returned partial descriptor keeps the original arity, null environment
and copied bound vector. The anonymous function's name, length and source text
remain unchanged; code is still created afresh when the arm is selected.

For an ordinary eligible partial application, both candidates remove the initial
arm function descriptor and its empty bound array, one trampoline record and one
generic `apply` entry. They retain the returned partial descriptor, field-vector
copy and later calls. These are predicted event differences at one selected arm;
the separate diagnostic reports measure whole benchmark calls.

One shared callback replaces distinct generated callback bodies. That changes the
set of function targets seen by the runtime's call site and is a plausible JIT
mechanism. It does not prove the cause of any timing difference. The original
inner lambda bodies were already identical in the inline variant; the source
alone did not establish extra captured contexts as the cause of its short-window
substitution regression. Warmup and timing evidence belong in the phase report.

The helper's authoritative source is `src/runtime/js/core.mjs`; rebuilding through
`src/runtime/js/build.mjs` produces the matching `src/runtime.mjs`. Runtime source
grows by 468 bytes and 11 nonblank/physical lines, with one `matcher1p` definition.
The generated bundle and fragment are the same logical code and must not be
double-counted as separate runtime implementations.

## Actual compiler membership component

The component extracts the real `has_name` and `has_name_next` functions. All
three saved emissions use the identical component source and Base. Each emitted
module begins with its exact recorded runtime bytes. After removing that prefix,
**only the `has_name` registration differs**; every other byte is identical.
Hashes, artifact paths and registration line numbers are in the census JSON.

| Emitted membership component bytes | Phase26 | Inline candidate | Shared candidate |
| --- | ---: | ---: | ---: |
| `has_name` registration | 289 | 567 | 311 |
| All six source registrations | 1,160 | 1,438 | 1,182 |
| Copied runtime | 42,878 | 42,878 | 43,346 |
| Complete library | 66,641 | 66,919 | 67,131 |

Registration sizes include the `G[...]` assignment and final semicolon, excluding
the newline. The six registrations are the two extracted functions and four
fixture helpers. Full-library sizes also include Base fallback registrations,
metadata and exports; those bytes are not attributed to the membership algorithm.

Sharing removes 256 bytes from the inline `has_name` registration. This one-site
library nevertheless grows by 212 bytes relative to inline because it gains the
468-byte runtime helper. Against Phase26 it grows by 490 bytes: 22 registration
bytes plus 468 runtime bytes. Smaller per-arm generated code therefore does not
mean a smaller complete library for this fixture. No whole-compiler throughput,
self-emitted H speedup or conformance expansion follows from this static census.
