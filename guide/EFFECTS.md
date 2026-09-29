# Effects in Bend

An AI wrote this text from the runtime's source (`bend2/comp.ts` and
`bend2/effs/`). A human will revise it later. Report anything wrong on
GitHub.

## An effect def

An effect is a def of type `IO(R)` whose body is two imports:

```python
def Clock.now() -> IO(U32):
  import "./clock.c"
  import "./clock.js"
```

Each file registers the effect under its def with `io_eff(CID(Clock.now),
..)`. The `.c` file serves `bend x.bend -o x`; the `.js` file
serves `bend x.bend -o x.js` and `bend x.bend`. Every effect in Base is
built this way: `bend2/effs/*.c` and `*.js` are the reference.

## The C side

The compiler splices your `.c` into the program's C source after the
runtime, so every runtime symbol is in scope. Define the effect and
register it in a constructor:

```c
Term clock_now_run(Env e, Term* f, IoWork* w);

static void __attribute__((constructor)) clock_now_use(void) {
  io_eff(CID(Clock.now), clock_now_run, 0);
}
```

`CID(Name)` is the C id of a constructor or of an effect def: the compiler
replaces it with the name's own id, reading `Name` in the effect's
namespace first (the file that declares the def), then in Base's, as the
def's body would. A constructor the program does not use has no id, so
`#ifdef CID(Name)` tests for it. `FID(name)` is a def's function id the
same way. `f` holds the def's arguments in order: a `U32` is the word
(`(u32)f[0]`), a `String` is taken with `io_cstr(e, f[0], &len)` (a
`malloc`ed copy you free), a handle with `io_hand_v(f[0])`. The last
argument of `io_eff` is the need: `0` runs the effect at once; `IO_READ`
parks it until the handle in `f[0]` is readable; `IO_TIME` parks it for
`f[0]` milliseconds. Then the loop calls the effect. The need also says
whether `IO.poll` can hold the effect; see "A pollable effect" below.

The effect returns a Term: a `U32` is `(Term)n`, `Unit` is
`term_pak(CID(Unit), 0)`, a `String` is `io_str(e, p, n)`, a two-field
constructor is `io_node(e, CID(K), a, b)`. A `Result` is `io_done(e, v)`
or `io_fail(e, code, text)` (`text` NULL prints `strerror(code)`).
`io_sys_end(w, n)` stores `errno` in `w->code` when a call fails.

A handle is a descriptor or pointer packed in one word by `io_hand(v)`. Its
type must be one of Base's handle laws (`File`, `Socket`, ...): a user
handle type is a WONTFIX entry for now, see `WONTFIX.txt`. An effect on a
handle hands it back beside its result: `io_tup(e, io_hand(h), r)`, also
on failure.

Blocking work leaves the loop in two ways. `io_work(w, call, pack)` runs
`call(w)` on a helper thread, then `pack(e, w)` on the loop; `pack`'s value
is the answer. `call` has no `Env`: it may only touch `w`.
`io_wait_on(w, fd, POLLIN, 0, more)` parks until `fd` is ready (`POLLIN` or
`POLLOUT`), then runs `more(e, w)` on the loop; `more` may call
`io_wait_on` again. Both return `IO_PARK`, which the effect returns.
Replace `0` with an absolute `io_tick()` deadline to also wake on time.

`w` is the effect's scratch space: `hand`, `made`, `word`, `size`, `data`,
`text`, `code`. The runtime owns `w` and `f`. The effect owns `w->data`:
allocate it in the run function and free it in `pack`. In `bend2/effs/`,
`file_read.c` is the pattern for `io_work` and `tcp_recv.c` for `io_wait_on`.

## The JS side

The `.js` file is a plain script, run once in a closure of its own, that
registers the effect: `io_eff(CID(Clock.now), clock_now, need, poll)`, the
need and the poll entry optional (see "A pollable effect" below). The
effect takes the def's arguments as JS values: a `U32` is a number, a
`Nat` a `BigInt`, a `String` a string, a constructor
`{$: CID(Name), field: value}`, a handle its host value (a descriptor).
`CID(Name)` is the constructor's tag, read as on the C side. It returns
the answer the same way: `io_done(v)`, `io_fail(code)`,
`io_tup(handle, result)`, `{$: CID(Unit)}`.

