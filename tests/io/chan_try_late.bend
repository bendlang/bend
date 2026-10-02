# io (io_chan_try_late): a try_ deadline that passes in the same loop pass
# as an earlier timer still withdraws its waiter before anything runs, on
# every lane. A receive bounded by 10 ms parks, a sender sleeps 1 ms, and a
# busy computation holds the loop past both. The sender's timer is due
# first, but the receive's deadline has passed too: it answers Wait{}, the
# sender finds no receiver and parks, and the recv after the Wait takes
# its 7.
import Base

def spin(n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      spin(p, (acc * 1664525 + 1013904223 : U32))

def show(r: Poll<&1, &1, Maybe<&1, U32>, Unit>) -> String:
  match r:
    case Ready{Some{v}}:
      "A: ready got " ++ U32.show(v)
    case Ready{None{}}:
      "A: ready ended"
    case Wait{u}:
      "A: wait"

def got(m: Maybe<&1, U32>) -> String:
  match m:
    case Some{v}:
      "A: then got " ++ U32.show(v)
    case None{}:
      "A: then ended"

def send(+c: Chan(U32)) -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.sleep(1)
    Result<&1, &1, U32, Unit> <- Chan.send(U32, c, 7)
    IO.print("S: sent")

def spun(m: Maybe<&1, Nat>) -> IO(Unit):
  match m:
    case Some{n}:
      IO.print("B: " ++ U32.show(spin(n, 0)))
    case None{}:
      IO.print("B: none")

# The count crosses a channel, so no build folds the spin.
def busy(+d: Chan(Nat)) -> IO(Unit):
  do IO<Unit>:
    Result<&1, &1, Nat, Unit> <- Chan.send(Nat, d, 50000000n)
    m : Maybe<&1, Nat> <- Chan.recv(Nat, d)
    spun(m)

def recv(+c: Chan(U32), d: Chan(Nat)) -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.spawn(Unit, send(c))
    Unit <- IO.spawn(Unit, busy(d))
    r : Poll<&1, &1, Maybe<&1, U32>, Unit> <- Chan.try_recv(U32, c, 10)
    Unit <- IO.print(show(r))
    m : Maybe<&1, U32> <- Chan.recv(U32, c)
    IO.print(got(m))

def go(c: Chan(U32)) -> IO(Unit):
  IO.bind(Chan(Nat), Unit, Chan.new(Nat, 1), d => recv(c, d))

def main() -> IO(Unit):
  IO.bind(Chan(U32), Unit, Chan.new(U32, 0), go)

#|B: 767263360
#|A: wait
#|A: then got 7
#|S: sent
