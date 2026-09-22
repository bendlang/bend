# Smoke test for #970: a List built at runtime (the sum comes from the
# length of IO.args) keeps the val_box-over-sum shape in the emitted C,
# the one place main's two lines differ from this branch's: main splices
# the parked Cons cell into the Pair node (_nd_2 = _sp_0) and heap_allocs
# the rebuild, so the Scalar path orphans it, while here the Pair is
# allocated and the rebuild keeps _sp_0. A leak is not visible in the
# output, so this only holds the shape compiling and running; a literal
# list folds away on both.
import Base

type Value is Data:
  Scalar{number: U32}
  Pair{left: Nat, right: Nat}

def wrap(n: Nat) -> Value:
  match n:
    case 0n:
      Scalar{7}
    case 1n+p:
      Pair{p, 4n}

def rebox(values: List<&2, Value>) -> List<&2, Value>:
  match values:
    case Nil{}:
      Nil{}
    case value <> tail:
      value <> tail

def head_u32(values: List<&2, Value>) -> U32:
  match values:
    case Nil{}:
      0
    case value <> tail:
      match value:
        case Scalar{+n}:
          n
        case Pair{left, right}:
          0

def head_nat(values: List<&2, Value>) -> Nat:
  match values:
    case Nil{}:
      0n
    case value <> tail:
      match value:
        case Scalar{number}:
          0n
        case Pair{+left, right}:
          left

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    +n : Nat = List.length(&1, String, xs)
    Unit <- IO.print(U32.show(head_u32(rebox(wrap(n) <> Nil{}))))
    IO.print(Nat.show(head_nat(rebox(wrap(Nat.add(n, 4n)) <> Nil{}))))

#|7
#|3
