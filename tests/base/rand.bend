# CSPRNG integration by Victor Duarte Melo (Fr0ggy)
# September 18, 2026
# The original Rnd API is preserved exactly for full source and behavior compatibility.
# rnew, rnext and rrange remain the original deterministic xorshift32 implementation.
# The secure API gets fresh U32 values from the operating system CSPRNG through IO.random_u32.
# Linux uses getrandom, macOS uses arc4random_buf and JavaScript uses node crypto.
# rrange.secure uses rejection sampling so every value in the requested range is unbiased.
import Base

type Rnd is Data:
  Rnd{state: U32}

law rnew.if:
  for +seed : U32
  for z     : Bool
  Rnd

def rnew.if(seed, z):
  match z:
    case True{}:
      Rnd{2654435769}
    case False{}:
      Rnd{seed}

law rnew:
  for +seed: U32
  Rnd

def rnew(seed):
  rnew.if(seed, U32.is_zero(seed))

law rnext:
  for r: Rnd
  (Rnd & U32)

def rnext(r):
  match r:
    case Rnd{+s0}:
      +a = U32.xor(s0, U32.shln(s0, 13n))
      +b = U32.xor(a, U32.shrn(a, 17n))
      +c = U32.xor(b, U32.shln(b, 5n))
      (Rnd{c}, c)

law rrange.go:
  for n  : U32
  for rx : Rnd & U32
  (Rnd & U32)

def rrange.go(n, rx):
  (r2, x) = rx
  (r2, U32.mod(x, n))

law rrange:
  for r: Rnd
  for n: U32
  (Rnd & U32)

def rrange(r, n):
  rrange.go(n, rnext(r))

# SecureRnd carries no external resource. Each secure draw asks the runtime CSPRNG directly.
type SecureRnd is Type:
  SecureRnd{}

law rnew.secure:
  IO(SecureRnd)

def rnew.secure():
  IO.pure(SecureRnd, SecureRnd{})

law rclose.secure:
  for r: SecureRnd
  IO(Unit)

def rclose.secure(r):
  match r:
    case SecureRnd{}:
      IO.pure(Unit, Unit{})

law rnext.secure:
  for r: SecureRnd
  IO(SecureRnd & U32)

def rnext.secure(r):
  match r:
    case SecureRnd{}:
      do IO<SecureRnd & U32>:
        x : U32 <- IO.try(U32, IO.random_u32())
        return (SecureRnd{}, x)

type SecureDraw is Type:
  SecureDraw{rnd: SecureRnd, x: U32, ok: Bool}

law secure.draw.got:
  for +threshold: U32
  for rx: SecureRnd & U32
  IO(SecureDraw)

def secure.draw.got(threshold, rx):
  (r, +x) = rx
  IO.pure(SecureDraw, SecureDraw{r, x, U32.is_ge(x, threshold)})

law secure.draw:
  for r: SecureRnd
  for +threshold: U32
  IO(SecureDraw)

def secure.draw(r, threshold):
  IO.bind(SecureRnd & U32, SecureDraw,
    rnext.secure(r), secure.draw.got(threshold))

law rrange.secure.loop:
  for fuel: Nat
  for +n: U32
  for +threshold: U32
  for d: SecureDraw
  IO(SecureRnd & U32)

def rrange.secure.loop(fuel, n, threshold, d):
  match fuel:
    case 0n:
      match d:
        case SecureDraw{rnd, x, ok}:
          match ok:
            case True{}:
              IO.pure(SecureRnd & U32, (rnd, U32.mod(x, n)))
            case False{}:
              do IO<SecureRnd & U32>:
                u : Unit <- rclose.secure(rnd)
                IO.die(SecureRnd & U32, 1, "rand: secure range rejection limit reached")
    case 1n+p:
      match d:
        case SecureDraw{rnd, x, ok}:
          match ok:
            case True{}:
              IO.pure(SecureRnd & U32, (rnd, U32.mod(x, n)))
            case False{}:
              IO.bind(SecureDraw, SecureRnd & U32,
                secure.draw(rnd, threshold),
                next => rrange.secure.loop(p, n, threshold, next))

law rrange.secure.if:
  for r: SecureRnd
  for +n: U32
  for z: Bool
  IO(SecureRnd & U32)

def rrange.secure.if(r, n, z):
  match z:
    case True{}:
      do IO<SecureRnd & U32>:
        u : Unit <- rclose.secure(r)
        IO.die(SecureRnd & U32, 1, "rand: secure range bound must be greater than zero")
    case False{}:
      +threshold = U32.mod(U32.sub(0, n), n)
      do IO<SecureRnd & U32>:
        d : SecureDraw <- secure.draw(r, threshold)
        rrange.secure.loop(127n, n, threshold, d)

# Returns a uniform value in the interval from zero inclusive to n exclusive.
law rrange.secure:
  for r: SecureRnd
  for +n: U32
  IO(SecureRnd & U32)

def rrange.secure(r, n):
  rrange.secure.if(r, n, U32.is_zero(n))

law go.c:
  for a  : U32
  for b  : U32
  for rc : Rnd & U32
  U32

def go.c(a, b, rc):
  (r3, c) = rc
  U32.add(U32.add(U32.mul(U32.mod(a, 1000), 10000), U32.mul(U32.mod(b, 1000), 10)), c)

law go.b:
  for a  : U32
  for rb : Rnd & U32
  U32

def go.b(a, rb):
  (r2, b) = rb
  go.c(a, b, rrange(r2, 10))

law go.a:
  for ra: Rnd & U32
  U32

def go.a(ra):
  (r1, a) = ra
  go.b(a, rnext(r1))

law go:
  for r: Rnd
  U32

def go(r):
  go.a(rnext(r))

law main.out:
  U32

def main.out():
  go(rnew(42))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|4323489
