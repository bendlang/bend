# io (io_now): IO.now answers a monotonic clock in milliseconds, so
# the span around a 2 ms sleep is at least 1 (the clock rounds
# down): the test prints ok, never early, and never the span itself.
import Base

law late:
  for c: Cmp
  String

def late(c):
  match c:
    case LT{}:
      "early"
    case EQ{}:
      "ok"
    case GT{}:
      "ok"

law main:
  IO(U32)

def main():
  do IO<U32>:
    t0 : Nat <- IO.now()
    Unit <- IO.sleep(2)
    t1 : Nat <- IO.now()
    Unit <- IO.print(late(Nat.cmp(Nat.sub(t1, t0), 1n)))
    return 0

#|ok
