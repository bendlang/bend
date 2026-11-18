# io (io_within): IO.within races an action against a deadline. A sleep of
# 150 ms loses to a deadline of 10 ms, and IO.within answers None{} while
# the sleep still runs; a sleep of 10 ms wins against 150 ms and answers
# its value. "late" still prints before the program exits. A winning
# action with an 8-second deadline exits within the gate's 5-second alarm.
import Base

def nap(ms: U32, +text: String) -> IO(String):
  do IO<String>:
    u : Unit <- IO.sleep(ms)
    v : Unit <- IO.print(text)
    return text

def show(got: Maybe<&1, String>) -> IO(Unit):
  match got:
    case None{}:
      IO.print("timeout")
    case Some{text}:
      IO.print(String.append("got ", text))

def main() -> IO(Unit):
  do IO<Unit>:
    instant : Maybe<&1, String> <- IO.within(String, 0, IO.pure(String, "instant"))
    Unit <- show(instant)
    a : Maybe<&1, String> <- IO.within(String, 10, nap(150, "late"))
    u : Unit <- show(a)
    b : Maybe<&1, String> <- IO.within(String, 150, nap(10, "fast"))
    Unit <- show(b)
    early : Maybe<&1, String> <- IO.within(String, 8000, IO.pure(String, "early"))
    show(early)

#|got instant
#|timeout
#|fast
#|got fast
#|got early
#|late
