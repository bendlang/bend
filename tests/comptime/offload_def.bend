# the control for comptime_offload: a plain def's app!(3n) marks the same
# fid as a bang site
import Base

def inc(n: Nat) -> Nat:
  1n+n

def app(x: Nat) -> Nat:
  inc(x)

def main() -> IO(Unit):
  IO.print(Nat.show(app!(3n)))

#|4
