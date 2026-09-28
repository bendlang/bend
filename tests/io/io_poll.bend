# io (io_poll): IO.poll answers Ready when its act answers without waiting
# and Wait{rest} where it would park; rest is the act from there on, its
# waiting effect not yet started: a send left in rest puts nothing in the
# channel until rest runs.
import Base

# says whether s is ready, and gives it back
def tell(-A: Type, name: String, s: IO.Step<A>) -> IO(IO.Step<A>):
  match s:
    case Ready{value}:
      IO.bind(Unit, IO.Step<A>, IO.print(String.append(name, ": ready")),
        u => IO.pure(IO.Step<A>, Ready{value}))
    case Wait{rest}:
      IO.bind(Unit, IO.Step<A>, IO.print(String.append(name, ": wait")),
        u => IO.pure(IO.Step<A>, Wait{rest}))

# the value, resuming rest if it is not ready
def get(-A: Type, s: IO.Step<A>) -> IO(A):
  match s:
    case Ready{value}:
      IO.pure(A, value)
    case Wait{rest}:
      IO.resume(A, rest)

def got(m: Maybe<&1, U32>) -> String:
  match m:
    case None{}:
      "closed"
    case Some{value}:
      U32.show(value)

def show_got(s: IO.Step<Maybe<&1, U32>>) -> IO(Unit):
  match s:
    case Ready{value}:
      IO.print(String.append("  got ", got(value)))
    case Wait{rest}:
      IO.pure(Unit, Unit{})

def poll_recv(name: String, +ch: Chan(U32)) -> IO(Unit):
  do IO<Unit>:
    r : IO.Step<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, Chan.recv(U32, ch))
    s : IO.Step<Maybe<&1, U32>> <- tell(Maybe<&1, U32>, name, r)
    show_got(s)

def chans(c: Chan(U32)) -> IO(U32):
  +ch = c
  do IO<U32>:
    Unit <- poll_recv("recv empty", ch)
    s1 : IO.Step<Bool> <- IO.poll(Bool, Chan.send(U32, ch, 7))
    t1 : IO.Step<Bool> <- tell(Bool, "send room", s1)
    s2 : IO.Step<Bool> <- IO.poll(Bool, Chan.send(U32, ch, 8))
    late : IO.Step<Bool> <- tell(Bool, "send full", s2)
    Unit <- poll_recv("recv one", ch)
    Unit <- poll_recv("recv, the held send not in", ch)
    ok : Bool <- get(Bool, late)
    Unit <- IO.print(String.append("rest sends: ", Bool.show(ok)))
    Unit <- poll_recv("recv the rest's", ch)
    Unit <- Chan.close(U32, ch)
    Unit <- poll_recv("recv closed", ch)
    return 0

# cancels s if it waits
def drop_step(-A: Type, s: IO.Step<A>, gone: A) -> IO(A):
  match s:
    case Ready{value}:
      IO.pure(A, value)
    case Wait{rest}:
      IO.cancel(A, rest)

def cancels(c: Chan(U32)) -> IO(U32):
  +ch = c
  do IO<U32>:
    Bool <- Chan.send(U32, ch, 1)
    s : IO.Step<Bool> <- IO.poll(Bool, Chan.send(U32, ch, 2))
    t : IO.Step<Bool> <- tell(Bool, "send full", s)
    ok : Bool <- drop_step(Bool, t, False{})
    Unit <- IO.print(String.append("cancelled send: ", Bool.show(ok)))
    Unit <- poll_recv("recv the first", ch)
    Unit <- poll_recv("recv, the cancelled send not in", ch)
    r : IO.Step<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, Chan.recv(U32, ch))
    m : Maybe<&1, U32> <- drop_step(Maybe<&1, U32>, r, None{})
    Unit <- IO.print(String.append("cancelled recv: ", got(m)))
    return 0

def naps() -> IO(U32):
  do IO<U32>:
    z1 : IO.Step<Unit> <- IO.poll(Unit, IO.sleep(30))
    n1 : IO.Step<Unit> <- tell(Unit, "sleep", z1)
    z2 : IO.Step<Unit> <- IO.poll(Unit, get(Unit, n1))
    n2 : IO.Step<Unit> <- tell(Unit, "rest at once", z2)
    Unit <- IO.sleep(60)
    z3 : IO.Step<Unit> <- IO.poll(Unit, get(Unit, n2))
    n3 : IO.Step<Unit> <- tell(Unit, "rest later", z3)
    return 0

def two(d: Chan(U32)) -> IO(U32):
  +ch = d
  act = IO.bind(Unit, U32, IO.print("before"), u =>
    IO.bind(Maybe<&1, U32>, U32, Chan.recv(U32, ch), m =>
      IO.bind(Unit, U32, IO.print("after"), v => IO.pure(U32, 5))))
  do IO<U32>:
    p : IO.Step<U32> <- IO.poll(U32, act)
    q : IO.Step<U32> <- tell(U32, "two effects", p)
    Unit <- IO.spawn(Bool, Chan.send(U32, ch, 1))
    x : U32 <- get(U32, q)
    Unit <- IO.print(String.append("two effects answer ", U32.show(x)))
    return 0

def main() -> IO(U32):
  do IO<U32>:
    c : Chan(U32) <- Chan.new(U32, 1)
    a : U32 <- chans(c)
    c2 : Chan(U32) <- Chan.new(U32, 1)
    a2 : U32 <- cancels(c2)
    b : U32 <- naps()
    d : Chan(U32) <- Chan.new(U32, 0)
    two(d)

#|recv empty: wait
#|send room: ready
#|send full: wait
#|recv one: ready
#|  got 7
#|recv, the held send not in: wait
#|rest sends: True
#|recv the rest's: ready
#|  got 8
#|recv closed: ready
#|  got closed
#|send full: wait
#|cancelled send: False
#|recv the first: ready
#|  got 1
#|recv, the cancelled send not in: wait
#|cancelled recv: closed
#|sleep: wait
#|rest at once: wait
#|rest later: ready
#|before
#|two effects: wait
#|after
#|two effects answer 5
