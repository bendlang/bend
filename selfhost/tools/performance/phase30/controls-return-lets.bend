import Base

# Prospective checked-source controls. No acquisition is claimed by this file.
type LetClosure is Data:
  LetClosure{run: U32 -> U32}

def let_identity(+x: U32) -> U32:
  x

@unsafe
def parallel_lets(+a: U32, +b: U32) -> U32:
  a b = U32.inc(b) U32.add(a, 2)
  U32.add(U32.mul(a, 100), b)

@unsafe
def nested_lets(+a: U32, +b: U32) -> U32:
  +a = U32.add(a, 3)
  a b = U32.inc(a) U32.add(b, 7)
  +a = U32.mul(a, 2)
  U32.add(U32.mul(a, 100), b)

@unsafe
def escaping_let(+a: U32) -> U32 -> U32:
  +saved = U32.add(a, 7)
  x => U32.add(saved, x)

@unsafe
def rhs_capture(+a: U32) -> U32 -> U32:
  a f = 1 {x => U32.add(a, x) : U32 -> U32}
  x => U32.add(a, f(x))

@unsafe
def record_closure(+a: U32) -> LetClosure:
  +saved = U32.add(a, 11)
  LetClosure{x => U32.add(saved, x)}

@unsafe
def callback_order(+callback: U32 -> U32, +a: U32) -> U32:
  x y = callback(a) callback(U32.inc(a))
  U32.add(U32.mul(x, 100), y)

@unsafe
def global_order(+a: U32) -> U32:
  x y = let_identity(a) let_identity(U32.inc(a))
  U32.add(U32.mul(x, 100), y)

@unsafe
def nested_factory(+a: U32) -> U32 -> U32 -> U32:
  +saved = U32.inc(a)
  b =>
    +middle = U32.add(saved, b)
    c => U32.add(middle, c)
