# Phase16: compact literal memo identity and size boundary

Freeze these controls before promoting literal source05. Its compact value is
explicit and preserves the distinction between a written literal and constructor
syntax. Source05's literal key includes kind, unsigned numeric payload or decoded
text, and excludes intervals. It deliberately has not installed the rejected
scoped-key06 algorithm. The old `sp_len(key)>32768` guard is still incidental to
the local serialization, so the representation candidate remains unselected.

Compare pinned parsed/lowered keys and materialized instance sets for repeated
U32, equivalent string escapes, literal versus written U32/Nat/String constructor,
F32 positive and negative zero, distinct bits and nested calls. Retain existing
multiple-template/quantity/cycle/grow/grow_double controls and the existing lost
Lam optional-quantity witness. Do not normalize signed zero: the pinned parser
stores F32 bits, so JSON serializes0 and2147483648 differently; the earlier
suggestion to fold signed zero is rejected by that source evidence.

Measure direct keys for ASCII, quote/backslash/control characters and astral text
at/below/above the pinned32768 UTF16 size boundary. The pinned key is
JSON.stringify(term_lower(argument)) with spans removed, and multiple arguments
join with one newline. Controls must compare actual pinned lengths, not assumed
character counts. Source interpretation may use code points, while this resource
limit counts UTF16 code units and JSON escapes.

There is a separate representational blocker for an exact general serializer:
generated Lam with absent q and written affine Lam both currently have ordinary
Lam/qt1, while pinned JSON preserves presence. Literal identity alone cannot
recover that fact. Retain evidence; either preserve this explicit Lambda syntax
fact before designing one canonical serializer/count contract, or explicitly
leave the existing general guard approximation inherited. Never tune a cutoff,
pad strings, guess quantity presence from origin/name, or claim a complete memo
contract from corpus agreement.
