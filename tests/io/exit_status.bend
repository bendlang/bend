import Base

def main() -> IO(U32):
  do IO<U32>:
    IO.print_err("usage error")
    return 2

#|usage error
#|exit 2
