# The run queue keeps FIFO through compaction: 20000 spawned waiters park on
# a channel in order, then a closer spawned after them closes it, which makes
# all 20000 runnable at once. Each reports its index on a second channel, so
# main must see 0, 1, 2, ... (the queue compacts with live runs behind; an
# off-by-one in the compaction drops, repeats or reorders one).
import Base

def waiter(c: Chan(U32), +out: Chan(U32), i: U32) -> IO(Unit):
  do IO<Unit>:
    r : Maybe<&1, U32> <- Chan.recv(U32, c)
    s : Result<&1, &1, U32, Unit> <- Chan.send(U32, out, i)
    IO.pure(Unit, Unit{})

def spawn_all(n: Nat, +c: Chan(U32), +out: Chan(U32), +next: U32) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        u : Unit <- IO.spawn(Unit, waiter(c, out, next))
        spawn_all(p, c, out, U32.inc(next))

def check(ok: Bool, at: U32) -> IO(Unit):
  match ok:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, "woken out of order at " ++ U32.show(at))

def got(+want: U32, r: Maybe<&1, U32>) -> IO(U32):
  match r:
    case Some{+v}:
      do IO<U32>:
        u : Unit <- check(U32.is_eq(v, want), want)
        IO.pure(U32, v)
    case None{}:
      IO.die(U32, 1, "waiters ran out")

def drain(n: Nat, +out: Chan(U32), +next: U32, acc: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, acc)
    case 1n+p:
      do IO<U32>:
        r : Maybe<&1, U32> <- Chan.recv(U32, out)
        v : U32 <- got(next, r)
        drain(p, out, U32.inc(next), U32.add(acc, v))

def main() -> IO(Unit):
  do IO<Unit>:
    +c : Chan(U32) <- Chan.new(U32, 0)
    +out : Chan(U32) <- Chan.new(U32, 20000)
    a : Unit <- spawn_all(20000n, c, out, 0)
    b : Unit <- IO.spawn(Unit, Chan.close(U32, c))
    s : U32 <- drain(20000n, out, 0, 0)
    IO.print(U32.show(s))

#|199990000
