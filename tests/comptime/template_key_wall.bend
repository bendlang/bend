# five U32 literals as ~ arguments: their structural keys, about 1900 chars
# each, stay under the 32768-char wall and the call instantiates
import Base

def Five(~a: U32, ~b: U32, ~c: U32, ~d: U32, ~e: U32) -> U32:
  U32.add(a, e)

def main() -> U32:
  Five(~1, ~2, ~3, ~4, ~5)
#|6
