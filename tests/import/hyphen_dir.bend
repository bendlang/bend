# a module in a hyphenated directory: the hyphen sits in its namespace,
# which the JS lane must mangle to a legal identifier (a hyphen is not
# an identifier character), so an IO main runs on every lane
import Base
import ./has-hyphen/lib.bend as L

def main() -> IO(Unit):
  IO.print(Nat.show(L.two()))

#|2
