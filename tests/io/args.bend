# io (io_args): the command line: its head is the program as invoked (the
# C binary, the JS file or the .bend file), then the C binary keeps
# --threads, --gpu, --gpu-build and --bend-help, the JS lane (one thread,
# no GPU) only --threads, --gpu and --bend-help; IO.args answers the rest,
# in order (--help is a program argument). The harness passes none, so
# every lane sees its program, named after this test, and no argument.
import Base

law main:
  IO(Unit)

def program(xs: List<String>) -> String:
  match xs:
    case Nil{}:
      "no program"
    case p <> t:
      Bool.show(String.contains(p, "args")) ++ " "
        ++ Nat.show(List.length(&1, String, t))

def main():
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(program(xs))

#|True 0
