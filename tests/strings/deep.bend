# 44 code points x 4096 = 180224, consumed to a small pure result. This is
# real normalization in the interpret lane, not an IO main's implicit JS.
# Counts are written as products so the checker's literal expansion stays
# shallow (a 4096n literal is 4,096 nested Succ nodes and rides the JS stack
# limit non-deterministically; class tracked upstream as #779/#791). That goes
# for every count, the split's 4096+1 included: a 4097n here overflowed
# check-ctr in 28/240 frontend runs. Payload value and size are unchanged.
import Base

def count.go(xs: List<&2, String>, n: Nat) -> Nat:
  match xs:
    case Nil{}:
      n
    case h <> t:
      count.go(t, 1n+n)

def sample() -> String:
  String.repeat("the quick brown fox jumps over the lazy dog\n", Nat.mul(64n, 64n))

def main() -> Bool & (Bool & (Bool & Bool)):
  (Nat.is_eq(String.length(sample()), Nat.mul(44n, Nat.mul(64n, 64n))),
   (Nat.is_eq(count.go(String.split(sample(), '\n'), 0n), 1n+Nat.mul(64n, 64n)),
    (Nat.is_eq(count.go(String.words(sample()), 0n), Nat.mul(9n, Nat.mul(64n, 64n))),
     String.eq(String.to_upper(sample()),
       String.repeat("THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG\n", Nat.mul(64n, 64n))))))

#|(True{}, True{}, True{}, True{})
