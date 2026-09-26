# a 200000-deep Succ chain compares with its literal in constant stack:
# a constructor's last field is compared in a loop
import Base

law big:
  {Nat.add(100000n, 100000n) == 200000n : Nat}

def big():
  {==}

#|All terms check.
