# Math: a C math.h-style F32 library for Bend 2.
#
# Bend 2 has one native floating-point format, F32.  This module therefore
# exposes one spelling per math.h function instead of C's float/double/long
# double suffix families.  Functions which return a C signed integer use S32,
# a small sign/magnitude type, because Bend 2 has no native signed integer.
# Consequently llround/llrint, scalbln, and the integer arguments of the C23
# pown/rootn extras are intentionally S32 adaptations rather than pretending
# Bend has C long/long long storage that it does not have.
#
# Bend also has no C floating-point environment.  nearbyint/rint use the
# language's deterministic round-to-nearest-even operation and
# math_errhandling() reports 0; errno/fenv exceptions are not emulated.
#
# The M_* definitions mirror the traditional math.h constants.  Bend has no
# value macros, so each constant is a nullary def: M_PI(), M_SQRT2(), ...

import Base

# Types
# =====

type S32 is Data:
  SNeg{mag: U32}
  SPos{mag: U32}

type FPClass is Data:
  FP_NAN{}
  FP_INFINITE{}
  FP_ZERO{}
  FP_SUBNORMAL{}
  FP_NORMAL{}

# Bit construction
# ================

def from_bits(x: U32) -> F32:
  match x:
    case U32{w}:
      F32{w}

# Constants
# =========

# Traditional BSD/glibc math constants, rounded to Bend's F32.
def M_E() -> F32:
  2.7182818284590452354

def M_LOG2E() -> F32:
  1.4426950408889634074

def M_LOG10E() -> F32:
  0.43429448190325182765

def M_LN2() -> F32:
  0.69314718055994530942

def M_LN10() -> F32:
  2.3025850929940456840

def M_PI() -> F32:
  3.14159265358979323846

def M_PI_2() -> F32:
  1.57079632679489661923

def M_PI_4() -> F32:
  0.78539816339744830962

def M_1_PI() -> F32:
  0.31830988618379067154

def M_2_PI() -> F32:
  0.63661977236758134308

def M_2_SQRTPI() -> F32:
  1.12837916709551257390

def M_SQRT2() -> F32:
  1.41421356237309504880

def M_SQRT1_2() -> F32:
  0.70710678118654752440

# IEEE-754 binary32 constants.  These are made from bits so they do not depend
# on the source parser accepting spellings such as inf or nan.
def INFINITY() -> F32:
  from_bits(2139095040)

def HUGE_VAL() -> F32:
  INFINITY()

def HUGE_VALF() -> F32:
  INFINITY()

def NAN() -> F32:
  from_bits(2143289344)

# math_errhandling has no errno/fenv analogue in Bend; keep the C bit values
# available while reporting that neither mechanism is provided.
def MATH_ERRNO() -> U32:
  1

def MATH_ERREXCEPT() -> U32:
  2

def math_errhandling() -> U32:
  0

# Signed integer bridge
# =====================

def S32.zero() -> S32:
  SPos{0}

def S32.neg.if(mag: U32, zero: Bool) -> S32:
  match zero:
    case True{}:
      SPos{0}
    case False{}:
      SNeg{mag}

def S32.neg(+mag: U32) -> S32:
  S32.neg.if(mag, U32.is_eq(mag, 0))

def S32.pos(mag: U32) -> S32:
  SPos{mag}

def S32.to_f32(x: S32) -> F32:
  match x:
    case SNeg{mag}:
      F32.neg(U32.to_f32(mag))
    case SPos{mag}:
      U32.to_f32(mag)

def S32.from_f32(+x: F32) -> S32:
  Bool.pick(S32, F32.is_lt(x, 0.0),
    SNeg{F32.to_u32(F32.abs(x))}, SPos{F32.to_u32(x)})

def S32.is_neg(x: S32) -> Bool:
  match x:
    case SNeg{mag}:
      U32.is_ne(mag, 0)
    case SPos{mag}:
      False{}

def S32.mag(x: S32) -> U32:
  match x:
    case SNeg{mag}:
      mag
    case SPos{mag}:
      mag

def S32.is_odd(x: S32) -> Bool:
  U32.is_ne(U32.and(S32.mag(x), 1), 0)

def S32.negate.pos(mag: U32, zero: Bool) -> S32:
  match zero:
    case True{}:
      SPos{0}
    case False{}:
      SNeg{mag}

def S32.negate(x: S32) -> S32:
  match x:
    case SNeg{mag}:
      SPos{mag}
    case SPos{+mag}:
      S32.negate.pos(mag, U32.is_eq(mag, 0))

