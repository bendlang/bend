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

The host function is named after the def: lowercased, dots to underscores
(`clock_now`). The `.c` file serves `bend x.bend -o x`; the `.js` file
serves `bend x.bend -o x.js` and `bend x.bend`. Every effect in Base is
built this way: `bend2/effs/*.c` and `*.js` are the reference.

## The C side

The compiler splices your `.c` into the program's C source after the
runtime, so every runtime symbol is in scope. Define the effect and
register it in a constructor:

```c
Term clock_now_run(Env e, Term* f, IoWork* w);

static void __attribute__((constructor)) clock_now_use(void) {
  io_eff(CID_CLOCK_NOW, clock_now_run, 0);
}
```

`CID_X` is the def's name uppercased, dots to underscores. `f` holds the
def's arguments in order: a `U32` is the word (`(u32)f[0]`), a `String` is
taken with `io_cstr(e, f[0], &len)` (a `malloc`ed copy you free), a handle
with `io_hand_v(f[0])`. The last argument of `io_eff` is the need: `0` runs
the effect at once; `IO_READ` parks it until the handle in `f[0]` is
readable; `IO_TIME` parks it for `f[0]` milliseconds. Then the loop calls
the effect.

The effect returns a Term: a `U32` is `(Term)n`, `Unit` is
`term_pak(CID_UNIT, 0)`, a `String` is `io_str(e, p, n)`, a two-field
constructor is `io_node(e, CID_K, a, b, 0)`. A `Result` is `io_done(e, v)`
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
`io_wait_on(w, fd, POLLIN, more)` parks until `fd` is ready (`POLLIN` or
`POLLOUT`), then runs `more(e, w)` on the loop; `more` may call
`io_wait_on` again. Both return `IO_PARK`, which the effect returns.

`w` is the effect's scratch space: `hand`, `made`, `word`, `size`, `data`,
`text`, `code`. The runtime owns `w` and `f`. The effect owns `w->data`:
allocate it in the run function and free it in `pack`. In `bend2/effs/`,
`file_read.c` is the pattern for `io_work` and `tcp_recv.c` for `io_wait_on`.

## The JS side

The `.js` file is a plain script, wrapped in a closure; the compiler finds
the function by name. It takes the def's arguments as JS values: a `U32` is
a number, a `Nat` a `BigInt`, a `String` a string, a constructor
`{$: "Name", field: value}`, a handle its host value (a descriptor). It
returns the answer the same way: `io_done(v)`, `io_fail(code)`,
`io_tup(handle, result)`, `{$: "Unit"}`.

A need is a second function, `clock_now_need`, that returns `{read: true}`
or `{time: true}`. A blocking effect takes one more argument, `k`, and
parks with `io_park_on(fd, out, k, more)`: it returns `undefined`, and the
loop calls `more()` when `fd` is ready; `more` answers the value, or
`undefined` to park again. `io_sys()` is `libc` through `bun:ffi`
(`read`, `recv`, `poll`, `errno`); `tcp_recv.js` shows the full shape.

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
  io_eff(CID_CLOCK_NOW, clock_now_run, 0);
}
```

`clock.js`:

```js
function clock_now() {
  return Math.floor(performance.now()) >>> 0;
}
```

`bend main.bend -o main && ./main` prints a line; so do `bend main.bend -o
main.js && bun main.js` and `bend main.bend`. The output name must not be
one of the effect's files.

## Compatibility

The C side tracks the exact compiler version: the names above are the
runtime's internals, and a release may rename any of them. There is no ABI
promise. Rebuild your effects with every update.
