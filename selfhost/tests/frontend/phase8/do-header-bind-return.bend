import Base
def main() -> IO(Unit):
  do IO<Unit>:
    u : Unit <- IO.print("4")
    return Unit{}
