# Different instantiations of one generic must not hide a Nat from the
# foreign-layout traversal. The second field is visited first by the JS stack.
import Base

type Bundle is Data:
  Bundle{n: Maybe<&2, Nat>, b: Maybe<&2, Bool>}

law good:
  IO(Bundle)

def good():
  import "./marshal_generic_nat.js"

law bad:
  IO(Bundle)

def bad():
  import "./marshal_generic_nat.js"

def main() -> IO(Unit):
  do IO<Unit>:
    a : Bundle <- good()
    u : Unit <- IO.print("good")
    b : Bundle <- bad()
    IO.print("unexpected acceptance")

#|good
#|bend: Bundle has no tag Bogus (its tags: Bundle); a tag names its constructor as the loading file sees it, which a later version will make the same everywhere (#1105)
#|exit 1
