# the if sugar is gone from bend (a lambda-match application is a
# banned form, and if desugared to one): 'if' is an ordinary name now,
# so the old chain no longer parses as a branch -- pinned here
import Base

law f:
  for b: Bool
  U32

def f(b):
  if b: 1

law main:
  U32

def main():
  f(True{})

#|Error:
#|- expected : '='
#|- observed : ':'
#|Location:
#|10 | def f(b):
#|11>|   if b: 1
#|   |       ^
#|12 |
#|exit 1
