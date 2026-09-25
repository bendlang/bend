# A million mutual tail calls must run in constant stack, including a cycle
# with a self-recursive member. IO.now keeps the depth out of constant folding.
import Base

@unsafe
def even(n: Nat) -> Bool:
  match n:
    case 0n:
      True{}
    case 1n+p:
      odd(p)

@unsafe
def odd(n: Nat) -> Bool:
  match n:
    case 0n:
      False{}
    case 1n+p:
      even(p)

@unsafe
def hop(n: Nat) -> Nat:
  loop(n, False{})

@unsafe
def loop(n: Nat, b: Bool) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      match b:
        case True{}:
          hop(p)
        case False{}:
          loop(p, True{})

def main() -> IO(Unit):
  do IO<Unit>:
    t : Nat <- IO.now()
    IO.print(Bool.show(even(Nat.add(1000000n, Nat.mul(Nat.mod(t, 1n), 1n)))))
    u : Nat <- IO.now()
    IO.print(Nat.show(hop(Nat.add(1000000n, Nat.mul(Nat.mod(u, 1n), 1n)))))

#|True
#|0
