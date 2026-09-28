# io (io_nat_host_neg): a foreign effect answers a negative Nat. The C
# lane reads it as a word past the cap, which matches as a successor and
# fail-stops when Nat.show computes with it. The JS lane cannot hold that
# word exactly: it matches as a successor too and fail-stops at its
# first arithmetic use, with the same message and exit code.
import Base

law get:
  IO(Nat)

def get():
  import "./nat_host_neg.c"
  import "./nat_host_neg.js"

def tag(n: Nat) -> String:
  match n:
    case 0n:
      "zero"
    case 1n+p:
      "succ"

def report(+n: Nat) -> IO(Unit):
  do IO<Unit>:
    a : Unit <- IO.print(tag(n))
    IO.print(Nat.show(n))

def main() -> IO(Unit):
  IO.bind(Nat, Unit, get(), n => report(n))

#|succ
#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
