# the C emitter's show pass runs before file_book resets its caches. A second
# book may reuse these names with another layout; gates/test compiles B, this
# file, then B again in one process and byte-compares B's two emissions.
import Base

type CacheLayout is Data:
  CacheLayoutOne{x: U32}

def main() -> CacheLayout:
  CacheLayoutOne{7}

#|CacheLayoutOne{7}
