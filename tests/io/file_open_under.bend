# File.open_under opens a regular file below a directory and nothing
# else: no symbolic link on the way, no ".", ".." or empty component, no
# directory, device or missing name at the end. The fixtures are built
# in /tmp, so the test owes the working directory nothing. ELOOP is 62
# on macOS and 40 on Linux, EILSEQ 92 and 84; every refusal is pinned to
# its exact code.
import Base

def check(name: String, ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print(name)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ name)

# w1, w2: the accepted codes; repeat w1 when the platforms agree.
def refused(r: Result<&1, &1, U32 & String, File>, name: String, w1: U32, w2: U32) ->
  IO(Unit):
  match r:
    case Done{f}:
      do IO<Unit>:
        File.close(f)
        IO.die(Unit, 1, "FAIL opened: " ++ name)
    case Fail{e}:
      (+code, text) = e
      check(name, Bool.or(U32.is_eq(code, w1), U32.is_eq(code, w2)))

def opened(r: Result<&1, &1, U32 & String, File>, name: String) -> IO(Unit):
  match r:
    case Fail{e}:
      IO.die(Unit, 1, "FAIL refused: " ++ name)
    case Done{f}:
      do IO<Unit>:
        File.close(f)
        IO.print(name)

def nul() -> String:
  SCon{Chr{0}, SNil{}}

def fixtures(r: Result<&1, &1, U32 & String, U32 & (String & String)>) -> IO(Unit):
  match r:
    case Done{(code, (out, err))}:
      check("fixtures", U32.is_eq(code, 0))
    case Fail{e}:
      IO.die(Unit, 1, "FAIL fixtures")

def main() -> IO(Unit):
  do IO<Unit>:
    setup : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/sh", ["-c", "rm -rf /tmp/bend_fou && mkdir -p /tmp/bend_fou/sub && printf hi > /tmp/bend_fou/real.txt && printf two > /tmp/bend_fou/sub/two.txt && ln -s real.txt /tmp/bend_fou/final.txt && ln -s sub /tmp/bend_fou/mid && ln -s nowhere /tmp/bend_fou/dangling"], "", 4096, 2000)
    fixtures(setup)
    a : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "real.txt")
    opened(a, "a file under the root")
    b : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "sub/two.txt")
    opened(b, "a file two components down")
    c : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "final.txt")
    refused(c, "a symbolic link at the end is refused", 62, 40)
    d : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "mid/two.txt")
    refused(d, "a symbolic link on the way is refused", 62, 40)
    e : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "dangling")
    refused(e, "a dangling symbolic link is refused", 62, 40)
    f : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "sub")
    refused(f, "a directory is not a file", 21, 21)
    g : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "../bend_fou/real.txt")
    refused(g, "a climb is refused", 13, 13)
    h : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "sub/./two.txt")
    refused(h, "a dot is refused", 13, 13)
    i : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "sub//two.txt")
    refused(i, "an empty component is refused", 13, 13)
    j : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "nope.txt")
    refused(j, "a missing name is ENOENT", 2, 2)
    k : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "/etc/passwd")
    refused(k, "an absolute path is refused", 13, 13)
    l : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "sub/")
    refused(l, "a trailing slash is refused", 13, 13)
    m : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", "real.txt/x")
    refused(m, "a file used as a directory", 20, 20)
    n : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou/real.txt", "x")
    refused(n, "the root must be a directory", 20, 20)
    o : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou/gone", "x")
    refused(o, "a missing root is ENOENT", 2, 2)
    p : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp/bend_fou", nul())
    refused(p, "a NUL in the path is EILSEQ", 92, 84)
    q : Result<&1, &1, U32 & String, File> <- File.open_under(nul(), "x")
    refused(q, "a NUL in the root is EILSEQ", 92, 84)
    r : Result<&1, &1, U32 & String, File> <- File.open_under("/dev", "null")
    refused(r, "a device is not a file", 13, 13)
    s : Result<&1, &1, U32 & String, File> <- File.open_under("/tmp", "bend_fou/real.txt")
    opened(s, "the root is taken as given")

#|fixtures
#|a file under the root
#|a file two components down
#|a symbolic link at the end is refused
#|a symbolic link on the way is refused
#|a dangling symbolic link is refused
#|a directory is not a file
#|a climb is refused
#|a dot is refused
#|an empty component is refused
#|a missing name is ENOENT
#|an absolute path is refused
#|a trailing slash is refused
#|a file used as a directory
#|the root must be a directory
#|a missing root is ENOENT
#|a NUL in the path is EILSEQ
#|a NUL in the root is EILSEQ
#|a device is not a file
#|the root is taken as given
