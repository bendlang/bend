# io (effect_versions): a program may import two versions of one package
# whose C effect defines the same names. Its C was pasted into the one C
# file twice, so clang refused each name the second time (#1533); a name
# its source marks HID(name) is the package version's own, and its macros
# and include guard end with its paste, so each version keeps its own
# counter.
import Base
import ./effect_version_a.bend as A
import ./effect_version_b.bend as B

def first(value: A.Instant) -> String:
  match value:
    case A.Instant{value}:
      U32.show(value)

def second(value: B.Instant) -> String:
  match value:
    case B.Instant{value}:
      U32.show(value)

def main() -> IO(Unit):
  do IO<Unit>:
    a : A.Instant <- A.now()
    b : B.Instant <- B.now()
    c : A.Instant <- A.now()
    d : B.Instant <- B.now()
    Unit <- IO.print(first(a))
    Unit <- IO.print(second(b))
    Unit <- IO.print(first(c))
    IO.print(second(d))

#|8
#|71
#|9
#|72
