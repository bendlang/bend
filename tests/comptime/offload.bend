# a template head keeps its offload mark: app!(~inc, 3n) marks its fid
# as a bang site, as the plain-def app!(3n) of comptime_offload_def does
# (the third fid, after main and its first mint); app(~inc, 3n) marks none
import Base

def inc(n: Nat) -> Nat:
  1n+n

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def main() -> IO(Unit):
  IO.print(Nat.show(app!(~inc, 3n)))

#|4
