# Outputs must not overwrite inputs or each other through paths or links.
import Base

def Output.input_links() -> IO(U32):
  import "./output_input_links.js"

def main() -> IO(Unit):
  do IO<Unit>:
    result : U32 <- Output.input_links()
    IO.print(U32.show(result))

#|0