def S32.show(x: S32) -> String:
  match x:
    case SNeg{mag}:
      "-" ++ U32.show(mag)
    case SPos{mag}:
      U32.show(mag)

# C uses implementation-defined integer sentinels for ilogb(0) and
# ilogb(NaN).  These names make the Bend choice explicit.
def FP_ILOGB0() -> S32:
  SNeg{2147483648}

def FP_ILOGBNAN() -> S32:
  SNeg{2147483648}

# Bit helpers and classification
# ==============================

def bits(x: F32) -> U32:
  F32.bits(x)

def signbit(x: F32) -> Bool:
  U32.is_ne(U32.and(F32.bits(x), 2147483648), 0)

def isnan(x: F32) -> Bool:
  +b = F32.bits(x)
  e = U32.and(b, 2139095040)
  m = U32.and(b, 8388607)
  Bool.and(U32.is_eq(e, 2139095040), U32.is_ne(m, 0))

def isinf(x: F32) -> Bool:
  U32.is_eq(U32.and(F32.bits(x), 2147483647), 2139095040)

def isfinite(x: F32) -> Bool:
  U32.is_ne(U32.and(F32.bits(x), 2139095040), 2139095040)

def isnormal(x: F32) -> Bool:
  +e = U32.and(F32.bits(x), 2139095040)
  Bool.and(U32.is_ne(e, 0), U32.is_ne(e, 2139095040))

def fpclassify(+x: F32) -> FPClass:
  +b = F32.bits(x)
  +e = U32.and(b, 2139095040)
  m = U32.and(b, 8388607)
  n = Bool.and(U32.is_eq(e, 2139095040), U32.is_ne(m, 0))
  i = U32.is_eq(U32.and(b, 2147483647), 2139095040)
  z = U32.is_eq(U32.and(b, 2147483647), 0)
  sub = U32.is_eq(e, 0)
  Bool.pick(FPClass, n, FP_NAN{},
    Bool.pick(FPClass, i, FP_INFINITE{},
    Bool.pick(FPClass, z, FP_ZERO{},
    Bool.pick(FPClass, sub, FP_SUBNORMAL{}, FP_NORMAL{}))))

def isgreater(x: F32, y: F32) -> Bool:
  F32.is_gt(x, y)

def isgreaterequal(x: F32, y: F32) -> Bool:
  F32.is_ge(x, y)

def isless(x: F32, y: F32) -> Bool:
  F32.is_lt(x, y)

def islessequal(x: F32, y: F32) -> Bool:
  F32.is_le(x, y)

def islessgreater(+x: F32, +y: F32) -> Bool:
  Bool.or(F32.is_lt(x, y), F32.is_gt(x, y))

def isunordered(+x: F32, +y: F32) -> Bool:
  Bool.or(isnan(x), isnan(y))

# Elementary operations
# =====================

def fabs(x: F32) -> F32:
  F32.abs(x)

def copysign(+x: F32, y: F32) -> F32:
  xb = U32.and(F32.bits(x), 2147483647)
  yb = U32.and(F32.bits(y), 2147483648)
  from_bits(U32.or(xb, yb))

def fmin(+x: F32, +y: F32) -> F32:
  both_zero = Bool.and(F32.is_eq(x, 0.0), F32.is_eq(y, 0.0))
  z = Bool.pick(F32, Bool.or(signbit(x), signbit(y)),
    from_bits(2147483648), 0.0)
  core = Bool.pick(F32, both_zero, z, F32.min(x, y))
  yn = Bool.pick(F32, isnan(y), x, core)
  Bool.pick(F32, isnan(x), y, yn)

def fmax(+x: F32, +y: F32) -> F32:
  both_zero = Bool.and(F32.is_eq(x, 0.0), F32.is_eq(y, 0.0))
  z = Bool.pick(F32, Bool.and(signbit(x), signbit(y)),
    from_bits(2147483648), 0.0)
  core = Bool.pick(F32, both_zero, z, F32.max(x, y))
  yn = Bool.pick(F32, isnan(y), x, core)
  Bool.pick(F32, isnan(x), y, yn)

def fdim(+x: F32, +y: F32) -> F32:
  Bool.pick(F32, Bool.or(isnan(x), isnan(y)), NAN(),
    Bool.pick(F32, F32.is_gt(x, y), F32.sub(x, y), 0.0))

# Fused multiply-add through the F32 compiler primitive.
def fma(x: F32, y: F32, z: F32) -> F32:
  F32.fma(x, y, z)

