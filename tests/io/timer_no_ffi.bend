# Timer-only waits work without Bun's FFI, including forked sleeps and races.
import Base
import ./sleep_order.bend as Order
import ./within.bend as Within

def Timer.hide() -> IO(Unit):
  import "./timer_no_ffi.js"

def Timer.restore() -> IO(Unit):
  import "./timer_no_ffi.js"

def main() -> IO(Unit):
  do IO<Unit>:
    Timer.hide()
    n : U32 <- Order.main()
    Within.main()
    # Within's late sleep outlives its main; keep FFI hidden until it fires.
    u : Unit <- IO.sleep(250)
    Timer.restore()

#|a
#|b
#|c
#|d
#|timeout
#|fast
#|got fast
#|late
