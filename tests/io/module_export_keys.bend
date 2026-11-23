# JS exports keep own __proto__ keys and a root dep.value, and leave the
# imported dep:value internal, including when the export object is spread.
import Base

def Module.export_keys() -> IO(U32):
  import "./module_export_keys.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- Module.export_keys()
    IO.print(U32.show(value))

#|0
