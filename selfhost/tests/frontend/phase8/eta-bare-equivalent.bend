import Base
def f(x: U32) -> U32: x
def g(x: U32) -> U32: x
def proof() -> {f == g : U32 -> U32}: {==}
