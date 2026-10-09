# Types
# =====

# Data
# ----

type Empty is Data:

type Unit is Data:
  Unit{}

type Bool is Data:
  False{}
  True{}

type Cmp is Data:
  LT{}
  EQ{}
  GT{}

type Either<a, b, -A: Kind(a), -B: Kind(b)> is Kind(a <&> b):
  Inl{value: A}
  Inr{value: B}

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Maybe<a, -A: Kind(a)> is Kind(a):
  None{}
  Some{value: A}

type Result<a, b, -E: Kind(a), -A: Kind(b)> is Kind(a <&> b):
  Fail{error: E}
  Done{value: A}

# What a try_ operation answers: Ready{x}, x what its blocking twin answers,
# or Wait{rest} once ms milliseconds pass first (0: at once), rest what did
# not happen (the value or the bytes not sent).
type Poll<a, b, -A: Kind(a), -R: Kind(b)> is Kind(a <&> b):
  Ready{value: A}
  Wait{rest: R}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

type Word.Nil is Data:
  WNil{}

type Word.Con<-p: Nat> is Data:
  WCon{head: Bool, tail: Word(p)}

def Word(n: Nat) -> Data:
  match n:
    case 0n:
      Word.Nil
    case 1n+p:
      Word.Con<p>

type U32 is Data:
  U32{data: Word(32n)}

type F32 is Data:
  F32{data: Word(32n)}

type Char is Data:
  Chr{code: U32}

type String is Data:
  SNil{}
  SCon{head: Char, tail: String}

type Array<-T: Type> is Type:
  ALeaf{value: T}
  ANode{xs: Array<T>, ys: Array<T>}

type Image is Data:
  Pix{color: U32}
  Qua{tl: Image, tr: Image, bl: Image, br: Image}

type Event is Data:
  Key{code: U32, down: Bool}
  Mouse{x: U32, y: U32, button: U32, down: Bool}
  Move{x: U32, y: U32}
  Look{dx: F32, dy: F32}
  Scroll{x: U32, y: U32, dx: F32, dy: F32}
  Close{}

type Map<a, -V: Kind(a)> is Kind(a):
  MTip{}
  MLeaf{key: String, val: V}
  MNode{pos: Nat, lo: Map<a, V>, hi: Map<a, V>}

# Effects
# -------

# A handle is opaque, a law with no constructor and no field, so no
# program forges one, and linear (Type), so none copies or reuses one.
law File:
  Type

law Socket:
  Type

law Listener:
  Type

law Window:
  Type

law Audio:
  Type

# A channel is Data: the computations it links each hold a copy.
law Chan:
  for -A: Type
  Data

type IO.OP<-R: Type> is Type:
  Emit{value: R}
  Halt{code: U32, message: String}

type App<-S: Type> is Type:
  App{view: S -> Pair(S, Image), tick: List<Event> -> S -> IO(Maybe<S>)}

# Defs
# ====

# Pair
# ----

def Pair(-A: Type, -B: Type) -> Type:
  Sigma<&1, &1, A, _ => B>

def Exists(-A: Type, -B: @-x: A -> Type) -> Type:
  Sigma<&1, &1, A, B>

def Or(-A: Type, -B: Type) -> Type:
  Either<&1, &1, A, B>

def Pair.fst(-A: Type, -B: Type, p: A & B) -> A:
  (a, b) = p
  a

def Pair.snd(-A: Type, -B: Type, p: A & B) -> B:
  (a, b) = p
  b

# Effects
# -------

def IO(-A: Type) -> Type:
  @-R: Type ->
  @k: (A -> IO.OP<R>) ->
  IO.OP<R>

def IO.pure(-A: Type, x: A) -> IO(A):
  R => k => k(x)

def IO.bind(-A: Type, -B: Type, m: IO(A), f: A -> IO(B)) -> IO(B):
  R => k => m(R, x => f(x, R, k))

def IO.print(text: String) -> IO(Unit):
  import "./effs/print.c"
  import "./effs/print.js"

def IO.write(text: String) -> IO(Unit):
  import "./effs/write.c"
  import "./effs/write.js"

def IO.print_err(text: String) -> IO(Unit):
  import "./effs/print_err.c"
  import "./effs/print_err.js"

def IO.get_env(name: String) -> IO(Result<&1, &1, U32 & String, String>):
  import "./effs/get_env.c"
  import "./effs/get_env.js"

# The command line, less the runtime's own options: the program as invoked
# (the binary, the JS file or the .bend file), then its arguments.
def IO.args() -> IO(List<String>):
  import "./effs/args.c"
  import "./effs/args.js"

def Process.run(program: String, args: List<String>, input: String,
  max_output: U32, timeout_ms: U32) ->
  IO(Result<&1, &1, U32 & String, U32 & (String & String)>):
  import "./effs/process_run.c"
  import "./effs/process_run.js"

def IO.die(-A: Type, code: U32, msg: String) -> IO(A):
  R => k => Halt{code, msg}

def IO.pass(-A: Type, r: Result<&1, &1, U32 & String, A>) -> IO(A):
  match r:
    case Done{value}:
      IO.pure(A, value)
    case Fail{(code, message)}:
      IO.die(A, code, message)

def IO.try(-A: Type, act: IO(Result<&1, &1, U32 & String, A>)) -> IO(A):
  IO.bind(Result<&1, &1, U32 & String, A>, A, act, IO.pass(A))

def IO.random_u32() -> IO(Result<&1, &1, U32 & String, U32>):
  import "./effs/random_u32.c"
  import "./effs/random_u32.js"

def IO.spawn(-A: Type, act: IO(A)) -> IO(Unit):
  import "./effs/spawn.c"
  import "./effs/spawn.js"

def IO.sleep(ms: U32) -> IO(Unit):
  import "./effs/sleep.c"
  import "./effs/sleep.js"

def IO.now() -> IO(Nat):
  import "./effs/now.c"
  import "./effs/now.js"

def IO.thread_count() -> IO(U32):
  import "./effs/thread_count.c"
  import "./effs/thread_count.js"

def Chan.new(-A: Type, room: U32) -> IO(Chan(A)):
  import "./effs/chan.c"
  import "./effs/chan.js"

# Done{} once the channel takes the value, Fail{value} if it is closed.
def Chan.send(-A: Type, chan: Chan(A), value: A) -> IO(Result<&1, &1, A, Unit>):
  import "./effs/chan.c"
  import "./effs/chan.js"

# Some{value}, or None{} once the channel is closed and drained.
def Chan.recv(-A: Type, chan: Chan(A)) -> IO(Maybe<&1, A>):
  import "./effs/chan.c"
  import "./effs/chan.js"

def Chan.try_send(-A: Type, chan: Chan(A), value: A, ms: U32) ->
  IO(Poll<&1, &1, Result<&1, &1, A, Unit>, A>):
  import "./effs/chan.c"
  import "./effs/chan.js"

def Chan.try_recv(-A: Type, chan: Chan(A), ms: U32) ->
  IO(Poll<&1, &1, Maybe<&1, A>, Unit>):
  import "./effs/chan.c"
  import "./effs/chan.js"

def Chan.close(-A: Type, chan: Chan(A)) -> IO(Unit):
  import "./effs/chan.c"
  import "./effs/chan.js"

def IO.fork.go(-A: Type, act: IO(A), chan: Chan(A)) -> IO(Chan(A)):
  +c = chan
  sent = IO.bind(A, Result<&1, &1, A, Unit>, act, x => Chan.send(A, c, x))
  IO.bind(Unit, Chan(A), IO.spawn(Result<&1, &1, A, Unit>, sent),
    u => IO.pure(Chan(A), c))

def IO.fork(-A: Type, act: IO(A)) -> IO(Chan(A)):
  IO.bind(Chan(A), Chan(A), Chan.new(A, 1), IO.fork.go(A, act))

def IO.join.go(-A: Type, chan: Chan(A), got: Maybe<&1, A>) -> IO(A):
  match got:
    case None{}:
      IO.die(A, 1, "IO.join: the channel was closed")
    case Some{value}:
      IO.bind(Unit, A, Chan.close(A, chan), u => IO.pure(A, value))

def IO.join(-A: Type, +chan: Chan(A)) -> IO(A):
  IO.bind(Maybe<&1, A>, A, Chan.recv(A, chan), IO.join.go(A, chan))

# Some{x} if act answers x within ms milliseconds, else None{}. The loser
# is not cancelled: it runs to its end before the program exits.
def IO.within(-A: Type, ms: U32, act: IO(A)) -> IO(Maybe<&1, A>):
  won = IO.bind(A, Maybe<&1, A>, act, x => IO.pure(Maybe<&1, A>, Some{x}))
  late = IO.bind(Unit, Maybe<&1, A>, IO.sleep(ms), u => IO.pure(Maybe<&1, A>, None{}))
  both = IO.bind(Chan(Maybe<&1, A>), Chan(Maybe<&1, A>), IO.fork(Maybe<&1, A>, won),
    IO.fork.go(Maybe<&1, A>, late))
  IO.bind(Chan(Maybe<&1, A>), Maybe<&1, A>, both, c => IO.join(Maybe<&1, A>, c))

def File.open(path: String, mode: String) ->
  IO(Result<&1, &1, U32 & String, File>):
  import "./effs/file_open.c"
  import "./effs/file_open.js"

def File.read(file: File, max: U32) ->
  IO(File & Result<&1, &1, U32 & String, String>):
  import "./effs/file_read.c"
  import "./effs/file_read.js"

def File.read_bytes(file: File, max: U32) ->
  IO(File & Result<&1, &1, U32 & String, List<&2, U32>>):
  import "./effs/file_read.c"
  import "./effs/file_read.js"

def File.read_at(file: File, offset: U32, max: U32) ->
  IO(File & Result<&1, &1, U32 & String, List<&2, U32>>):
  import "./effs/file_read.c"
  import "./effs/file_read.js"

def File.size(file: File) ->
  IO(File & Result<&1, &1, U32 & String, U32>):
  import "./effs/file_size.c"
  import "./effs/file_size.js"

def File.write(file: File, data: String) ->
  IO(File & Result<&1, &1, U32 & String, Unit>):
  import "./effs/file_write.c"
  import "./effs/file_write.js"

def File.write_bytes(file: File, data: List<&2, U32>) ->
  IO(File & Result<&1, &1, U32 & String, Unit>):
  import "./effs/file_write.c"
  import "./effs/file_write.js"

def File.close(file: File) -> IO(Unit):
  import "./effs/file_close.c"
  import "./effs/file_close.js"

def TCP.listen(host: String, port: U32) -> IO(Result<&1, &1, U32 & String, Listener>):
  import "./effs/tcp_listen.c"
  import "./effs/tcp_listen.js"

def TCP.accept(listener: Listener) ->
  IO(Listener & Result<&1, &1, U32 & String, Socket>):
  import "./effs/tcp_accept.c"
  import "./effs/tcp_accept.js"

def TCP.try_accept(listener: Listener, ms: U32) ->
  IO(Listener & Poll<&1, &1, Result<&1, &1, U32 & String, Socket>, Unit>):
  import "./effs/tcp_accept.c"
  import "./effs/tcp_accept.js"

def TCP.connect(host: String, port: U32) ->
  IO(Result<&1, &1, U32 & String, Socket>):
  import "./effs/tcp_connect.c"
  import "./effs/tcp_connect.js"

# A failed send hands back what the kernel did not take. Sent means taken
# by the kernel, not yet read by the peer.
def TCP.send(sock: Socket, data: String) ->
  IO(Socket & Result<&1, &1, (U32 & String) & String, Unit>):
  import "./effs/tcp_send.c"
  import "./effs/tcp_send.js"

def TCP.try_send(sock: Socket, data: String, ms: U32) ->
  IO(Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & String, Unit>, String>):
  import "./effs/tcp_send.c"
  import "./effs/tcp_send.js"

# Some{data}, or None{} once the peer has sent everything (it may still
# read). A max of 0 fails with EINVAL, as in every receive below.
def TCP.recv(sock: Socket, max: U32) ->
  IO(Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>):
  import "./effs/tcp_recv.c"
  import "./effs/tcp_recv.js"

def TCP.try_recv(sock: Socket, max: U32, ms: U32) ->
  IO(Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit>):
  import "./effs/tcp_recv.c"
  import "./effs/tcp_recv.js"

# The bytes as they are (0..255), one List cell each: no UTF-8 decoding, so
# binary data and a character split between two reads survive. A value past
# 255 fails with EINVAL before any byte is sent.
def TCP.send_bytes(sock: Socket, data: List<&2, U32>) ->
  IO(Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>):
  import "./effs/tcp_send.c"
  import "./effs/tcp_send.js"

def TCP.try_send_bytes(sock: Socket, data: List<&2, U32>, ms: U32) ->
  IO(Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>,
    List<&2, U32>>):
  import "./effs/tcp_send.c"
  import "./effs/tcp_send.js"

def TCP.recv_bytes(sock: Socket, max: U32) ->
  IO(Socket & Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>>):
  import "./effs/tcp_recv.c"
  import "./effs/tcp_recv.js"

def TCP.try_recv_bytes(sock: Socket, max: U32, ms: U32) ->
  IO(Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>>,
    Unit>):
  import "./effs/tcp_recv.c"
  import "./effs/tcp_recv.js"

def UDP.bind(host: String, port: U32) -> IO(Result<&1, &1, U32 & String, Socket>):
  import "./effs/udp_bind.c"
  import "./effs/udp_bind.js"

# A datagram goes whole or not at all: a failed send hands it back.
def UDP.send_to(sock: Socket, host: String, port: U32, data: String) ->
  IO(Socket & Result<&1, &1, (U32 & String) & String, Unit>):
  import "./effs/udp_send_to.c"
  import "./effs/udp_send_to.js"

def UDP.try_send_to(sock: Socket, host: String, port: U32, data: String, ms: U32) ->
  IO(Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & String, Unit>, String>):
  import "./effs/udp_send_to.c"
  import "./effs/udp_send_to.js"

# The datagram's bytes as they are (0..255), one List cell each: no UTF-8
# encoding, so a binary protocol's datagram goes out as written. A value
# past 255 fails with EINVAL before anything is sent.
def UDP.send_bytes_to(sock: Socket, host: String, port: U32, data: List<&2, U32>) ->
  IO(Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>):
  import "./effs/udp_send_to.c"
  import "./effs/udp_send_to.js"

def UDP.try_send_bytes_to(sock: Socket, host: String, port: U32, data: List<&2, U32>,
  ms: U32) ->
  IO(Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>,
    List<&2, U32>>):
  import "./effs/udp_send_to.c"
  import "./effs/udp_send_to.js"

# A datagram may be empty: UDP has no end, so no None{}.
def UDP.recv_from(sock: Socket, max: U32) ->
  IO(Socket & Result<&1, &1, U32 & String, String & U32 & String>):
  import "./effs/udp_recv_from.c"
  import "./effs/udp_recv_from.js"

def UDP.try_recv_from(sock: Socket, max: U32, ms: U32) ->
  IO(Socket & Poll<&1, &1, Result<&1, &1, U32 & String, String & U32 & String>, Unit>):
  import "./effs/udp_recv_from.c"
  import "./effs/udp_recv_from.js"

# The datagram's bytes as they are: no UTF-8 decoding, so every byte of a
# binary datagram survives.
def UDP.recv_bytes_from(sock: Socket, max: U32) ->
  IO(Socket & Result<&1, &1, U32 & String, String & U32 & List<&2, U32>>):
  import "./effs/udp_recv_from.c"
  import "./effs/udp_recv_from.js"

def UDP.try_recv_bytes_from(sock: Socket, max: U32, ms: U32) ->
  IO(Socket & Poll<&1, &1, Result<&1, &1, U32 & String,
    String & U32 & List<&2, U32>>, Unit>):
  import "./effs/udp_recv_from.c"
  import "./effs/udp_recv_from.js"

def Socket.close(socket: Socket) -> IO(Unit):
  import "./effs/socket_close.c"
  import "./effs/socket_close.js"

def Listener.close(listener: Listener) -> IO(Unit):
  import "./effs/listener_close.c"
  import "./effs/listener_close.js"

def Window.open(title: String, width: U32, height: U32) ->
  IO(Result<&1, &1, U32 & String, Window>):
  import "./effs/window.c"
  import "./effs/window_open.js"

def Window.frame(window: Window, image: Image) ->
  IO(Window & Image & List<Event>):
  import "./effs/window.c"
  import "./effs/window_frame.js"

def Window.set_title(window: Window, title: String) -> IO(Window):
  import "./effs/window.c"
  import "./effs/window_set_title.js"

# While grabbed, the cursor is hidden and held, and the mouse's motion
# comes as Look deltas instead of Move; losing focus releases it.
def Window.grab(window: Window, on: Bool) -> IO(Window):
  import "./effs/window.c"
  import "./effs/window_grab.js"

def Window.close(window: Window) -> IO(Unit):
  import "./effs/window.c"
  import "./effs/window_close.js"

def Audio.open(rate: U32) -> IO(Result<&1, &1, U32 & String, Audio>):
  import "./effs/audio.c"
  import "./effs/audio_open.js"

def Audio.write(audio: Audio, samples: List<&2, F32>) -> IO(Audio & U32):
  import "./effs/audio.c"
  import "./effs/audio_write.js"

def Audio.close(audio: Audio) -> IO(Unit):
  import "./effs/audio.c"
  import "./effs/audio_close.js"

# Equal
# -----

law Equal.cong:
  for -A: Type
  for -B: Type
  for -f: A -> B
  for -a: A
  for -b: A
  for  e: {a == b : A}
  {f(a) == f(b) : B}

def Equal.cong(A, B, f, a, b, e):
  %e : {f(a) == f(_) : B}
  {==}

law Equal.sym:
  for -A: Type
  for -a: A
  for -b: A
  for  e: {a == b : A}
  {b == a : A}

def Equal.sym(A, a, b, e):
  %e : {_ == a : A}
  {==}

law Equal.trans:
  for -A : Type
  for -a : A
  for -b : A
  for -c : A
  for ab : {a == b : A}
  for bc : {b == c : A}
  {a == c : A}

def Equal.trans(A, a, b, c, ab, bc):
  %bc : {a == _ : A}
  ab

# Empty
# -----

def Empty.absurd(-A: Type, e: Empty) -> A:
  match e:

# Bool
# ----

def Bool.not(b: Bool) -> Bool:
  match b:
    case False{}:
      True{}
    case True{}:
      False{}

def Bool.and(a: Bool, b: Bool) -> Bool:
  match a:
    case False{}:
      False{}
    case True{}:
      b

def Bool.or(a: Bool, b: Bool) -> Bool:
  match a:
    case False{}:
      b
    case True{}:
      True{}

def Bool.xor(a: Bool, b: Bool) -> Bool:
  match a:
    case False{}:
      b
    case True{}:
      Bool.not(b)

def Bool.cmp(a: Bool, b: Bool) -> Cmp:
  match a b:
    case False{} False{}:
      EQ{}
    case False{} True{}:
      LT{}
    case True{} False{}:
      GT{}
    case True{} True{}:
      EQ{}

def Bool.full_add(a: Bool, +b: Bool, +c: Bool) -> Bool & Bool:
  match a:
    case False{}:
      (Bool.xor(b, c), Bool.and(b, c))
    case True{}:
      (Bool.not(Bool.xor(b, c)), Bool.or(b, c))

def Bool.pick(-A: Type, c: Bool, a: A, b: A) -> A:
  match c:
    case False{}:
      b
    case True{}:
      a

