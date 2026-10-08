# Recursive function domains have no finite eta-long normal form.
# Run --verdict too: frontend acceptance alone does not exercise eta expansion.
import Base

def F() -> Type:
  @-x: F -> Empty

def use_f(f: @-x: F -> Empty) -> Empty:
  f(f)

def G() -> Type:
  (G -> U32) -> U32

def use_g(g: G, k: G -> U32) -> U32:
  g(k)

def keep_g(g: G) -> G:
  g

def finite(f: (U32 -> U32) -> U32, h: U32 -> U32) -> U32:
  f(h)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(finite(h => h(20), x => (x + 3 : U32))))

#| 23
