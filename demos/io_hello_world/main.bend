# Hello world: the smallest IO program. Try it:
#
#   bend demos/io_hello_world/main.bend
import Base

def main() -> IO(Unit):
  IO.print("Hello, world!")
