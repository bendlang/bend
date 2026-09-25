# a do block of one bare statement is that statement typed by its
# header: `do M<..>: e` is {e : M<..>} when M is a datatype (leading
# quantities padded as in a written type) and {e : M(..)} when M is a
# def family. So a header that names the wrong family is refused at
# the block, not dropped (#900). The one-liners that must still pass:
# a constructor, a def family, a nested step block, a padded datatype.
import Base

type Id<-A: Type> is Type:
  MkId{v: A}

def one() -> Id<U32>:
  do Id<U32>:
    MkId{9}

def two() -> Result<String, U32>:
  do Result<String, U32>:
    Done{2}

def three() -> IO(Unit):
  do IO<Unit>:
    IO.print("3")

def four() -> IO(Unit):
  do IO<Unit>:
    do IO<Unit>:
      IO.print("4")
    three()

def main() -> IO(Unit):
  do List<Unit>:
    IO.print("5")

#|Error:
#|- expected : List<&1, Unit>
#|- observed : @-R:Type -> @k:(@_:Unit -> IO.OP<R>) -> IO.OP<R>
#|Location: main
#|31 |   do List<Unit>:
#|32>|     IO.print("5")
#|   |     ^^^^^^^^^^^^^
#|33 |
#|exit 1
