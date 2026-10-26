# A big buffer keeps FIFO through compaction and a drain after close: fill a
# 100000-slot buffer, then a spawned producer parks sending 20000 more (each
# receive takes a value and wakes it into the buffer) and closes. Draining
# all 120000 values must see them in the order they were sent, then None.
import Base

def check(ok: Bool, at: U32) -> IO(Unit):
  match ok:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, "wrong buffered value at " ++ U32.show(at))

def sent(r: Result<&1, &1, U32, Unit>) -> IO(Unit):
  match r:
    case Done{u}:
      IO.pure(Unit, Unit{})
    case Fail{v}:
      IO.die(Unit, 1, "buffered send failed")

def got(+want: U32, r: Maybe<&1, U32>) -> IO(U32):
  match r:
    case Some{+v}:
      do IO<U32>:
        u : Unit <- check(U32.is_eq(v, want), want)
        IO.pure(U32, v)
    case None{}:
      IO.die(U32, 1, "buffer ran out")

def fill(n: Nat, +c: Chan(U32), +next: U32) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        r : Result<&1, &1, U32, Unit> <- Chan.send(U32, c, next)
        u : Unit <- sent(r)
        fill(p, c, U32.inc(next))

def drain(n: Nat, +c: Chan(U32), +next: U32, acc: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, acc)
    case 1n+p:
      do IO<U32>:
        r : Maybe<&1, U32> <- Chan.recv(U32, c)
        v : U32 <- got(next, r)
        drain(p, c, U32.inc(next), U32.add(acc, v))

def feed(+c: Chan(U32)) -> IO(Unit):
  do IO<Unit>:
    a : Unit <- fill(20000n, c, 100000)
    Chan.close(U32, c)

def ended(r: Maybe<&1, U32>) -> IO(Unit):
  match r:
    case None{}:
      IO.pure(Unit, Unit{})
    case Some{v}:
      IO.die(Unit, 1, "closed buffer retained data")

def main() -> IO(Unit):
  do IO<Unit>:
    +c : Chan(U32) <- Chan.new(U32, 100000)
    a : Unit <- fill(100000n, c, 0)
    b : Unit <- IO.spawn(Unit, feed(c))
    s : U32 <- drain(120000n, c, 0, 0)
    r : Maybe<&1, U32> <- Chan.recv(U32, c)
    u : Unit <- ended(r)
    IO.print(U32.show(s))

#|2904972704
