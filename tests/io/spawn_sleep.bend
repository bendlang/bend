# io (io_spawn_sleep): IO.spawn starts a computation of its own and
# IO.sleep parks one without stopping the others: two spawned pings
# wake in deadline order (10 ms before 30 ms) while main, which
# spawned them, printed first and sleeps past both. The process ends
# when every computation has answered.
import Base

law ping:
  for ms: U32
  for tag: String
  IO(Unit)

def ping(ms, tag):
  do IO<Unit>:
    Unit <- IO.sleep(ms)
    IO.print(tag)

law main:
  IO(U32)

def main():
  do IO<U32>:
    Unit <- IO.spawn(Unit, ping(30, "a"))
    Unit <- IO.spawn(Unit, ping(10, "b"))
    Unit <- IO.print("main")
    Unit <- IO.sleep(60)
    Unit <- IO.print("done")
    return 0

#|main
#|b
#|a
#|done
