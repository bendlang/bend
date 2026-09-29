# Located literal failures without successful-input rescans

Prospective bounded stage from immutable semantic source05, independent of the
pending token-context stage. Target four remaining parser fixtures/eight paired
observations: parse/expected_float_literal.bend, parse/hex_no_digits.bend,
parse/word_overflow_literal.bend, parse/invalid_string_escape.bend.

The lexer already carries exact literal origin. Numeric lowering currently
returns an unlocated generic Error; string decoding can embed that Error below
several valid SCon nodes. Preserve the existing conversion and error-selection
order. Attach explicit diagnostic payloads where the conversion rejects. For
numeric failures, inspect the rejected spelling only after conversion failed:
non-decimal suffixes point after decimal digits, and a decimal U32 overflow
covers the whole literal. Unsupported failure families keep their old fallback.

Thread the literal's existing origin through the existing string-decoding
recursion, sharing the same character decoder and preserving generated string
shape. On escape refusal only, replay that rejected literal to recover the
actual parser cursor (after consuming the rejected escape character); compute
UTF16 offset from the existing literal interval. No successful literal gets a
second scan, and no renderer parses a legacy error string. Valid escapes,
Unicode scalars, decimal maximum, valid floats, string structure, source interval
boundaries, and first-error order need direct pinned controls. Keep all failed
attempts. Run four paired fixtures, focused36, and the244 parser census before
handoff. Parent owns full-corpus and performance guards.
