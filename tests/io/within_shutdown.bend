# A zero deadline lets the action's own zero sleep wake first. A winner
# with an 8-second deadline exits within the gate's 5-second alarm.
import Base

def main() -> IO(Unit):
  do IO<Unit>:
    zero : Maybe<&1, Unit> <- IO.within(Unit, 0, IO.sleep(0))
    IO.print(Bool.show(Maybe.is_some(&1, Unit, zero)))
    early : Maybe<&1, Unit> <- IO.within(Unit, 8000, IO.pure(Unit, Unit{}))
    IO.print(Bool.show(Maybe.is_some(&1, Unit, early)))

#|True
#|True
