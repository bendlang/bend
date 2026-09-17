# gfx (gfx_app_play): App.play folds scripted frames (a List of event
# lists) through an App's tick, in IO, and answers the last state, or
# None when a tick quits, so an app runs and tests without a window.
# This tick prints a line per frame, counts events and quits on Close.
import Base

type Counter is Data:
  Counter{n: U32}

def count_event(e: Event, s: Counter) -> Maybe<Counter>:
  match e:
    case Close{}:
      None{}
    case other:
      Counter{n} = s
      Some{Counter{U32.inc(n)}}

def count_events(events: List<Event>, s: Counter) -> Maybe<Counter>:
  match events:
    case Nil{}:
      Some{s}
    case e <> rest:
      Maybe.bind(&1, Counter, Counter, count_event(e, s),
        s2 => count_events(rest, s2))

def Counter.tick(events: List<Event>, s: Counter) -> IO(Maybe<Counter>):
  do IO<Maybe<Counter>>:
    u : Unit <- IO.print("frame")
    IO.pure(Maybe<Counter>, count_events(events, s))

def Counter.view(s: Counter) -> Counter & Image:
  Counter{+n} = s
  (Counter{n}, Pix{n})

def show(m: Maybe<Counter>) -> IO(Unit):
  match m:
    case None{}:
      IO.print("quit")
    case Some{s}:
      Counter{n} = s
      IO.print(U32.show(n))

def main() -> IO(Unit):
  do IO<Unit>:
    a : Maybe<Counter> <- App.play(~Counter, ~App{Counter.view, Counter.tick},
      [[Key{97, True{}}], [Key{97, False{}}, Key{98, True{}}, Move{1, 2}],
        [], [Key{99, True{}}]], Counter{0})
    u : Unit <- show(a)
    b : Maybe<Counter> <- App.play(~Counter, ~App{Counter.view, Counter.tick},
      [[Key{97, True{}}], [Close{}], [Key{98, True{}}]], Counter{5})
    v : Unit <- show(b)
    c : Maybe<Counter> <- App.play(~Counter, ~App{Counter.view, Counter.tick},
      [], Counter{7})
    show(c)

#|frame
#|frame
#|frame
#|frame
#|5
#|frame
#|frame
#|quit
#|7
