# A prompt reaches stdout before a synchronous file read. The JS twin
# observes the real write/read calls, then restores them at the first read.
import Base

def Host.prompt_input() -> IO(File):
  import "./file_read_prompt.js"

def Host.prompt_flushed() -> IO(U32):
  import "./file_read_prompt.js"

def finish(p: File & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (f, r) = p
  do IO<Unit>:
    File.close(f)
    s : String <- IO.pass(String, r)
    IO.write(s)
    status : U32 <- Host.prompt_flushed()
    IO.print(U32.show(status))

def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- Host.prompt_input()
    IO.write("prompt> ")
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(f, 64)
    finish(p)

#|prompt> hello
#|0
