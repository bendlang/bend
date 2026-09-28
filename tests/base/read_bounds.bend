# Nat.read and U32.read answer None for what the lane cannot hold:
# Nat.read reads up to 2^48-1 (the runtime's largest immediate). Leading
# zeros are stripped, then fewer than fifteen digits are in range, more
# are None, and fifteen compare as the text 281474976710655. A checked
# read of "7" closes (#1008). U32.read refuses a wrap past 2^32-1 (it
# once answered Some of the wrapped word); a Nat fuel seeds through
# U32.to_nat; File.open("") is ENOENT on every lane (the JS kit once
# answered EIO)
import Base

def mn(m: Maybe<&2, Nat>) -> String:
  match m:
    case None{}:
      "None"
    case Some{v}:
      Nat.show(v)

def mu(m: Maybe<&2, U32>) -> String:
  match m:
    case None{}:
      "None"
    case Some{v}:
      U32.show(v)

def rc(r: Result<&1, &1, U32 & String, File>) -> IO(Unit):
  match r:
    case Done{f}:
      File.close(f)
    case Fail{(c, m)}:
      IO.print(U32.show(c) ++ " " ++ m)

law read_seven:
  {Nat.read("7") == Some{7n} : Maybe<&2, Nat>}

def read_seven():
  {==}

law read_empty:
  {Nat.read("") == None{} : Maybe<&2, Nat>}

def read_empty():
  {==}

law read_bad:
  {Nat.read("12x") == None{} : Maybe<&2, Nat>}

def read_bad():
  {==}

law read_lead:
  {Nat.read("007") == Some{7n} : Maybe<&2, Nat>}

def read_lead():
  {==}

law read_zero:
  {Nat.read("000") == Some{0n} : Maybe<&2, Nat>}

def read_zero():
  {==}

law read_wide:
  {Nat.read("1000000000000000") == None{} : Maybe<&2, Nat>}

def read_wide():
  {==}

law read_past:
  {Nat.read("281474976710656") == None{} : Maybe<&2, Nat>}

def read_past():
  {==}

law read_shown:
  {Nat.read(Nat.show(7n)) == Some{7n} : Maybe<&2, Nat>}

def read_shown():
  {==}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(mn(Nat.read("99999999999999")))
    Unit <- IO.print(mn(Nat.read("100000000000000")))
    Unit <- IO.print(mn(Nat.read("281474976710655")))
    Unit <- IO.print(mn(Nat.read("281474976710656")))
    Unit <- IO.print(mn(Nat.read("12x")))
    Unit <- IO.print(mn(Nat.read("1000000000000000")))
    Unit <- IO.print(mn(Nat.read("0000000000000007")))
    Unit <- IO.print(mn(Nat.read("0281474976710656")))
    Unit <- IO.print(mn(Nat.read("00000000000000000000281474976710655")))
    Unit <- IO.print(mu(U32.read("4294967295")))
    Unit <- IO.print(mu(U32.read("4294967296")))
    Unit <- IO.print(mu(U32.read("99999999999")))
    Unit <- IO.print(mu(U32.read("+1")))
    Unit <- IO.print(Nat.show(U32.to_nat(4294967295)))
    r : Result<&1, &1, U32 & String, File> <- File.open("", "r")
    rc(r)

#|99999999999999
#|100000000000000
#|281474976710655
#|None
#|None
#|None
#|7
#|None
#|281474976710655
#|4294967295
#|None
#|None
#|None
#|4294967295
#|2 No such file or directory
