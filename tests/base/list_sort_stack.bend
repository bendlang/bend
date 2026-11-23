import Base

def check(xs: List<&2, Nat>, +i: Nat, ok: Bool) -> String:
  match xs:
    case Nil{}:
      Bool.show(ok) ++ "/" ++ Nat.show(i)
    case x <> t:
      check(t, 1n+i, Bool.and(ok, Nat.is_eq(x, i)))

def sorted(n: Nat) -> String:
  xs = List.reverse(&2, Nat, List.range(n))
  check(List.sort(~Nat, ~Nat.is_le, xs), 0n, True{})

def main() -> IO(Unit):
  do IO<Unit>:
    args: List<String> <- IO.args()
    IO.print(sorted(32768n+List.length(&1, String, args)))

#|True/32769
