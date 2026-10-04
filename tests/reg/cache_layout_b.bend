# the two live fields deliberately give the same type and constructor names a
# different layout than cache_layout_a.bend; see that fixture and gates/test.
import Base

type CacheLayout is Data:
  CacheLayoutOne{x: U32, y: U32}

def main() -> CacheLayout:
  CacheLayoutOne{8, 9}

#|CacheLayoutOne{8, 9}
