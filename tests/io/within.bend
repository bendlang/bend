# io (io_within): IO.within races an action against a deadline. A sleep of
# 300 ms loses to a deadline of 10 ms, and IO.within answers None{} while
# the sleep still runs; a sleep of 10 ms wins against 300 ms and answers
# its value. The losers are not cancelled, so "late" still prints before
# the program exits.
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
    a : Maybe<&1, String> <- IO.within(String, 10, nap(300, "late"))
    u : Unit <- show(a)
    b : Maybe<&1, String> <- IO.within(String, 300, nap(10, "fast"))
    show(b)

#|timeout
#|fast
#|got fast
#|late
