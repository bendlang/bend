# A text-returning closure stays callable at the JS module boundary; only
# an actual text result is converted, after live and erased arguments.
import Base

def Module.export_closure() -> IO(U32):
  import "./module_export_closure.js"

def main() -> IO(Unit):
  do IO<Unit>:
    status : U32 <- Module.export_closure()
    IO.print(U32.show(status))

#|0
