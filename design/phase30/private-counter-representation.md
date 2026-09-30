# Numeric representation for a private countdown

Prospective experiment, 2026-09-30. The pinned TypeScript JavaScript backend uses
Number for native Nat values and converts at its host boundary. Our public ABI
uses BigInt. A closed scalar loop can potentially keep its private countdown as
Number while preserving that public ABI. This is separate from eliminating
generic helper calls.

First derive two disposable versions of the existing Phase29 Mandelbrot helper
fixture using the frozen scalar-region derivation: BigInt-region and otherwise
identical Number-counter region. The latter changes only the private loop's
initial counter conversion, zero comparison and predecessor subtraction. Leave
the entry guard, helper functions, public matcher, arithmetic, arguments, Zero
body and fallback unchanged. Refuse the derivation unless the predecessor alias
appears only as the first self-tail argument. The count is a validated native
48-bit Nat, which is exactly representable by Number throughout decrement.

Correctness includes the existing120 independent points, counts0/1/2/31/128,
50,000 iterations, saved partials, invalid host counters selecting fallback and
direct private-loop small-count tests near numeric precision boundaries where
possible without performing an astronomical number of iterations. The general
rule must decline if the predecessor escapes into an arithmetic operand,
closure, record or another state slot. Do not convert arbitrary BigInt arithmetic
or claim the full Nat representation has changed.

Freeze hashes/configs before timing. Use the existing exclusive CPU3 paired
screen and longer-warm confirmation against Phase29, both region variants and
pinned TypeScript on the same128/524800 helper point. Report the representation
ablation separately from the combined region gain. Large counts are not timed.
If the gain is small, retain the simpler BigInt compiler implementation.