def sqrt(x: F32) -> F32:
  F32.sqrt(x)

def cbrt(x: F32) -> F32:
  F32.cbrt(x)

def hypot(x: F32, y: F32) -> F32:
  F32.hypot(x, y)

def pow(x: F32, y: F32) -> F32:
  F32.pow(x, y)

# Exponential and logarithmic functions
# =====================================

def exp(x: F32) -> F32:
  F32.exp(x)

def exp2(x: F32) -> F32:
  F32.exp2(x)

def exp10(x: F32) -> F32:
  F32.pow(10.0, x)

def expm1(x: F32) -> F32:
  F32.expm1(x)

def log(x: F32) -> F32:
  F32.log(x)

def log2(x: F32) -> F32:
  F32.log2(x)

def log10(x: F32) -> F32:
  F32.log10(x)

def log1p(x: F32) -> F32:
  F32.log1p(x)

# C23-style convenience spellings.  The p1/m1 forms use backend operations
# so the critical product/division is evaluated wider than F32 before the
# single final binary32 rounding.
def exp2m1(x: F32) -> F32:
  F32.exp2m1(x)

def exp10m1(x: F32) -> F32:
  F32.exp10m1(x)

def logp1(x: F32) -> F32:
  F32.log1p(x)

def log2p1(x: F32) -> F32:
  F32.log2p1(x)

def log10p1(x: F32) -> F32:
  F32.log10p1(x)

# Trigonometric functions
# =======================

def sin(x: F32) -> F32:
  F32.sin(x)

def cos(x: F32) -> F32:
  F32.cos(x)

def tan(x: F32) -> F32:
  F32.tan(x)

def asin(x: F32) -> F32:
  F32.asin(x)

def acos(x: F32) -> F32:
  F32.acos(x)

def atan(x: F32) -> F32:
  F32.atan(x)

def atan2(y: F32, x: F32) -> F32:
  F32.atan2(y, x)

def sincos(+x: F32) -> F32 & F32:
  (F32.sin(x), F32.cos(x))

# pi-scaled forms use backend primitives with exact integer/half-integer
# reduction instead of multiplying a large F32 by an approximation of pi.
def sinpi(x: F32) -> F32:
  F32.sinpi(x)

def cospi(x: F32) -> F32:
  F32.cospi(x)

def tanpi(x: F32) -> F32:
  F32.tanpi(x)

def asinpi(x: F32) -> F32:
  F32.asinpi(x)

def acospi(x: F32) -> F32:
  F32.acospi(x)

def atanpi(x: F32) -> F32:
  F32.atanpi(x)

def atan2pi(y: F32, x: F32) -> F32:
  F32.atan2pi(y, x)

# Hyperbolic functions
# ====================

def sinh(x: F32) -> F32:
  F32.sinh(x)

def cosh(x: F32) -> F32:
  F32.cosh(x)

def tanh(x: F32) -> F32:
  F32.tanh(x)

def asinh(x: F32) -> F32:
  F32.asinh(x)

def acosh(x: F32) -> F32:
  F32.acosh(x)

def atanh(x: F32) -> F32:
  F32.atanh(x)

# Decomposition and scaling
# =========================

def scalbn(x: F32, n: S32) -> F32:
  match n:
    case SNeg{mag}:
      F32.scalbn_neg(x, mag)
    case SPos{mag}:
      F32.scalbn_pos(x, mag)

def scalbln(x: F32, n: S32) -> F32:
  scalbn(x, n)

def ldexp(x: F32, n: S32) -> F32:
  scalbn(x, n)

def frexp.regular(+x: F32) -> F32 & S32:
  +e = S32.from_f32(F32.add(F32.logb(F32.abs(x)), 1.0))
  (scalbn(x, S32.negate(e)), e)

def frexp.if(x: F32, special: Bool) -> F32 & S32:
  match special:
    case True{}:
      (x, S32.zero())
    case False{}:
      frexp.regular(x)

def frexp(+x: F32) -> F32 & S32:
  frexp.if(x, Bool.or(F32.is_eq(x, 0.0), Bool.or(isnan(x), isinf(x))))

def modf.finite(+x: F32) -> F32 & F32:
  +i = F32.trunc(x)
  +f = F32.sub(x, i)
  frac = Bool.pick(F32, F32.is_eq(f, 0.0), copysign(0.0, x), f)
  (frac, i)

