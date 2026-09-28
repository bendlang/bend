# bend2 converts functions up to eta; BendTT's kernel does not, and
# never unfolds a bare def. --verdict puts each term of a function type
# eta-long, so both sides of each equation here are lambdas the kernel
# compares under the binder, unfolding the applied defs. Before, the
# kernel rejected each one
import Base

def f(x: U32) -> U32:
  x

def g(x: U32) -> U32:
  x

def add(a: U32, b: U32) -> U32:
  U32.add(a, b)

def plus(a: U32, b: U32) -> U32:
  U32.add(a, b)

# two eta-redexes of different heads
def redexes() -> {(x => f(x)) == (x => g(x)) : U32 -> U32}:
  {==}

# a def against a lambda
def def_lam() -> {f == (x => x) : U32 -> U32}:
  {==}

# a partial application against a lambda
def partial() -> {add(1) == (y => plus(1, y)) : U32 -> U32}:
  {==}

# an eta-redex passed live against its head
def same(h: U32 -> U32, -k: U32 -> U32, -e: {h == k : U32 -> U32}) -> U32:
  h(1)

# a carrier only the call knows: the endpoints go eta-long there
def same_at(A: Type, a: A, -b: A, -e: {a == b : A}) -> A:
  a

# a function as a type's index
type Tag<-h: U32 -> U32> is Data:
  TT{}

def use(-h: U32 -> U32, t: Tag<h>) -> U32:
  2

def tag() -> Tag<f>:
  TT{}

def main() -> U32:
  (same(x => f(x), f, {==}) + same_at(U32 -> U32, f, g, {==})(3) + use(g, tag()) : U32)

#|6
