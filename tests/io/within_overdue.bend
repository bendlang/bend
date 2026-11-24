# The action's sleep comes due before the deadline. A blocking effect
# holds the loop until both are overdue, and the action still wins.
import Base
import ./chan_try_late.bend as Pause

def nap() -> IO(Unit):
  do IO<Unit>:
    IO.spawn(Unit, Pause.hold(100))
    IO.sleep(10)

def main() -> IO(Unit):
  do IO<Unit>:
    got : Maybe<&1, Unit> <- IO.within(Unit, 50, nap())
    IO.print(Bool.show(Maybe.is_some(&1, Unit, got)))

#|True
