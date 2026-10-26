# Many parked senders keep FIFO through compaction and a close: 20000 spawned
# senders park on a rendezvous channel, in order. Receiving 15000 of them must
# see 0, 1, 2, ... (the queue compacts with live waiters behind), then a close
# fails the 5000 still parked and a receive after it answers None.
import Base

def sender(c: Chan(U32), i: U32) -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, U32, Unit> <- Chan.send(U32, c, i)
    IO.pure(Unit, Unit{})

def spawn_all(n: Nat, +c: Chan(U32), +next: U32) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        u : Unit <- IO.spawn(Unit, sender(c, next))
        spawn_all(p, c, U32.inc(next))

def check(ok: Bool, at: U32) -> IO(Unit):
  match ok:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, "wrong parked value at " ++ U32.show(at))

def got(+want: U32, r: Maybe<&1, U32>) -> IO(U32):
  match r:
    case Some{+v}:
      do IO<U32>:
        u : Unit <- check(U32.is_eq(v, want), want)
        IO.pure(U32, v)
    case None{}:
      IO.die(U32, 1, "senders ran out")

def drain(n: Nat, +c: Chan(U32), +next: U32, acc: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, acc)
    case 1n+p:
      do IO<U32>:
        r : Maybe<&1, U32> <- Chan.recv(U32, c)
        v : U32 <- got(next, r)
        drain(p, c, U32.inc(next), U32.add(acc, v))

def ended(r: Maybe<&1, U32>) -> IO(Unit):
  match r:
    case None{}:
      IO.pure(Unit, Unit{})
    case Some{v}:
      IO.die(Unit, 1, "closed channel handed a parked value")

def main() -> IO(Unit):
  do IO<Unit>:
    +c : Chan(U32) <- Chan.new(U32, 0)
    a : Unit <- spawn_all(20000n, c, 0)
    s : U32 <- drain(15000n, c, 0, 0)
    b : Unit <- Chan.close(U32, c)
    r : Maybe<&1, U32> <- Chan.recv(U32, c)
    u : Unit <- ended(r)
    IO.print(U32.show(s))

#|112492500
