# io: a woken try_ waiter cuts its own timer wherever it sits in the timer
# list. 300 senders park on a with a 60 s bound, then 300 on b with 30 s and
# 300 on b with 60 s, so b's timers sit both before and after a's; on JS the
# clock is stopped first, so b's 60 s timers are due at the same time as a's.
# Draining b, then a, leaves no timer: a recv that nothing will answer then
# reports the deadlock at once instead of waiting out the bounds.
import Base

def Clock.stop() -> IO(Unit):
  import "./chan_try_wake_timers.c"
  import "./chan_try_wake_timers.js"

def sender(c: Chan(U32), +i: U32, ms: U32) -> IO(Unit):
  do IO<Unit>:
    r : Poll<&1, &1, Result<&1, &1, U32, Unit>, U32> <- Chan.try_send(U32, c, i, ms)
    IO.pure(Unit, Unit{})

def spawn_all(n: Nat, +c: Chan(U32), +next: U32, +ms: U32) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        u : Unit <- IO.spawn(Unit, sender(c, next, ms))
        spawn_all(p, c, U32.inc(next), ms)

def val(r: Maybe<&1, U32>) -> U32:
  match r:
    case Some{v}:
      v
    case None{}:
      0

def drain(n: Nat, +c: Chan(U32), acc: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, acc)
    case 1n+p:
      do IO<U32>:
        r : Maybe<&1, U32> <- Chan.recv(U32, c)
        drain(p, c, U32.add(acc, val(r)))

def main() -> IO(Unit):
  do IO<Unit>:
    +a : Chan(U32) <- Chan.new(U32, 0)
    +b : Chan(U32) <- Chan.new(U32, 0)
    t : Unit <- Clock.stop()
    x : Unit <- spawn_all(300n, a, 0, 60000)
    y : Unit <- spawn_all(300n, b, 0, 30000)
    z : Unit <- spawn_all(300n, b, 300, 60000)
    sb : U32 <- drain(600n, b, 0)
    sa : U32 <- drain(300n, a, 0)
    u : Unit <- IO.print("b " ++ U32.show(sb) ++ ", a " ++ U32.show(sa))
    r : Maybe<&1, U32> <- Chan.recv(U32, b)
    IO.pure(Unit, Unit{})

#|b 179700, a 44850
#|bend: deadlock: every computation waits on a channel
#|exit 1
