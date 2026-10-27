# Process.run runs no shell: an executable with no #! line is refused with
# ENOEXEC (8), as Linux does. macOS's posix_spawnp would run it with /bin/sh.
# A name with no slash is searched in PATH: found, it runs; missing, ENOENT.
import Base

def outcome(r: Result<&1, &1, U32 & String, U32 & (String & String)>) ->
  String:
  match r:
    case Done{(code, (stdout, stderr))}:
      "ran " ++ U32.show(code)
    case Fail{(code, message)}:
      "refused " ++ U32.show(code)

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
    y : Unit <- IO.print("chmod: " ++ outcome(c))
    r : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/tmp/bend_io_no_shell.tmp", [], "", 128, 1000)
    z : Unit <- IO.print("no #!: " ++ outcome(r))
    d : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/rm", ["-f", "/tmp/bend_io_no_shell.tmp"], "", 128,
        1000)
    s : Unit <- IO.print("rm: " ++ outcome(d))
    p : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("true", [], "", 128, 1000)
    t : Unit <- IO.print("in PATH: " ++ outcome(p))
    m : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("__bend_missing_executable__", [], "", 128, 1000)
    IO.print("not in PATH: " ++ outcome(m))

#|chmod: ran 0
#|no #!: refused 8
#|rm: ran 0
#|in PATH: ran 0
#|not in PATH: refused 2
