# A flat generic def at a record of scalars takes and returns its words
# (#1195): its spin is one per layout of its erased arguments. One that
# returns an A gets it in words, from words or from a list's node; one
# that only stores its A in a node keeps it boxed. Picks, swaps and a
# tail-recursive last under a bang: the last stays a loop.
import Base

type Tint is Data:
  Tint{r: F32, g: F32, b: F32}

type Two is Data:
  Two{x: U32, y: U32}

def choose(-A: Type, c: Bool, a: A, b: A) -> A:
  match c:
    case False{}:
      b
    case True{}:
      a

def swap(-A: Type, -B: Type, p: A & B) -> B & A:
  (a, b) = p
  (b, a)

def head(-A: Type, xs: List<A>, d: A) -> A:
  match xs:
    case Nil{}:
      d
    case Con{h, t}:
      h

def last(-A: Type, xs: List<A>, d: A) -> A:
  match xs:
    case Nil{}:
      d
    case Con{h, t}:
      last(A, t, h)

def twos(+n: Nat, +i: U32) -> List<Two>:
  match n:
    case 0n:
      []
    case 1n+p:
      Two{i, (i * 3 : U32)} <> twos(p, (i + 1 : U32))

def red(t: Tint) -> U32:
  Tint{+r, g, b} = t
  F32.to_u32((r * 100.0 : F32))

def sum(t: Two) -> U32:
  Two{+x, +y} = t
  (x + y : U32)

def tally(p: U32 & Tint) -> U32:
  (n, t) = p
  (n + red(t) : U32)

def total(p: U32 & Two) -> U32:
  (n, t) = p
  (n + sum(t) : U32)

def swapped() -> U32:
  tally(swap(Tint, U32, (Tint{0.5, 0.25, 0.125}, 7)))

def leaf(+i: U32) -> U32:
  +x = (U32.to_f32((i % 1000 : U32)) * 0.001 : F32)
  (red(choose(Tint, (x < 0.5 : F32), Tint{0.84, 0.95, 1.2}, Tint{x, 0.0, 0.0}))
    + sum(choose(Two, U32.is_even(i), Two{i, 1}, Two{2, i}))
    + total(swap(Two, U32, (Two{i, 5}, (i % 7 : U32))))
    + sum(last(Two, twos(20n, i), Two{i, 1})) : U32)

def tree(+k: Nat, +i: U32) -> U32:
  match k:
    case 0n:
      leaf(i)
    case 1n+e:
      a b = tree(e, (i * 2 : U32)) tree(e, (i * 2 + 1 : U32))
      (a + b : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(swapped()))
    IO.print(U32.show(sum(head(Two, [Two{3, 4}, Two{5, 6}], Two{0, 0}))))
    IO.print(U32.show(sum(head(Two, [], Two{1, 1}))))
    IO.print(String.append(choose(String, True{}, "a", "b"), choose(String, False{}, "c", "d")))
    IO.print(U32.show(tree!(10n, 0)))

#|57
#|7
#|2
#|ad
#|3311469
