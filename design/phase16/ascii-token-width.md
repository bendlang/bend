# Reuse the lexer's existing ASCII token length

The indexed lexer recomputes `dg_width(word)` after scanning every identifier or
number. The existing `FScanned.size` already counts exactly the same UTF16 units
for these words: `f_scan_word` accepts only ASCII identifier characters and the
ASCII exponent signs. Quoted tokens are different and must retain their actual
UTF16 traversal, including astral codepoints and escapes.

Change only `f_lex_scanned`'s indexed end calculation. Preserve the offset-zero
legacy guard, use the stored size for kind1, and keep `dg_width` for quotes.
No scanner, token kind, source representation, helper or extra pass changes.
The parser owner reviewed the ASCII invariant and confirmed no overlapping lexer
edit. Parent is the isolated range-cost composition; its inconclusive timing and
higher observed peak memory remain explicit.

Before selection, compare complete raw/indexed token lists and parsed trees with
the unchanged parent at offsets1 and4097 for the existing cursor fixtures, failed
partial books, whole Base, quotes/escapes/astral text/comments/CRLF/numeric exponents.
Instrument copied checked APIs to count real dg_width invocations. An ASCII-only
word stream must make zero width calls in the candidate; raw offset-zero behavior
must remain identical. Build through the genuine checked/v5 workflow and retain
focused36 results. A confirming exclusive whole-source comparison is required:
eliminating calls alone does not prove a measurable speed or memory improvement.
