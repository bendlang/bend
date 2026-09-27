# io (io_file_sendfile): File.sendfile puts a file's bytes on a socket
# from an offset, without moving the file's position, and on the C lane
# without the bytes passing through the program. "0123456789" is
# written; from 2, five bytes arrive as "23456"; from 8, five are asked
# and the file has two: "89" arrives and the send fails with ENODATA;
# a File.read after both still reads from the start, and then a zero
# length is Done at once and an offset past the end is ENODATA, on the
# same pair. The big case: a 4 MiB file, sent WHILE the peer reads, so
# the send really parks (the loopback buffers cannot hold 4 MiB), the
# bytes arrive in 32 KiB reads and are written to a second file, and
# the shell's cmp says the two files are byte for byte the same.
import Base

def path() -> String:
  "/tmp/bend_io_file_sendfile"

def big() -> String:
  "/tmp/bend_io_file_sendfile_big"

def recv_path() -> String:
  "/tmp/bend_io_file_sendfile_recv"

def short(+code: U32) -> String:
  Bool.pick(String, U32.is_eq(code, 61) || U32.is_eq(code, 96), "short", "failed")

def shown(r: Result<&1, &1, (U32 & String), Unit>) -> String:
  match r:
    case Done{u}:
      "done"
    case Fail{e}:
      (code, msg) = e
      short(code)

law write_go:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def write_go(w):
  (f, r) = w
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

def wgo(w: File & Result<&1, &1, (U32 & String), Unit>) -> IO(File):
  (f, r) = w
  do IO<File>:
    u : Unit <- IO.pass(Unit, r)
    return f

def heard(m: Socket & Result<&1, &1, (U32 & String), String>) -> IO(Socket):
  (s, r) = m
  do IO<Socket>:
    bs : String <- IO.pass(String, r)
    IO.print(bs)
    return s

def read_keep(m: File & Result<&1, &1, (U32 & String), String>) -> IO(File):
  (f, r) = m
  do IO<File>:
    bs : String <- IO.pass(String, r)
    IO.print(bs)
    return f

# prints the send's line, then sends the next range on the same pair
def next2(m: Socket & File & Result<&1, &1, (U32 & String), Unit>, label: String, off: U32, len: U32) -> IO(Socket & File & Result<&1, &1, (U32 & String), Unit>):
  (a2, f2r) = m
  (f2, r) = f2r
  do IO<(Socket & File & Result<&1, &1, (U32 & String), Unit>)>:
    IO.print(label ++ shown(r))
    File.sendfile(a2, f2, off, len)

def fin2(m: Socket & File & Result<&1, &1, (U32 & String), Unit>, label: String) -> IO(Unit):
  (a3, f3r) = m
  (f3, r) = f3r
  do IO<Unit>:
    IO.print(label ++ shown(r))
    File.close(f3)
    Socket.close(a3)

def last(c: Socket, m: Socket & File & Result<&1, &1, (U32 & String), Unit>) -> IO(U32):
  (a, fr) = m
  (f, r) = fr
  do IO<U32>:
    IO.print(shown(r))
    r2 : Socket & Result<&1, &1, (U32 & String), String> <- TCP.recv(c, 64)
    c2 : Socket <- heard(r2)
    g  : File & Result<&1, &1, (U32 & String), String> <- File.read(f, 4)
    f2 : File <- read_keep(g)
    mz : Socket & File & Result<&1, &1, (U32 & String), Unit> <- File.sendfile(a, f2, 0, 0)
    mo : Socket & File & Result<&1, &1, (U32 & String), Unit> <- next2(mz, "zero length: ", 5000, 5)
    u  : Unit <- fin2(mo, "past the end: ")
    Socket.close(c2)
    return 0

def first(c: Socket, m: Socket & File & Result<&1, &1, (U32 & String), Unit>) -> IO(U32):
  (a, fr) = m
  (f, r) = fr
  do IO<U32>:
    IO.print(shown(r))
    r1 : Socket & Result<&1, &1, (U32 & String), String> <- TCP.recv(c, 64)
    c2 : Socket <- heard(r1)
    m2 : Socket & File & Result<&1, &1, (U32 & String), Unit> <- File.sendfile(a, f, 8, 5)
    last(c2, m2)

def pair(c: Socket, a: Socket, f: File) -> IO(U32):
  do IO<U32>:
    m1 : Socket & File & Result<&1, &1, (U32 & String), Unit> <- File.sendfile(a, f, 2, 5)
    first(c, m1)

def step_accept(c: Socket, p: Listener & Result<&1, &1, (U32 & String), Socket>) -> IO(U32):
  (l2, ar) = p
  do IO<U32>:
    a : Socket <- IO.pass(Socket, ar)
    f : File <- IO.try(File, File.open(path(), "r"))
    x : U32 <- pair(c, a, f)
    Listener.close(l2)
    return x

def main_go(b: Listener & U32) -> IO(U32):
  (l, port) = b
  do IO<U32>:
    c : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    p : Listener & Result<&1, &1, (U32 & String), Socket> <- TCP.accept(l)
    step_accept(c, p)

def tcp_retry(port: U32, r: Result<&1, &1, (U32 & String), Listener>, rest: IO(Listener & U32)) -> IO(Listener & U32):
  match r:
    case Done{l}:
      IO.pure(Listener & U32, (l, port))
    case Fail{e}:
      rest

def tcp_listen_any(tries: Nat, +port: U32) -> IO(Listener & U32):
  match tries:
    case 0n:
      IO.die(Listener & U32, 1, "no free tcp port")
    case 1n+t:
      rest = tcp_listen_any(t, (port + 1 : U32))
      do IO<Listener & U32>:
        r : Result<&1, &1, (U32 & String), Listener> <- TCP.listen(port)
        tcp_retry(port, r, rest)

