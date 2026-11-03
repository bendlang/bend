# io (io_select_eintr): a signal that lands while the loop waits in
# select wakes nothing. Idle.park installs a no-op handler, has the
# signal arrive a few ms later, and parks on a pipe nobody writes, so any
# wake of it is spurious; main sleeps 30 ms and ends the process itself
# (the park is still live). An interrupted select fails with EINTR and
# leaves its sets as they were; the JS loop read them anyway and woke
# every parked fd, so a TCP.connect still in progress answered Done
# (SO_ERROR reads 0 then). It now retries the select, as the native
# loop does.
import Base

def Idle.park(ms: U32) -> IO(Unit):
  import "./select_eintr.c"
  import "./select_eintr.js"

def idle() -> IO(Unit):
  do IO<Unit>:
    Unit <- Idle.park(5)
    IO.print("the idle park woke")

def main() -> IO(U32):
  do IO<U32>:
    Unit <- IO.spawn(Unit, idle())
    Unit <- IO.sleep(30)
    Unit <- IO.print("slept")
    IO.die(U32, 0, "")

#|slept