def modf.inf(+x: F32, inf: Bool) -> F32 & F32:
  match inf:
    case True{}:
      (copysign(0.0, x), x)
    case False{}:
      modf.finite(x)

def modf.nan(+x: F32, nanv: Bool) -> F32 & F32:
  match nanv:
    case True{}:
      (x, x)
    case False{}:
      modf.inf(x, isinf(x))

def modf(+x: F32) -> F32 & F32:
  modf.nan(x, isnan(x))

def logb(x: F32) -> F32:
  F32.logb(x)

def ilogb.zero(x: F32, zero: Bool) -> S32:
  match zero:
    case True{}:
      FP_ILOGB0()
    case False{}:
      S32.from_f32(F32.logb(x))

def ilogb.inf(+x: F32, inf: Bool) -> S32:
  match inf:
    case True{}:
      SPos{2147483647}
    case False{}:
      ilogb.zero(x, F32.is_eq(x, 0.0))

def ilogb.nan(+x: F32, nanv: Bool) -> S32:
  match nanv:
    case True{}:
      FP_ILOGBNAN()
    case False{}:
      ilogb.inf(x, isinf(x))

def ilogb(+x: F32) -> S32:
  ilogb.nan(x, isnan(x))

def ceil(x: F32) -> F32:
  F32.ceil(x)

def floor(x: F32) -> F32:
  F32.floor(x)

def trunc(x: F32) -> F32:
  F32.trunc(x)

def round.small(+x: F32, neg: Bool) -> F32:
  match neg:
    case True{}:
      F32.ceil(F32.sub(x, 0.5))
    case False{}:
      F32.floor(F32.add(x, 0.5))

def round.large(+x: F32, large: Bool) -> F32:
  match large:
    case True{}:
      x
    case False{}:
      round.small(x, signbit(x))

def round(+x: F32) -> F32:
  # Every binary32 value with |x| >= 2^23 is already integral.  Returning it
  # directly avoids the x +/- 0.5 rounding bug at large odd integers.
  round.large(x, F32.is_ge(F32.abs(x), 8388608.0))

def roundeven(x: F32) -> F32:
  F32.roundeven(x)

def nearbyint(x: F32) -> F32:
  roundeven(x)

def rint(x: F32) -> F32:
  roundeven(x)

def lround(x: F32) -> S32:
  S32.from_f32(round(x))

def llround(x: F32) -> S32:
  S32.from_f32(round(x))

def lrint(x: F32) -> S32:
  S32.from_f32(rint(x))

def llrint(x: F32) -> S32:
  S32.from_f32(rint(x))

# Remainders
# ==========

def fmod(x: F32, y: F32) -> F32:
  F32.mod(x, y)

def remainder(x: F32, y: F32) -> F32:
  F32.remainder(x, y)

# C only guarantees the sign and at least the low three quotient bits.  We
# return exactly those three bits in S32, avoiding overflow for huge x/y.
def remquo.code(code: U32, neg: Bool) -> S32:
  match neg:
    case True{}:
      S32.neg(U32.and(code, 7))
    case False{}:
      SPos{U32.and(code, 7)}

def remquo(+x: F32, +y: F32) -> F32 & S32:
  +r = F32.remainder(x, y)
  +q = F32.remquo_code(x, y)
  (r, remquo.code(q, U32.is_ne(U32.and(q, 2147483648), 0)))

# nextafter / nexttoward
# =====================

def nextafter.zero(y: F32) -> F32:
  s = U32.and(F32.bits(y), 2147483648)
  from_bits(U32.or(s, 1))

def nextafter.step(+x: F32, +y: F32) -> F32:
  +b = F32.bits(x)
  sx = signbit(x)
  up = F32.is_lt(x, y)
  down_bits = from_bits(U32.sub(b, 1))
  up_bits = from_bits(U32.add(b, 1))
  Bool.pick(F32, Bool.not(Bool.xor(sx, up)), down_bits, up_bits)

def nextafter(+x: F32, +y: F32) -> F32:
  stepped = nextafter.step(x, y)
  zeroed = Bool.pick(F32, F32.is_eq(x, 0.0), nextafter.zero(y), stepped)
  equaled = Bool.pick(F32, F32.is_eq(x, y), y, zeroed)
  Bool.pick(F32, Bool.or(isnan(x), isnan(y)), F32.add(x, y), equaled)

def nexttoward(x: F32, y: F32) -> F32:
  nextafter(x, y)

# Error and gamma functions
# =========================

def erf(x: F32) -> F32:
  F32.erf(x)

