# io (io_poll_deadline): IO.poll(ms, act) waits up to ms for a channel
# step. A recv whose value comes in time answers Ready; one that does not
# answers Late{None} without taking the late value, which a plain recv
# then gets. A send on a full channel that a reader drains in time answers
# Ready.
import Base

def tell(-A: Type, name: String, p: IO.Poll<A>, show: A -> String) -> IO(Unit):
  match p:
    case Ready{value}:
      IO.print(name ++ ": ready " ++ show(value))
    case Late{value}:
      IO.print(name ++ ": late " ++ show(value))

def got(m: Maybe<&1, U32>) -> String:
  match m:
    case None{}:
      "none"
    case Some{value}:
      U32.show(value)

def later(ms: U32, ch: Chan(U32), x: U32) -> IO(Bool):
  IO.bind(Unit, Bool, IO.sleep(ms), u => Chan.send(U32, ch, x))

def drain(ms: U32, ch: Chan(U32)) -> IO(Maybe<&1, U32>):
  IO.bind(Unit, Maybe<&1, U32>, IO.sleep(ms), u => Chan.recv(U32, ch))

def recvs(c: Chan(U32)) -> IO(U32):
  +ch = c
  do IO<U32>:
    Unit <- IO.spawn(Bool, later(20, ch, 1))
    r1 : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 1000, Chan.recv(U32, ch))
    Unit <- tell(Maybe<&1, U32>, "recv, sent in time", r1, got)
    Unit <- IO.spawn(Bool, later(150, ch, 2))
    r2 : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 30, Chan.recv(U32, ch))
    Unit <- tell(Maybe<&1, U32>, "recv, sent late", r2, got)
    m3 : Maybe<&1, U32> <- Chan.recv(U32, ch)
    Unit <- IO.print("then a recv gets the late one: " ++ got(m3))
    return 0

def sends(d: Chan(U32)) -> IO(U32):
  +ch = d
  do IO<U32>:
    Bool <- Chan.send(U32, ch, 5)
    Unit <- IO.spawn(Maybe<&1, U32>, drain(20, ch))
    s : IO.Poll<Bool> <- IO.poll(Bool, 1000, Chan.send(U32, ch, 6))
    Unit <- tell(Bool, "send on a full channel, drained in time", s, Bool.show)
    m : Maybe<&1, U32> <- Chan.recv(U32, ch)
    Unit <- IO.print("  and it is there: " ++ got(m))
    return 0

def main() -> IO(U32):
  do IO<U32>:
    c : Chan(U32) <- Chan.new(U32, 0)
    a : U32 <- recvs(c)
    d : Chan(U32) <- Chan.new(U32, 1)
    sends(d)

#|recv, sent in time: ready 1
#|recv, sent late: late none
#|then a recv gets the late one: 2
#|send on a full channel, drained in time: ready True
#|  and it is there: 6
