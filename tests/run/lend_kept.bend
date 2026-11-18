import Base

# A caller that keeps an argument (reads it after the call) runs the
# callee's lend variant on the C lane: the callee borrows it and copies
# what escapes, instead of the caller sharing it and the callee taking a
# shared value apart. Each call here must answer as the def does, and the
# kept argument must read the same after it.

# a suffix of the kept string (a spin)
def tails(n: Nat, +k: Nat, +s: String, acc: String) -> String:
  match n:
    case 0n:
      acc ++ "|" ++ s
    case 1n+p:
      tails(p, Nat.add(k, 1n), s, acc ++ String.drop(s, k))

# a new list of the kept list's first heads (no tail call: a task)
def firstn(l: List<&2, String>, n: Nat) -> List<&2, String>:
  match l n:
    case [] _:
      []
    case _ 0n:
      []
    case +h <> t 1n+p:
      h <> firstn(t, p)

def join(l: List<&2, String>) -> String:
  match l:
    case []:
      ""
    case h <> t:
      h ++ "," ++ join(t)

def heads(n: Nat, +k: Nat, +l: List<&2, String>, acc: String) -> String:
  match n:
    case 0n:
      acc ++ "|" ++ join(l)
    case 1n+p:
      heads(p, Nat.add(k, 1n), l, acc ++ join(firstn(l, k)) ++ ";")

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(tails(4n, 0n, "abcdef", ""))
    IO.print(tails(3n, 0n, "", ""))
    IO.print(heads(3n, 1n, ["x", "yy", "zzz", "w"], ""))
    IO.print(heads(2n, 0n, [], ""))

#|abcdefbcdefcdefdef|abcdef
#||
#|x,;x,yy,;x,yy,zzz,;|x,yy,zzz,w,
#|;;|
