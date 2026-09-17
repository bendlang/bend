# io (io_request_dead_fall): a main that IS one effect call, no
# IO.bind (every bench main has this shape), runs through the one
# request protocol: the event loop applies main's closure to the Emit
# continuation through FID_CLO_APPLY, the foreign REQUEST segment
# builds the request node, and the loop runs it. No shortcut reads a
# foreign closure's captures in the loop, so FID_CLO_APPLY, FID_IO_EMIT
# and the reached foreign segments are live in every program.
import Base

law main:
  IO(Unit)

def main():
  IO.print("dead fall")

#|dead fall
