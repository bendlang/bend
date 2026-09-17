# bend3's builtin rename audit (u2f dead); bend never had the old
# names -- u2f is an ordinary unbound name and dies as one
import Base

law main:
  F32

def main():
  u2f(1)

#|Error:
#|- expected : a defined name
#|- observed : u2f
#|Location: main
#| 8 | def main():
#| 9>|   u2f(1)
#|10 |
#|exit 1
