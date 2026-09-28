import Base
def f(x: U32, y: U32) -> U32: U32.add(x, y)
def g(x: U32, y: U32) -> U32: U32.add(x, y)
def proof() -> {f(0) == g(0) : U32 -> U32}: {==}
