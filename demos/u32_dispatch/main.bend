# Native U32 dispatch reproducer. Usage: binary COUNT SEED +RTS --threads 1 --gpu off
import Base

def choose(+tag: U32, +salt: U32) -> U32:
  match tag:
    case 0: ((salt * 3) + 7919 : U32)
    case 1: ((salt * 5) + 15838 : U32)
    case 2: ((salt * 7) + 23757 : U32)
    case 3: ((salt * 9) + 31676 : U32)
    case 4: ((salt * 11) + 39595 : U32)
    case 5: ((salt * 13) + 47514 : U32)
    case 6: ((salt * 15) + 55433 : U32)
    case 7: ((salt * 17) + 63352 : U32)
    case 8: ((salt * 19) + 71271 : U32)
    case 9: ((salt * 21) + 79190 : U32)
    case 10: ((salt * 23) + 87109 : U32)
    case 11: ((salt * 25) + 95028 : U32)
    case 12: ((salt * 27) + 102947 : U32)
    case 13: ((salt * 29) + 110866 : U32)
    case 14: ((salt * 31) + 118785 : U32)
    case 15: ((salt * 33) + 126704 : U32)
    case U32{WCon{False{}, _}}: U32.xor(salt, 305419896)
    case _: U32.xor(salt, 3735928559)

def loop(n: Nat, +tag: U32, acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+p:
      loop(p, U32.and((tag + 13 : U32), 31), choose(tag, acc))

def execute(n: Maybe<&2, U32>, salt: Maybe<&2, U32>) -> IO(Unit):
  match n salt:
    case Some{n} Some{s}: IO.print(U32.show(loop(U32.to_nat(n), s, 7)))
    case _ _: IO.die(Unit, 1, "bad arguments")

def arguments(argv: List<String>) -> IO(Unit):
  match argv:
    case _ <> n <> salt <> Nil{}: execute(U32.read(n), U32.read(salt))
    case _: IO.die(Unit, 1, "expected count and seed")

def main() -> IO(Unit):
  do IO<Unit>:
    argv : List<String> <- IO.args()
    arguments(argv)
