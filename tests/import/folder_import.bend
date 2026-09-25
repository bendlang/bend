# a path with no suffix imports a folder: every .bend file right in it
# loads under the one alias, and the alias finds each name in the file
# that declares it; folder/deep/ is a subfolder and stays unloaded
import Base
import ./folder as F

def main() -> IO(Unit):
  IO.print(Nat.show(F.dbl(F.sq(3n))))

#|18