def Bool.to_u32(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

# Cmp
# ---

def Cmp.is_lt(c: Cmp) -> Bool:
  match c:
    case LT{}:
      True{}
    case o:
      False{}

def Cmp.is_eq(c: Cmp) -> Bool:
  match c:
    case EQ{}:
      True{}
    case o:
      False{}

def Cmp.is_gt(c: Cmp) -> Bool:
  match c:
    case GT{}:
      True{}
    case o:
      False{}

def Cmp.is_le(c: Cmp) -> Bool:
  match c:
    case GT{}:
      False{}
    case o:
      True{}

def Cmp.is_ge(c: Cmp) -> Bool:
  match c:
    case LT{}:
      False{}
    case o:
      True{}

# Nat
# ---

def Nat.double(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      2n+Nat.double(p)

def Nat.add(a: Nat, b: Nat) -> Nat:
  match a:
    case 0n:
      b
    case 1n+p:
      1n+Nat.add(p, b)

def Nat.sub(a: Nat, b: Nat) -> Nat:
  match a b:
    case 0n _:
      0n
    case 1n+ap 0n:
      1n+ap
    case 1n+ap 1n+bp:
      Nat.sub(ap, bp)

def Nat.mul(a: Nat, +b: Nat) -> Nat:
  match a:
    case 0n:
      0n
    case 1n+p:
      Nat.add(b, Nat.mul(p, b))

def Nat.divmod.go(n: Nat, m: Nat, d: Nat, r: Nat) -> Nat & Nat:
  match n:
    case 0n:
      (d, r)
    case 1n+np:
      match m:
        case 0n:
          Nat.divmod.go(np, r, 1n+d, 0n)
        case 1n+mp:
          Nat.divmod.go(np, mp, d, 1n+r)

def Nat.divmod(a: Nat, b: Nat) -> Nat & Nat:
  match b:
    case 0n:
      (0n, a)
    case 1n+bp:
      Nat.divmod.go(a, bp, 0n, 0n)

def Nat.cmp(a: Nat, b: Nat) -> Cmp:
  match a b:
    case 0n 0n:
      EQ{}
    case 0n 1n+bp:
      LT{}
    case 1n+ap 0n:
      GT{}
    case 1n+ap 1n+bp:
      Nat.cmp(ap, bp)

def Nat.is_lt(a: Nat, b: Nat) -> Bool:
  Cmp.is_lt(Nat.cmp(a, b))

def Nat.is_eq(a: Nat, b: Nat) -> Bool:
  Cmp.is_eq(Nat.cmp(a, b))

def Nat.is_ne(a: Nat, b: Nat) -> Bool:
  Bool.not(Cmp.is_eq(Nat.cmp(a, b)))

def Nat.is_le(a: Nat, b: Nat) -> Bool:
  Cmp.is_le(Nat.cmp(a, b))

def Nat.is_gt(a: Nat, b: Nat) -> Bool:
  Cmp.is_gt(Nat.cmp(a, b))

def Nat.is_ge(a: Nat, b: Nat) -> Bool:
  Cmp.is_ge(Nat.cmp(a, b))

def Nat.min(+a: Nat, +b: Nat) -> Nat:
  match a b:
    case 0n _:
      0n
    case 1n+ap 0n:
      0n
    case 1n+ap 1n+bp:
      1n+Nat.min(ap, bp)

def Nat.max(+a: Nat, +b: Nat) -> Nat:
  match a b:
    case 0n _:
      b
    case 1n+ap 0n:
      1n+ap
    case 1n+ap 1n+bp:
      1n+Nat.max(ap, bp)

law Nat.ge_refl:
  for a: Nat
  {Nat.is_ge(a, a) == True{} : Bool}

def Nat.ge_refl(a):
  match a:
    case 0n:
      {==}
    case 1n+p:
      Nat.ge_refl(p)

law Nat.max_ge_l:
  for +a: Nat
  for +b: Nat
  {Nat.is_ge(Nat.max(a, b), a) == True{} : Bool}

def Nat.max_ge_l(a, b):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Nat.ge_refl(a)
    case 1n+ap 1n+bp:
      Nat.max_ge_l(ap, bp)

law Nat.max_ge_r:
  for +a: Nat
  for +b: Nat
  {Nat.is_ge(Nat.max(a, b), b) == True{} : Bool}

def Nat.max_ge_r(a, b):
  match a b:
    case 0n _:
      Nat.ge_refl(b)
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      Nat.max_ge_r(ap, bp)

def Nat.div(a: Nat, b: Nat) -> Nat:
  Pair.fst(Nat, Nat, Nat.divmod(a, b))

def Nat.mod(a: Nat, b: Nat) -> Nat:
  Pair.snd(Nat, Nat, Nat.divmod(a, b))

def Nat.pow(+a: Nat, b: Nat) -> Nat:
  match b:
    case 0n:
      1n
    case 1n+p:
      Nat.mul(a, Nat.pow(a, p))

# Maybe
# -----

def Maybe.pure(a, -A: Kind(a), x: A) -> Maybe<a, A>:
  Some{x}

def Maybe.bind(
  a, -A: Kind(a), -B: Kind(a), m: Maybe<a, A>, f: A -> Maybe<a, B>
) -> Maybe<a, B>:
  match m:
    case None{}:
      None{}
    case Some{x}:
      f(x)

def Maybe.default(a, -A: Kind(a), m: Maybe<a, A>, d: A) -> A:
  match m:
    case None{}:
      d
    case Some{x}:
      x

def Maybe.is_some(a, -A: Kind(a), m: Maybe<a, A>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{x}:
      True{}

def Maybe.is_none(a, -A: Kind(a), m: Maybe<a, A>) -> Bool:
  Bool.not(Maybe.is_some(a, A, m))

def Maybe.map(
  a, -A: Kind(a), -B: Kind(a), f: A -> B, m: Maybe<a, A>
) -> Maybe<a, B>:
  match m:
    case None{}:
      None{}
    case Some{x}:
      Some{f(x)}

def Maybe.or(a, -A: Kind(a), m: Maybe<a, A>, n: Maybe<a, A>) -> Maybe<a, A>:
  match m:
    case None{}:
      n
    case Some{x}:
      Some{x}

# Result
# ------

def Result.pure(a, b, -E: Kind(a), -A: Kind(b), x: A) -> Result<a, b, E, A>:
  Done{x}

def Result.bind(
  a, b, -E: Kind(a), -A: Kind(b), -B: Kind(b), r: Result<a, b, E, A>,
  f: A -> Result<a, b, E, B>
) -> Result<a, b, E, B>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{x}:
      f(x)

def Result.default(
  a, b, -E: Kind(a), -A: Kind(b), r: Result<a, b, E, A>, d: A
) -> A:
  match r:
    case Fail{e}:
      d
    case Done{x}:
      x

def Result.is_done(
  a, b, -E: Kind(a), -A: Kind(b), r: Result<a, b, E, A>
) -> Bool:
  match r:
    case Fail{e}:
      False{}
    case Done{x}:
      True{}

def Result.is_fail(
  a, b, -E: Kind(a), -A: Kind(b), r: Result<a, b, E, A>
) -> Bool:
  Bool.not(Result.is_done(a, b, E, A, r))

def Result.map(
  a, b, -E: Kind(a), -A: Kind(b), -B: Kind(b), f: A -> B,
  r: Result<a, b, E, A>
) -> Result<a, b, E, B>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{x}:
      Done{f(x)}

# List
# ----

def List.map(~A: Type, ~B: Type, ~f: A -> B, xs: List<A>) -> List<B>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      f(h) <> List.map(~A, ~B, ~f, t)

def List.length(a, -A: Kind(a), xs: List<a, A>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      1n+List.length(a, A, t)

def List.append(a, -A: Kind(a), xs: List<a, A>, ys: List<a, A>) -> List<a, A>:
  match xs:
    case Nil{}:
      ys
    case h <> t:
      h <> List.append(a, A, t, ys)

def List.concat(a, -A: Kind(a), xss: List<a, List<a, A>>) -> List<a, A>:
  match xss:
    case Nil{}:
      Nil{}
    case h <> t:
      List.append(a, A, h, List.concat(a, A, t))

def List.reverse.go(a, -A: Kind(a), xs: List<a, A>, acc: List<a, A>) ->
  List<a, A>:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      List.reverse.go(a, A, t, h <> acc)

def List.reverse(a, -A: Kind(a), xs: List<a, A>) -> List<a, A>:
  List.reverse.go(a, A, xs, Nil{})

def List.is_empty(a, -A: Kind(a), xs: List<a, A>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> t:
      False{}

def List.head(a, -A: Kind(a), xs: List<a, A>) -> Maybe<a, A>:
  match xs:
    case Nil{}:
      None{}
    case h <> t:
      Some{h}

def List.tail(a, -A: Kind(a), xs: List<a, A>) -> List<a, A>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      t

def List.last.go(a, -A: Kind(a), xs: List<a, A>, last: A) -> A:
  match xs:
    case Nil{}:
      last
    case h <> t:
      List.last.go(a, A, t, h)

def List.last(a, -A: Kind(a), xs: List<a, A>) -> Maybe<a, A>:
  match xs:
    case Nil{}:
      None{}
    case h <> t:
      Some{List.last.go(a, A, t, h)}

def List.get(a, -A: Kind(a), xs: List<a, A>, n: Nat) -> Maybe<a, A>:
  match xs n:
    case Nil{} _:
      None{}
    case h <> t 0n:
      Some{h}
    case h <> t 1n+p:
      List.get(a, A, t, p)

def List.set(a, -A: Kind(a), xs: List<a, A>, n: Nat, x: A) -> List<a, A>:
  match xs n:
    case Nil{} _:
      Nil{}
    case h <> t 0n:
      x <> t
    case h <> t 1n+p:
      h <> List.set(a, A, t, p, x)

def List.take(a, -A: Kind(a), xs: List<a, A>, n: Nat) -> List<a, A>:
  match xs n:
    case Nil{} _:
      Nil{}
    case h <> t 0n:
      Nil{}
    case h <> t 1n+p:
      h <> List.take(a, A, t, p)

def List.drop(a, -A: Kind(a), xs: List<a, A>, n: Nat) -> List<a, A>:
  match xs n:
    case Nil{} _:
      Nil{}
    case h <> t 0n:
      h <> t
    case h <> t 1n+p:
      List.drop(a, A, t, p)

def List.zip(
  a, -A: Kind(a), b, -B: Kind(b), xs: List<a, A>, ys: List<b, B>
) -> List<&1, A & B>:
  match xs ys:
    case Nil{} _:
      Nil{}
    case h <> t Nil{}:
      Nil{}
    case x <> xt y <> yt:
      (x, y) <> List.zip(a, A, b, B, xt, yt)

def List.range.go(+n: Nat, acc: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n:
      acc
    case 1n+p:
      List.range.go(p, p <> acc)

def List.range(n: Nat) -> List<&2, Nat>:
  List.range.go(n, Nil{})

def List.replicate(-A: Data, n: Nat, +x: A) -> List<&2, A>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      x <> List.replicate(A, p, x)

def List.filter.put(-A: Data, h: A, r: List<&2, A>, keep: Bool) -> List<&2, A>:
  match keep:
    case False{}:
      r
    case True{}:
      h <> r

def List.filter(~A: Data, ~f: A -> Bool, xs: List<&2, A>) -> List<&2, A>:
  match xs:
    case Nil{}:
      Nil{}
    case +h <> t:
      List.filter.put(A, h, List.filter(~A, ~f, t), f(h))

def List.foldl(
  ~a: Quant, ~A: Kind(a), ~B: Type, ~f: B -> A -> B, xs: List<a, A>, acc: B
) -> B:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      List.foldl(~a, ~A, ~B, ~f, t, f(acc, h))

def List.foldr(
  ~a: Quant, ~A: Kind(a), ~B: Type, ~f: A -> B -> B, xs: List<a, A>, z: B
) -> B:
  match xs:
    case Nil{}:
      z
    case h <> t:
      f(h, List.foldr(~a, ~A, ~B, ~f, t, z))

def List.any(~a: Quant, ~A: Kind(a), ~f: A -> Bool, xs: List<a, A>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(f(h), List.any(~a, ~A, ~f, t))

def List.all(~a: Quant, ~A: Kind(a), ~f: A -> Bool, xs: List<a, A>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> t:
      Bool.and(f(h), List.all(~a, ~A, ~f, t))

def List.find.put(-A: Data, h: A, r: Maybe<&2, A>, hit: Bool) -> Maybe<&2, A>:
  match hit:
    case False{}:
      r
    case True{}:
      Some{h}

def List.find(~A: Data, ~f: A -> Bool, xs: List<&2, A>) -> Maybe<&2, A>:
  match xs:
    case Nil{}:
      None{}
    case +h <> t:
      List.find.put(A, h, List.find(~A, ~f, t), f(h))

def List.contains(
  ~A: Data, ~eq: A -> A -> Bool, xs: List<&2, A>, +x: A
) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(eq(h, x), List.contains(~A, ~eq, t, x))

def List.merge.step(
  -A: Data, acc: List<&2, A>, x: A, xt: List<&2, A>, y: A, yt: List<&2, A>,
  le: Bool
) -> List<&2, A> & List<&2, A> & List<&2, A>:
  match le:
    case False{}:
      (y <> acc, x <> xt, yt)
    case True{}:
      (x <> acc, xt, y <> yt)

# The fuel bounds the steps: a sort passes its length, enough for any merge.
def List.merge.go(
  ~A: Data, ~le: A -> A -> Bool, fuel: Nat,
  st: List<&2, A> & List<&2, A> & List<&2, A>
) -> List<&2, A>:
  match fuel:
    case 0n:
      (acc, xs, ys) = st
      List.reverse.go(&2, A, acc, List.append(&2, A, xs, ys))
    case 1n+f:
      (acc, xs, ys) = st
      match xs ys:
        case Nil{} Nil{}:
          List.reverse.go(&2, A, acc, Nil{})
        case Nil{} y <> yt:
          List.reverse.go(&2, A, acc, y <> yt)
        case x <> xt Nil{}:
          List.reverse.go(&2, A, acc, x <> xt)
        case +x <> xt +y <> yt:
          List.merge.go(~A, ~le, f,
            List.merge.step(A, acc, x, xt, y, yt, le(x, y)))

def List.sort.runs(-A: Data, xs: List<&2, A>) -> List<&2, List<&2, A>>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      [h] <> List.sort.runs(A, t)

def List.sort.pass(
  ~A: Data, ~le: A -> A -> Bool, +n: Nat, runs: List<&2, List<&2, A>>
) -> List<&2, List<&2, A>>:
  match runs:
    case Nil{}:
      Nil{}
    case r <> Nil{}:
      [r]
    case r1 <> r2 <> rest:
      List.merge.go(~A, ~le, n, (Nil{}, r1, r2))
        <> List.sort.pass(~A, ~le, n, rest)

def List.sort.go(
  ~A: Data, ~le: A -> A -> Bool, fuel: Nat, +n: Nat, runs: List<&2, List<&2, A>>
) -> List<&2, A>:
  match fuel:
    case 0n:
      List.concat(&2, A, runs)
    case 1n+f:
      match runs:
        case Nil{}:
          Nil{}
        case r <> Nil{}:
          r
        case r1 <> r2 <> rest:
          List.sort.go(~A, ~le, f, n,
            List.sort.pass(~A, ~le, n, r1 <> r2 <> rest))

def List.sort(~A: Data, ~le: A -> A -> Bool, xs: List<&2, A>) -> List<&2, A>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      +ys = {h <> t : List<&2, A>}
      +n = List.length(&2, A, ys)
      List.sort.go(~A, ~le, n, n, List.sort.runs(A, ys))

def List.for_each(
  ~a: Quant, ~A: Kind(a), ~f: A -> IO(Unit), xs: List<a, A>
) -> IO(Unit):
  match xs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case h <> t:
      IO.bind(Unit, Unit, f(h), u => List.for_each(~a, ~A, ~f, t))

# Word
# ----

def Word.zero(n: Nat) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      WCon{False{}, Word.zero(p)}

def Word.not(n: Nat, w: Word(n)) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match w:
        case WCon{b, t}:
          WCon{Bool.not(b), Word.not(p, t)}

def Word.and(n: Nat, a: Word(n), b: Word(n)) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match a b:
        case WCon{ab, at} WCon{bb, bt}:
          WCon{Bool.and(ab, bb), Word.and(p, at, bt)}

def Word.or(n: Nat, a: Word(n), b: Word(n)) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match a b:
        case WCon{ab, at} WCon{bb, bt}:
          WCon{Bool.or(ab, bb), Word.or(p, at, bt)}

def Word.xor(n: Nat, a: Word(n), b: Word(n)) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match a b:
        case WCon{ab, at} WCon{bb, bt}:
          WCon{Bool.xor(ab, bb), Word.xor(p, at, bt)}

def Word.shl.put(n: Nat, c: Bool, w: Word(n)) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match w:
        case WCon{b, t}:
          WCon{c, Word.shl.put(p, b, t)}

def Word.shl(n: Nat, w: Word(n)) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match w:
        case WCon{b, t}:
          WCon{False{}, Word.shl.put(p, b, t)}

def Word.shl.out.con(-p: Nat, c: Bool, r: Bool & Word(p)) -> Bool & Word(1n+p):
  (hi, t2) = r
  (hi, WCon{c, t2})

def Word.shl.out(n: Nat, c: Bool, w: Word(n)) -> Bool & Word(n):
  match n:
    case 0n:
      (c, WNil{})
    case 1n+p:
      match w:
        case WCon{b, t}:
          Word.shl.out.con(p, c, Word.shl.out(p, b, t))

def Word.shr.pad(n: Nat, w: Word(n)) -> Word(1n+n):
  match n:
    case 0n:
      WCon{False{}, w}
    case 1n+p:
      match w:
        case WCon{b, t}:
          WCon{b, Word.shr.pad(p, t)}

def Word.shr(n: Nat, w: Word(n)) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match w:
        case WCon{b, t}:
          Word.shr.pad(p, t)

def Word.cmp.fin(ab: Bool, bb: Bool, t: Cmp) -> Cmp:
  match t:
    case LT{}:
      LT{}
    case EQ{}:
      Bool.cmp(ab, bb)
    case GT{}:
      GT{}

def Word.cmp(n: Nat, a: Word(n), b: Word(n)) -> Cmp:
  match n:
    case 0n:
      EQ{}
    case 1n+p:
      match a b:
        case WCon{ab, at} WCon{bb, bt}:
          Word.cmp.fin(ab, bb, Word.cmp(p, at, bt))

def Word.inc(n: Nat, w: Word(n)) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match w:
        case WCon{False{}, t}:
          WCon{True{}, t}
        case WCon{True{}, t}:
          WCon{False{}, Word.inc(p, t)}

law Word.adc:
  for n: Nat
  for a: Word(n)
  for b: Word(n)
  for f: Bool
  for c: Bool
  Word(n)

def Word.adc.con(p: Nat, at: Word(p), bt: Word(p), f: Bool, sk: Bool & Bool) ->
  Word(1n+p):
  (s, k) = sk
  WCon{s, Word.adc(p, at, bt, f, k)}

def Word.adc(n, a, b, f, c):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match a b f:
        case WCon{ab, at} WCon{bb, bt} False{}:
          Word.adc.con(p, at, bt, False{}, Bool.full_add(ab, bb, c))
        case WCon{ab, at} WCon{bb, bt} True{}:
          Word.adc.con(p, at, bt, True{}, Bool.full_add(ab, Bool.not(bb), c))

def Word.add(n: Nat, a: Word(n), b: Word(n)) -> Word(n):
  Word.adc(n, a, b, False{}, False{})

def Word.sub(n: Nat, a: Word(n), b: Word(n)) -> Word(n):
  Word.adc(n, a, b, True{}, True{})

law Word.add_comm.arm:
  for p  : Nat
  for at : Word(p)
  for bt : Word(p)
  for k  : Bool
  for -h : Bool
  {WCon{h, Word.adc(p, at, bt, False{}, k)}
    == WCon{h, Word.adc(p, bt, at, False{}, k)} : Word.Con<p>}

law Word.add_comm.go:
  for n: Nat
  for a: Word(n)
  for b: Word(n)
  for c: Bool
  {Word.adc(n, a, b, False{}, c) == Word.adc(n, b, a, False{}, c) : Word(n)}

def Word.add_comm.arm(p, at, bt, k, h):
  Equal.cong(Word(p), Word(1n+p), w => WCon{h, w},
    Word.adc(p, at, bt, False{}, k), Word.adc(p, bt, at, False{}, k),
    Word.add_comm.go(p, at, bt, k))

def Word.add_comm.go(n, a, b, c):
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}:
          {==}
    case 1n+p:
      match a b c:
        case WCon{False{}, at} WCon{False{}, bt} False{}:
          Word.add_comm.arm(p, at, bt, False{}, False{})
        case WCon{False{}, at} WCon{False{}, bt} True{}:
          Word.add_comm.arm(p, at, bt, False{}, True{})
        case WCon{False{}, at} WCon{True{}, bt} False{}:
          Word.add_comm.arm(p, at, bt, False{}, True{})
        case WCon{False{}, at} WCon{True{}, bt} True{}:
          Word.add_comm.arm(p, at, bt, True{}, False{})
        case WCon{True{}, at} WCon{False{}, bt} False{}:
          Word.add_comm.arm(p, at, bt, False{}, True{})
        case WCon{True{}, at} WCon{False{}, bt} True{}:
          Word.add_comm.arm(p, at, bt, True{}, False{})
        case WCon{True{}, at} WCon{True{}, bt} False{}:
          Word.add_comm.arm(p, at, bt, True{}, False{})
        case WCon{True{}, at} WCon{True{}, bt} True{}:
          Word.add_comm.arm(p, at, bt, True{}, True{})

law Word.add_comm:
  for n: Nat
  for a: Word(n)
  for b: Word(n)
  {Word.add(n, a, b) == Word.add(n, b, a) : Word(n)}

def Word.add_comm(n, a, b):
  Word.add_comm.go(n, a, b, False{})

def Word.to_nat(n: Nat, w: Word(n)) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      match w:
        case WCon{False{}, t}:
          Nat.double(Word.to_nat(p, t))
        case WCon{True{}, t}:
          1n+Nat.double(Word.to_nat(p, t))

def Word.mul.go(+n: Nat, m: Nat, a: Word(m), +b: Word(n), acc: Word(n)) ->
  Word(n):
  match m:
    case 0n:
      acc
    case 1n+mp:
      match a:
        case WCon{False{}, at}:
          Word.mul.go(n, mp, at, Word.shl(n, b), acc)
        case WCon{True{}, at}:
          Word.mul.go(n, mp, at, Word.shl(n, b), Word.add(n, acc, b))

def Word.mul(+n: Nat, a: Word(n), b: Word(n)) -> Word(n):
  Word.mul.go(n, n, a, b, Word.zero(n))

# U32
# ---

def U32.inc(a: U32) -> U32:
  match a:
    case U32{x}:
      U32{Word.inc(32n, x)}

def U32.add(a: U32, b: U32) -> U32:
  match a b:
    case U32{x} U32{y}:
      U32{Word.add(32n, x, y)}

law U32.add_comm:
  for a: U32
  for b: U32
  {U32.add(a, b) == U32.add(b, a) : U32}

def U32.add_comm(a, b):
  match a b:
    case U32{x} U32{y}:
      Equal.cong(Word(32n), U32, w => U32{w}, Word.add(32n, x, y),
        Word.add(32n, y, x), Word.add_comm(32n, x, y))

def U32.sub(a: U32, b: U32) -> U32:
  match a b:
    case U32{x} U32{y}:
      U32{Word.sub(32n, x, y)}

def U32.mul(a: U32, b: U32) -> U32:
  match a b:
    case U32{x} U32{y}:
      U32{Word.mul(32n, x, y)}

def U32.not(a: U32) -> U32:
  match a:
    case U32{x}:
      U32{Word.not(32n, x)}

def U32.and(a: U32, b: U32) -> U32:
  match a b:
    case U32{x} U32{y}:
      U32{Word.and(32n, x, y)}

def U32.or(a: U32, b: U32) -> U32:
  match a b:
    case U32{x} U32{y}:
      U32{Word.or(32n, x, y)}

def U32.xor(a: U32, b: U32) -> U32:
  match a b:
    case U32{x} U32{y}:
      U32{Word.xor(32n, x, y)}

def U32.shl(a: U32) -> U32:
  match a:
    case U32{x}:
      U32{Word.shl(32n, x)}

def U32.shr(a: U32) -> U32:
  match a:
    case U32{x}:
      U32{Word.shr(32n, x)}

def U32.shln(a: U32, n: Nat) -> U32:
  match n:
    case 0n:
      a
    case 1n+p:
      U32.shl(U32.shln(a, p))

def U32.shrn(a: U32, n: Nat) -> U32:
  match n:
    case 0n:
      a
    case 1n+p:
      U32.shr(U32.shrn(a, p))

def U32.cmp(a: U32, b: U32) -> Cmp:
  match a b:
    case U32{x} U32{y}:
      Word.cmp(32n, x, y)

def U32.is_eq(a: U32, b: U32) -> Bool:
  Cmp.is_eq(U32.cmp(a, b))

def U32.is_ne(a: U32, b: U32) -> Bool:
  Bool.not(Cmp.is_eq(U32.cmp(a, b)))

def U32.is_lt(a: U32, b: U32) -> Bool:
  Cmp.is_lt(U32.cmp(a, b))

def U32.is_le(a: U32, b: U32) -> Bool:
  Cmp.is_le(U32.cmp(a, b))

def U32.is_gt(a: U32, b: U32) -> Bool:
  Cmp.is_gt(U32.cmp(a, b))

def U32.is_ge(a: U32, b: U32) -> Bool:
  Cmp.is_ge(U32.cmp(a, b))

def U32.is_zero(a: U32) -> Bool:
  U32.is_eq(a, 0)

def U32.to_nat(a: U32) -> Nat:
  match a:
    case U32{w}:
      Word.to_nat(32n, w)

def U32.from_nat(n: Nat) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      U32.inc(U32.from_nat(p))

def U32.log2.go(+k: Nat, +n: U32, b: Nat) -> Nat:
  match k:
    case 0n:
      b
    case 1n+p:
      +s = U32.to_nat(U32.shln(1, p))
      +t = Nat.mul(s, U32.to_nat(Bool.to_u32(U32.is_ne(U32.shrn(n, s), 0))))
      U32.log2.go(p, U32.shrn(n, t), Nat.add(b, t))

def U32.log2(n: U32) -> Nat:
  U32.log2.go(5n, n, 0n)

def U32.divmod.go.fin(-p: Nat, q: Word(p), s: U32, b: U32, g: Bool) ->
  Word(1n+p) & U32:
  match g:
    case True{}:
      (WCon{True{}, q}, U32.sub(s, b))
    case False{}:
      (WCon{False{}, q}, s)

def U32.divmod.go.shl(-p: Nat, q: Word(p), +b: U32, ts: Bool & Word(32n)) ->
  Word(1n+p) & U32:
  (t, s) = ts
  +s2 = {U32{s} : U32}
  U32.divmod.go.fin(p, q, s2, b, Bool.or(t, U32.is_ge(s2, b)))

def U32.divmod.go.rec(-p: Nat, a0: Bool, +b: U32, qr: Word(p) & U32) ->
  Word(1n+p) & U32:
  (q, r) = qr
  U32{rw} = r
  U32.divmod.go.shl(p, q, b, Word.shl.out(32n, a0, rw))

def U32.divmod.go(m: Nat, a: Word(m), +b: U32) -> Word(m) & U32:
  match m a:
    case 0n WNil{}:
      (WNil{}, 0)
    case 1n+p WCon{a0, hi}:
      U32.divmod.go.rec(p, a0, b, U32.divmod.go(p, hi, b))

def U32.div.fin(qr: Word(32n) & U32) -> U32:
  (q, r) = qr
  U32{q}

def U32.div.if(aw: Word(32n), b: U32, z: Bool) -> U32:
  match z:
    case True{}:
      0
    case False{}:
      U32.div.fin(U32.divmod.go(32n, aw, b))

def U32.div(a: U32, b: U32) -> U32:
  U32{aw} = a
  U32{+bw} = b
  U32.div.if(aw, U32{bw}, U32.is_zero(U32{bw}))

def U32.mod.fin(qr: Word(32n) & U32) -> U32:
  (q, r) = qr
  r

def U32.mod.if(aw: Word(32n), b: U32, z: Bool) -> U32:
  match z:
    case True{}:
      U32{aw}
    case False{}:
      U32.mod.fin(U32.divmod.go(32n, aw, b))

def U32.mod(a: U32, b: U32) -> U32:
  U32{aw} = a
  U32{+bw} = b
  U32.mod.if(aw, U32{bw}, U32.is_zero(U32{bw}))

def U32.min(a: U32, b: U32) -> U32:
  match a b:
    case U32{+x} U32{+y}:
      Bool.pick(U32, U32.is_lt(U32{x}, U32{y}), U32{x}, U32{y})

def U32.max(a: U32, b: U32) -> U32:
  match a b:
    case U32{+x} U32{+y}:
      Bool.pick(U32, U32.is_lt(U32{x}, U32{y}), U32{y}, U32{x})

def U32.clamp(x: U32, lo: U32, hi: U32) -> U32:
  U32.min(U32.max(x, lo), hi)

def U32.pow(+a: U32, n: Nat) -> U32:
  match n:
    case 0n:
      1
    case 1n+p:
      U32.mul(a, U32.pow(a, p))

def U32.is_even(a: U32) -> Bool:
  U32.is_zero(U32.and(a, 1))

# F32
# ---

law U32.to_f32:
  for a: U32
  F32

law F32.to_u32:
  for a: F32
  U32

law F32.add:
  for a: F32
  for b: F32
  F32

law F32.sub:
  for a: F32
  for b: F32
  F32

law F32.mul:
  for a: F32
  for b: F32
  F32

law F32.div:
  for a: F32
  for b: F32
  F32

law F32.mod:
  for a: F32
  for b: F32
  F32

law F32.pow:
  for a: F32
  for b: F32
  F32

law F32.atan2:
  for a: F32
  for b: F32
  F32

law F32.neg:
  for a: F32
  F32

law F32.abs:
  for a: F32
  F32

law F32.sqrt:
  for a: F32
  F32

law F32.exp:
  for a: F32
  F32

law F32.log:
  for a: F32
  F32

law F32.log2:
  for a: F32
  F32

law F32.log10:
  for a: F32
  F32

law F32.sin:
  for a: F32
  F32

law F32.cos:
  for a: F32
  F32

law F32.tan:
  for a: F32
  F32

law F32.asin:
  for a: F32
  F32

law F32.acos:
  for a: F32
  F32

law F32.atan:
  for a: F32
  F32

law F32.sinh:
  for a: F32
  F32

law F32.cosh:
  for a: F32
  F32

law F32.tanh:
  for a: F32
  F32

law F32.floor:
  for a: F32
  F32

law F32.ceil:
  for a: F32
  F32

law F32.trunc:
  for a: F32
  F32

law F32.is_eq:
  for a: F32
  for b: F32
  Bool

law F32.is_ne:
  for a: F32
  for b: F32
  Bool

law F32.is_lt:
  for a: F32
  for b: F32
  Bool

law F32.is_le:
  for a: F32
  for b: F32
  Bool

law F32.is_gt:
  for a: F32
  for b: F32
  Bool

law F32.is_ge:
  for a: F32
  for b: F32
  Bool

law F32.show:
  for +a: F32
  String

law F32.bits:
  for a: F32
  U32

law F32.read:
  for s: String
  Maybe<&2, F32>

def F32.min(a: F32, b: F32) -> F32:
  match a b:
    case F32{+x} F32{+y}:
      Bool.pick(F32, F32.is_lt(F32{x}, F32{y}), F32{x}, F32{y})

def F32.max(a: F32, b: F32) -> F32:
  match a b:
    case F32{+x} F32{+y}:
      Bool.pick(F32, F32.is_lt(F32{x}, F32{y}), F32{y}, F32{x})

def F32.clamp(x: F32, lo: F32, hi: F32) -> F32:
  F32.min(F32.max(x, lo), hi)

def F32.lerp(a: F32, b: F32, t: F32) -> F32:
  match a:
    case F32{+x}:
      F32.add(F32{x}, F32.mul(F32.sub(b, F32{x}), t))

def F32.square(a: F32) -> F32:
  match a:
    case F32{+x}:
      F32.mul(F32{x}, F32{x})

def F32.hypot(a: F32, b: F32) -> F32:
  match a b:
    case F32{+x} F32{+y}:
      F32.sqrt(F32.add(F32.mul(F32{x}, F32{x}), F32.mul(F32{y}, F32{y})))

def F32.round(a: F32) -> F32:
  F32.floor(F32.add(a, 0.5))

def F32.pi() -> F32:
  3.14159265

def F32.from_nat(n: Nat) -> F32:
  U32.to_f32(U32.from_nat(n))

def F32.to_nat(a: F32) -> Nat:
  U32.to_nat(F32.to_u32(a))

# Char
# ----

def Char.cmp(a: Char, b: Char) -> (Char & Char) & Cmp:
  match a b:
    case Chr{+x} Chr{+y}:
      ((Chr{x}, Chr{y}), U32.cmp(x, y))

def Char.to_u32(c: Char) -> U32:
  match c:
    case Chr{x}:
      x

def Char.from_u32(x: U32) -> Char:
  Chr{x}

def Char.is_eq(a: Char, b: Char) -> Bool:
  match a b:
    case Chr{x} Chr{y}:
      U32.is_eq(x, y)

def Char.is_digit(c: Char) -> Bool:
  match c:
    case Chr{+x}:
      Bool.and(U32.is_ge(x, 48), U32.is_le(x, 57))

def Char.is_upper(c: Char) -> Bool:
  match c:
    case Chr{+x}:
      Bool.and(U32.is_ge(x, 65), U32.is_le(x, 90))

def Char.is_lower(c: Char) -> Bool:
  match c:
    case Chr{+x}:
      Bool.and(U32.is_ge(x, 97), U32.is_le(x, 122))

def Char.is_alpha(+c: Char) -> Bool:
  Bool.or(Char.is_upper(c), Char.is_lower(c))

def Char.is_space(c: Char) -> Bool:
  match c:
    case Chr{+x}:
      Bool.or(U32.is_eq(x, 32), Bool.and(U32.is_ge(x, 9), U32.is_le(x, 13)))

def Char.to_upper(c: Char) -> Char:
  match c:
    case Chr{+x}:
      Chr{U32.sub(x, U32.mul(Bool.to_u32(Char.is_lower(Chr{x})), 32))}

def Char.to_lower(c: Char) -> Char:
  match c:
    case Chr{+x}:
      Chr{U32.add(x, U32.mul(Bool.to_u32(Char.is_upper(Chr{x})), 32))}

# String
# ------

def String.append(a: String, b: String) -> String:
  match a:
    case SNil{}:
      b
    case SCon{h, t}:
      SCon{h, String.append(t, b)}

def String.cmp.rec(h1b: Char, h2b: Char, rr: (String & String) & Cmp) ->
  (String & String) & Cmp:
  ((t1b, t2b), r) = rr
  ((SCon{h1b, t1b}, SCon{h2b, t2b}), r)

law String.cmp:
  for a: String
  for b: String
  (String & String) & Cmp

def String.cmp.fin(t1: String, t2: String, hc: (Char & Char) & Cmp) ->
  (String & String) & Cmp:
  ((h1b, h2b), c) = hc
  match c:
    case LT{}:
      ((SCon{h1b, t1}, SCon{h2b, t2}), LT{})
    case EQ{}:
      String.cmp.rec(h1b, h2b, String.cmp(t1, t2))
    case GT{}:
      ((SCon{h1b, t1}, SCon{h2b, t2}), GT{})

def String.cmp(a, b):
  match a b:
    case SNil{} SNil{}:
      ((SNil{}, SNil{}), EQ{})
    case SNil{} SCon{h, t}:
      ((SNil{}, SCon{h, t}), LT{})
    case SCon{h, t} SNil{}:
      ((SCon{h, t}, SNil{}), GT{})
    case SCon{h1, t1} SCon{h2, t2}:
      String.cmp.fin(t1, t2, Char.cmp(h1, h2))

def String.eq(a: String, b: String) -> Bool:
  Cmp.is_eq(String.order(a, b))

def String.length(s: String) -> Nat:
  match s:
    case SNil{}:
      0n
    case SCon{h, t}:
      1n+String.length(t)

def String.is_empty(s: String) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{h, t}:
      False{}

def String.reverse.go(s: String, acc: String) -> String:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      String.reverse.go(t, SCon{h, acc})

def String.reverse(s: String) -> String:
  String.reverse.go(s, SNil{})

def String.order(a: String, b: String) -> Cmp:
  Pair.snd(String & String, Cmp, String.cmp(a, b))

def String.is_lt(a: String, b: String) -> Bool:
  Cmp.is_lt(String.order(a, b))

def String.is_le(a: String, b: String) -> Bool:
  Cmp.is_le(String.order(a, b))

def String.is_gt(a: String, b: String) -> Bool:
  Cmp.is_gt(String.order(a, b))

def String.is_ge(a: String, b: String) -> Bool:
  Cmp.is_ge(String.order(a, b))

law String.starts_with:
  for s: String
  for p: String
  Bool

def String.starts_with.if(t: String, pt: String, same: Bool) -> Bool:
  match same:
    case False{}:
      False{}
    case True{}:
      String.starts_with(t, pt)

def String.starts_with(s, p):
  match s p:
    case SNil{} SNil{}:
      True{}
    case SNil{} SCon{h, t}:
      False{}
    case SCon{h, t} SNil{}:
      True{}
    case SCon{x, xt} SCon{y, yt}:
      String.starts_with.if(xt, yt, Char.is_eq(x, y))

def String.ends_with(s: String, p: String) -> Bool:
  String.starts_with(String.reverse(s), String.reverse(p))

law String.contains:
  for +s: String
  for +p: String
  Bool

def String.contains.if(t: String, p: String, here: Bool) -> Bool:
  match here:
    case False{}:
      String.contains(t, p)
    case True{}:
      True{}

def String.contains(s, p):
  match s:
    case SNil{}:
      String.is_empty(p)
    case SCon{h, t}:
      String.contains.if(t, p, String.starts_with(SCon{h, t}, p))

def String.take(s: String, n: Nat) -> String:
  match s n:
    case SNil{} _:
      SNil{}
    case SCon{h, t} 0n:
      SNil{}
    case SCon{h, t} 1n+p:
      SCon{h, String.take(t, p)}

def String.drop(s: String, n: Nat) -> String:
  match s n:
    case SNil{} _:
      SNil{}
    case SCon{h, t} 0n:
      SCon{h, t}
    case SCon{h, t} 1n+p:
      String.drop(t, p)

def String.get(s: String, n: Nat) -> Maybe<&2, Char>:
  match s n:
    case SNil{} _:
      None{}
    case SCon{h, t} 0n:
      Some{h}
    case SCon{h, t} 1n+p:
      String.get(t, p)

def String.to_list(s: String) -> List<&2, Char>:
  match s:
    case SNil{}:
      Nil{}
    case SCon{h, t}:
      h <> String.to_list(t)

def String.from_list(cs: List<&2, Char>) -> String:
  match cs:
    case Nil{}:
      SNil{}
    case h <> t:
      SCon{h, String.from_list(t)}

def String.concat(xs: List<&2, String>) -> String:
  match xs:
    case Nil{}:
      SNil{}
    case h <> t:
      String.append(h, String.concat(t))

def String.join.go(xs: List<&2, String>, h: String, +sep: String) -> String:
  match xs:
    case Nil{}:
      h
    case h2 <> t:
      String.append(h, String.append(sep, String.join.go(t, h2, sep)))

def String.join(xs: List<&2, String>, +sep: String) -> String:
  match xs:
    case Nil{}:
      SNil{}
    case h <> t:
      String.join.go(t, h, sep)

def String.split.push(c: Char, ps: List<&2, String>) -> List<&2, String>:
  match ps:
    case Nil{}:
      [SCon{c, SNil{}}]
    case h <> t:
      SCon{c, h} <> t

def String.split.fin(c: Char, r: List<&2, String>, cut: Bool) ->
  List<&2, String>:
  match cut:
    case False{}:
      String.split.push(c, r)
    case True{}:
      SNil{} <> r

def String.split(s: String, +sep: Char) -> List<&2, String>:
  match s:
    case SNil{}:
      [SNil{}]
    case SCon{+h, t}:
      String.split.fin(h, String.split(t, sep), Char.is_eq(h, sep))

def String.lines(s: String) -> List<&2, String>:
  String.split(s, '\n')

def String.repeat(+s: String, n: Nat) -> String:
  match n:
    case 0n:
      SNil{}
    case 1n+p:
      String.append(s, String.repeat(s, p))

def String.to_upper(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{h, t}:
      SCon{Char.to_upper(h), String.to_upper(t)}

def String.to_lower(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{h, t}:
      SCon{Char.to_lower(h), String.to_lower(t)}

law String.trim_start:
  for s: String
  String

def String.trim_start.if(t: String, h: Char, space: Bool) -> String:
  match space:
    case False{}:
      SCon{h, t}
    case True{}:
      String.trim_start(t)

def String.trim_start(s):
  match s:
    case SNil{}:
      SNil{}
    case SCon{+h, t}:
      String.trim_start.if(t, h, Char.is_space(h))

def String.trim_end(s: String) -> String:
  String.reverse(String.trim_start(String.reverse(s)))

def String.trim(s: String) -> String:
  String.trim_end(String.trim_start(s))

# Text
# ----

def Nat.show.put(qr: Nat & Nat) -> Char & Nat:
  (q, r) = qr
  (Chr{U32.from_nat(Nat.add(48n, r))}, q)

law Nat.show.go:
  for f   : Nat
  for n   : Nat
  for acc : String
  String

def Nat.show.fin(g: Nat, acc: String, dq: Char & Nat) -> String:
  (d, q) = dq
  match q:
    case 0n:
      SCon{d, acc}
    case 1n+p:
      Nat.show.go(g, 1n+p, SCon{d, acc})

def Nat.show.go(f, n, acc):
  match f:
    case 0n:
      acc
    case 1n+g:
      Nat.show.fin(g, acc, Nat.show.put(Nat.divmod(n, 10n)))

def Nat.show(n: Nat) -> String:
  +m = n
  Nat.show.fin(m, SNil{}, Nat.show.put(Nat.divmod(m, 10n)))

law Nat.read.go:
  for s   : String
  for +acc : Nat
  Maybe<&2, Nat>

def Nat.read.if(t: String, acc: Nat, d: U32, ok: Bool) -> Maybe<&2, Nat>:
  match ok:
    case True{}:
      Nat.read.go(t, Nat.add(Nat.mul(acc, 10n), U32.to_nat(d)))
    case False{}:
      None{}

def Nat.read.go(s, acc):
  match s:
    case SNil{}:
      Some{acc}
    case SCon{Chr{x}, t}:
      +d = U32.sub(x, 48)
      Nat.read.if(t, acc, d, U32.is_lt(d, 10))

# 2^48-1 is the text 281474976710655. Past leading zeros, fewer than
# fifteen characters fit, more do not, and fifteen compare as text;
# Nat.read.go still refuses a non-digit. The gate is a def, not a
# Bool.pick: an argument is built before the call, and reading a string
# that does not fit would build a Nat past the bound. A law that reads
# "7" never builds the unary nat (each digit once divided it).
def Nat.read.trim(s: String) -> String:
  match s:
    case SCon{'0', t}:
      Nat.read.trim(t)
    case t:
      t

def Nat.read.fits(+s: String) -> Bool:
  +n = String.length(s)
  Bool.or(Nat.is_lt(n, 15n),
    Bool.and(Nat.is_eq(n, 15n), String.is_le(s, "281474976710655")))

def Nat.read.gate(+s: String, ok: Bool) -> Maybe<&2, Nat>:
  match ok:
    case True{}:
      Nat.read.go(s, 0n)
    case False{}:
      None{}

def Nat.read(s: String) -> Maybe<&2, Nat>:
  match s:
    case SNil{}:
      None{}
    case SCon{h, t}:
      +u = Nat.read.trim(SCon{h, t})
      Nat.read.gate(u, Nat.read.fits(u))

law U32.show.go:
  for f   : Nat
  for +n  : U32
  for acc : String
  String

def U32.show.fin(g: Nat, acc: String, +n: U32, z: Bool) -> String:
  match z:
    case True{}:
      acc
    case False{}:
      U32.show.go(g, U32.div(n, 10),
        SCon{Chr{U32.add(48, U32.mod(n, 10))}, acc})

def U32.show.go(f, n, acc):
  match f:
    case 0n:
      acc
    case 1n+g:
      U32.show.fin(g, acc, n, U32.is_zero(n))

def U32.show.if(a: U32, z: Bool) -> String:
  match z:
    case True{}:
      SCon{Chr{48}, SNil{}}
    case False{}:
      U32.show.go(10n, a, SNil{})

def U32.show(a: U32) -> String:
  +b = a
  U32.show.if(b, U32.is_zero(b))

law U32.read.go:
  for s   : String
  for +acc : U32
  Maybe<&2, U32>

def U32.read.if(t: String, n: U32, ok: Bool) -> Maybe<&2, U32>:
  match ok:
    case True{}:
      U32.read.go(t, n)
    case False{}:
      None{}

def U32.read.go(s, acc):
  match s:
    case SNil{}:
      Some{acc}
    case SCon{Chr{x}, t}:
      +n = U32.add(U32.mul(acc, 10), U32.sub(x, 48))
      U32.read.if(t, n, U32.is_eq(U32.div(n, 10), acc))

def U32.read(s: String) -> Maybe<&2, U32>:
  match s:
    case SNil{}:
      None{}
    case SCon{h, t}:
      U32.read.go(SCon{h, t}, 0)

def Bool.show(b: Bool) -> String:
  match b:
    case False{}:
      "False"
    case True{}:
      "True"

def Char.show(c: Char) -> String:
  SCon{c, SNil{}}

def Maybe.show(~a: Quant, ~A: Kind(a), ~f: A -> String, m: Maybe<a, A>) ->
  String:
  match m:
    case None{}:
      "None"
    case Some{x}:
      "Some(" ++ f(x) ++ ")"

def List.show.go(~a: Quant, ~A: Kind(a), ~f: A -> String, xs: List<a, A>) ->
  String:
  match xs:
    case Nil{}:
      "]"
    case h <> t:
      ", " ++ f(h) ++ List.show.go(~a, ~A, ~f, t)

def List.show(~a: Quant, ~A: Kind(a), ~f: A -> String, xs: List<a, A>) ->
  String:
  match xs:
    case Nil{}:
      "[]"
    case h <> t:
      "[" ++ f(h) ++ List.show.go(~a, ~A, ~f, t)

# Array
# -----

def Array.size.node(-T: Type, ys: Array<T>, r: Array<T> & U32) ->
  Array<T> & U32:
  (xs2, n) = r
  (ANode{xs2, ys}, U32.shl(n))

def Array.size(-T: Type, a: Array<T>) -> Array<T> & U32:
  match a:
    case ALeaf{x}:
      (ALeaf{x}, 1)
    case ANode{xs, ys}:
      Array.size.node(T, ys, Array.size(T, xs))

def Array.swap.lo(-T: Type, ys: Array<T>, r: Array<T> & T) -> Array<T> & T:
  (nxs, old) = r
  (ANode{nxs, ys}, old)

def Array.swap.hi(-T: Type, xs: Array<T>, r: Array<T> & T) -> Array<T> & T:
  (nys, old) = r
  (ANode{xs, nys}, old)

# the recursion descends into a subtree, and z says which: the caller
# computes it from the index and the subtree's half size
def Array.swap.go(-T: Type, a: Array<T>, n: U32, +i: U32, v: T, z: Bool) -> Array<T> & T:
  match a z:
    case ALeaf{x} _:
      (ALeaf{v}, x)
    case ANode{xs, ys} True{}:
      +h = U32.shr(n)
      Array.swap.lo(T, ys, Array.swap.go(T, xs, h, i, v, U32.is_lt(i, U32.shr(h))))
    case ANode{xs, ys} False{}:
      +h = U32.shr(n)
      +j = U32.sub(i, h)
      Array.swap.hi(T, xs, Array.swap.go(T, ys, h, j, v, U32.is_lt(j, U32.shr(h))))

def Array.swap.at(-T: Type, i: U32, v: T, an: Array<T> & U32) -> Array<T> & T:
  (a, +n) = an
  +j = U32.and(i, U32.sub(n, 1))
  Array.swap.go(T, a, n, j, v, U32.is_lt(j, U32.shr(n)))

def Array.swap(-T: Type, a: Array<T>, +i: U32, v: T) -> Array<T> & T:
  Array.swap.at(T, i, v, Array.size(T, a))

def Array.clone.node(
  -T: Data, cx: Array<T> & Array<T>, cy: Array<T> & Array<T>
) -> Array<T> & Array<T>:
  (xa, xb) = cx
  (ya, yb) = cy
  (ANode{xa, ya}, ANode{xb, yb})

def Array.clone(-T: Data, a: Array<T>) -> Array<T> & Array<T>:
  match a:
    case ALeaf{+x}:
      (ALeaf{x}, ALeaf{x})
    case ANode{xs, ys}:
      Array.clone.node(T, Array.clone(T, xs), Array.clone(T, ys))

# A fork is two handles to one array in O(1). Both read and write the
# same cells, so racing writes go through the atomics; a match on a
# handle copies its part, as a clone does. An atomic takes an Array<U32>
# (fadd an Array<F32>) and returns the array with the old value.

@unsafe
def Array.fork(-T: Type, +a: Array<T>) -> Array<T> & Array<T>:
  (a, a)

@unsafe
def Array.join(-T: Type, a: Array<T>, b: Array<T>) -> Array<T>:
  a

law Array.atomic.add:
  for  a: Array<U32>
  for +i: U32
  for +v: U32
  Array<U32> & U32

law Array.atomic.min:
  for  a: Array<U32>
  for +i: U32
  for +v: U32
  Array<U32> & U32

law Array.atomic.max:
  for  a: Array<U32>
  for +i: U32
  for +v: U32
  Array<U32> & U32

law Array.atomic.and:
  for  a: Array<U32>
  for +i: U32
  for +v: U32
  Array<U32> & U32

law Array.atomic.or:
  for  a: Array<U32>
  for +i: U32
  for +v: U32
  Array<U32> & U32

law Array.atomic.xor:
  for  a: Array<U32>
  for +i: U32
  for +v: U32
  Array<U32> & U32

law Array.atomic.exch:
  for  a: Array<U32>
  for +i: U32
  for +v: U32
  Array<U32> & U32

law Array.atomic.cas:
  for  a: Array<U32>
  for +i: U32
  for +x: U32
  for +v: U32
  Array<U32> & U32

law Array.atomic.fadd:
  for  a: Array<F32>
  for +i: U32
  for +v: F32
  Array<F32> & F32

def Array.new(-T: Data, +d: Nat, +v: T) -> Array<T>:
  match d:
    case 0n:
      ALeaf{v}
    case 1n+p:
      ANode{[v : T^p], [v : T^p]}

def Array.set.fin(-T: Type, r: Array<T> & T) -> Array<T>:
  (na, old) = r
  na

def Array.set(-T: Type, a: Array<T>, i: U32, v: T) -> Array<T>:
  Array.set.fin(T, Array.swap(T, a, i, v))

def Array.get.go(-T: Data, a: Array<T>, n: U32, +i: U32, z: Bool) -> Array<T> & T:
  match a z:
    case ALeaf{+x} _:
      (ALeaf{x}, x)
    case ANode{xs, ys} True{}:
      +h = U32.shr(n)
      Array.swap.lo(T, ys, Array.get.go(T, xs, h, i, U32.is_lt(i, U32.shr(h))))
    case ANode{xs, ys} False{}:
      +h = U32.shr(n)
      +j = U32.sub(i, h)
      Array.swap.hi(T, xs, Array.get.go(T, ys, h, j, U32.is_lt(j, U32.shr(h))))

def Array.get.at(-T: Data, i: U32, an: Array<T> & U32) -> Array<T> & T:
  (a, +n) = an
  +j = U32.and(i, U32.sub(n, 1))
  Array.get.go(T, a, n, j, U32.is_lt(j, U32.shr(n)))

def Array.get(-T: Data, a: Array<T>, +i: U32) -> Array<T> & T:
  Array.get.at(T, i, Array.size(T, a))

# Array.q4mv(w, x, y, r, n, cols, rows) is the MLX affine 4-bit product
# (bits 4, group 64) of rows r .. r+n of w, a matrix of `rows` rows of `cols`
# weights (cols a multiple of 128): the codes (rows * cols/8 words, weight
# 8k+m of a row in bits 4m..4m+3 of its word k), then the bfloat16 scales
# (rows * cols/128 words, group g in the low half when g is even), then the
# biases laid out as the scales. x holds the cols activations, then at
# cols + g the sum of group g. Each row is summed in a fixed tree that
# SIMD lanes can run: lane j of a group sums nibble j of its 8 words times
# x in word order; the lanes meet as ((0+4)+(2+6))+((1+5)+(3+7)) into qx;
# the group's term scale * qx + bias * x-sum goes onto partial g % 32 (from
# 0.0, groups in order); the 32 partials fold as p[l] += p[l + o] for
# o = 16, 8, 4, 2, 1. p[0] is rounded to bfloat16 (nearest even, a NaN to
# sign | 0x7fff) and written to y at the row's index. The compiler lowers
# it to NEON and Metal SIMD-group loops; the defs below are its meaning.

def Array.q4mv.f32(+u: U32) -> F32:
  match u:
    case U32{+w}:
      F32{w}

def Array.q4mv.bits(+x: F32) -> U32:
  match x:
    case F32{+w}:
      U32{w}

def Array.q4mv.half(even: Bool, +u: U32) -> F32:
  match even:
    case True{}:
      Array.q4mv.f32(((u .&. 65535 : U32) << 16n : U32))
    case False{}:
      Array.q4mv.f32((u .&. 4294901760 : U32))

def Array.q4mv.narrow(nan: Bool, +u: U32) -> U32:
  match nan:
    case True{}:
      (((u >> 16n) .&. 32768) .|. 32767 : U32)
    case False{}:
      ((u + 32767 + ((u >> 16n) .&. 1)) >> 16n : U32)

def Array.q4mv.round(+x: F32) -> F32:
  +u = Array.q4mv.bits(x)
  Array.q4mv.f32((Array.q4mv.narrow(U32.is_gt((u .&. 2147483647 : U32), 2139095040), u) << 16n : U32))

def Array.q4mv.mac(g: Array<F32> & F32, w: Array<U32>, +c: U32, +sh: U32, +s: F32) -> (Array<U32> & Array<F32>) & F32:
  (x, +a) = g
  ((w, x), (s + U32.to_f32(((c >> U32.to_nat(sh)) .&. 15 : U32)) * a : F32))

def Array.q4mv.word(g: Array<U32> & U32, x: Array<F32>, +j: U32, +sh: U32, +s: F32) -> (Array<U32> & Array<F32>) & F32:
  (w, +c) = g
  Array.q4mv.mac(Array.get(F32, x, j), w, c, sh, s)

# Lane sum: nibble sh/4 of words i .. i+n against x[j], x[j + 8], ..., in order.
def Array.q4mv.lane(n: Nat, q: (Array<U32> & Array<F32>) & F32, +i: U32, +j: U32, +sh: U32) -> (Array<U32> & Array<F32>) & F32:
  match n:
    case 0n:
      q
    case 1n+p:
      ((w, x), +s) = q
      Array.q4mv.lane(p, Array.q4mv.word(Array.get(U32, w, i), x, j, sh, s), (i + 1 : U32), (j + 8 : U32), sh)

def Array.q4mv.add(q: (Array<U32> & Array<F32>) & F32, +a: F32) -> (Array<U32> & Array<F32>) & F32:
  (wx, +b) = q
  (wx, (a + b : F32))

# Lanes m and m + 4 of the group at code word i, activation j, added.
def Array.q4mv.l2(q: (Array<U32> & Array<F32>) & F32, +i: U32, +j: U32, +m: U32) -> (Array<U32> & Array<F32>) & F32:
  (wx, +a) = q
  Array.q4mv.add(Array.q4mv.lane(8n, (wx, 0.0), i, (j + m + 4 : U32), (m * 4 + 16 : U32)), a)

def Array.q4mv.p2(wx: Array<U32> & Array<F32>, +i: U32, +j: U32, +m: U32) -> (Array<U32> & Array<F32>) & F32:
  Array.q4mv.l2(Array.q4mv.lane(8n, (wx, 0.0), i, (j + m : U32), (m * 4 : U32)), i, j, m)

def Array.q4mv.p4b(q: (Array<U32> & Array<F32>) & F32, +i: U32, +j: U32, +m: U32) -> (Array<U32> & Array<F32>) & F32:
  (wx, +a) = q
  Array.q4mv.add(Array.q4mv.p2(wx, i, j, (m + 2 : U32)), a)

def Array.q4mv.p4(wx: Array<U32> & Array<F32>, +i: U32, +j: U32, +m: U32) -> (Array<U32> & Array<F32>) & F32:
  Array.q4mv.p4b(Array.q4mv.p2(wx, i, j, m), i, j, m)

def Array.q4mv.qxb(q: (Array<U32> & Array<F32>) & F32, +i: U32, +j: U32) -> (Array<U32> & Array<F32>) & F32:
  (wx, +a) = q
  Array.q4mv.add(Array.q4mv.p4(wx, i, j, 1), a)

def Array.q4mv.gb(g: Array<U32> & U32, x: Array<F32>, +sw: U32, +qx: F32, +xs: F32, +even: Bool) -> (Array<U32> & Array<F32>) & F32:
  (w, +bw) = g
  +sc = Array.q4mv.half(even, sw)
  ((w, x), (sc * qx + Array.q4mv.half(even, bw) * xs : F32))

def Array.q4mv.gs(g: Array<U32> & U32, h: Array<F32> & F32, +qx: F32, +even: Bool, +bat: U32) -> (Array<U32> & Array<F32>) & F32:
  (w, +sw) = g
  (x, +xs) = h
  Array.q4mv.gb(Array.get(U32, w, bat), x, sw, qx, xs, even)

def Array.q4mv.gfin(q: (Array<U32> & Array<F32>) & F32, +at: U32, +d: U32, +xg: U32, +even: Bool) -> (Array<U32> & Array<F32>) & F32:
  ((w, x), +qx) = q
  Array.q4mv.gs(Array.get(U32, w, at), Array.get(F32, x, xg), qx, even, (at + d : U32))

# Group g's term: its lanes meet as ((0+4)+(2+6))+((1+5)+(3+7)) into qx, then
# scale * qx + bias * the group's x-sum.
def Array.q4mv.term(wx: Array<U32> & Array<F32>, +i: U32, +g: U32, +sa: U32, +d: U32, +cols: U32) -> (Array<U32> & Array<F32>) & F32:
  +k = (i + g * 8 : U32)
  +j = (g * 64 : U32)
  Array.q4mv.gfin(Array.q4mv.qxb(Array.q4mv.p4(wx, k, j, 0), k, j), (sa + (g >> 1n) : U32), d, (cols + g : U32),
    U32.is_zero((g .&. 1 : U32)))

# Partial l: 0.0 plus the terms of groups l, l + 32, ... in order.
def Array.q4mv.part(n: Nat, q: (Array<U32> & Array<F32>) & F32, +i: U32, +g: U32, +sa: U32, +d: U32, +cols: U32) -> (Array<U32> & Array<F32>) & F32:
  match n:
    case 0n:
      q
    case 1n+p:
      (wx, +s) = q
      Array.q4mv.part(p, Array.q4mv.add(Array.q4mv.term(wx, i, g, sa, d, cols), s), i, (g + 32 : U32), sa, d, cols)

def Array.q4mv.foldb(q: (Array<U32> & Array<F32>) & F32, +n: Nat, +i: U32, +l: U32, +s: U32, +sa: U32, +d: U32, +cols: U32) -> (Array<U32> & Array<F32>) & F32:
  (wx, +a) = q
  Array.q4mv.add(Array.q4mv.fold(n, wx, i, (l + s : U32), (s * 2 : U32), sa, d, cols), a)

# The 32 partials folded as p[l] += p[l + o] for o = 16, 8, 4, 2, 1: the value
# at lane l, stride s, is the partial l when s = 32, else its two halves' sum.
def Array.q4mv.fold(+n: Nat, wx: Array<U32> & Array<F32>, +i: U32, +l: U32, +s: U32, +sa: U32, +d: U32, +cols: U32) -> (Array<U32> & Array<F32>) & F32:
  match n:
    case 0n:
      Array.q4mv.part(U32.to_nat((((cols >> 6n) + 31 - l) >> 5n : U32)), (wx, 0.0), i, l, sa, d, cols)
    case 1n+p:
      Array.q4mv.foldb(Array.q4mv.fold(p, wx, i, l, (s * 2 : U32), sa, d, cols), p, i, l, s, sa, d, cols)

def Array.q4mv.put(q: (Array<U32> & Array<F32>) & F32, y: Array<F32>, +i: U32) -> (Array<U32> & Array<F32>) & Array<F32>:
  (wx, +acc) = q
  (wx, Array.set(F32, y, i, Array.q4mv.round(acc)))

def Array.q4mv.rows(n: Nat, q: (Array<U32> & Array<F32>) & Array<F32>, +i: U32, +cols: U32, +cw: U32, +s0: U32, +sw: U32, +d: U32) -> (Array<U32> & Array<F32>) & Array<F32>:
  match n:
    case 0n:
      q
    case 1n+p:
      (wx, y) = q
      Array.q4mv.rows(p, Array.q4mv.put(Array.q4mv.fold(5n, wx, (i * cw : U32), 0, 1, (s0 + i * sw : U32), d, cols), y, i),
        (i + 1 : U32), cols, cw, s0, sw, d)

def Array.q4mv(w: Array<U32>, x: Array<F32>, y: Array<F32>, +r: U32, +n: U32, +cols: U32, +rows: U32) -> (Array<U32> & Array<F32>) & Array<F32>:
  +cw = (cols >> 3n : U32)
  +sw = (cols >> 7n : U32)
  Array.q4mv.rows(U32.to_nat(n), ((w, x), y), r, cols, cw, (rows * cw : U32), sw, (rows * sw : U32))

# Array.q4go is Array.q4mv, except that a native build with a Metal heap may
# queue the product on the GPU: y then holds it only after the next
# Array.q4wait. Queued products run concurrently, so none may read another's
# y. The GPU reads w and x and writes y until the wait, and a value is freed
# at its last use: wait on x, and use w and y after the wait.
def Array.q4go(w: Array<U32>, x: Array<F32>, y: Array<F32>, +r: U32, +n: U32, +cols: U32, +rows: U32) -> (Array<U32> & Array<F32>) & Array<F32>:
  Array.q4mv(w, x, y, r, n, cols, rows)

# Array.q4wait(x) is x, once every queued Array.q4go has run.
def Array.q4wait(x: Array<F32>) -> Array<F32>:
  x

# Array.rmsq(x, y, w, o, n, eps, add) is the residual add and RMS norm that
# feeds Array.q4mv, for n a multiple of 64. When add is not 0, x[i] becomes
# x[i] + y[i] rounded to bfloat16 (as Array.q4mv rounds). s sums x[i] * x[i]
# from 0.0 in index order, and inv is 1.0 / sqrt(s / n + eps). o[i] becomes
# w[i] * (x[i] * inv) rounded to bfloat16 (w holds F32 bits), and o[n + g]
# the sum of group g as Array.q4mv reads it: each 32-value half summed from
# 0.0 in order, then the halves added. A native build with a Metal heap
# queues it as Array.q4go, after every product queued before it and before
# every one queued after; use x, y, w and o after the next Array.q4wait.
# The Metal kernel sums in a tree, so its last bits may differ.
def Array.rmsq.two(a: Array<F32>, r: Array<F32> & F32, +u: F32) -> (Array<F32> & Array<F32>) & (F32 & F32):
  (b, +v) = r
  ((a, b), (u, v))

def Array.rmsq.get(r: Array<F32> & F32, b: Array<F32>, +i: U32) -> (Array<F32> & Array<F32>) & (F32 & F32):
  (a, +u) = r
  Array.rmsq.two(a, Array.get(F32, b, i), u)

def Array.rmsq.add1(r: (Array<F32> & Array<F32>) & (F32 & F32), +i: U32) -> Array<F32> & Array<F32>:
  ((a, b), (u, v)) = r
  (Array.set(F32, a, i, Array.q4mv.round((u + v : F32))), b)

def Array.rmsq.adds(k: Nat, ab: Array<F32> & Array<F32>, +i: U32) -> Array<F32> & Array<F32>:
  match k:
    case 0n:
      ab
    case 1n+p:
      (a, b) = ab
      Array.rmsq.adds(p, Array.rmsq.add1(Array.rmsq.get(Array.get(F32, a, i), b, i), i), (i + 1 : U32))

def Array.rmsq.sq1(r: Array<F32> & F32, +s: F32) -> Array<F32> & F32:
  (a, +u) = r
  (a, (s + u * u : F32))

def Array.rmsq.sqs(k: Nat, as: Array<F32> & F32, +i: U32) -> Array<F32> & F32:
  match k:
    case 0n:
      as
    case 1n+p:
      (a, +s) = as
      Array.rmsq.sqs(p, Array.rmsq.sq1(Array.get(F32, a, i), s), (i + 1 : U32))

def Array.rmsq.wtwo(a: Array<F32>, r: Array<U32> & U32, +u: F32) -> (Array<F32> & Array<U32>) & (F32 & F32):
  (b, +v) = r
  ((a, b), (u, Array.q4mv.f32(v)))

def Array.rmsq.getw(r: Array<F32> & F32, b: Array<U32>, +i: U32) -> (Array<F32> & Array<U32>) & (F32 & F32):
  (a, +u) = r
  Array.rmsq.wtwo(a, Array.get(U32, b, i), u)

def Array.rmsq.mul1(r: (Array<F32> & Array<U32>) & (F32 & F32), o: Array<F32>, +i: U32, +k: F32) -> (Array<F32> & Array<U32>) & Array<F32>:
  (xw, (u, v)) = r
  (xw, Array.set(F32, o, i, Array.q4mv.round((v * (u * k : F32) : F32))))

def Array.rmsq.muls(n: Nat, q: (Array<F32> & Array<U32>) & Array<F32>, +i: U32, +k: F32) -> (Array<F32> & Array<U32>) & Array<F32>:
  match n:
    case 0n:
      q
    case 1n+p:
      ((x, w), o) = q
      Array.rmsq.muls(p, Array.rmsq.mul1(Array.rmsq.getw(Array.get(F32, x, i), w, i), o, i, k), (i + 1 : U32), k)

def Array.rmsq.ad1(r: Array<F32> & F32, +s: F32) -> Array<F32> & F32:
  (a, +u) = r
  (a, (s + u : F32))

def Array.rmsq.half(k: Nat, as: Array<F32> & F32, +i: U32) -> Array<F32> & F32:
  match k:
    case 0n:
      as
    case 1n+p:
      (a, +s) = as
      Array.rmsq.half(p, Array.rmsq.ad1(Array.get(F32, a, i), s), (i + 1 : U32))

def Array.rmsq.gset(r: Array<F32> & F32, +sa: F32, +j: U32) -> Array<F32>:
  (a, +sb) = r
  Array.set(F32, a, j, (sa + sb : F32))

def Array.rmsq.g1(r: Array<F32> & F32, +i: U32, +j: U32) -> Array<F32>:
  (a, +sa) = r
  Array.rmsq.gset(Array.rmsq.half(32n, (a, 0.0), (i + 32 : U32)), sa, j)

def Array.rmsq.gs(k: Nat, o: Array<F32>, +g: U32, +n: U32) -> Array<F32>:
  match k:
    case 0n:
      o
    case 1n+p:
      Array.rmsq.gs(p, Array.rmsq.g1(Array.rmsq.half(32n, (o, 0.0), (g * 64 : U32)), (g * 64 : U32), (n + g : U32)),
        (g + 1 : U32), n)

def Array.rmsq.fin(q: (Array<F32> & Array<U32>) & Array<F32>, y: Array<F32>, +n: U32) -> ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  ((x, w), o) = q
  (((x, y), w), Array.rmsq.gs(U32.to_nat((n >> 6n : U32)), o, 0, n))

def Array.rmsq.norm(xs: Array<F32> & F32, w: Array<U32>, o: Array<F32>, y: Array<F32>, +n: U32, +eps: F32) -> ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  (x, +s) = xs
  +k = (1.0 / F32.sqrt((s / U32.to_f32(n) + eps : F32)) : F32)
  Array.rmsq.fin(Array.rmsq.muls(U32.to_nat(n), ((x, w), o), 0, k), y, n)

def Array.rmsq.go(xy: Array<F32> & Array<F32>, w: Array<U32>, o: Array<F32>, +n: U32, +eps: F32) -> ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  (x, y) = xy
  Array.rmsq.norm(Array.rmsq.sqs(U32.to_nat(n), (x, 0.0), 0), w, o, y, n, eps)

def Array.rmsq.sel(z: Bool, x: Array<F32>, y: Array<F32>, +n: U32) -> Array<F32> & Array<F32>:
  match z:
    case True{}:
      (x, y)
    case False{}:
      Array.rmsq.adds(U32.to_nat(n), (x, y), 0)

def Array.rmsq(x: Array<F32>, y: Array<F32>, w: Array<U32>, o: Array<F32>, +n: U32, +eps: F32, +add: U32) -> ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  Array.rmsq.go(Array.rmsq.sel(U32.is_zero(add), x, y, n), w, o, n, eps)

# Array.swq(a, o, n) is the SwiGLU that feeds Array.q4mv, for n a multiple
# of 64: o[i] becomes silu(a[i]) * a[n + i] rounded to bfloat16, with
# silu(x) = x / (1.0 + exp(-x)), and o[n + g] the sum of group g as
# Array.rmsq writes it. Queued like Array.rmsq; use a and o after the next
# Array.q4wait. Metal's exp and its tree sums may differ in the last bits.
def Array.swq.put(r: Array<F32> & F32, o: Array<F32>, +g: F32, +i: U32) -> Array<F32> & Array<F32>:
  (a, +u) = r
  (a, Array.set(F32, o, i, Array.q4mv.round(((g / (1.0 + F32.exp(F32.neg(g))) : F32) * u : F32))))

def Array.swq.at(r: Array<F32> & F32, o: Array<F32>, +i: U32, +n: U32) -> Array<F32> & Array<F32>:
  (a, +g) = r
  Array.swq.put(Array.get(F32, a, (n + i : U32)), o, g, i)

def Array.swq.go(k: Nat, r: Array<F32> & Array<F32>, +i: U32, +n: U32) -> Array<F32> & Array<F32>:
  match k:
    case 0n:
      r
    case 1n+p:
      (a, o) = r
      Array.swq.go(p, Array.swq.at(Array.get(F32, a, i), o, i, n), (i + 1 : U32), n)

def Array.swq.fin(r: Array<F32> & Array<F32>, +n: U32) -> Array<F32> & Array<F32>:
  (a, o) = r
  (a, Array.rmsq.gs(U32.to_nat((n >> 6n : U32)), o, 0, n))

def Array.swq(a: Array<F32>, o: Array<F32>, +n: U32) -> Array<F32> & Array<F32>:
  Array.swq.fin(Array.swq.go(U32.to_nat(n), (a, o), 0, n), n)

# Array.gdn(y, w, s, cw, ab, sn, o, c, dk, dv, nvh, din, ko, eps) is one
# token of a gated DeltaNet mixer (Qwen3.5's linear attention), feeding
# Array.q4mv. y holds the projections: qkv (c values: q at 0, k at ko, v at
# 2 * ko), then z (din), beta (nvh) and alpha (nvh). w is the conv window
# (rows of c values, oldest first), s the state (value head h, row j at
# (h * dv + j) * dk), cw the conv taps (4 a channel, oldest first), ab
# a (nvh) then dt (nvh), and sn the gated norm's weights (dv); cw, ab and
# sn hold F32 bits. Value head h reads key head h. Every value below is
# rounded to bfloat16 where it says round, and sums run in index order:
#  1. channel i: v = round(w0 * a + .. + w3 * y[i]) over the window and
#     y[i], conv = round(v * round(sigmoid(v))); the window moves on a row.
#  2. each q head of dk: q = round(round(q * inv) * round(1 / dk)) with
#     inv = 1 / sqrt(sum q^2 / dk + eps / dk); each k head likewise with
#     round(1 / sqrt(dk)).
#  3. head h: g = exp(round(max(x, 0) + log(1 + exp(-|x|))) * a[h]) with
#     x = round(alpha[h] + dt[h]), beta = round(sigmoid(beta[h])); row j:
#     d = sum (s * g) * k, then s = s * g + ((v_j - d) * beta) * k in place
#     and o_j = sum s * q.
#  4. head h: o = round(o), inv = 1 / sqrt(sum o^2 / dk + eps), then
#     o = round(round(sn * (o * inv)) * silu(z)).
#  5. o[din + g] holds group g's sum as Array.rmsq writes it.
# Queued like Array.rmsq; use every array after the next Array.q4wait.
# Metal's exp and its tree sums may differ in the last bits.
def Array.gdn.sig(+x: F32) -> F32:
  (1.0 / (1.0 + F32.exp(F32.neg(x))) : F32)

def Array.gdn.uf(r: Array<U32> & U32) -> Array<U32> & F32:
  (a, +u) = r
  (a, Array.q4mv.f32(u))

def Array.gdn.ui(a: Array<U32>, +i: U32) -> Array<U32> & F32:
  Array.gdn.uf(Array.get(U32, a, i))

# Conv of channel i: the window's three values and y[i] against the taps.
def Array.gdn.cv4(r: Array<U32> & F32, y: Array<F32>, w: Array<F32>, co: Array<F32>, +d: F32, +acc: F32, +i: U32) ->
  ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  (cw, +t) = r
  +v = Array.q4mv.round((acc + d * t : F32))
  (((y, w), cw), Array.set(F32, co, i, Array.q4mv.round((v * Array.q4mv.round(Array.gdn.sig(v)) : F32))))

def Array.gdn.cv3(r: Array<F32> & F32, w: Array<F32>, cw: Array<U32>, co: Array<F32>, +acc: F32, +i: U32, +c: U32) ->
  ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  (y, +d) = r
  Array.gdn.cv4(Array.gdn.ui(cw, (i * 4 + 3 : U32)), y, Array.set(F32, w, (i + c + c : U32), d), co, d, acc, i)

def Array.gdn.cv2(r: Array<U32> & F32, y: Array<F32>, w: Array<F32>, co: Array<F32>, +x: F32, +acc: F32, +i: U32, +c: U32) ->
  ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  (cw, +t) = r
  Array.gdn.cv3(Array.get(F32, y, i), Array.set(F32, w, (i + c : U32), x), cw, co, (acc + x * t : F32), i, c)

def Array.gdn.cvc(r: Array<F32> & F32, y: Array<F32>, cw: Array<U32>, co: Array<F32>, +acc: F32, +i: U32, +c: U32) ->
  ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  (w, +x) = r
  Array.gdn.cv2(Array.gdn.ui(cw, (i * 4 + 2 : U32)), y, w, co, x, acc, i, c)

def Array.gdn.cv1(r: Array<U32> & F32, y: Array<F32>, w: Array<F32>, co: Array<F32>, +x: F32, +acc: F32, +i: U32, +c: U32) ->
  ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  (cw, +t) = r
  Array.gdn.cvc(Array.get(F32, Array.set(F32, w, i, x), (i + c + c : U32)), y, cw, co, (acc + x * t : F32), i, c)

def Array.gdn.cvb(r: Array<F32> & F32, y: Array<F32>, cw: Array<U32>, co: Array<F32>, +acc: F32, +i: U32, +c: U32) ->
  ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  (w, +x) = r
  Array.gdn.cv1(Array.gdn.ui(cw, (i * 4 + 1 : U32)), y, w, co, x, acc, i, c)

def Array.gdn.cv0(r: Array<U32> & F32, y: Array<F32>, w: Array<F32>, co: Array<F32>, +a: F32, +i: U32, +c: U32) ->
  ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  (cw, +t) = r
  Array.gdn.cvb(Array.get(F32, w, (i + c : U32)), y, cw, co, (a * t : F32), i, c)

def Array.gdn.cva(r: Array<F32> & F32, y: Array<F32>, cw: Array<U32>, co: Array<F32>, +i: U32, +c: U32) ->
  ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  (w, +a) = r
  Array.gdn.cv0(Array.gdn.ui(cw, (i * 4 : U32)), y, w, co, a, i, c)

def Array.gdn.conv(k: Nat, q: ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>, +i: U32, +c: U32) ->
  ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>:
  match k:
    case 0n:
      q
    case 1n+p:
      (((y, w), cw), co) = q
      Array.gdn.conv(p, Array.gdn.cva(Array.get(F32, w, i), y, cw, co, i, c), (i + 1 : U32), c)

# a[i ..] = round(a[i ..] * k) over n slots.
def Array.gdn.sc1(r: Array<F32> & F32, +i: U32, +k: F32) -> Array<F32>:
  (a, +x) = r
  Array.set(F32, a, i, Array.q4mv.round((x * k : F32)))

def Array.gdn.scl(n: Nat, a: Array<F32>, +i: U32, +k: F32) -> Array<F32>:
  match n:
    case 0n:
      a
    case 1n+p:
      Array.gdn.scl(p, Array.gdn.sc1(Array.get(F32, a, i), i, k), (i + 1 : U32), k)

def Array.gdn.l2f(r: Array<F32> & F32, +i: U32, +n: U32, +eps: F32, +sc: F32) -> Array<F32>:
  (a, +s) = r
  +nf = U32.to_f32(n)
  +inv = (1.0 / F32.sqrt((s / nf + eps / nf : F32)) : F32)
  Array.gdn.scl(U32.to_nat(n), Array.gdn.scl(U32.to_nat(n), a, i, inv), i, sc)

# k heads of n values from i, each scaled to unit norm and by sc, in place.
def Array.gdn.l2(k: Nat, a: Array<F32>, +i: U32, +n: U32, +eps: F32, +sc: F32) -> Array<F32>:
  match k:
    case 0n:
      a
    case 1n+p:
      Array.gdn.l2(p, Array.gdn.l2f(Array.rmsq.sqs(U32.to_nat(n), (a, 0.0), i), i, n, eps, sc), (i + n : U32), n, eps, sc)

# The delta rule's state rows: s[ri ..] against k = co[ki ..], q = co[qi ..].
def Array.gdn.d1(g: Array<F32> & F32, s: Array<F32>, +a: F32, +eg: F32, +acc: F32) -> (Array<F32> & Array<F32>) & F32:
  (co, +k) = g
  ((s, co), (acc + (a * eg : F32) * k : F32))

def Array.gdn.d0(g: Array<F32> & F32, co: Array<F32>, +ki: U32, +eg: F32, +acc: F32) -> (Array<F32> & Array<F32>) & F32:
  (s, +a) = g
  Array.gdn.d1(Array.get(F32, co, ki), s, a, eg, acc)

def Array.gdn.dot(n: Nat, r: (Array<F32> & Array<F32>) & F32, +ri: U32, +ki: U32, +eg: F32) -> (Array<F32> & Array<F32>) & F32:
  match n:
    case 0n:
      r
    case 1n+p:
      ((s, co), +acc) = r
      Array.gdn.dot(p, Array.gdn.d0(Array.get(F32, s, ri), co, ki, eg, acc), (ri + 1 : U32), (ki + 1 : U32), eg)

def Array.gdn.u2(g: Array<F32> & F32, s: Array<F32>, +nv: F32, +o: F32) -> (Array<F32> & Array<F32>) & F32:
  (co, +q) = g
  ((s, co), (o + nv * q : F32))

def Array.gdn.u1(g: Array<F32> & F32, s: Array<F32>, +a: F32, +ri: U32, +qi: U32, +eg: F32, +dj: F32, +o: F32) ->
  (Array<F32> & Array<F32>) & F32:
  (co, +k) = g
  +nv = (a * eg + dj * k : F32)
  Array.gdn.u2(Array.get(F32, co, qi), Array.set(F32, s, ri, nv), nv, o)

def Array.gdn.u0(g: Array<F32> & F32, co: Array<F32>, +ri: U32, +ki: U32, +qi: U32, +eg: F32, +dj: F32, +o: F32) ->
  (Array<F32> & Array<F32>) & F32:
  (s, +a) = g
  Array.gdn.u1(Array.get(F32, co, ki), s, a, ri, qi, eg, dj, o)

def Array.gdn.upd(n: Nat, r: (Array<F32> & Array<F32>) & F32, +ri: U32, +ki: U32, +qi: U32, +eg: F32, +dj: F32) ->
  (Array<F32> & Array<F32>) & F32:
  match n:
    case 0n:
      r
    case 1n+p:
      ((s, co), +o) = r
      Array.gdn.upd(p, Array.gdn.u0(Array.get(F32, s, ri), co, ri, ki, qi, eg, dj, o), (ri + 1 : U32), (ki + 1 : U32),
        (qi + 1 : U32), eg, dj)

def Array.gdn.ro(r: (Array<F32> & Array<F32>) & F32, o: Array<F32>, +oi: U32) -> (Array<F32> & Array<F32>) & Array<F32>:
  ((s, co), +ov) = r
  ((s, co), Array.set(F32, o, oi, ov))

def Array.gdn.rv(r: Array<F32> & F32, s: Array<F32>, o: Array<F32>, +d: F32, +ri: U32, +ki: U32, +qi: U32, +oi: U32,
  +eg: F32, +beta: F32, +dk: U32) -> (Array<F32> & Array<F32>) & Array<F32>:
  (co, +v) = r
  Array.gdn.ro(Array.gdn.upd(U32.to_nat(dk), ((s, co), 0.0), ri, ki, qi, eg, ((v - d) * beta : F32)), o, oi)

def Array.gdn.rd(r: (Array<F32> & Array<F32>) & F32, o: Array<F32>, +vi: U32, +ri: U32, +ki: U32, +qi: U32, +oi: U32,
  +eg: F32, +beta: F32, +dk: U32) -> (Array<F32> & Array<F32>) & Array<F32>:
  ((s, co), +d) = r
  Array.gdn.rv(Array.get(F32, co, vi), s, o, d, ri, ki, qi, oi, eg, beta, dk)

# Rows j .. of value head h; each reads s, co (q at qi, k at ki, v at vi)
# and writes o[oi + j].
def Array.gdn.rows(n: Nat, q: (Array<F32> & Array<F32>) & Array<F32>, +j: U32, +ri: U32, +ki: U32, +qi: U32, +vi: U32,
  +oi: U32, +eg: F32, +beta: F32, +dk: U32) -> (Array<F32> & Array<F32>) & Array<F32>:
  match n:
    case 0n:
      q
    case 1n+p:
      (sc, o) = q
      Array.gdn.rows(p, Array.gdn.rd(Array.gdn.dot(U32.to_nat(dk), (sc, 0.0), ri, ki, eg), o, (vi + j : U32), ri, ki, qi,
        (oi + j : U32), eg, beta, dk), (j + 1 : U32), (ri + dk : U32), ki, qi, vi, oi, eg, beta, dk)

def Array.gdn.soft(+x: F32) -> F32:
  Array.q4mv.round((F32.max(x, 0.0) + F32.log((1.0 + F32.exp(F32.neg(F32.abs(x))) : F32)) : F32))

def Array.gdn.hb(r: Array<F32> & F32, s: Array<F32>, co: Array<F32>, o: Array<F32>, ab: Array<U32>, +eg: F32, +h: U32,
  +dk: U32, +dv: U32, +ko: U32) -> (((Array<F32> & Array<F32>) & Array<F32>) & Array<F32>) & Array<U32>:
  (y, +b) = r
  ((Array.gdn.rows(U32.to_nat(dv), ((s, co), o), 0, (h * dv * dk : U32), (ko + h * dk : U32), (h * dk : U32),
    (ko + ko + h * dv : U32), (h * dv : U32), eg, Array.q4mv.round(Array.gdn.sig(b)), dk), y), ab)

def Array.gdn.hp(g: Array<F32> & F32, ab: Array<U32>, s: Array<F32>, co: Array<F32>, o: Array<F32>, +a: F32, +dt: F32,
  +h: U32, +dk: U32, +dv: U32, +nvh: U32, +ko: U32, +bi: U32) -> (((Array<F32> & Array<F32>) & Array<F32>) & Array<F32>) & Array<U32>:
  (y, +al) = g
  Array.gdn.hb(Array.get(F32, y, (bi + h : U32)), s, co, o, ab,
    F32.exp((Array.gdn.soft(Array.q4mv.round((al + dt : F32))) * a : F32)), h, dk, dv, ko)

def Array.gdn.hd(r: Array<U32> & F32, y: Array<F32>, s: Array<F32>, co: Array<F32>, o: Array<F32>, +a: F32, +h: U32,
  +dk: U32, +dv: U32, +nvh: U32, +ko: U32, +bi: U32) -> (((Array<F32> & Array<F32>) & Array<F32>) & Array<F32>) & Array<U32>:
  (ab, +dt) = r
  Array.gdn.hp(Array.get(F32, y, (bi + nvh + h : U32)), ab, s, co, o, a, dt, h, dk, dv, nvh, ko, bi)

def Array.gdn.ha(r: Array<U32> & F32, y: Array<F32>, s: Array<F32>, co: Array<F32>, o: Array<F32>, +h: U32, +dk: U32,
  +dv: U32, +nvh: U32, +ko: U32, +bi: U32) -> (((Array<F32> & Array<F32>) & Array<F32>) & Array<F32>) & Array<U32>:
  (ab, +a) = r
  Array.gdn.hd(Array.gdn.ui(ab, (nvh + h : U32)), y, s, co, o, a, h, dk, dv, nvh, ko, bi)

# Value heads h ..: decay, beta and the delta rule's rows.
def Array.gdn.heads(n: Nat, q: (((Array<F32> & Array<F32>) & Array<F32>) & Array<F32>) & Array<U32>, +h: U32, +dk: U32,
  +dv: U32, +nvh: U32, +ko: U32, +bi: U32) -> (((Array<F32> & Array<F32>) & Array<F32>) & Array<F32>) & Array<U32>:
  match n:
    case 0n:
      q
    case 1n+p:
      ((((s, co), o), y), ab) = q
      Array.gdn.heads(p, Array.gdn.ha(Array.gdn.ui(ab, h), y, s, co, o, h, dk, dv, nvh, ko, bi), (h + 1 : U32), dk, dv,
        nvh, ko, bi)

# The gated norm: o[i] = round(round(sn[j] * (o[i] * inv)) * silu(y[zi])).
def Array.gdn.g2(r: Array<F32> & F32, o: Array<F32>, sn: Array<U32>, +x: F32, +w: F32, +i: U32) ->
  (Array<F32> & Array<F32>) & Array<U32>:
  (y, +z) = r
  ((Array.set(F32, o, i, Array.q4mv.round((x * (z / (1.0 + F32.exp(F32.neg(z))) : F32) : F32))), y), sn)

def Array.gdn.g1(r: Array<U32> & F32, o: Array<F32>, y: Array<F32>, +v: F32, +inv: F32, +i: U32, +zi: U32) ->
  (Array<F32> & Array<F32>) & Array<U32>:
  (sn, +w) = r
  Array.gdn.g2(Array.get(F32, y, zi), o, sn, Array.q4mv.round((w * (v * inv : F32) : F32)), w, i)

def Array.gdn.g0(r: Array<F32> & F32, y: Array<F32>, sn: Array<U32>, +inv: F32, +i: U32, +j: U32, +zi: U32) ->
  (Array<F32> & Array<F32>) & Array<U32>:
  (o, +v) = r
  Array.gdn.g1(Array.gdn.ui(sn, j), o, y, v, inv, i, zi)

def Array.gdn.gate(n: Nat, q: (Array<F32> & Array<F32>) & Array<U32>, +inv: F32, +i: U32, +j: U32, +zi: U32) ->
  (Array<F32> & Array<F32>) & Array<U32>:
  match n:
    case 0n:
      q
    case 1n+p:
      ((o, y), sn) = q
      Array.gdn.gate(p, Array.gdn.g0(Array.get(F32, o, i), y, sn, inv, i, j, zi), inv, (i + 1 : U32), (j + 1 : U32),
        (zi + 1 : U32))

def Array.gdn.gnf(r: Array<F32> & F32, y: Array<F32>, sn: Array<U32>, +i: U32, +zi: U32, +n: U32, +nf: F32, +eps: F32) ->
  (Array<F32> & Array<F32>) & Array<U32>:
  (o, +s) = r
  Array.gdn.gate(U32.to_nat(n), ((o, y), sn), (1.0 / F32.sqrt((s / nf + eps : F32)) : F32), i, 0, zi)

def Array.gdn.gn(k: Nat, q: (Array<F32> & Array<F32>) & Array<U32>, +i: U32, +zi: U32, +n: U32, +nf: F32, +eps: F32) ->
  (Array<F32> & Array<F32>) & Array<U32>:
  match k:
    case 0n:
      q
    case 1n+p:
      ((o, y), sn) = q
      Array.gdn.gn(p, Array.gdn.gnf(Array.rmsq.sqs(U32.to_nat(n), (Array.gdn.scl(U32.to_nat(n), o, i, 1.0), 0.0), i), y,
        sn, i, zi, n, nf, eps), (i + n : U32), (zi + n : U32), n, nf, eps)

def Array.gdn.fin(q: (Array<F32> & Array<F32>) & Array<U32>, co: Array<F32>, w: Array<F32>, s: Array<F32>, cw: Array<U32>,
  ab: Array<U32>, +din: U32) -> (((((Array<F32> & Array<F32>) & Array<F32>) & Array<U32>) & Array<U32>) & Array<U32>) & Array<F32>:
  ((o, y), sn) = q
  _ = co
  ((((((y, w), s), cw), ab), sn), Array.rmsq.gs(U32.to_nat((din >> 6n : U32)), o, 0, din))

def Array.gdn.mix(q: (((Array<F32> & Array<F32>) & Array<F32>) & Array<F32>) & Array<U32>, w: Array<F32>, cw: Array<U32>,
  sn: Array<U32>, +c: U32, +dk: U32, +dv: U32, +nvh: U32, +din: U32, +eps: F32) ->
  (((((Array<F32> & Array<F32>) & Array<F32>) & Array<U32>) & Array<U32>) & Array<U32>) & Array<F32>:
  ((((s, co), o), y), ab) = q
  Array.gdn.fin(Array.gdn.gn(U32.to_nat(nvh), ((o, y), sn), 0, c, dv, U32.to_f32(dk), eps), co, w, s, cw, ab, din)

def Array.gdn.norm(q: ((Array<F32> & Array<F32>) & Array<U32>) & Array<F32>, s: Array<F32>, ab: Array<U32>, sn: Array<U32>,
  o: Array<F32>, +c: U32, +dk: U32, +dv: U32, +nvh: U32, +din: U32, +ko: U32, +eps: F32) ->
  (((((Array<F32> & Array<F32>) & Array<F32>) & Array<U32>) & Array<U32>) & Array<U32>) & Array<F32>:
  (((y, w), cw), co) = q
  +nk = U32.to_nat(U32.div(ko, dk))
  +df = U32.to_f32(dk)
  co2 = Array.gdn.l2(nk, Array.gdn.l2(nk, co, 0, dk, eps, Array.q4mv.round((1.0 / df : F32))), ko, dk, eps,
    Array.q4mv.round((1.0 / F32.sqrt(df) : F32)))
  Array.gdn.mix(Array.gdn.heads(U32.to_nat(nvh), ((((s, co2), o), y), ab), 0, dk, dv, nvh, ko, (c + din : U32)), w, cw, sn,
    c, dk, dv, nvh, din, eps)

def Array.gdn.co(r: Array<F32> & Array<F32>, w: Array<F32>, s: Array<F32>, cw: Array<U32>, ab: Array<U32>, sn: Array<U32>,
  o: Array<F32>, +c: U32, +dk: U32, +dv: U32, +nvh: U32, +din: U32, +ko: U32, +eps: F32) ->
  (((((Array<F32> & Array<F32>) & Array<F32>) & Array<U32>) & Array<U32>) & Array<U32>) & Array<F32>:
  (y, co) = r
  Array.gdn.norm(Array.gdn.conv(U32.to_nat(c), (((y, w), cw), co), 0, c), s, ab, sn, o, c, dk, dv, nvh, din, ko, eps)

def Array.gdn(y: Array<F32>, w: Array<F32>, s: Array<F32>, cw: Array<U32>, ab: Array<U32>, sn: Array<U32>, o: Array<F32>,
  +c: U32, +dk: U32, +dv: U32, +nvh: U32, +din: U32, +ko: U32, +eps: F32) ->
  (((((Array<F32> & Array<F32>) & Array<F32>) & Array<U32>) & Array<U32>) & Array<U32>) & Array<F32>:
  Array.gdn.co(Array.clone(F32, y), w, s, cw, ab, sn, o, c, dk, dv, nvh, din, ko, eps)

# Array.atq(y, kc, vc, kw, cs, o, pos, nq, nkv, hd, half, eps) is one token of
# gated full attention (Qwen3.5's), feeding Array.q4mv. y holds the
# projections: query head h's q at h * 2 * hd and its gate after it, then
# nkv keys (at nq * 2 * hd) and nkv values, hd values each. kc and vc are
# the key and value caches as F32 bits, position p's head g at
# (p * nkv + g) * hd; kw holds the q norm's weights then the k norm's (hd
# each, F32 bits); cs the rotation's cos then sin (half each). In order:
#  1. each key head, then each query head, in place in y: x = round(w * (x *
#     inv)) with inv = 1 / sqrt(sum x^2 / hd + eps), then slots j < half
#     rotate against j + half: (a, b) to (round(a c - b s), round(b c + a s)).
#  2. the keys and values join the caches at pos.
#  3. query head h reads cache head g = h / (nq / nkv) at every position t
#     from pos down to 0: score = (sum k q, in order) * (1 / sqrt(hd)), m their
#     max, e = exp(score - m), sum = the e's added in that order, acc = the
#     e * v's added in that order; o[h * hd + d] = round(round(acc * (1 / sum))
#     * round(sigmoid(gate))).
#  4. o[nq * hd + g] holds group g's sum as Array.rmsq writes it.
# Queued like Array.rmsq; use every array after the next Array.q4wait.
# Metal's exp and its tree sums may differ in the last bits, and it leaves
# y as it was. A Metal heap queues positions below 4096; past that the call
# runs on the CPU at once, so wait before it.
def Array.atq.dep(k: Nat, +n: U32, +m: U32, +d: Nat) -> Nat:
  match k:
    case 0n:
      d
    case 1n+p:
      Bool.pick(Nat, U32.is_le(n, m), d, Array.atq.dep(p, n, (m + m : U32), 1n+d))

# x[i ..] = round(w[j ..] * (x[i ..] * inv)) over n slots.
def Array.atq.w1(r: Array<U32> & F32, a: Array<F32>, +x: F32, +inv: F32, +i: U32) -> Array<F32> & Array<U32>:
  (kw, +w) = r
  (Array.set(F32, a, i, Array.q4mv.round((w * (x * inv : F32) : F32))), kw)

def Array.atq.w0(r: Array<F32> & F32, kw: Array<U32>, +inv: F32, +i: U32, +j: U32) -> Array<F32> & Array<U32>:
  (a, +x) = r
  Array.atq.w1(Array.gdn.ui(kw, j), a, x, inv, i)

def Array.atq.ws(n: Nat, r: Array<F32> & Array<U32>, +inv: F32, +i: U32, +j: U32) -> Array<F32> & Array<U32>:
  match n:
    case 0n:
      r
    case 1n+p:
      (a, kw) = r
      Array.atq.ws(p, Array.atq.w0(Array.get(F32, a, i), kw, inv, i, j), inv, (i + 1 : U32), (j + 1 : U32))

def Array.atq.nf(r: Array<F32> & F32, kw: Array<U32>, +i: U32, +j: U32, +hd: U32, +eps: F32) -> Array<F32> & Array<U32>:
  (a, +s) = r
  Array.atq.ws(U32.to_nat(hd), (a, kw), (1.0 / F32.sqrt((s / U32.to_f32(hd) + eps : F32)) : F32), i, j)

# The rotation of slot i + j against i + j + half by cs[j], cs[half + j].
def Array.atq.r3(r: Array<F32> & F32, a: Array<F32>, +x: F32, +y: F32, +c: F32, +i: U32, +h: U32) -> Array<F32> & Array<F32>:
  (cs, +s) = r
  (Array.set(F32, Array.set(F32, a, i, Array.q4mv.round((x * c - y * s : F32))), (i + h : U32),
    Array.q4mv.round((y * c + x * s : F32))), cs)

def Array.atq.r2(r: Array<F32> & F32, a: Array<F32>, +x: F32, +y: F32, +i: U32, +j: U32, +h: U32) -> Array<F32> & Array<F32>:
  (cs, +c) = r
  Array.atq.r3(Array.get(F32, cs, (h + j : U32)), a, x, y, c, i, h)

def Array.atq.r1(r: Array<F32> & F32, cs: Array<F32>, +x: F32, +i: U32, +j: U32, +h: U32) -> Array<F32> & Array<F32>:
  (a, +y) = r
  Array.atq.r2(Array.get(F32, cs, j), a, x, y, i, j, h)

def Array.atq.r0(r: Array<F32> & F32, cs: Array<F32>, +i: U32, +j: U32, +h: U32) -> Array<F32> & Array<F32>:
  (a, +x) = r
  Array.atq.r1(Array.get(F32, a, (i + h : U32)), cs, x, i, j, h)

def Array.atq.rot(n: Nat, r: Array<F32> & Array<F32>, +i: U32, +j: U32, +h: U32) -> Array<F32> & Array<F32>:
  match n:
    case 0n:
      r
    case 1n+p:
      (a, cs) = r
      Array.atq.rot(p, Array.atq.r0(Array.get(F32, a, i), cs, i, j, h), (i + 1 : U32), (j + 1 : U32), h)

def Array.atq.hr.k(r: Array<F32> & Array<F32>, kw: Array<U32>) -> (Array<F32> & Array<U32>) & Array<F32>:
  (a, cs) = r
  ((a, kw), cs)

def Array.atq.hr(r: Array<F32> & Array<U32>, cs: Array<F32>, +i: U32, +h: U32) -> (Array<F32> & Array<U32>) & Array<F32>:
  (a, kw) = r
  Array.atq.hr.k(Array.atq.rot(U32.to_nat(h), (a, cs), i, 0, h), kw)

def Array.atq.hd1(q: (Array<F32> & Array<U32>) & Array<F32>, +i: U32, +j: U32, +hd: U32, +h: U32, +eps: F32) ->
  (Array<F32> & Array<U32>) & Array<F32>:
  ((a, kw), cs) = q
  Array.atq.hr(Array.atq.nf(Array.rmsq.sqs(U32.to_nat(hd), (a, 0.0), i), kw, i, j, hd, eps), cs, i, h)

# k heads from i, step apart: norm by kw[j ..], then rotate, in place.
def Array.atq.hds(k: Nat, q: (Array<F32> & Array<U32>) & Array<F32>, +i: U32, +step: U32, +j: U32, +hd: U32, +h: U32,
  +eps: F32) -> (Array<F32> & Array<U32>) & Array<F32>:
  match k:
    case 0n:
      q
    case 1n+p:
      Array.atq.hds(p, Array.atq.hd1(q, i, j, hd, h, eps), (i + step : U32), step, j, hd, h, eps)

# c[j ..] = the bits of a[i ..] over n slots.
def Array.atq.p1(r: Array<F32> & F32, c: Array<U32>, +j: U32) -> Array<F32> & Array<U32>:
  (a, +x) = r
  (a, Array.set(U32, c, j, Array.q4mv.bits(x)))

def Array.atq.put(n: Nat, r: Array<F32> & Array<U32>, +i: U32, +j: U32) -> Array<F32> & Array<U32>:
  match n:
    case 0n:
      r
    case 1n+p:
      (a, c) = r
      Array.atq.put(p, Array.atq.p1(Array.get(F32, a, i), c, j), (i + 1 : U32), (j + 1 : U32))

# acc + k * q over hd slots, in order (cache k at ki, q in a at qi).
def Array.atq.d1(r: Array<F32> & F32, kc: Array<U32>, +k: F32, +acc: F32) -> (Array<U32> & Array<F32>) & F32:
  (a, +q) = r
  ((kc, a), (acc + k * q : F32))

def Array.atq.d0(r: Array<U32> & F32, a: Array<F32>, +qi: U32, +acc: F32) -> (Array<U32> & Array<F32>) & F32:
  (kc, +k) = r
  Array.atq.d1(Array.get(F32, a, qi), kc, k, acc)

def Array.atq.dot(n: Nat, r: (Array<U32> & Array<F32>) & F32, +ki: U32, +qi: U32) -> (Array<U32> & Array<F32>) & F32:
  match n:
    case 0n:
      r
    case 1n+p:
      ((kc, a), +acc) = r
      Array.atq.dot(p, Array.atq.d0(Array.gdn.ui(kc, ki), a, qi, acc), (ki + 1 : U32), (qi + 1 : U32))

def Array.atq.sc1(r: (Array<U32> & Array<F32>) & F32, ss: Array<F32>, +t: U32, +sc: F32) ->
  (Array<U32> & Array<F32>) & Array<F32>:
  (ka, +d) = r
  (ka, Array.set(F32, ss, t, (d * sc : F32)))

# ss[t] = score of the position t below the newest, its key at ki.
def Array.atq.scs(n: Nat, q: (Array<U32> & Array<F32>) & Array<F32>, +t: U32, +ki: U32, +qi: U32, +stride: U32,
  +hd: U32, +sc: F32) -> (Array<U32> & Array<F32>) & Array<F32>:
  match n:
    case 0n:
      q
    case 1n+p:
      (ka, ss) = q
      Array.atq.scs(p, Array.atq.sc1(Array.atq.dot(U32.to_nat(hd), (ka, 0.0), ki, qi), ss, t, sc), (t + 1 : U32),
        (ki - stride : U32), qi, stride, hd, sc)

def Array.atq.mx1(r: Array<F32> & F32, +m: F32) -> Array<F32> & F32:
  (a, +x) = r
  (a, F32.max(x, m))

def Array.atq.mx(n: Nat, r: Array<F32> & F32, +i: U32) -> Array<F32> & F32:
  match n:
    case 0n:
      r
    case 1n+p:
      (a, +m) = r
      Array.atq.mx(p, Array.atq.mx1(Array.get(F32, a, i), m), (i + 1 : U32))

def Array.atq.ex1(r: Array<F32> & F32, +i: U32, +m: F32) -> Array<F32>:
  (a, +x) = r
  Array.set(F32, a, i, F32.exp((x - m : F32)))

def Array.atq.ex(n: Nat, a: Array<F32>, +i: U32, +m: F32) -> Array<F32>:
  match n:
    case 0n:
      a
    case 1n+p:
      Array.atq.ex(p, Array.atq.ex1(Array.get(F32, a, i), i, m), (i + 1 : U32), m)

# acc[d] = acc[d] + v[d] * pr over hd slots (cache v at vi).
def Array.atq.a1(r: Array<F32> & F32, vc: Array<U32>, +v: F32, +pr: F32, +d: U32) -> Array<U32> & Array<F32>:
  (acc, +x) = r
  (vc, Array.set(F32, acc, d, (x + (v * pr : F32) : F32)))

def Array.atq.a0(r: Array<U32> & F32, acc: Array<F32>, +pr: F32, +d: U32) -> Array<U32> & Array<F32>:
  (vc, +v) = r
  Array.atq.a1(Array.get(F32, acc, d), vc, v, pr, d)

def Array.atq.acc(n: Nat, r: Array<U32> & Array<F32>, +vi: U32, +d: U32, +pr: F32) -> Array<U32> & Array<F32>:
  match n:
    case 0n:
      r
    case 1n+p:
      (vc, acc) = r
      Array.atq.acc(p, Array.atq.a0(Array.gdn.ui(vc, vi), acc, pr, d), (vi + 1 : U32), (d + 1 : U32), pr)

def Array.atq.wt1(r: Array<F32> & F32, va: Array<U32> & Array<F32>, +vi: U32, +hd: U32) -> Array<F32> & (Array<U32> & Array<F32>):
  (es, +pr) = r
  (es, Array.atq.acc(U32.to_nat(hd), va, vi, 0, pr))

# acc = sum of e_t * v_t over the positions, newest first.
def Array.atq.wts(n: Nat, q: Array<F32> & (Array<U32> & Array<F32>), +t: U32, +vi: U32, +stride: U32, +hd: U32) ->
  Array<F32> & (Array<U32> & Array<F32>):
  match n:
    case 0n:
      q
    case 1n+p:
      (es, va) = q
      Array.atq.wts(p, Array.atq.wt1(Array.get(F32, es, t), va, vi, hd), (t + 1 : U32), (vi - stride : U32), stride, hd)

def Array.atq.o2(r: Array<F32> & F32, acc: Array<F32>, o: Array<F32>, +a: F32, +inv: F32, +oi: U32) ->
  (Array<F32> & Array<F32>) & Array<F32>:
  (y, +g) = r
  ((acc, y), Array.set(F32, o, oi, Array.q4mv.round((Array.q4mv.round((a * inv : F32)) *
    Array.q4mv.round(Array.gdn.sig(g)) : F32))))

def Array.atq.o1(r: Array<F32> & F32, y: Array<F32>, o: Array<F32>, +inv: F32, +gi: U32, +oi: U32) ->
  (Array<F32> & Array<F32>) & Array<F32>:
  (acc, +a) = r
  Array.atq.o2(Array.get(F32, y, gi), acc, o, a, inv, oi)

def Array.atq.outs(n: Nat, q: (Array<F32> & Array<F32>) & Array<F32>, +d: U32, +gi: U32, +oi: U32, +inv: F32) ->
  (Array<F32> & Array<F32>) & Array<F32>:
  match n:
    case 0n:
      q
    case 1n+p:
      ((acc, y), o) = q
      Array.atq.outs(p, Array.atq.o1(Array.get(F32, acc, d), y, o, inv, gi, oi), (d + 1 : U32), (gi + 1 : U32),
        (oi + 1 : U32), inv)

# One query head's attention; its scratch arrays are dropped.
def Array.atq.h4(q: (Array<F32> & Array<F32>) & Array<F32>, ss: Array<F32>, kc: Array<U32>, vc: Array<U32>) ->
  ((Array<F32> & Array<U32>) & Array<U32>) & Array<F32>:
  ((acc, y), o) = q
  _ = acc
  _ = ss
  (((y, kc), vc), o)

def Array.atq.h3(r: Array<F32> & (Array<U32> & Array<F32>), y: Array<F32>, kc: Array<U32>, o: Array<F32>, +sum: F32,
  +h: U32, +hd: U32) -> ((Array<F32> & Array<U32>) & Array<U32>) & Array<F32>:
  (ss, va) = r
  (vc, acc) = va
  Array.atq.h4(Array.atq.outs(U32.to_nat(hd), ((acc, y), o), 0, (h * hd * 2 + hd : U32), (h * hd : U32),
    (1.0 / sum : F32)), ss, kc, vc)

def Array.atq.h2(r: Array<F32> & F32, y: Array<F32>, kc: Array<U32>, vc: Array<U32>, o: Array<F32>, +n: U32, +vi: U32,
  +stride: U32, +h: U32, +hd: U32) -> ((Array<F32> & Array<U32>) & Array<U32>) & Array<F32>:
  (ss, +sum) = r
  Array.atq.h3(Array.atq.wts(U32.to_nat(n), (ss, (vc, Array.new(F32, Array.atq.dep(32n, hd, 1, 0n), 0.0))), 0, vi, stride,
    hd), y, kc, o, sum, h, hd)

def Array.atq.h1(r: Array<F32> & F32, y: Array<F32>, kc: Array<U32>, vc: Array<U32>, o: Array<F32>, +n: U32, +vi: U32,
  +stride: U32, +h: U32, +hd: U32) -> ((Array<F32> & Array<U32>) & Array<U32>) & Array<F32>:
  (ss, +m) = r
  Array.atq.h2(Array.rmsq.half(U32.to_nat(n), (Array.atq.ex(U32.to_nat(n), ss, 0, m), 0.0), 0), y, kc, vc, o, n, vi,
    stride, h, hd)

def Array.atq.h0(q: (Array<U32> & Array<F32>) & Array<F32>, vc: Array<U32>, o: Array<F32>, +n: U32, +vi: U32,
  +stride: U32, +h: U32, +hd: U32) -> ((Array<F32> & Array<U32>) & Array<U32>) & Array<F32>:
  ((kc, y), ss) = q
  Array.atq.h1(Array.atq.mx(U32.to_nat((n - 1 : U32)), Array.get(F32, ss, 0), 1), y, kc, vc, o, n, vi, stride, h, hd)

def Array.atq.head(q: ((Array<F32> & Array<U32>) & Array<U32>) & Array<F32>, +h: U32, +pos: U32, +nq: U32, +nkv: U32,
  +hd: U32) -> ((Array<F32> & Array<U32>) & Array<U32>) & Array<F32>:
  (((y, kc), vc), o) = q
  +n = (pos + 1 : U32)
  +stride = (nkv * hd : U32)
  +at = ((pos * nkv + U32.div(h, U32.div(nq, nkv))) * hd : U32)
  Array.atq.h0(Array.atq.scs(U32.to_nat(n), ((kc, y), Array.new(F32, Array.atq.dep(32n, n, 1, 0n), 0.0)), 0, at,
    (h * hd * 2 : U32), stride, hd, (1.0 / F32.sqrt(U32.to_f32(hd)) : F32)), vc, o, n, at, stride, h, hd)

def Array.atq.heads(k: Nat, q: ((Array<F32> & Array<U32>) & Array<U32>) & Array<F32>, +h: U32, +pos: U32, +nq: U32,
  +nkv: U32, +hd: U32) -> ((Array<F32> & Array<U32>) & Array<U32>) & Array<F32>:
  match k:
    case 0n:
      q
    case 1n+p:
      Array.atq.heads(p, Array.atq.head(q, h, pos, nq, nkv, hd), (h + 1 : U32), pos, nq, nkv, hd)

def Array.atq.fin(q: ((Array<F32> & Array<U32>) & Array<U32>) & Array<F32>, kw: Array<U32>, cs: Array<F32>, +n: U32) ->
  ((((Array<F32> & Array<U32>) & Array<U32>) & Array<U32>) & Array<F32>) & Array<F32>:
  (((y, kc), vc), o) = q
  (((((y, kc), vc), kw), cs), Array.rmsq.gs(U32.to_nat((n >> 6n : U32)), o, 0, n))

def Array.atq.cv(r: Array<F32> & Array<U32>, kc: Array<U32>, kw: Array<U32>, cs: Array<F32>, o: Array<F32>, +pos: U32,
  +nq: U32, +nkv: U32, +hd: U32) -> ((((Array<F32> & Array<U32>) & Array<U32>) & Array<U32>) & Array<F32>) & Array<F32>:
  (y, vc) = r
  Array.atq.fin(Array.atq.heads(U32.to_nat(nq), (((y, kc), vc), o), 0, pos, nq, nkv, hd), kw, cs, (nq * hd : U32))

def Array.atq.ck(r: Array<F32> & Array<U32>, vc: Array<U32>, kw: Array<U32>, cs: Array<F32>, o: Array<F32>, +pos: U32,
  +nq: U32, +nkv: U32, +hd: U32) -> ((((Array<F32> & Array<U32>) & Array<U32>) & Array<U32>) & Array<F32>) & Array<F32>:
  (y, kc) = r
  +ko = (nq * hd * 2 : U32)
  Array.atq.cv(Array.atq.put(U32.to_nat((nkv * hd : U32)), (y, vc), (ko + nkv * hd : U32), (pos * nkv * hd : U32)), kc,
    kw, cs, o, pos, nq, nkv, hd)

def Array.atq.rq(q: (Array<F32> & Array<U32>) & Array<F32>, kc: Array<U32>, vc: Array<U32>, o: Array<F32>, +pos: U32,
  +nq: U32, +nkv: U32, +hd: U32) -> ((((Array<F32> & Array<U32>) & Array<U32>) & Array<U32>) & Array<F32>) & Array<F32>:
  ((y, kw), cs) = q
  Array.atq.ck(Array.atq.put(U32.to_nat((nkv * hd : U32)), (y, kc), (nq * hd * 2 : U32), (pos * nkv * hd : U32)), vc, kw,
    cs, o, pos, nq, nkv, hd)

def Array.atq(y: Array<F32>, kc: Array<U32>, vc: Array<U32>, kw: Array<U32>, cs: Array<F32>, o: Array<F32>, +pos: U32,
  +nq: U32, +nkv: U32, +hd: U32, +half: U32, +eps: F32) ->
  ((((Array<F32> & Array<U32>) & Array<U32>) & Array<U32>) & Array<F32>) & Array<F32>:
  Array.atq.rq(Array.atq.hds(U32.to_nat(nq), Array.atq.hds(U32.to_nat(nkv), ((y, kw), cs), (nq * hd * 2 : U32), hd, hd,
    hd, half, eps), 0, (hd * 2 : U32), 0, hd, half, eps), kc, vc, o, pos, nq, nkv, hd)

def Array.to_list.go(~T: Type, a: Array<T>, acc: List<T>) -> List<T>:
  match a:
    case ALeaf{x}:
      x <> acc
    case ANode{xs, ys}:
      Array.to_list.go(~T, xs, Array.to_list.go(~T, ys, acc))

def Array.to_list(~T: Type, a: Array<T>) -> List<T>:
  Array.to_list.go(~T, a, Nil{})

def Array.map.go(
  ~T: Data, ~U: Data, ~f: T -> U, +n: Nat, +i: U32, b: Array<U>,
  r: Array<T> & T
) -> Array<U>:
  match n:
    case 0n:
      b
    case 1n+p:
      (a, x) = r
      +j = U32.inc(i)
      Array.map.go(~T, ~U, ~f, p, j, Array.set(U, b, i, f(x)),
        Array.get(T, a, j))

def Array.map.at(
  ~T: Data, ~U: Data, ~f: T -> U, v: U, an: Array<T> & U32
) -> Array<U>:
  (a, +n) = an
  Array.map.go(~T, ~U, ~f, U32.to_nat(U32.sub(n, 1)), 1,
    Array.new(U, U32.log2(n), v), Array.get(T, a, 1))

def Array.map.seed(~T: Data, ~U: Data, ~f: T -> U, r: Array<T> & T) -> Array<U>:
  (a, x) = r
  Array.map.at(~T, ~U, ~f, f(x), Array.size(T, a))

def Array.map(~T: Data, ~U: Data, ~f: T -> U, a: Array<T>) -> Array<U>:
  Array.map.seed(~T, ~U, ~f, Array.get(T, a, 0))

# Map
# ---

def Map.bit.u(x: U32, k: Nat) -> Bool:
  U32.is_ne(U32.and(U32.shrn(x, k), 1), 0)

def Map.bit.chr(c: Char, off: Nat) -> Char & Bool:
  match c off:
    case Chr{x} 0n:
      (Chr{x}, True{})
    case Chr{+x} 1n+b:
      (Chr{x}, Map.bit.u(x, Nat.sub(31n, b)))

def Map.bit.go.chr(t: String, r: Char & Bool) -> String & Bool:
  (c2, b) = r
  (SCon{c2, t}, b)

def Map.bit.go.rec(c: Char, r: String & Bool) -> String & Bool:
  (t2, b) = r
  (SCon{c, t2}, b)

def Map.bit.go(key: String, ci: Nat, off: Nat) -> String & Bool:
  match key:
    case SNil{}:
      (SNil{}, False{})
    case SCon{c, t}:
      match ci:
        case 0n:
          Map.bit.go.chr(t, Map.bit.chr(c, off))
        case 1n+j:
          Map.bit.go.rec(c, Map.bit.go(t, j, off))

def Map.bit.at(key: String, co: Nat & Nat) -> String & Bool:
  (ci, off) = co
  Map.bit.go(key, ci, off)

def Map.bit(key: String, pos: Nat) -> String & Bool:
  Map.bit.at(key, Nat.divmod(pos, 33n))

law Map.msb.u:
  for n: Nat
  for +x: U32
  Nat

def Map.msb.u.if(p: Nat, x2: U32, z: Bool) -> Nat:
  match z:
    case True{}:
      0n
    case False{}:
      Nat.add(1n, Map.msb.u(p, U32.shr(x2)))

def Map.msb.u(n, x):
  match n:
    case 0n:
      0n
    case 1n+p:
      Map.msb.u.if(p, x, U32.is_zero(x))

def Map.diff.chr(x: U32) -> Nat:
  Nat.sub(33n, Map.msb.u(32n, x))

def Map.diff.step(x: Char, y: Char) -> Nat & Bool:
  match x y:
    case Chr{+cx} Chr{+cy}:
      (Map.diff.chr(U32.xor(cx, cy)), U32.is_eq(cx, cy))

law Map.diff:
  for a: String
  for b: String
  Nat

def Map.diff.fin(xt: String, yt: String, rc: Nat & Bool) -> Nat:
  (r, c) = rc
  match c:
    case True{}:
      Nat.add(33n, Map.diff(xt, yt))
    case False{}:
      r

def Map.diff(a, b):
  match a b:
    case SNil{} _:
      0n
    case SCon{h, t} SNil{}:
      0n
    case SCon{x, xt} SCon{y, yt}:
      Map.diff.fin(xt, yt, Map.diff.step(x, y))

def Map.new(a, -V: Kind(a)) -> Map<a, V>:
  MTip{}

# Map.put.go, Map.ins.go, Map.seek.go, Map.has.go, Map.get.go and
# Map.pop.go take the node they are in, whole, and the key's bit at it:
# the child they descend into is that node's field, a node rebuilt
def Map.put.go(-a: Quant, -V: Kind(a), node: Map<a, V>, x: V, kb: String & Bool) -> Map<a, V>:
  match node kb:
    case MNode{p, MTip{}, hi} Tuple{key, False{}}:
      MNode{p, MLeaf{key, x}, hi}
    case MNode{p, MLeaf{k, v}, hi} Tuple{key, False{}}:
      MNode{p, MLeaf{k, x}, hi}
    case MNode{p, MNode{+q, c, d}, hi} Tuple{key, False{}}:
      MNode{p, Map.put.go(a, V, MNode{q, c, d}, x, Map.bit(key, q)), hi}
    case MNode{p, lo, MTip{}} Tuple{key, True{}}:
      MNode{p, lo, MLeaf{key, x}}
    case MNode{p, lo, MLeaf{k, v}} Tuple{key, True{}}:
      MNode{p, lo, MLeaf{k, x}}
    case MNode{p, lo, MNode{+q, c, d}} Tuple{key, True{}}:
      MNode{p, lo, Map.put.go(a, V, MNode{q, c, d}, x, Map.bit(key, q))}
    case m _:
      m

def Map.put(-a: Quant, -V: Kind(a), m: Map<a, V>, key: String, x: V) -> Map<a, V>:
  match m:
    case MTip{}:
      MLeaf{key, x}
    case MLeaf{k, v}:
      MLeaf{k, x}
    case MNode{+pos, lo, hi}:
      Map.put.go(a, V, MNode{pos, lo, hi}, x, Map.bit(key, pos))

def Map.ins.splice.bit(
  a, -V: Kind(a), x: V, rest: Map<a, V>, pb: Nat, kb: String & Bool
) -> Map<a, V>:
  (key2, b) = kb
  match b:
    case False{}:
      MNode{pb, MLeaf{key2, x}, rest}
    case True{}:
      MNode{pb, rest, MLeaf{key2, x}}

def Map.ins.splice(
  a, -V: Kind(a), +p: Nat, key: String, x: V, rest: Map<a, V>
) -> Map<a, V>:
  Map.ins.splice.bit(a, V, x, rest, p, Map.bit(key, p))

# t says whether the key splits deeper than node: else it goes above
def Map.ins.go(
  -a: Quant, -V: Kind(a), node: Map<a, V>, x: V, +p: Nat, kb: String & Bool,
  t: Bool
) -> Map<a, V>:
  match node kb t:
    case MNode{q, lo, hi} Tuple{key, b} False{}:
      Map.ins.splice(a, V, p, key, x, MNode{q, lo, hi})
    case MNode{q, MTip{}, hi} Tuple{key, False{}} True{}:
      MNode{q, MLeaf{key, x}, hi}
    case MNode{q, MLeaf{k, v}, hi} Tuple{key, False{}} True{}:
      MNode{q, Map.ins.splice(a, V, p, key, x, MLeaf{k, v}), hi}
    case MNode{q, MNode{+r, c, d}, hi} Tuple{key, False{}} True{}:
      MNode{q, Map.ins.go(a, V, MNode{r, c, d}, x, p, Map.bit(key, r), Nat.is_lt(r, p)), hi}
    case MNode{q, lo, MTip{}} Tuple{key, True{}} True{}:
      MNode{q, lo, MLeaf{key, x}}
    case MNode{q, lo, MLeaf{k, v}} Tuple{key, True{}} True{}:
      MNode{q, lo, Map.ins.splice(a, V, p, key, x, MLeaf{k, v})}
    case MNode{q, lo, MNode{+r, c, d}} Tuple{key, True{}} True{}:
      MNode{q, lo, Map.ins.go(a, V, MNode{r, c, d}, x, p, Map.bit(key, r), Nat.is_lt(r, p))}
    case m _ _:
      m

def Map.ins(
  -a: Quant, -V: Kind(a), m: Map<a, V>, key: String, x: V, +p: Nat
) -> Map<a, V>:
  match m:
    case MTip{}:
      MLeaf{key, x}
    case MLeaf{k, v}:
      Map.ins.splice(a, V, p, key, x, MLeaf{k, v})
    case MNode{+pos, lo, hi}:
      Map.ins.go(a, V, MNode{pos, lo, hi}, x, p, Map.bit(key, pos), Nat.is_lt(pos, p))

def Map.lo(
  a, -V: Kind(a), -R: Type, p2: Nat, hi: Map<a, V>, r0: Map<a, V> & R
) -> Map<a, V> & R:
  (lo2, r) = r0
  (MNode{p2, lo2, hi}, r)

def Map.hi(
  a, -V: Kind(a), -R: Type, p2: Nat, lo: Map<a, V>, r0: Map<a, V> & R
) -> Map<a, V> & R:
  (hi2, r) = r0
  (MNode{p2, lo, hi2}, r)

def Map.seek.go(-a: Quant, -V: Kind(a), node: Map<a, V>, kb: String & Bool) ->
  Map<a, V> & String & Maybe<&2, String>:
  match node kb:
    case MNode{p, MTip{}, hi} Tuple{key, False{}}:
      (MNode{p, MTip{}, hi}, key, None{})
    case MNode{p, MLeaf{+k, v}, hi} Tuple{key, False{}}:
      (MNode{p, MLeaf{k, v}, hi}, key, Some{k})
    case MNode{p, MNode{+q, c, d}, hi} Tuple{key, False{}}:
      Map.lo(a, V, String & Maybe<&2, String>, p, hi, Map.seek.go(a, V, MNode{q, c, d}, Map.bit(key, q)))
    case MNode{p, lo, MTip{}} Tuple{key, True{}}:
      (MNode{p, lo, MTip{}}, key, None{})
    case MNode{p, lo, MLeaf{+k, v}} Tuple{key, True{}}:
      (MNode{p, lo, MLeaf{k, v}}, key, Some{k})
    case MNode{p, lo, MNode{+q, c, d}} Tuple{key, True{}}:
      Map.hi(a, V, String & Maybe<&2, String>, p, lo, Map.seek.go(a, V, MNode{q, c, d}, Map.bit(key, q)))
    case m Tuple{key, b}:
      (m, key, None{})

def Map.seek(-a: Quant, -V: Kind(a), m: Map<a, V>, key: String) ->
  Map<a, V> & String & Maybe<&2, String>:
  match m:
    case MTip{}:
      (MTip{}, key, None{})
    case MLeaf{+k, v}:
      (MLeaf{k, v}, key, Some{k})
    case MNode{+pos, lo, hi}:
      Map.seek.go(a, V, MNode{pos, lo, hi}, Map.bit(key, pos))

def Map.set.fin.go(
  a, -V: Kind(a), m: Map<a, V>, key: String, x: V, r: (String & String) & Cmp
) -> Map<a, V>:
  ((keyb2, k2), c) = r
  match c:
    case EQ{}:
      Map.put(a, V, m, key, x)
    case o:
      Map.ins(a, V, m, key, x, Map.diff(keyb2, k2))

def Map.set.fin(
  a, -V: Kind(a), m: Map<a, V>, key: String, x: V, keyb: String, k: String
) -> Map<a, V>:
  Map.set.fin.go(a, V, m, key, x, String.cmp(keyb, k))

def Map.set.go(
  a, -V: Kind(a), x: V, r: Map<a, V> & String & Maybe<&2, String>
) -> Map<a, V>:
  (m2, key2, found) = r
  match found:
    case None{}:
      MLeaf{key2, x}
    case Some{k}:
      +ka = {key2 : String}
      Map.set.fin(a, V, m2, ka, x, ka, k)

def Map.set(a, -V: Kind(a), m: Map<a, V>, key: String, x: V) -> Map<a, V>:
  Map.set.go(a, V, x, Map.seek(a, V, m, key))

def Map.has.leaf(a, -V: Kind(a), v: V, r: (String & String) & Cmp) ->
  Map<a, V> & Bool:
  ((key2, k2), c) = r
  (MLeaf{k2, v}, Cmp.is_eq(c))

def Map.has.go(-a: Quant, -V: Kind(a), node: Map<a, V>, kb: String & Bool) ->
  Map<a, V> & Bool:
  match node kb:
    case MNode{p, MTip{}, hi} Tuple{key, False{}}:
      (MNode{p, MTip{}, hi}, False{})
    case MNode{p, MLeaf{k, v}, hi} Tuple{key, False{}}:
      Map.lo(a, V, Bool, p, hi, Map.has.leaf(a, V, v, String.cmp(key, k)))
    case MNode{p, MNode{+q, c, d}, hi} Tuple{key, False{}}:
      Map.lo(a, V, Bool, p, hi, Map.has.go(a, V, MNode{q, c, d}, Map.bit(key, q)))
    case MNode{p, lo, MTip{}} Tuple{key, True{}}:
      (MNode{p, lo, MTip{}}, False{})
    case MNode{p, lo, MLeaf{k, v}} Tuple{key, True{}}:
      Map.hi(a, V, Bool, p, lo, Map.has.leaf(a, V, v, String.cmp(key, k)))
    case MNode{p, lo, MNode{+q, c, d}} Tuple{key, True{}}:
      Map.hi(a, V, Bool, p, lo, Map.has.go(a, V, MNode{q, c, d}, Map.bit(key, q)))
    case m _:
      (m, False{})

def Map.has(-a: Quant, -V: Kind(a), m: Map<a, V>, key: String) -> Map<a, V> & Bool:
  match m:
    case MTip{}:
      (MTip{}, False{})
    case MLeaf{k, v}:
      Map.has.leaf(a, V, v, String.cmp(key, k))
    case MNode{+pos, lo, hi}:
      Map.has.go(a, V, MNode{pos, lo, hi}, Map.bit(key, pos))

def Map.get.leaf(-V: Data, d: V, +v: V, r: (String & String) & Cmp) ->
  Map<&2, V> & V:
  ((key2, k2), c) = r
  match c:
    case EQ{}:
      (MLeaf{k2, v}, v)
    case o:
      (MLeaf{k2, v}, d)

def Map.get.go(-V: Data, node: Map<&2, V>, d: V, kb: String & Bool) -> Map<&2, V> & V:
  match node kb:
    case MNode{p, MTip{}, hi} Tuple{key2, False{}}:
      (MNode{p, MTip{}, hi}, d)
    case MNode{p, MLeaf{k, v}, hi} Tuple{key2, False{}}:
      Map.lo(&2, V, V, p, hi, Map.get.leaf(V, d, v, String.cmp(key2, k)))
    case MNode{p, MNode{+q, a, b}, hi} Tuple{key2, False{}}:
      Map.lo(&2, V, V, p, hi, Map.get.go(V, MNode{q, a, b}, d, Map.bit(key2, q)))
    case MNode{p, lo, MTip{}} Tuple{key2, True{}}:
      (MNode{p, lo, MTip{}}, d)
    case MNode{p, lo, MLeaf{k, v}} Tuple{key2, True{}}:
      Map.hi(&2, V, V, p, lo, Map.get.leaf(V, d, v, String.cmp(key2, k)))
    case MNode{p, lo, MNode{+q, a, b}} Tuple{key2, True{}}:
      Map.hi(&2, V, V, p, lo, Map.get.go(V, MNode{q, a, b}, d, Map.bit(key2, q)))
    case m _:
      (m, d)

def Map.get(-V: Data, d: V, m: Map<&2, V>, key: String) -> Map<&2, V> & V:
  match m:
    case MTip{}:
      (MTip{}, d)
    case MLeaf{k, v}:
      Map.get.leaf(V, d, v, String.cmp(key, k))
    case MNode{+pos, lo, hi}:
      Map.get.go(V, MNode{pos, lo, hi}, d, Map.bit(key, pos))

def Map.pop.lo(
  a, -V: Kind(a), pos: Nat, hi: Map<a, V>, r0: Map<a, V> & Maybe<a, V>
) -> Map<a, V> & Maybe<a, V>:
  (lo, r) = r0
  match lo:
    case MTip{}:
      (hi, r)
    case lo2:
      (MNode{pos, lo2, hi}, r)

def Map.pop.hi(
  a, -V: Kind(a), pos: Nat, lo: Map<a, V>, r0: Map<a, V> & Maybe<a, V>
) -> Map<a, V> & Maybe<a, V>:
  (hi, r) = r0
  match hi:
    case MTip{}:
      (lo, r)
    case hi2:
      (MNode{pos, lo, hi2}, r)

def Map.pop.leaf(a, -V: Kind(a), v: V, r: (String & String) & Cmp) ->
  Map<a, V> & Maybe<a, V>:
  ((key2, k2), c) = r
  match c:
    case EQ{}:
      (MTip{}, Some{v})
    case o:
      (MLeaf{k2, v}, None{})

def Map.pop.go(-a: Quant, -V: Kind(a), node: Map<a, V>, kb: String & Bool) ->
  Map<a, V> & Maybe<a, V>:
  match node kb:
    case MNode{p, MTip{}, hi} Tuple{key, False{}}:
      (hi, None{})
    case MNode{p, MLeaf{k, v}, hi} Tuple{key, False{}}:
      Map.pop.lo(a, V, p, hi, Map.pop.leaf(a, V, v, String.cmp(key, k)))
    case MNode{p, MNode{+q, c, d}, hi} Tuple{key, False{}}:
      Map.pop.lo(a, V, p, hi, Map.pop.go(a, V, MNode{q, c, d}, Map.bit(key, q)))
    case MNode{p, lo, MTip{}} Tuple{key, True{}}:
      (lo, None{})
    case MNode{p, lo, MLeaf{k, v}} Tuple{key, True{}}:
      Map.pop.hi(a, V, p, lo, Map.pop.leaf(a, V, v, String.cmp(key, k)))
    case MNode{p, lo, MNode{+q, c, d}} Tuple{key, True{}}:
      Map.pop.hi(a, V, p, lo, Map.pop.go(a, V, MNode{q, c, d}, Map.bit(key, q)))
    case m _:
      (m, None{})

def Map.pop(-a: Quant, -V: Kind(a), m: Map<a, V>, key: String) -> Map<a, V> & Maybe<a, V>:
  match m:
    case MTip{}:
      (MTip{}, None{})
    case MLeaf{k, v}:
      Map.pop.leaf(a, V, v, String.cmp(key, k))
    case MNode{+pos, lo, hi}:
      Map.pop.go(a, V, MNode{pos, lo, hi}, Map.bit(key, pos))

def Map.del.fin(a, -V: Kind(a), r: Map<a, V> & Maybe<a, V>) -> Map<a, V>:
  (m2, x) = r
  m2

def Map.del(a, -V: Kind(a), m: Map<a, V>, key: String) -> Map<a, V>:
  Map.del.fin(a, V, Map.pop(a, V, m, key))

def Map.to_list.go(
  a, -V: Kind(a), m: Map<a, V>, acc: List<a, Sigma<&2, a, String, _ => V>>
) -> List<a, Sigma<&2, a, String, _ => V>>:
  match m:
    case MTip{}:
      acc
    case MLeaf{k, v}:
      (k, v) <> acc
    case MNode{pos, lo, hi}:
      Map.to_list.go(a, V, lo, Map.to_list.go(a, V, hi, acc))

def Map.to_list(a, -V: Kind(a), m: Map<a, V>) ->
  List<a, Sigma<&2, a, String, _ => V>>:
  Map.to_list.go(a, V, m, Nil{})

def Map.keys.go(a, -V: Kind(a), m: Map<a, V>, acc: List<&2, String>) ->
  List<&2, String>:
  match m:
    case MTip{}:
      acc
    case MLeaf{k, v}:
      k <> acc
    case MNode{pos, lo, hi}:
      Map.keys.go(a, V, lo, Map.keys.go(a, V, hi, acc))

def Map.keys(a, -V: Kind(a), m: Map<a, V>) -> List<&2, String>:
  Map.keys.go(a, V, m, Nil{})

def Map.from_list.go(
  a, -V: Kind(a), kvs: List<a, Sigma<&2, a, String, _ => V>>, m: Map<a, V>
) -> Map<a, V>:
  match kvs:
    case Nil{}:
      m
    case (k, v) <> t:
      Map.from_list.go(a, V, t, Map.set(a, V, m, k, v))

def Map.from_list(a, -V: Kind(a), kvs: List<a, Sigma<&2, a, String, _ => V>>) ->
  Map<a, V>:
  Map.from_list.go(a, V, kvs, MTip{})

def Map.union(a, -V: Kind(a), m: Map<a, V>, n: Map<a, V>) -> Map<a, V>:
  Map.from_list.go(a, V, Map.to_list(a, V, n), m)

def Map.size(a, -V: Kind(a), m: Map<a, V>) -> Nat:
  match m:
    case MTip{}:
      0n
    case MLeaf{k, v}:
      1n
    case MNode{pos, lo, hi}:
      Nat.add(Map.size(a, V, lo), Map.size(a, V, hi))

def Map.values.go(a, -V: Kind(a), m: Map<a, V>, acc: List<a, V>) -> List<a, V>:
  match m:
    case MTip{}:
      acc
    case MLeaf{k, v}:
      v <> acc
    case MNode{pos, lo, hi}:
      Map.values.go(a, V, lo, Map.values.go(a, V, hi, acc))

def Map.values(a, -V: Kind(a), m: Map<a, V>) -> List<a, V>:
  Map.values.go(a, V, m, Nil{})

# Set
# ---

def Set() -> Data:
  Map<&2, Unit>

def Set.new() -> Set():
  Map.new(&2, Unit)

def Set.add(s: Set(), key: String) -> Set():
  Map.set(&2, Unit, s, key, Unit{})

def Set.has(s: Set(), key: String) -> Set() & Bool:
  Map.has(&2, Unit, s, key)

def Set.del(s: Set(), key: String) -> Set():
  Map.del(&2, Unit, s, key)

def Set.size(s: Set()) -> Nat:
  Map.size(&2, Unit, s)

def Set.to_list(s: Set()) -> List<&2, String>:
  Map.keys(&2, Unit, s)

def Set.from_list.go(keys: List<&2, String>, s: Set()) -> Set():
  match keys:
    case Nil{}:
      s
    case h <> t:
      Set.from_list.go(t, Set.add(s, h))

def Set.from_list(keys: List<&2, String>) -> Set():
  Set.from_list.go(keys, Set.new())

# Image
# -----

def Image.sink(img: Image) -> Unit:
  Unit{}

def Image.drop.join(a: Unit, b: Unit, c: Unit, d: Unit) -> Unit:
  match a b c d:
    case Unit{} Unit{} Unit{} Unit{}:
      Unit{}

# Forks k levels, then a dead parameter sinks the rest in one loop.
def Image.free(+k: Nat, img: Image) -> Unit:
  match k:
    case 0n:
      Image.sink(img)
    case 1n+e:
      match img:
        case Pix{c}:
          Unit{}
        case Qua{tl, tr, bl, br}:
          a b c d = Image.free(e, tl) Image.free(e, tr) Image.free(e, bl)
            Image.free(e, br)
          Image.drop.join(a, b, c, d)

def Image.drop(img: Image) -> Unit:
  Image.free(7n, img)

# App
# ---

def App.next(
  -S: Type, window: Window, rest: Window -> S -> IO(Unit), next: Maybe<S>
) -> IO(Unit):
  match next:
    case None{}:
      Window.close(window)
    case Some{state}:
      rest(window, state)

def App.turn(
  -S: Type, shown: Window & Image & List<Event>,
  tick: List<Event> -> S -> IO(Maybe<S>), state: S,
  rest: Window -> S -> IO(Unit)
) -> IO(Unit):
  (window, image, events) = shown
  do IO<Unit>:
    Unit <- IO.pure(Unit, Image.drop!(image))
    IO.bind(Maybe<S>, Unit, tick(events, state), App.next(S, window, rest))

def App.draw(
  -S: Type, window: Window, drawn: S & Image,
  tick: List<Event> -> S -> IO(Maybe<S>), rest: Window -> S -> IO(Unit)
) -> IO(Unit):
  (state, image) = drawn
  do IO<Unit>:
    shown : Window & Image & List<Event> <- Window.frame(window, image)
    App.turn(S, shown, tick, state, rest)

def App.step(
  -S: Type, app: App<S>, window: Window, state: S,
  rest: Window -> S -> IO(Unit)
) -> IO(Unit):
  App{view, tick} = app
  App.draw(S, window, view(state), tick, rest)

def App.loop(~S: Type, ~app: App<S>, fuel: Nat, window: Window, state: S) ->
  IO(Unit):
  match fuel:
    case 0n:
      Window.close(window)
    case 1n+f:
      App.step(S, app, window, state, w => s => App.loop(~S, ~app, f, w, s))

def App.run(
  ~S: Type, ~app: App<S>, title: String, width: U32, height: U32, state: S
) -> IO(Unit):
  do IO<Unit>:
    window : Window <- IO.try(Window, Window.open(title, width, height))
    App.loop(~S, ~app, 4294967295n, window, state)

def App.more(-S: Type, rest: S -> IO(Maybe<S>), next: Maybe<S>) ->
  IO(Maybe<S>):
  match next:
    case None{}:
      IO.pure(Maybe<S>, None{})
    case Some{state}:
      rest(state)

def App.fold(
  -S: Type, app: App<S>, events: List<Event>, state: S,
  rest: S -> IO(Maybe<S>)
) -> IO(Maybe<S>):
  App{view, tick} = app
  IO.bind(Maybe<S>, Maybe<S>, tick(events, state), App.more(S, rest))

def App.play(~S: Type, ~app: App<S>, frames: List<List<Event>>, state: S) ->
  IO(Maybe<S>):
  match frames:
    case Nil{}:
      IO.pure(Maybe<S>, Some{state})
    case events <> rest:
      App.fold(S, app, events, state, s => App.play(~S, ~app, rest, s))
