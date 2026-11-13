import Base

def sum(+d: Nat, +s: String) -> Nat:
  match d:
    case 0n:
      String.length(String.drop(s, 4n))
    case 1n+p:
      a b = sum(p, s) sum(p, s)
      Nat.add(a, b)

def check(ok: Bool) -> IO(Unit):
  match ok:
    case True{}: IO.pure(Unit, Unit{})
    case False{}: IO.die(Unit, 1, "wrong dropped string")

def main() -> IO(Unit):
  do IO<Unit>:
    +salt : U32 <- IO.try(U32, IO.random_u32())
    +digits : String = U32.show(salt)
    +chars : String = digits ++ "\u{0}\u{d800}\u{ffffffff}\u{1f600}x"
    +s : String <- IO.pure(String, String.repeat("abcd", 64n))
    check(String.eq(String.drop(chars, 0n), chars))
    check(String.eq(String.drop(chars, String.length(digits)), "\u{0}\u{d800}\u{ffffffff}\u{1f600}x"))
    check(String.eq(String.drop("X" ++ chars, 1n), chars))
    check(String.eq(String.drop("", 4294967295n), ""))
    check(String.eq(String.drop(chars, 4294967295n), ""))
    IO.print(Nat.show(String.length(String.drop(s, 0n))))
    IO.print(Nat.show(String.length(String.drop(s, 256n))))
    IO.print(Nat.show(String.length(String.drop(s, 257n))))
    IO.print(Nat.show(String.length(String.drop("X" ++ s, 2n))))
    IO.print(Nat.show(sum!(4n, s)))
    IO.print(Nat.show(String.length(s)))
    IO.print(Nat.show(String.length(String.drop(String.repeat("x", 64n), 32n))))
#|256
#|0
#|0
#|255
#|4032
#|256
#|32
