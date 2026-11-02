# a stuck float goal displays its build: two different literals do not
# meet, and the error spells both sides as their binary32 words
import Base

law prf:
  {1.5 == 2.5 : F32}

def prf():
  {==}

law main:
  Type

def main():
  {1.5 == 2.5 : F32}

#|SOME PROOFS FAIL
#|Error:
#|- expected : 1.5
#|- observed : 2.5
#|Location: prf
#| 8 | def prf():
#| 9>|   {==}
#|   |   ^^^^
#|10 |
#|Note: expected is the left side, 1.5, observed the right, 2.5.
#|exit 1
