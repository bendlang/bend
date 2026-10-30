# io (io_chan_try_gone): try_ receivers whose deadline comes first leave the
# queue while live receivers wait in front of and behind them. A receive
# parks with no deadline, then 800 try_recv park behind it: three in four
# with 5 ms, which come back Wait{}, and one in four with 4 s. The 600 gone
# outnumber the live by more than 64, so the queue sheds them with live ones
# on both sides; then 201 sends reach the live receivers in the order they
# parked.
import Base

def check(ok: Bool, msg: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, msg)

def expect(+want: U32, r: Maybe<&1, U32>) -> IO(Unit):
  match r:
    case Some{+v}:
      check(U32.is_eq(v, want), "receiver " ++ U32.show(want) ++ " got " ++ U32.show(v))
    case None{}:
      IO.die(Unit, 1, "receiver " ++ U32.show(want) ++ " ended")

def first(c: Chan(U32)) -> IO(Unit):
  IO.bind(Maybe<&1, U32>, Unit, Chan.recv(U32, c), r => expect(0, r))

def short_wait(+i: U32, r: Poll<&1, &1, Maybe<&1, U32>, Unit>) -> IO(Unit):
  match r:
    case Wait{u}:
      IO.pure(Unit, Unit{})
    case Ready{m}:
      IO.die(Unit, 1, "short receiver " ++ U32.show(i) ++ " was woken")

def long_ready(+i: U32, r: Poll<&1, &1, Maybe<&1, U32>, Unit>) -> IO(Unit):
  match r:
    case Ready{m}:
      expect(U32.div(i, 4), m)
    case Wait{u}:
      IO.die(Unit, 1, "long receiver " ++ U32.show(i) ++ " timed out")

def receiver(long: Bool, c: Chan(U32), +i: U32) -> IO(Unit):
  match long:
    case True{}:
      IO.bind(Poll<&1, &1, Maybe<&1, U32>, Unit>, Unit, Chan.try_recv(U32, c, 4000), r => long_ready(i, r))
    case False{}:
      IO.bind(Poll<&1, &1, Maybe<&1, U32>, Unit>, Unit, Chan.try_recv(U32, c, 5), r => short_wait(i, r))

def spawn_all(n: Nat, +c: Chan(U32), +next: U32) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        u : Unit <- IO.spawn(Unit, receiver(U32.is_zero(U32.mod(next, 4)), c, next))
        spawn_all(p, c, U32.inc(next))

def sent(r: Result<&1, &1, U32, Unit>) -> IO(Unit):
  match r:
    case Done{u}:
      IO.pure(Unit, Unit{})
    case Fail{v}:
      IO.die(Unit, 1, "send failed")

def send_all(n: Nat, +c: Chan(U32), +next: U32) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        r : Result<&1, &1, U32, Unit> <- Chan.send(U32, c, next)
        u : Unit <- sent(r)
        send_all(p, c, U32.inc(next))

def main() -> IO(Unit):
  do IO<Unit>:
    +c : Chan(U32) <- Chan.new(U32, 0)
    a : Unit <- IO.spawn(Unit, first(c))
    b : Unit <- spawn_all(800n, c, 1)
    s : Unit <- IO.sleep(200)
    d : Unit <- send_all(201n, c, 0)
    IO.print("ok")

#|ok
