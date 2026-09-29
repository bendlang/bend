# Reuse scanned ASCII lengths

The [one-expression lexer change](../../design/phase16/ascii-token-width.md)
passes a genuine checked/v5 build and focused36. All **59 complete lexer/parser
controls** agree exactly with the parent at both origins1 and4097, including
whole Base, quotes, astral text, CRLF, numeric words and rejected partial books.

Private instrumentation counts real dg_width calls, including recursive calls.
For Base they fall **50,102→1,985** at each offset; the simple ASCII stream falls
28→0. Quoted text retains its UTF16 traversal, and the raw offset-zero path makes
zero width calls in both images. This is an operation-count result, not a measured
whole-compiler speedup. No physical line, definition, type or pass is added.

The change is integrated into wave4. The full wave4 timing still costs 11.88% more
than Phase15 on identical final source, so performance recovery remains open.
Evidence: `ascii-width-source-01`, `ascii-width-build-01` and
`ascii-width-controls-01`, under `selfhost/build/phase16/`.
