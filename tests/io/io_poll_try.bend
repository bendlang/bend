# io (io_poll_try): #1162's chan_try cases through IO.poll(0, _): on a channel with room for
# one, a send goes, a second one is late (full), and after the close a send
# answers False (closed, told apart from full); a recv takes the value,
# then is late, then answers None once closed. On a channel with no room, a
# sender parked on send hands its value to a polled recv, a receiver
# parked on recv takes a polled send's value, and a polled send with
# nobody waiting is late. By @aldeni.
import Base

def step(-A: Type, s: IO.Poll<A>, show: A -> String) -> String:
  match s:
    case Ready{value}:
      "ready " ++ show(value)
    case Late{value}:
      "late " ++ show(value)

def got(m: Maybe<&1, U32>) -> String:
  match m:
    case None{}:
      "none"
    case Some{value}:
      U32.show(value)

# the partners report through done, so the lines come in one order on
# every lane
def sender(+c: Chan(U32), done: Chan(String)) -> IO(Unit):
  do IO<Unit>:
    Bool <- Chan.send(U32, c, 9)
    Bool <- Chan.send(String, done, "sender: 9 went")
    return Unit{}

def receiver(+c: Chan(U32), done: Chan(String)) -> IO(Unit):
  do IO<Unit>:
    m : Maybe<&1, U32> <- Chan.recv(U32, c)
    Bool <- Chan.send(String, done, "receiver: " ++ got(m))
    return Unit{}

def said(m: Maybe<&1, String>) -> String:
  match m:
    case None{}:
      "none"
    case Some{value}:
      value

def rendezvous(c: Chan(U32), d: Chan(String)) -> IO(U32):
  +ch = c
  +done = d
  do IO<U32>:
    Unit <- IO.spawn(Unit, sender(ch, done))
    Unit <- IO.sleep(0)
    p : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    Unit <- IO.print("recv from a parked sender: " ++ step(Maybe<&1, U32>, p, got))
    Unit <- IO.spawn(Unit, receiver(ch, done))
    Unit <- IO.sleep(0)
    a : IO.Poll<Bool> <- IO.poll(Bool, 0, Chan.send(U32, ch, 7))
    b : IO.Poll<Bool> <- IO.poll(Bool, 0, Chan.send(U32, ch, 8))
    Unit <- IO.print("send to a parked receiver, then to nobody: " ++ step(Bool, a, Bool.show) ++ ", " ++ step(Bool, b, Bool.show))
    s1 : Maybe<&1, String> <- Chan.recv(String, done)
    s2 : Maybe<&1, String> <- Chan.recv(String, done)
    Unit <- IO.print(said(s1))
    Unit <- IO.print(said(s2))
    return 0

def buffered(c: Chan(U32)) -> IO(U32):
  +ch = c
  do IO<U32>:
    a : IO.Poll<Bool> <- IO.poll(Bool, 0, Chan.send(U32, ch, 1))
    b : IO.Poll<Bool> <- IO.poll(Bool, 0, Chan.send(U32, ch, 2))
    Unit <- IO.print("send with room for one: " ++ step(Bool, a, Bool.show) ++ ", " ++ step(Bool, b, Bool.show))
    p : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    q : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    Unit <- Chan.close(U32, ch)
    r : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    d : IO.Poll<Bool> <- IO.poll(Bool, 0, Chan.send(U32, ch, 3))
    Unit <- IO.print("recv: " ++ step(Maybe<&1, U32>, p, got) ++ ", " ++ step(Maybe<&1, U32>, q, got) ++ ", " ++ step(Maybe<&1, U32>, r, got))
    Unit <- IO.print("send once closed: " ++ step(Bool, d, Bool.show))
    d : Chan(String) <- Chan.new(String, 2)
    IO.bind(Chan(U32), U32, Chan.new(U32, 0), r => rendezvous(r, d))

def main() -> IO(U32):
  IO.bind(Chan(U32), U32, Chan.new(U32, 1), buffered)

#|send with room for one: ready True, late False
#|recv: ready 1, late none, ready none
#|send once closed: ready False
#|recv from a parked sender: ready 9
#|send to a parked receiver, then to nobody: ready True, late False
#|sender: 9 went
#|receiver: 7
