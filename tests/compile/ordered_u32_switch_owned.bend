# A switch in an owned-array tail loop must preserve continue and default paths.
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

type State is Type:
  State{tag: U32, cells: Array<U32>, acc: U32}

def store(+tag: U32, acc: U32, pair: Array<U32> & U32) -> State:
  match pair:
    case (a, old):
      +next = choose(tag, U32.xor(old, acc))
      a[tag] <- next
      State{U32.and((tag + 13 : U32), 31), a, next}

def step(s: State) -> State:
  match s:
    case State{+tag, a, acc}: store(tag, acc, a[tag])

def run(n: Nat, s: State) -> State:
  match n:
    case 0n: s
    case 1n+p: run(p, step(s))

def show(acc: U32, pair: Array<U32> & U32) -> IO(Unit):
  match pair:
    case (_, x): IO.print(U32.show(U32.xor(acc, x)))

def finish(s: State) -> IO(Unit):
  match s:
    case State{_, a, acc}: show(acc, a[17])

def main() -> IO(Unit):
  finish(run(1025n, State{0, [7 : U32^5n], 0}))

#|1614483136
