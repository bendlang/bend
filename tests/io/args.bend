# io (io_args): the command line: the runtime keeps its own flags and
# IO.args answers the rest, in order. The harness passes none, so the
# list is empty on every lane.
import Base

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(Nat.show(List.length(&1, String, xs)))

#|0