# receives up to k chunks of 32 KiB, writing each; the count is a
# backstop only (4 MiB needs 128 full reads, and loopback gives about
# that), and reads after the peer's close come back empty and write
# nothing; the socket rides in m and comes back with it
def drain(k: Nat, wb: File, m: Socket & Result<&1, &1, (U32 & String), String>) -> IO(File & (Socket & Result<&1, &1, (U32 & String), String>)):
  match k:
    case 0n:
      IO.pure(File & (Socket & Result<&1, &1, (U32 & String), String>), (wb, m))
    case 1n+t:
      (c2, rr) = m
      do IO<(File & (Socket & Result<&1, &1, (U32 & String), String>))>:
        s : String <- IO.pass(String, rr)
        w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(wb, s)
        w2 : File <- wgo(w)
        m2 : Socket & Result<&1, &1, (U32 & String), String> <- TCP.recv(c2, 32768)
        drain(t, w2, m2)

# the forked send: the whole file, then the send side closes, so the
# reader above sees an empty read when the bytes are done
def big_action_fin(m: Socket & File & Result<&1, &1, (U32 & String), Unit>) -> IO(File & Result<&1, &1, (U32 & String), Unit>):
  (ab2, fbr) = m
  do IO<(File & Result<&1, &1, (U32 & String), Unit>)>:
    Socket.close(ab2)
    return fbr

def big_action(ab: Socket, rb: File) -> IO(File & Result<&1, &1, (U32 & String), Unit>):
  do IO<(File & Result<&1, &1, (U32 & String), Unit>)>:
    m : Socket & File & Result<&1, &1, (U32 & String), Unit> <- File.sendfile(ab, rb, 0, 4194304)
    big_action_fin(m)

def cmp_out(r: Result<&1, &1, U32 & String, U32 & (String & String)>) -> String:
  match r:
    case Done{(code, (out, err))}:
      Bool.show(Bool.and(U32.is_eq(code, 0), String.contains(out, "same")))
    case Fail{e}:
      "failed"

def big_fin(fin: File & (Socket & Result<&1, &1, (U32 & String), String>), m: File & Result<&1, &1, (U32 & String), Unit>) -> IO(U32):
  (wb2, mlast) = fin
  (c3, rlast) = mlast
  (fbb, rb) = m
  do IO<U32>:
    File.close(wb2)
    File.close(fbb)
    Socket.close(c3)
    IO.print("big send: " ++ shown(rb))
    cr : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/sh", ["-c", "cmp -s /tmp/bend_io_file_sendfile_big /tmp/bend_io_file_sendfile_recv && echo same || echo diff"], "", 64, 2000)
    IO.print("big cmp: " ++ cmp_out(cr))
    return 0

# 4 MiB out from a forked send while this side reads: the send parks
# (the buffers hold much less), yields, and resumes as the reads land
def big_send(cb: Socket, ab: Socket, rb: File, wb: File) -> IO(U32):
  do IO<U32>:
    ch : Chan(File & Result<&1, &1, (U32 & String), Unit>) <-
      IO.fork(File & Result<&1, &1, (U32 & String), Unit>, big_action(ab, rb))
    m1 : Socket & Result<&1, &1, (U32 & String), String> <- TCP.recv(cb, 32768)
    fin : File & (Socket & Result<&1, &1, (U32 & String), String>) <- drain(1024n, wb, m1)
    res : File & Result<&1, &1, (U32 & String), Unit> <-
      IO.join(File & Result<&1, &1, (U32 & String), Unit>, ch)
    big_fin(fin, res)

def big_accept(cb: Socket, p: Listener & Result<&1, &1, (U32 & String), Socket>) -> IO(U32):
  (lb2, arb) = p
  do IO<U32>:
    ab : Socket <- IO.pass(Socket, arb)
    rb : File <- IO.try(File, File.open(big(), "r"))
    wb : File <- IO.try(File, File.open(recv_path(), "w"))
    x : U32 <- big_send(cb, ab, rb, wb)
    Listener.close(lb2)
    return x

def big_go(b: Listener & U32) -> IO(U32):
  (lb, portb) = b
  do IO<U32>:
    cb : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", portb))
    pb : Listener & Result<&1, &1, (U32 & String), Socket> <- TCP.accept(lb)
    big_accept(cb, pb)

def mk_go(r: Result<&1, &1, U32 & String, U32 & (String & String)>) -> IO(Unit):
  match r:
    case Done{(code, (out, err))}:
      Bool.pick(IO(Unit), U32.is_eq(code, 0), IO.pure(Unit, Unit{}), IO.die(Unit, 1, "FAIL big file"))
    case Fail{e}:
      IO.die(Unit, 1, "FAIL big file")

def main() -> IO(U32):
  do IO<U32>:
    mk : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/sh", ["-c", "yes A | head -c 4194304 > /tmp/bend_io_file_sendfile_big"], "", 4096, 2000)
    u0 : Unit <- mk_go(mk)
    f : File <- IO.try(File, File.open(path(), "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(f, "0123456789")
    u : Unit <- write_go(w)
    b : Listener & U32 <- tcp_listen_any(32n, 19951)
    u2 : U32 <- main_go(b)
    bb : Listener & U32 <- tcp_listen_any(32n, 19961)
    u3 : U32 <- big_go(bb)
    return 0

#|done
#|23456
#|short
#|89
#|0123
#|zero length: done
#|past the end: short
#|big send: done
#|big cmp: True
