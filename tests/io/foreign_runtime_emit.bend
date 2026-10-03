# IO~emit is another runtime segment that has no declaration in the book.
import Base

def native.emit(value: U32) -> IO(Unit):
  import "./foreign_runtime_emit.c"
  import "./foreign_runtime_emit.js"

def main() -> IO(Unit):
  native.emit(42)

#|42
