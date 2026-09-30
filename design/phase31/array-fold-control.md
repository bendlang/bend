# A structurally different local-array source

This source-level control accompanies the full edit-distance transfer. A scalar
root creates one 128-slot Array<U32>, then a Nat countdown reads and updates one
slot per iteration while carrying a U32 accumulator. The intermediate value is a
Tuple with a delayed Array.set in its first field and a scalar in its second.
It has no Dp record, minimum selection, PRNG, four-array cell chain or nested DP.
The result is a scalar checksum. This challenges constructor-prefix analysis and
field-demand order at a different field position from edit distance.

Freeze the source before checked17 and pinned TypeScript library acquisition.
Compare n = 0, 1, 2, 7, 32, 64 and seed = 0, 1, 17, 4294967295 against an independent
U32 oracle. The production local-region implementation, if attempted, must also
run these same points and admit the full first-order helper graph; merely
renaming edit-distance helpers does not establish the same scope.

The baseline acquisition is correctness evidence only. No speed result is
claimed for this additional source, and it is not silently substituted into
any frozen row or full-pair timing. Raw material is retained under
`selfhost/build/phase31/local-data-fold-*`.

Before running controls, add n = 128, 129 and 257. These revisit the same physical
slots through the original modulo-indexed Array operations, so delayed writes
must become visible before later reads. An oracle that only checks n <= 64
would not expose that scheduling error. The emitted source remains unchanged.
