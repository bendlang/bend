# A timed-out sender behind a live waiter must release its discarded payload.
# JS-only: the host checks collection in a child with a pre-existing WeakRef.
import Base

def Host.run(action: IO(Unit)) -> IO(U32):
  import "./chan_try_release.js"

def Host.payload() -> IO(Array<U32>):
  import "./chan_try_release.js"

def Host.collected(c: Chan(Array<U32>)) -> IO(U32):
  import "./chan_try_release.js"

def blocked(c: Chan(Array<U32>)) -> IO(Unit):
  IO.bind(Result<&1, &1, Array<U32>, Unit>, Unit,
    Chan.send(Array<U32>, c, Array.new(U32, 0n, 0)), r => IO.pure(Unit, Unit{}))

def timed_out(p: Poll<&1, &1, Result<&1, &1, Array<U32>, Unit>, Array<U32>>) -> IO(Unit):
  match p:
    case Wait{rest}: IO.pure(Unit, Unit{})
    case Ready{r}: IO.die(Unit, 1, "expected timeout")

def probe() -> IO(Unit):
  do IO<Unit>:
    +c : Chan(Array<U32>) <- Chan.new(Array<U32>, 0)
    IO.spawn(Unit, blocked(c))
    IO.sleep(1)
    a : Array<U32> <- Host.payload()
    r : Poll<&1, &1, Result<&1, &1, Array<U32>, Unit>, Array<U32>> <-
      Chan.try_send(Array<U32>, c, a, 1)
    timed_out(r)
    IO.sleep(1)
    code : U32 <- Host.collected(c)
    Chan.close(Array<U32>, c)
    IO.exit(code)

def main() -> IO(Unit):
  do IO<Unit>:
    code : U32 <- Host.run(probe())
    IO.print(U32.show(code))

#|0
