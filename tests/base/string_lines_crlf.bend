import Base

def joined(s: String) -> String:
  String.join(String.lines(s), "|")

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(joined("x\r\ny\n\r\n"))
    IO.print(Bool.show(String.eq(joined("x\ry"), "x\ry")))

#|x|y||
#|True
