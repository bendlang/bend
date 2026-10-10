import Base

def grandchild() -> IO(U32):
  do IO<U32>:
    IO.print("grandchild finished")
    return 9

def child() -> IO(U32):
  do IO<U32>:
    IO.sleep(1)
    IO.spawn(U32, grandchild())
    IO.print("child finished")
    return 7

def main() -> IO(U32):
  do IO<U32>:
    IO.spawn(U32, child())
    return 2

#|child finished
#|grandchild finished
#|exit 2
