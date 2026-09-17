# io (io_sleep_timer): IO.sleep parks the computation on the loop's
# timer heap and the print lands after the sleep, with exit 0: the
# timer is the loop's own, no thread sleeps for it.
import Base

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Unit <- IO.sleep(1)
    b : Unit <- IO.print("woke")
    return 0

#|woke
