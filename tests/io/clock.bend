# io (io_clock): Mono uses IO.now's origin and unit conversion; both
# clocks normalize their nanosecond part without pinning a timestamp.
import Base

def clock_ok(before: Nat, after: Nat, mono: Nat & U32, wall: Nat & U32) -> Bool:
  (seconds, +nanoseconds) = mono
  (_, wall_ns) = wall
  +ms = Nat.add(Nat.mul(seconds, 1000n), U32.to_nat(U32.div(nanoseconds, 1000000)))
  Bool.and(U32.is_lt(nanoseconds, 1000000000),
    Bool.and(U32.is_lt(wall_ns, 1000000000),
      Bool.and(Nat.is_le(before, ms), Nat.is_le(ms, after))))

def clock_show(ok: Bool) -> String:
  match ok:
    case True{}:
      "ok"
    case False{}:
      "clock mismatch"

def main() -> IO(Unit):
  do IO<Unit>:
    wall : Nat & U32 <- IO.clock(Wall{})
    before : Nat <- IO.now()
    mono : Nat & U32 <- IO.clock(Mono{})
    after : Nat <- IO.now()
    IO.print(clock_show(clock_ok(before, after, mono, wall)))

#|ok