The need is a function that returns `{read: true}` or `{time: true}`. A
blocking effect takes one more argument, `k`, and parks with
`io_park_on(fd, out, k, more)`: it returns `undefined`, and the loop calls
`more()` when `fd` is ready; `more` answers the value, or `undefined` to
park again. Add an absolute `performance.now()` deadline as a fifth
argument to also wake on time. `io_sys()` is `libc` through `bun:ffi`
(`read`, `recv`, `select`, `errno`); `tcp_accept.js` shows the full shape.

## A pollable effect

`IO.poll(ms, act)` (see `bend2/base.bend`) runs `act` until it answers or
would wait. It can only hold an effect *before* the effect starts: the loop
checks, before calling it, whether it would wait, and if so keeps the
untouched request as the `rest` of `Wait{rest}`. `IO.resume(rest)` later
runs it as if for the first time, `IO.cancel(rest)` answers it cancelled
without running it, and a dropped `rest` is a plain term that frees itself.
So an effect is never interrupted halfway: from `IO.poll`'s view it has
two states, not started (holdable) or started (runs to its end).

An effect declares nothing by default, and that is always safe: `IO.poll`
runs it as usual and waits for it, past `ms`. Declare it pollable only if
all of these hold:

1. **Its first wait is on a handle, and the handle is its first argument.**
   The loop checks `f[0]` (in JS, the first argument) for readable or
   writable before running the effect. If the effect waits on anything
   else first (a second descriptor, a timer, work on a helper thread),
   declare nothing.
2. **Ready means it can start.** When the handle is ready, the effect does
   its work as usual. If it still has to park (a spurious wakeup, or a
   send that fills the buffer halfway), that is fine: it has started, so
   it runs to its end, and `IO.poll` waits for it.
3. **It answers `(handle, Result<&1, &1, U32 & String, X>)`**, as every
   effect on a handle in Base does. `IO.cancel` answers a held request
   with `(handle, Fail{(ECANCELED, text)})` in its place: the runtime builds
   that value itself, and drops the request's other arguments.

Then declare it:

- **C:** add `IO_HAND` to the need, with `IO_IN` (wait for readable) or
  `IO_OUT` (writable) for an effect that tries at once, or keep `IO_READ`
  for one the loop parks until readable:
  `io_eff(CID(Socket.peek), socket_peek_run, IO_IN | IO_HAND)`.
  `IO_IN` and `IO_OUT` change nothing outside `IO.poll`: the effect still
  runs at once and parks itself with `io_wait_on`.
- **JS:** pass the poll entry `{ fd: "in" }` or `{ fd: "out" }` as the
  fourth argument: `io_eff(CID(Socket.peek), socket_peek, undefined,
  { fd: "in" })`. The entry's other fields (`wait`, `cancel`, `list`,
  `time`) are Base's own, for channels and sleep: do not use them.

Declare both lanes alike, or the two builds poll differently.
`tcp_recv.c`, `tcp_send.c`, `tcp_accept.c` and their `.js` twins are the
reference.

**What a wrong declaration breaks.** The runtime trusts the declaration;
nothing checks it against the def's type yet.

- `IO_HAND` on an effect that does not answer `(handle, Result)`: a
  cancelled request answers a value of the wrong shape, and the program
  crashes, or reads garbage, where it matches on it.
- A handle that is not the first argument: the loop checks readiness on
  the wrong descriptor, so a request is held when it could run, or runs
  (and blocks the poll) when it should be held.
- A wait that is not the effect's first: a request the loop thought
  ready still waits, so `IO.poll` waits past `ms`.

## A complete example

`main.bend`:

```python
import Base

def Clock.now() -> IO(U32):
  import "./clock.c"
  import "./clock.js"

def main() -> IO(Unit):
  do IO<Unit>:
    t : U32 <- Clock.now()
    IO.print("ms since boot: " ++ U32.show(t))
```

`clock.c`:

```c
Term clock_now_run(Env e, Term* f, IoWork* w) {
  return (Term)(uint32_t)(io_tick() / 1000000ull);
}

static void __attribute__((constructor)) clock_now_use(void) {
  io_eff(CID(Clock.now), clock_now_run, 0);
}
```

`clock.js`:

```js
function clock_now() {
  return Math.floor(performance.now()) >>> 0;
}

io_eff(CID(Clock.now), clock_now);
```

`bend main.bend -o main && ./main` prints a line; so do `bend main.bend -o
main.js && bun main.js` and `bend main.bend`. The output name must not be
one of the effect's files.

## Compatibility

The C side tracks the exact compiler version: the names above are the
runtime's internals, and a release may rename any of them. There is no ABI
promise. Rebuild your effects with every update.
