# a module whose own goal fails, for goal_own
import Base
import ./mod.bend as M

def quad(n: Nat) -> Nat:
  M.double(M.double(n))

def quad_id(x: Nat) -> {quad(x) == x : Nat}:
  {==}
