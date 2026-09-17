# io (io_spawn_outlives_main): the process ends when the LAST
# computation answers, not when main does (Node's rule): main spawns
# a late print and returns 0 at once; the print still lands, and the
# exit status is main's.
import Base

law late:
  IO(Unit)

def late():
  do IO<Unit>:
    Unit <- IO.sleep(20)
    IO.print("late")

law main:
  IO(U32)

def main():
  do IO<U32>:
    Unit <- IO.spawn(Unit, late())
    Unit <- IO.print("main returns")
    return 0

#|main returns
#|late
