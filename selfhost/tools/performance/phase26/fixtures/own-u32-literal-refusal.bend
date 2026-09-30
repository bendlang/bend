# Upstream tests/check/u32_literal_own_u32: numeric literal has the wrong identity.
type U32 is Data:
  Foo{}

def bench() -> U32:
  5
