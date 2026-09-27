# Scroll pans a viewport only under its pointer. The axes are independent,
# fractional movement survives, and negative offsets clamp to zero.
import Base

def clamp(+v: F32) -> F32:
  Bool.pick(F32, F32.is_lt(v, 0.0), 0.0, v)

def step.go(inside: Bool, dx: F32, dy: F32, offset: F32 & F32)
  -> F32 & F32:
  match inside:
    case False{}:
      offset
    case True{}:
      (left, top) = offset
      (clamp((left + dx : F32)), clamp((top + dy : F32)))

def step(e: Event, offset: F32 & F32) -> F32 & F32:
  match e:
    case Scroll{x, y, dx, dy}:
      step.go(Bool.and(U32.is_lt(x, 32), U32.is_lt(15, y)), dx, dy, offset)
    case _:
      offset

def move(es: List<Event>, offset: F32 & F32) -> F32 & F32:
  match es:
    case Nil{}:
      offset
    case e <> rest:
      move(rest, step(e, offset))

def show(offset: F32 & F32) -> String:
  (x, y) = offset
  F32.show(x) ++ " " ++ F32.show(y)

def main() -> IO(Unit):
  IO.print(show(move([Scroll{12, 20, 0.25, F32.neg(0.5)},
    Scroll{200, 20, 9.0, 9.0}, Mouse{12, 20, 0, True{}},
    Scroll{12, 20, F32.neg(0.5), F32.neg(0.75)},
    Scroll{12, 20, 0.25, 0.25}], (1.0, 0.25))))

#|1 0.25
