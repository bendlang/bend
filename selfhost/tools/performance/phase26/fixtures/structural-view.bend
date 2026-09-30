# Direct Word(32n) projection/reconstruction must retain its ordinary JS behavior.
import Base

def view(n: U32) -> U32:
  match n:
    case U32{w}: U32{w}

def bench(n: U32, seed: U32) -> U32:
  U32.xor(view(n), seed)
