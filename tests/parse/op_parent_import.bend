# a module reached through ../ names its defs ../<path>.<def>: that leading
# dot is not an operator's (.add, .sub, ..), so ": T" leaves the name alone
import Base
import ../import/unsafe_lib.bend as U

def main() -> IO(Unit):
  IO.print(Nat.show((U.safe(2n) + 1n : Nat)))

#|3
