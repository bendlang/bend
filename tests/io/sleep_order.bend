# io (io_sleep_order): four sleeps of one span registered in a row
# wake in registration order on every lane: the loop stamps each
# timer with a strictly later deadline, so equal spans never race.
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
    Unit <- IO.spawn(Unit, ping(1, "a"))
    Unit <- IO.spawn(Unit, ping(1, "b"))
    Unit <- IO.spawn(Unit, ping(1, "c"))
    Unit <- IO.spawn(Unit, ping(1, "d"))
    return 0

#|a
#|b
#|c
#|d
