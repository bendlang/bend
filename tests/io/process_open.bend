# A persistent child, not Process.run: waiting is parked while two turns run.
import Base
import ./file_binary.bend as T

def read_text(pair: File & Result<&1, &1, U32 & String, String>,
  want: String, name: String) -> IO(File):
  (f, r) = pair
  do IO<File>:
    got : String <- IO.pass(String, r)
    T.check(name, String.eq(got, want))
    return f

def talk(value: U32 & (File & File)) -> IO(Unit):
  (+pid, streams) = value
  (input, output) = streams
  do IO<Unit>:
    waiter : Chan(Result<&1, &1, U32 & String, U32>) <-
      IO.fork(Result<&1, &1, U32 & String, U32>, Process.wait(pid))
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(output, 64)
    output : File <- read_text(p, U32.show(pid) ++ "\n", "pid belongs to the live child")
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(input, "alpha\n")
    input : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(output, 64)
    output : File <- read_text(p, "1:alpha\n", "first interactive turn")
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(input, "beta\n")
    input : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(output, 64)
    output : File <- read_text(p, "2:beta\n", "second turn keeps child state")
    File.close(input)
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(output, 64)
    output : File <- read_text(p, "eof\n", "closing stdin delivers EOF")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(output, 1)
    output : File <- T.read(p, [], "child stdout closes after exit")
    File.close(output)
    r : Result<&1, &1, U32 & String, U32> <- IO.join(Result<&1, &1, U32 & String, U32>, waiter)
    code : U32 <- IO.pass(U32, r)
    T.check("parked wait returns child exit code", U32.is_eq(code, 7))
    again : Result<&1, &1, U32 & String, U32> <- Process.wait(pid)
    T.failed(U32, again, 10, "child is reaped once")

def signaled(value: U32 & (File & File)) -> IO(Unit):
  (pid, streams) = value
  (input, output) = streams
  do IO<Unit>:
    File.close(input)
    File.close(output)
    r : Result<&1, &1, U32 & String, U32> <- Process.wait(pid)
    code : U32 <- IO.pass(U32, r)
    T.check("wait preserves signal status", U32.is_eq(code, 143))

def main() -> IO(Unit):
  do IO<Unit>:
    missing : Result<&1, &1, U32 & String, U32 & (File & File)> <-
      Process.open("/__bend_missing_interactive_program__", [])
    T.failed(U32 & (File & File), missing, 2, "missing interactive program")
    empty : Result<&1, &1, U32 & String, U32 & (File & File)> <- Process.open("", [])
    T.failed(U32 & (File & File), empty, 2, "empty interactive program")
    nul : Result<&1, &1, U32 & String, U32 & (File & File)> <-
      Process.open("/bin/echo", ["bad\u{0}arg"])
    T.failed(U32 & (File & File), nul, 22, "NUL rejected before spawn")
    value : U32 & (File & File) <- IO.try(U32 & (File & File),
      Process.open("/bin/sh", ["-c", "printf '%s\\n' \"$$\"; n=0; while IFS= read -r x; do n=$((n+1)); printf '%s:%s\\n' \"$n\" \"$x\"; done; printf 'eof\\n'; exit 7"]))
    talk(value)
    value : U32 & (File & File) <- IO.try(U32 & (File & File),
      Process.open("/bin/sh", ["-c", "kill -TERM $$"]))
    signaled(value)

#|missing interactive program
#|empty interactive program
#|NUL rejected before spawn
#|pid belongs to the live child
#|first interactive turn
#|second turn keeps child state
#|closing stdin delivers EOF
#|child stdout closes after exit
#|parked wait returns child exit code
#|child is reaped once
#|wait preserves signal status
