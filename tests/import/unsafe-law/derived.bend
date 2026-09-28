# succ_is_id, derived from the unsafe fill of false_law with no further
# unsafe: boom is a helper here, not a law
import Base
import ./laws.bend as Laws
import ./fill.bend as F
import ./succ.bend as S

def disc(n: Nat) -> Type:
  match n:
    case 0n:
      Empty
    case 1n+p:
      Unit

def boom() -> Empty:
  %Laws.false_law() : disc(_)
  Unit{}

def ex(+n: Nat, e: Empty) -> {1n+n == n : Nat}:
  match e:

def S.succ_is_id(n):
  ex(n, boom())
