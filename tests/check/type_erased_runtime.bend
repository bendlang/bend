# Types are inert at runtime (never applied nor matched), and a type
# family's binder multiplies only into types, which are dead.
# ported from bend3
import Base

law pick:
  @_:Type -> Type

def pick(): t => {t == t : Type}

law main:
  pick(U32)

def main(): {==}

#|{==}
