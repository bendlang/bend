# U64.to_nat keeps the Nat cap: a U64 past 2^48-1 fail-stops on every
# lane, as a Nat sum past it does (run/nat_overflow)
import Base

def main() -> IO(Unit):
  IO.print(Nat.show(U64.to_nat(281474976710656u64)))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