def erfc(x: F32) -> F32:
  F32.erfc(x)

def tgamma(x: F32) -> F32:
  F32.tgamma(x)

def lgamma(x: F32) -> F32:
  F32.lgamma(x)

# C's nan(tagp); Bend does not expose NaN payload parsing, so tag is accepted
# for API familiarity and a canonical quiet NaN is returned.
def nan(tag: String) -> F32:
  NAN()

# Integer-power helpers (C23 family)
# ==================================

def pown(x: F32, n: S32) -> F32:
  match n:
    case SNeg{mag}:
      F32.pown_neg(x, mag)
    case SPos{mag}:
      F32.pown_pos(x, mag)

def powr.zero_y(y: F32, zero: Bool) -> F32:
  match zero:
    case True{}:
      NAN()
    case False{}:
      Bool.pick(F32, F32.is_lt(y, 0.0), INFINITY(), 0.0)

def powr.xzero(+x: F32, +y: F32, zero: Bool) -> F32:
  match zero:
    case True{}:
      powr.zero_y(y, F32.is_eq(y, 0.0))
    case False{}:
      F32.pow(x, y)

def powr.one_inf(+x: F32, +y: F32, bad: Bool) -> F32:
  match bad:
    case True{}:
      NAN()
    case False{}:
      powr.xzero(x, y, F32.is_eq(x, 0.0))

def powr.inf_zero(+x: F32, +y: F32, bad: Bool) -> F32:
  match bad:
    case True{}:
      NAN()
    case False{}:
      powr.one_inf(x, y, Bool.and(F32.is_eq(x, 1.0), isinf(y)))

def powr.neg(+x: F32, +y: F32, neg: Bool) -> F32:
  match neg:
    case True{}:
      NAN()
    case False{}:
      powr.inf_zero(x, y, Bool.and(isinf(x), F32.is_eq(y, 0.0)))

def powr.nan(+x: F32, +y: F32, nanv: Bool) -> F32:
  match nanv:
    case True{}:
      NAN()
    case False{}:
      powr.neg(x, y, F32.is_lt(x, 0.0))

def powr.eval(+x: F32, +y: F32) -> F32:
  # Unlike pow, powr has deliberately stricter zero/one/infinity semantics.
  powr.nan(x, y, Bool.or(isnan(x), isnan(y)))

# C23 spells this API as powr(y, x) and computes x^y.  Keep that unusual
# argument order so code ported from <math.h> does not silently change meaning.
def powr(+y: F32, +x: F32) -> F32:
  powr.eval(x, y)

def rootn.neg(x: F32, nf: F32, odd: Bool) -> F32:
  match odd:
    case True{}:
      F32.neg(F32.pow(F32.abs(x), F32.div(1.0, nf)))
    case False{}:
      NAN()

def rootn.sign(+x: F32, +n: S32, nf: F32, neg: Bool) -> F32:
  match neg:
    case True{}:
      rootn.neg(x, nf, S32.is_odd(n))
    case False{}:
      F32.pow(x, F32.div(1.0, nf))

def rootn.nonzero(+x: F32, +n: S32) -> F32:
  nf = S32.to_f32(n)
  rootn.sign(x, n, nf, signbit(x))

def rootn.zero.neg(x: F32, odd: Bool) -> F32:
  match odd:
    case True{}:
      copysign(INFINITY(), x)
    case False{}:
      INFINITY()

def rootn.zero.pos(x: F32, odd: Bool) -> F32:
  match odd:
    case True{}:
      x
    case False{}:
      0.0

def rootn.zero.sign(+x: F32, +n: S32, negn: Bool) -> F32:
  match negn:
    case True{}:
      rootn.zero.neg(x, S32.is_odd(n))
    case False{}:
      rootn.zero.pos(x, S32.is_odd(n))

def rootn.xzero(+x: F32, +n: S32, zero: Bool) -> F32:
  match zero:
    case True{}:
      rootn.zero.sign(x, n, S32.is_neg(n))
    case False{}:
      rootn.nonzero(x, n)

def rootn.nzero(+x: F32, +n: S32, zero: Bool) -> F32:
  match zero:
    case True{}:
      NAN()
    case False{}:
      rootn.xzero(x, n, F32.is_eq(x, 0.0))

def rootn(+x: F32, +n: S32) -> F32:
  rootn.nzero(x, n, U32.is_eq(S32.mag(n), 0))

def rsqrt(x: F32) -> F32:
  F32.rsqrt(x)
