# regression witness: a def whose only params are erased is a complete
# call at its bare head (zero live args), so carbonize's apps() took
# the head of `mk(3)` as a nested cut and applied the erased argument
# to the cut's result variable -- no longer a call, and bound() died
# "null is not an object (evaluating 'call_kind(cb, v(EMPTY)).k')" on
# both emitters. An erased argument never makes its head a nested call.
import Base
def mk(-p1: U32) -> String:
  "ab" ++ ""
def rs() -> String:
  v0 = mk(3)
  v0 ++ "c"
def main() -> IO(Unit):
  IO.print(rs())

#|abc
