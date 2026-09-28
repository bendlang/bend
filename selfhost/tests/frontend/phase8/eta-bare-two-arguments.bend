import Base
def f(x: U32, y: U32) -> U32: U32.add(x, y)
def g(x: U32, y: U32) -> U32: U32.add(x, y)
def proof() -> {f == g : U32 -> U32 -> U32}: {==}
