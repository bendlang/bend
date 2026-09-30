# Bound bootstrap error formatting

Prospective Phase30 plan, before changing the bootstrap helper. Attempt02's
120-second child timeout was caused by formatting a checker error. A disposable
probe reached the error in about 1.9 seconds: `j_nat_loop_region` bound an
unannotated `KDef` constructor. Upstream `err_show` strongly normalizes expected,
observed and contextual terms before printing them; reporting this particular
error expands compiler computations. The timeout therefore did not measure
checking or emission throughput. Preserve the original failed attempt.

Change only `selfhost/tools/stage0-library.mjs`, the TypeScript bootstrap adapter.
For upstream `Err` values, print a concise structural summary without calling
the evaluator, lowerer or upstream formatter. Retain a string expectation,
observed term head/name (including named holes), definition, exact source line
and column when present, a bounded source excerpt and any note. Bound all output
strings and do not traverse the book/context or serialize arbitrary terms;
their source references contain cycles. Mark the format as an unnormalized
bootstrap summary. Ordinary non-Err exceptions keep their existing messages.
This deliberately trades normalized context detail for a predictable failure
path; the self-hosted compiler's user diagnostics are unchanged.

An always-structural bootstrap formatter is smaller and more reliable than
guessing which terms will normalize cheaply. A worker/subprocess formatter with
a deadline would add lifecycle and protocol complexity to a path that already
has the exact source and rejected construct available. Keep successful checking,
export selection, ownership checking and emission byte-for-byte unchanged.

Before concluding, run the frozen attempt02 source with the changed helper under
a 10-second deadline, retaining its rejection and source location. Compare a
successful small library emitted by old and new helpers byte-for-byte and execute
its exports. Exercise representative parse/type/named-hole and missing-export
errors, requiring prompt failure and no output module. Record tool/source/pinned
upstream identities, all subprocess outcomes and elapsed developer-loop time;
these diagnostic observations are not generated-program performance timings.

## Exact bootstrap recipe admission

Attempt04 successfully generated its genuine checked API, then the equality
derivative correctly rejected the changed, not-yet-reviewed bootstrap helper.
Before retrying, admit exactly two coherent recipe bundles for the existing
Phase23 pin: the original stage0/assembler pair and the diagnostic-only stage0
hash paired with that same unchanged assembler. Do not accept arbitrary helper
hashes, mix recipes across upstream pins, weaken provenance/input identity checks,
or change transformation version6. Keep every historical transformation's exact
replay behavior. Validate old/new provenance acceptance, unknown/tampered/duplicate
recipe rejection, and existing equality tests before the next checked attempt.
