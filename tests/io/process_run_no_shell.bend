# Process.run runs no shell: an executable with no #! line is refused with
# ENOEXEC (8), as Linux does. macOS's posix_spawnp would run it with /bin/sh.
import Base

def failure(r: Result<&1, &1, U32 & String, U32 & (String & String)>) ->
  String:
  match r:
    case Done{(code, (stdout, stderr))}:
      "ran: " ++ stdout
    case Fail{(code, message)}:
      "refused: " ++ U32.show(code)

def written(w: File & Result<&1, &1, (U32 & String), Unit>) -> IO(File):
  (f, r) = w
  do IO<File>:
    u : Unit <- IO.pass(Unit, r)
    return f

def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_no_shell.tmp", "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <-
      File.write(f, "echo through a shell\n")
    g : File <- written(w)
    x : Unit <- File.close(g)
    c : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/chmod", ["755", "/tmp/bend_io_no_shell.tmp"], "", 128,
        1000)
    r : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/tmp/bend_io_no_shell.tmp", [], "", 128, 1000)
    IO.print(failure(r))

#|refused: 8
