# HOAS printing refreshes binders it passes through: the shadowing
# chain prints back as written, each binder its own.
# ported from bend3: unchanged shape
import Base

law main:
  @x:U32 -> @y:U32 -> U32

def main():
  x => x => x

#|x => x => x
