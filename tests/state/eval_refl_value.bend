# float literals are definitionally transparent: one literal is one
# word, so refl closes the goal in a dead (type-level) position
import Base

law prf:
  {1.5 == 1.5 : F32}

def prf():
  {==}

law main:
  Type

def main():
  {1.5 == 1.5 : F32}

#|{1.5 == 1.5 : F32}
