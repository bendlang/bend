import Base

def fields(ref: WindowRef) -> String:
  X11WindowRef{display, id} = ref
  display ++ " " ++ U32.show(id)

def main() -> IO(Unit):
  +ref = {X11WindowRef{":7.0", 4294967295} : WindowRef}
  do IO<Unit>:
    IO.print(fields(ref))
    IO.print(fields(ref))

#|:7.0 4294967295
#|:7.0 4294967295
