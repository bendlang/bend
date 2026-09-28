# a compound type argument takes parens: Maybe<U32 & U32> reads its first
# argument up to the &, which a type argument cannot continue past, so the
# parser asks for Maybe<(U32 & U32)>; a glued comparison still parses
import Base

def ok(r: Maybe<(U32 & U32)>) -> Bool:
  (1<2 && 2<3 : U32)

def bad(r: Maybe<U32 & U32>) -> U32:
  0

