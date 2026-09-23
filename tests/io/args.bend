# io (io_args): the command line: the C binary keeps --threads, --gpu,
# --gpu-build and --bend-help, the JS lane (one thread, no GPU) only
# --threads, --gpu and --bend-help; IO.args answers the rest, in order
# (--help is a program argument). The harness passes none, so the list
# is empty on every lane.
import Base

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(Nat.show(List.length(&1, String, xs)))

#|0
