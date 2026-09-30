import Base
# Helpers copied unchanged from pinned upstream Mandelbrot.
def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def sel.go(x: U32, y: U32, z: Bool) -> U32:
  match z:
    case True{}:
      x
    case False{}:
      y

def sel(t: U32, x: U32, y: U32) -> U32:
  sel.go(x, y, U32.is_zero(t))

# arithmetic shift right by 8 over two's-complement u32
def asr8(+v: U32) -> U32:
  U32.or(U32.shrn(v, 8n), sel(U32.shrn(v, 31n), 0, 4278190080))

# ITERS branchless escape-time iterations: z steps while esc == 0 and
# freezes after (sel), it counts the pre-escape iterations
def mit(n: Nat, +cr: U32, +ci: U32, +zr: U32, +zi: U32, esc: U32,
        it: U32) -> U32:
  match n:
    case 0n:
      it
    case 1n+p:
      +r2 = asr8(U32.mul(zr, zr))
      +i2 = asr8(U32.mul(zi, zi))
      +e2 = U32.or(esc, b2u(U32.is_gt(U32.add(r2, i2), 1024)))
      nzr = U32.add(U32.sub(r2, i2), cr)
      nzi = U32.add(asr8(U32.mul(2, U32.mul(zr, zi))), ci)
      sr = sel(e2, nzr, zr)
      si = sel(e2, nzi, zi)
      mit(p, cr, ci, sr, si, e2, U32.add(it, b2u(U32.is_zero(e2))))

# Phase29: exact upstream helper bodies above; only these adapters are new.
def bench(size: U32, +seed: U32) -> U32:
  cr = U32.sub(U32.and(seed, 1023), 512)
  ci = U32.sub(U32.and(U32.shrn(seed, 10n), 1023), 512)
  mit(U32.to_nat(size), cr, ci, 0, 0, 0, 0)

def point(n: U32, cr: U32, ci: U32, zr: U32, zi: U32, esc: U32, it: U32) -> U32:
  mit(U32.to_nat(n), cr, ci, zr, zi, esc, it)
