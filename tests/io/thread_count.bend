# io (io_thread_count): IO.thread_count answers the worker pool's size:
# BEND_THREADS, else the CPU count, clamped to 1..128 on the C lane, and 1
# on the JS lanes. The harness leaves it unset and CPU counts differ,
# so the test prints only that the count is in range.
import Base

def in_range(+n: U32) -> Bool:
  Bool.and(U32.is_ge(n, 1), U32.is_le(n, 128))

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- IO.thread_count()
    IO.print(Bool.show(in_range(n)))

#|True
