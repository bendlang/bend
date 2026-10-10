# IO.args excludes the program name and preserves all program arguments.
# With no arguments, all backends must return the empty list.
import Base

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(List.show(~&1, ~String, ~(s => "<" ++ s ++ ">"), xs))

#|[]
