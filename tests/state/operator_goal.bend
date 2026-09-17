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

#|Error:
#|- expected : 1.5
#|- observed : 2.5
#|Location: prf
#| 8 | def prf():
#| 9>|   {==}
#|10 |
#|exit 1
