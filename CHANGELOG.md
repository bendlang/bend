# Changelog

Each release names what changed for a user. `bend update` installs the
latest one; the GitHub release carries the same notes.

## 2.0.16 (2026-09-19)

- The template memo and the compiler's show table key on the syntax tree
  (`term_key`), not on a printed term: two `~` arguments share an instance
  only when they are the same term (#838).
- A template instance is picked after the enclosing `( .. : T)` closes, so
  its operators carry that namespace (#841).
- A def that is a template instance counts as unsafe: a file with a
  template prints "All terms check, with N unsafe annotations." until the
  checker verifies template expansion itself.

## 2.0.15 (2026-09-19)

- `U32` literals as `~` arguments instantiate again (2.0.14 broke them).

## 2.0.14 (2026-09-19)

- Template keys carry no sugar, so NaN payloads that print alike no longer
  share an instance (#838).
- `bend guide shaders` states at the top that AIs wrote it.

## 2.0.13 (2026-09-18)

- `IO.random_u32`, a CSPRNG (#837).
- `File.read_at`, `File.size`, `File.write_bytes` (#823).
- A UTF-8 byte order mark survives on the JS lane (#833).
- A forky continuation that becomes ready during a grow turn runs in place
  (#831).
- A Nix flake: `nix profile install github:bendlang/bend` (#830).
- `bend guide effects` prints a note on the C and JS side of custom
  effects (#825).

## 2.0.12 (2026-09-18)

- Metal: `U32` division and remainder near 2^32 are exact (#824).
- Closure applies allocate no tasks in fork-free code (#832).
- The publisher refuses a file with no name before mining (#835).

## 2.0.11 (2026-09-18)

- Two `Array` shapes with the same leaves no longer share a template
  instance or a show descriptor (#834).

## 2.0.10 (2026-09-18)

- `bend guide shaders` prints "Shaders in Bend"; the guide's Extra section
  points to it.

## 2.0.9 (2026-09-18)

- `--help` is as before 2.0.8.

## 2.0.8 (2026-09-18)

- The installer downloads one executable per platform from a GitHub
  release, verified against a sha256 in the script, and installs nothing
  else. Bend never updates itself: `bend update` reruns the installer.
  Once a day `bend` asks bend-lang.com for the latest version, sending its
  version, OS and CPU type; `BEND_NO_TELEMETRY=1` turns that off.
- `+` on a pattern field is a quantity mark (#810).
- The hub client checks a file against the manifest's hash prefix again
  (2.0.6 refused every package).
- WONTFIX.txt gains a RUNTIME section.

## 2.0.7 (2026-09-18)

- `IO.args` answers the command line (#821).
- A `Nat` literal past `256n` is `U32.to_nat(n)` underneath (#779).
- The C runtime decodes UTF-8 as WHATWG does (#809).
- `String.length` is an intrinsic on JS (#798).
- An unbalanced `Array` traps on JS (#808).
- The verdict reads "All terms check, with N unsafe annotations."
- WONTFIX.txt lists what we will not change, and why.

## 2.0.6 (2026-09-18)

- Hub installs are atomic and pinned (#794, #787).
- The JS lane refuses names it cannot mangle apart (#790, #799) and scopes
  FFI to its file (#800); emit is linear in program size (#785).
- Nullary imported constructors (#815); `Char.to_upper`/`to_lower` on
  control chars (#803); `F32.read` follows one grammar on C and JS (#801).

## 2.0.5 (2026-09-17)

- `CUDA_HOME` names the CUDA install; `lib` and `lib64` both link (#771).
- `$CC` is tried first, then `clang` and `clang-NN` (#773).
- The runtime's reservation halves until it fits, down to 8 GiB (#774).
- comp.ts passes strict TypeScript (#778).

## 2.0.4 (2026-09-17)

- A `!`-free program on macOS builds as plain C (#769).
- The descent error states its left-to-right rule; the guide says it too
  (#770).

## 2.0.3 (2026-09-17)

- A plain parallel call forks on the CPU pool (#767).
- Hub paths are validated before any directory is made (#768).

## 2.0.2 (2026-09-17)

- The Metal bag stays at 128 groups; only CUDA sizes it to the L2.

## 2.0.1 (2026-09-17)

- The guide as revised on launch day.

## 2.0.0 (2026-09-17)

- Bend 2: a new type checker (an affine dependent type theory), a new
  compiler to C, Metal, CUDA and JavaScript, and a new runtime.
