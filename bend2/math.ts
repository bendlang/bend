// Runtime support for bend2/math.bend. Kept separate from comp.ts so the
// compiler core remains within its repository size gate.

const CMPS = "is_eq:==:=== is_ne:!=:!== is_lt:< is_le:<= is_gt:> is_ge:>=";

function tpl_ops(pre: string, names: string, C: string, JS: string) {
  const out: Record<string, { C: string; JS: string; call?: boolean }> = {};
  for (const p of names.split(" ")) {
    const [k, o = k, jo = o] = p.split(":");
    out[pre + k] = { C: C.replaceAll("$o", o), JS: JS.replaceAll("$o", jo) };
  }
  return out;
}

export const OPERATIONS = {
  ...tpl_ops("f32_", "add:+ sub:- mul:* div:/",
    "f32_rewrap(f32_unbox($0) $o f32_unbox($1))", "Math.fround($0 $o $1)"),
  f32_neg: {
    C:  "f32_rewrap(-f32_unbox($0))",
    JS: "(-$0)",
  },
  ...tpl_ops("f32_", CMPS, "((u64)(f32_unbox($0) $o f32_unbox($1)))",
    "($0 $o $1)"),
  ...tpl_ops("f32_", "sqrt exp log log2 log10 sin cos tan asin acos atan"
    + " sinh cosh tanh floor ceil trunc abs:fabs:abs",
    "f32_rewrap((f32)$o(f32_unbox($0)))", "Math.fround(Math.$o($0))"),
  f32_pow: {
    C:  "f32_rewrap((f32)pow(f32_unbox($0), f32_unbox($1)))",
    JS: "f32_pow($0, $1)",
  },
  f32_atan2: {
    C:  "f32_rewrap((f32)atan2(f32_unbox($0), f32_unbox($1)))",
    JS: "Math.fround(Math.atan2($0, $1))",
  },
  f32_fma: {
    C:  "f32_rewrap(fmaf(f32_unbox($0), f32_unbox($1), f32_unbox($2)))",
    JS: "f32_fma($0, $1, $2)",
  },
  f32_cbrt: {
    C:  "f32_rewrap((f32)cbrt(f32_unbox($0)))",
    JS: "Math.fround(Math.cbrt($0))",
  },
  f32_hypot_native: {
    C:  "f32_rewrap((f32)hypot(f32_unbox($0), f32_unbox($1)))",
    JS: "Math.fround(Math.hypot($0, $1))",
  },
  f32_exp2: {
    C:  "f32_rewrap((f32)exp2(f32_unbox($0)))",
    JS: "Math.fround(2 ** $0)",
  },
  f32_expm1: {
    C:  "f32_rewrap((f32)expm1(f32_unbox($0)))",
    JS: "Math.fround(Math.expm1($0))",
  },
  f32_exp2m1: {
    C:  "f32_rewrap(bend_exp2m1f(f32_unbox($0)))",
    JS: "Math.fround(Math.expm1($0 * Math.LN2))",
  },
  f32_exp10m1: {
    C:  "f32_rewrap(bend_exp10m1f(f32_unbox($0)))",
    JS: "Math.fround(Math.expm1($0 * 2.30258509299404568402))",
  },
  f32_log1p: {
    C:  "f32_rewrap((f32)log1p(f32_unbox($0)))",
    JS: "Math.fround(Math.log1p($0))",
  },
  f32_log2p1: {
    C:  "f32_rewrap(bend_log2p1f(f32_unbox($0)))",
    JS: "Math.fround(Math.log1p($0) * Math.LOG2E)",
  },
  f32_log10p1: {
    C:  "f32_rewrap(bend_log10p1f(f32_unbox($0)))",
    JS: "Math.fround(Math.log1p($0) * Math.LOG10E)",
  },
  f32_asinh: {
    C:  "f32_rewrap((f32)asinh(f32_unbox($0)))",
    JS: "Math.fround(Math.asinh($0))",
  },
  f32_acosh: {
    C:  "f32_rewrap((f32)acosh(f32_unbox($0)))",
    JS: "Math.fround(Math.acosh($0))",
  },
  f32_atanh: {
    C:  "f32_rewrap((f32)atanh(f32_unbox($0)))",
    JS: "Math.fround(Math.atanh($0))",
  },
  f32_scalbn_pos: {
    C:  "f32_rewrap(scalbnf(f32_unbox($0), (int)((u32)$1 > 512 ? 512 : (u32)$1)))",
    JS: "f32_scalbn($0, $1, false)",
  },
  f32_scalbn_neg: {
    C:  "f32_rewrap(scalbnf(f32_unbox($0), -(int)((u32)$1 > 512 ? 512 : (u32)$1)))",
    JS: "f32_scalbn($0, $1, true)",
  },
  f32_logb: {
    C:  "f32_rewrap(logbf(f32_unbox($0)))",
    JS: "f32_logb($0)",
  },
  f32_roundeven: {
    C:  "f32_rewrap(bend_roundevenf(f32_unbox($0)))",
    JS: "f32_roundeven($0)",
  },
  f32_remainder: {
    C:  "f32_rewrap(remainderf(f32_unbox($0), f32_unbox($1)))",
    JS: "f32_remainder($0, $1)",
  },
  f32_remquo_code: {
    C:  "bend_remquo_code(f32_unbox($0), f32_unbox($1))",
    JS: "f32_remquo_code($0, $1)",
  },
  f32_erf: {
    C:  "f32_rewrap(erff(f32_unbox($0)))",
    JS: "f32_erf($0)",
  },
  f32_erfc: {
    C:  "f32_rewrap(erfcf(f32_unbox($0)))",
    JS: "f32_erfc($0)",
  },
  f32_tgamma: {
    C:  "f32_rewrap(tgammaf(f32_unbox($0)))",
    JS: "f32_tgamma($0)",
  },
  f32_lgamma: {
    C:  "f32_rewrap(lgammaf(f32_unbox($0)))",
    JS: "f32_lgamma($0)",
  },
  f32_sinpi: {
    C:  "f32_rewrap(bend_sinpif(f32_unbox($0)))",
    JS: "f32_sinpi($0)",
  },
  f32_cospi: {
    C:  "f32_rewrap(bend_cospif(f32_unbox($0)))",
    JS: "f32_cospi($0)",
  },
  f32_tanpi: {
    C:  "f32_rewrap(bend_tanpif(f32_unbox($0)))",
    JS: "f32_tanpi($0)",
  },
  f32_asinpi: {
    C:  "f32_rewrap(bend_asinpif(f32_unbox($0)))",
    JS: "Math.fround(Math.asin($0) / Math.PI)",
  },
  f32_acospi: {
    C:  "f32_rewrap(bend_acospif(f32_unbox($0)))",
    JS: "Math.fround(Math.acos($0) / Math.PI)",
  },
  f32_atanpi: {
    C:  "f32_rewrap(bend_atanpif(f32_unbox($0)))",
    JS: "Math.fround(Math.atan($0) / Math.PI)",
  },
  f32_atan2pi: {
    C:  "f32_rewrap(bend_atan2pif(f32_unbox($0), f32_unbox($1)))",
    JS: "Math.fround(Math.atan2($0, $1) / Math.PI)",
  },
  f32_rsqrt: {
    C:  "f32_rewrap(bend_rsqrtf(f32_unbox($0)))",
    JS: "Math.fround(1 / Math.sqrt($0))",
  },
  f32_pown_pos: {
    C:  "f32_rewrap(bend_pownf(f32_unbox($0), (u32)$1, 0))",
    JS: "Math.fround(Math.pow($0, ($1 >>> 0)))",
  },
  f32_pown_neg: {
    C:  "f32_rewrap(bend_pownf(f32_unbox($0), (u32)$1, 1))",
    JS: "Math.fround(Math.pow($0, -($1 >>> 0)))",
  },
  f32_mod: {
    C:  "f32_rewrap((f32)fmod(f32_unbox($0), f32_unbox($1)))",
    JS: "Math.fround($0 % $1)",
  },
  f32_to_u32: {
    C:  "f32_to_u32($0)",
    JS: "($0 >= 1 && $0 < 4294967296 ? Math.floor($0) : 0)",
  },
  f32_bits: {
    C:  "$0",
    JS: "f32_bits($0)",
  },
  f32_show: {
    C:    "f32_show(e, $0)",
    call: true,
    JS:   "f32_show($0)",
  },
  f32_read: {
    C:    "f32_read(e, $0)",
    call: true,
    JS:   "f32_read($0)",
  },
};

export const SHIMS = (() => {
  const names = ("sqrt exp log log2 log10 sin cos tan asin acos atan sinh cosh"
    + " tanh floor ceil trunc fabs pow fmod fma cbrt hypot exp2 expm1 log1p"
    + " asinh acosh atanh logb rint remainder erf erfc tgamma lgamma").split(" ");
  const target = (n: string) =>
    (["sin", "cos", "tan"].includes(n) ? " fast::" : " precise::") + n;
  return names.map((n) => "#define " + n.padEnd(11) + target(n))
    .concat(names.map((n) => "#define " + (n + "f").padEnd(11) + target(n)))
    .join("\n") + "\n#define scalbnf    precise::ldexp"
    + "\n#define atan2      atan2_c99"
    + "\n#define atan2f     atan2_c99";
})();

export const C_PRE = String.raw`
INLINE f32 f32_unbox(u64 x) {
  union { u32 u; f32 f; } p = { (u32)x };
  return p.f;
}

INLINE u64 f32_rewrap(f32 x) {
  union { f32 f; u32 u; } p = { x };
  return p.u;
}

`.slice(1);

export const C_POST = String.raw`
INLINE U32 f32_to_u32(U32 a) {
  f32 v = f32_unbox(a);
  return v >= 0.0f && v < 4294967296.0f ? (u32)v : 0;
}

`.slice(1);

export const C_F32_IO_DECL = String.raw`
#if DEVICE

#define f32_show(e, x) (err_post(e.mem, ERR_FIDS), 0)
#define f32_read(e, s) (err_post(e.mem, ERR_FIDS), 0)

#else

static Term f32_show(Env e, Term x);
static Term f32_read(Env e, Term s);

#endif
`.slice(1);

export const C_IO = String.raw`
static int f32_text(char* buf, f32 v) {
  int n = 0;
  int p = 0;
  if (v != v) {
    return sprintf(buf, "nan");
  }
  for (; p < 9; p += 1) {
    n = snprintf(buf, 40, "%.*e", p, (double)v);
    if (strtof(buf, NULL) == v) {
      break;
    }
  }
  char* ep = strchr(buf, 'e');
  if (ep == NULL) {
    return n;
  }
  int ex = atoi(ep + 1);
  if (ex >= 21 || ex <= -7) {
    n = (int)(ep - buf) + sprintf(ep, "e%c%d", ex < 0 ? '-' : '+', abs(ex));
  } else if (ex <= p) {
    n = snprintf(buf, 40, "%.*f", p - ex, (double)v);
  } else {
    int s = *buf == '-';
    memmove(buf + s + 1, buf + s + 2, p);
    memset(buf + s + 1 + p, '0', ex - p);
    n = s + 1 + ex;
  }
  return n;
}

static Term f32_show(Env e, Term x) {
  char buf[40];
  return io_str(e, buf, f32_text(buf, f32_unbox(x)));
}

static Term f32_read(Env e, Term s) {
  u64 n = 0;
  char* text = io_cstr(e, s, &n);
  char* end;
  f32 v = strtof(text, &end);
  Term out = n > 0 && (u64)(end - text) == n && strpbrk(text, "xX(") == NULL
    ? io_box(e, CID_SOME, f32_rewrap(v)) : term_pak(CID_NONE, 0);
  free(text);
  return out;
}
`.slice(1);

export const JS_PRE = String.raw`
function f32_show(x) {
  if (x !== x) {
    return "nan";
  }
  if (!Number.isFinite(x) || Object.is(x, -0)) {
    return x < 0 ? "-inf"
      : x === 0 ? "-0" : "inf";
  }
  let s = "x";
  for (let p = 1; p <= 9 && Math.fround(Number(s)) !== x; p += 1) {
    s = String(Number(x.toExponential(p - 1)));
  }
  return s;
}

function f32_bits(x) {
  return new Uint32Array(new Float32Array([x]).buffer)[0];
}

function f32_from_bits(u) {
  return new Float32Array(new Uint32Array([u]).buffer)[0];
}

`.slice(1);

export const JS_POST = String.raw`
function f32_read(s) {
  const re = /^\s*[+-]?((\d+\.?\d*|\.\d+)(e[+-]?\d+)?|inf(inity)?|nan)$/i;
  const v = Number(s.replace(/inf\w*/i, "Infinity"));
  return re.test(s) ? {$: "Some", value: Math.fround(v)} : {$: "None"};
}

`.slice(1);

export const C = String.raw`
INLINE f32 bend_pownf(f32 x, u32 n, int neg_exp) {
#ifdef __METAL_VERSION__
  if (n == 0) return 1.0f;
  const int neg_result = signbit(x) && (n & 1u);
  const f32 a = fabs(x);
  const f32 ehi = (f32)(n & 0xffff0000u);
  const f32 elo = (f32)(n & 0x0000ffffu);
  const f32 hi = precise::pow(a, neg_exp ? -ehi : ehi);
  const f32 lo = precise::pow(a, neg_exp ? -elo : elo);
  const f32 mag = hi * lo;
  return neg_result ? -mag : mag;
#else
  const double e = neg_exp ? -(double)n : (double)n;
  return (f32)pow((double)x, e);
#endif
}

INLINE f32 bend_asinpif(f32 x) {
#ifdef __METAL_VERSION__
  return precise::asin(x) * 0.31830988618379067154f;
#else
  return (f32)(asin((double)x) * 0x1.45f306dc9c883p-2);
#endif
}

INLINE f32 bend_acospif(f32 x) {
#ifdef __METAL_VERSION__
  return precise::acos(x) * 0.31830988618379067154f;
#else
  return (f32)(acos((double)x) * 0x1.45f306dc9c883p-2);
#endif
}

INLINE f32 bend_atanpif(f32 x) {
#ifdef __METAL_VERSION__
  return precise::atan(x) * 0.31830988618379067154f;
#else
  return (f32)(atan((double)x) * 0x1.45f306dc9c883p-2);
#endif
}

INLINE f32 bend_atan2pif(f32 y, f32 x) {
#ifdef __METAL_VERSION__
  return atan2_c99(y, x) * 0.31830988618379067154f;
#else
  return (f32)(atan2((double)y, (double)x) * 0x1.45f306dc9c883p-2);
#endif
}

INLINE f32 bend_rsqrtf(f32 x) {
#ifdef __METAL_VERSION__
  return 1.0f / precise::sqrt(x);
#else
  return (f32)(1.0 / sqrt((double)x));
#endif
}

INLINE f32 bend_exp2m1f(f32 x) {
#ifdef __METAL_VERSION__
  return precise::expm1(x * 0.69314718055994530942f);
#else
  return (f32)expm1((double)x * 0x1.62e42fefa39efp-1);
#endif
}

INLINE f32 bend_exp10m1f(f32 x) {
#ifdef __METAL_VERSION__
  return precise::expm1(x * 2.30258509299404568402f);
#else
  return (f32)expm1((double)x * 0x1.26bb1bbb55516p+1);
#endif
}

INLINE f32 bend_log2p1f(f32 x) {
#ifdef __METAL_VERSION__
  return precise::log1p(x) * 1.44269504088896340736f;
#else
  return (f32)(log1p((double)x) * 0x1.71547652b82fep+0);
#endif
}

INLINE f32 bend_log10p1f(f32 x) {
#ifdef __METAL_VERSION__
  return precise::log1p(x) * 0.43429448190325182765f;
#else
  return (f32)(log1p((double)x) * 0x1.bcb7b1526e50ep-2);
#endif
}

INLINE f32 bend_sinpif(f32 x) {
#ifdef __METAL_VERSION__
  return precise::sinpi(x);
#else
  if (!isfinite(x)) return NAN;
  if (x == 0.0f) return x;
  f32 a = fabsf(x);
  if (a >= 0x1p24f) return copysignf(0.0f, x);
  f32 r = fmodf(a, 2.0f);
  double y;
  if (r == 0.0f || r == 1.0f) y = 0.0;
  else if (r == 0.5f) y = 1.0;
  else if (r == 1.5f) y = -1.0;
  else if (r < 0.5f) y = sin(0x1.921fb54442d18p+1 * (double)r);
  else if (r < 1.0f) y = sin(0x1.921fb54442d18p+1 * (double)(1.0f - r));
  else if (r < 1.5f) y = -sin(0x1.921fb54442d18p+1 * (double)(r - 1.0f));
  else y = -sin(0x1.921fb54442d18p+1 * (double)(2.0f - r));
  return (f32)(signbit(x) ? -y : y);
#endif
}

INLINE f32 bend_cospif(f32 x) {
#ifdef __METAL_VERSION__
  return precise::cospi(x);
#else
  if (!isfinite(x)) return NAN;
  f32 a = fabsf(x);
  if (a >= 0x1p24f) return 1.0f;
  f32 r = fmodf(a, 2.0f);
  if (r == 0.0f) return 1.0f;
  if (r == 0.5f || r == 1.5f) return 0.0f;
  if (r == 1.0f) return -1.0f;
  if (r < 0.5f) return (f32)cos(0x1.921fb54442d18p+1 * (double)r);
  if (r < 1.0f) return (f32)-cos(0x1.921fb54442d18p+1 * (double)(1.0f - r));
  if (r < 1.5f) return (f32)-cos(0x1.921fb54442d18p+1 * (double)(r - 1.0f));
  return (f32)cos(0x1.921fb54442d18p+1 * (double)(2.0f - r));
#endif
}

INLINE f32 bend_tanpif(f32 x) {
#ifdef __METAL_VERSION__
  return precise::tanpi(x);
#else
  if (!isfinite(x)) return NAN;
  if (x == 0.0f) return x;
  const int neg = signbit(x) != 0;
  f32 a = fabsf(x);
  if (a >= 0x1p24f) return copysignf(0.0f, x); // all such F32 integers are even
  f32 p = fmodf(a, 2.0f);
  f32 r = fmodf(a, 1.0f);
  if (r == 0.0f) {
    const int odd = p == 1.0f;
    return (odd != neg) ? -0.0f : 0.0f;
  }
  if (r == 0.5f) {
    const int floor_odd = p == 1.5f;
    return (floor_odd != neg) ? -INFINITY : INFINITY;
  }
  double y = r < 0.5f
    ? tan(0x1.921fb54442d18p+1 * (double)r)
    : -tan(0x1.921fb54442d18p+1 * (double)(1.0f - r));
  return (f32)(neg ? -y : y);
#endif
}

INLINE f32 bend_roundevenf(f32 x) {
#ifdef __METAL_VERSION__
  return precise::rint(x);
#else
  if (!isfinite(x) || fabsf(x) >= 0x1p23f) return x;
  f32 f = floorf(x);
  f32 d = x - f;
  f32 r;
  if (d < 0.5f) r = f;
  else if (d > 0.5f) r = f + 1.0f;
  else r = fmodf(fabsf(f), 2.0f) == 0.0f ? f : f + 1.0f;
  return r == 0.0f ? copysignf(0.0f, x) : r;
#endif
}

INLINE U32 bend_remquo_code(f32 x, f32 y) {
  if (!isfinite(x) || isnan(y) || y == 0.0f) return 0;
  if (!isfinite(y)) return 0;
  int q = 0;
  f32 r;
#ifdef __METAL_VERSION__
  r = precise::remquo(x, y, q);
#else
  r = remquof(x, y, &q);
#endif
  u32 uq = (u32)q;
  u32 mag = q < 0 ? 0u - uq : uq;
  bool nonzero = q != 0 || r != x;
  bool neg = signbit(x) != signbit(y);
  return (mag & 7u) | (neg && nonzero ? 0x80000000u : 0u);
}

`.slice(1);

export const JS = String.raw`
function f32_decomp(x) {
  const u = f32_bits(x);
  const s = (u >>> 31) === 0 ? 1n : -1n;
  const e = (u >>> 23) & 255;
  const f = u & 0x7FFFFF;
  if (e === 255) return null;
  return e === 0
    ? {s, m: BigInt(f), e: -149}
    : {s, m: BigInt(0x800000 | f), e: e - 150};
}

function f32_round_shr(a, n) {
  if (n <= 0) return a << BigInt(-n);
  const sh = BigInt(n);
  const q = a >> sh;
  const r = a - (q << sh);
  const h = 1n << (sh - 1n);
  return r > h || (r === h && (q & 1n) !== 0n) ? q + 1n : q;
}

function f32_from_exact(n, e, zeroNeg = false) {
  if (n === 0n) return zeroNeg ? -0 : 0;
  const neg = n < 0n;
  let a = neg ? -n : n;
  let len = a.toString(2).length;
  let top = e + len - 1;
  if (top > 127) return neg ? -Infinity : Infinity;
  let bits;
  if (top >= -126) {
    let q = f32_round_shr(a, len - 24);
    if (q === 0x1000000n) {
      q >>= 1n;
      top += 1;
      if (top > 127) return neg ? -Infinity : Infinity;
    }
    const exp = top + 127;
    bits = (exp << 23) | Number(q - 0x800000n);
  } else {
    const q = f32_round_shr(a, -(e + 149));
    if (q === 0n) return neg ? -0 : 0;
    bits = q >= 0x800000n ? 0x00800000 : Number(q);
  }
  if (neg) bits |= 0x80000000;
  return f32_from_bits(bits >>> 0);
}

function f32_fma(a, b, c) {
  if (Number.isNaN(a) || Number.isNaN(b) || Number.isNaN(c)) return NaN;
  const az = a === 0;
  const bz = b === 0;
  if ((!Number.isFinite(a) && bz) || (!Number.isFinite(b) && az)) return NaN;
  if (!Number.isFinite(a) || !Number.isFinite(b)) {
    const pn = (a < 0 || Object.is(a, -0)) !== (b < 0 || Object.is(b, -0));
    if (!Number.isFinite(c) && ((c < 0) !== pn)) return NaN;
    return pn ? -Infinity : Infinity;
  }
  if (!Number.isFinite(c)) return c;
  const pa = f32_decomp(a), pb = f32_decomp(b), pc = f32_decomp(c);
  let np = pa.s * pb.s * pa.m * pb.m;
  const ep = pa.e + pb.e;
  let nc = pc.s * pc.m;
  if (np === 0n && nc === 0n) {
    const an = a < 0 || Object.is(a, -0);
    const bn = b < 0 || Object.is(b, -0);
    const pn = an !== bn;
    const cn = c < 0 || Object.is(c, -0);
    return pn === cn && pn ? -0 : 0;
  }
  if (np === 0n) return c;
  const e = Math.min(ep, pc.e);
  np <<= BigInt(ep - e);
  nc <<= BigInt(pc.e - e);
  return f32_from_exact(np + nc, e);
}

function f32_pow(x, y) {
  // ECMAScript intentionally differs from IEC 60559/C pow at a few exact
  // special values.  Normalize those cases before using the host Math.pow.
  if (y === 0 || x === 1) return 1;
  if (x === -1 && (y === Infinity || y === -Infinity)) return 1;
  return Math.fround(Math.pow(x, y));
}

function f32_scalbn(x, mag, neg) {
  const n = Math.min(mag >>> 0, 512);
  return Math.fround(x * 2 ** (neg ? -n : n));
}

function f32_logb(x) {
  const u = f32_bits(x) & 0x7FFFFFFF;
  const e = u >>> 23;
  const f = u & 0x7FFFFF;
  if (e === 255) return f === 0 ? Infinity : NaN;
  if (e !== 0) return Math.fround(e - 127);
  if (f === 0) return -Infinity;
  return Math.fround(-149 + (31 - Math.clz32(f)));
}

function f32_roundeven(x) {
  if (!Number.isFinite(x) || Math.abs(x) >= 0x800000) return x;
  const f = Math.floor(x);
  const d = x - f;
  let r = d < 0.5 ? f : d > 0.5 ? f + 1 : (f % 2 === 0 ? f : f + 1);
  if (r === 0) r = Object.is(x, -0) || x < 0 ? -0 : 0;
  return Math.fround(r);
}

function f32_remainder(x, y) {
  if (Number.isNaN(x) || Number.isNaN(y) || !Number.isFinite(x) || y === 0) {
    return NaN;
  }
  if (!Number.isFinite(y)) return x;
  const px = f32_decomp(x), py = f32_decomp(y);
  if (px.m === 0n) return x;
  const d = px.e - py.e;
  const num = d >= 0 ? px.m << BigInt(d) : px.m;
  const den = d >= 0 ? py.m : py.m << BigInt(-d);
  let q = num / den;
  const rem = num % den;
  const twice = rem << 1n;
  if (twice > den || (twice === den && (q & 1n) !== 0n)) q += 1n;
  q *= px.s * py.s;
  const e = Math.min(px.e, py.e);
  const xi = px.s * (px.m << BigInt(px.e - e));
  const yi = py.s * (py.m << BigInt(py.e - e));
  const ri = xi - q * yi;
  return f32_from_exact(ri, e, px.s < 0n);
}

function f32_remquo_code(x, y) {
  if (Number.isNaN(x) || Number.isNaN(y) || !Number.isFinite(x) || y === 0
      || !Number.isFinite(y)) {
    return 0;
  }
  const px = f32_decomp(x), py = f32_decomp(y);
  if (px.m === 0n) return 0;
  const d = px.e - py.e;
  const num = d >= 0 ? px.m << BigInt(d) : px.m;
  const den = d >= 0 ? py.m : py.m << BigInt(-d);
  let q = num / den;
  const rem = num % den;
  const twice = rem << 1n;
  if (twice > den || (twice === den && (q & 1n) !== 0n)) q += 1n;
  const neg = px.s !== py.s;
  const mag = Number(q & 7n) >>> 0;
  return (mag | (neg && q !== 0n ? 0x80000000 : 0)) >>> 0;
}

function f64_erf_series(x) {
  const x2 = x * x;
  let term = x;
  let sum = x;
  for (let n = 1; n < 48; ++n) {
    term *= -x2 / n;
    const add = term / (2 * n + 1);
    sum += add;
    if (Math.abs(add) < 1e-18 * Math.max(1, Math.abs(sum))) break;
  }
  return 1.1283791670955125739 * sum;
}

// Q(1/2,z^2) = erfc(z), evaluated by a bounded continued fraction.  Keeping
// the iteration in binary64 avoids the severe tail cancellation of 1-erf(z).
function f64_erfc_pos(z) {
  if (z < 1.5) return 1 - f64_erf_series(z);
  if (z > 27) return 0;
  const x = z * z;
  const a = 0.5;
  let b = x + 1 - a;
  let c = 1e300;
  let d = 1 / b;
  let h = d;
  for (let i = 1; i <= 100; ++i) {
    const an = -i * (i - a);
    b += 2;
    d = an * d + b;
    if (Math.abs(d) < 1e-300) d = 1e-300;
    c = b + an / c;
    if (Math.abs(c) < 1e-300) c = 1e-300;
    d = 1 / d;
    const del = d * c;
    h *= del;
    if (Math.abs(del - 1) < 2e-16) break;
  }
  return Math.exp(-x + a * Math.log(x) - 0.57236494292470008707) * h;
}

function f32_erf(x) {
  if (Number.isNaN(x)) return NaN;
  if (x === Infinity) return 1;
  if (x === -Infinity) return -1;
  if (x === 0) return x;
  const z = Math.abs(x);
  const y = z < 1.5 ? f64_erf_series(z) : 1 - f64_erfc_pos(z);
  return Math.fround(x < 0 ? -y : y);
}

function f32_erfc(x) {
  if (Number.isNaN(x)) return NaN;
  if (x === Infinity) return 0;
  if (x === -Infinity) return 2;
  if (x === 0) return 1;
  const q = f64_erfc_pos(Math.abs(x));
  return Math.fround(x < 0 ? 2 - q : q);
}

const F32_GAMMA_C = [0.99999999999980993, 676.5203681218851,
  -1259.1392167224028, 771.32342877765313, -176.61502916214059,
  12.507343278686905, -0.13857109526572012, 9.984369578019572e-6,
  1.5056327351493116e-7];

function f64_sinpi(x) {
  if (!Number.isFinite(x)) return NaN;
  if (x === 0) return x;
  const neg = x < 0 || Object.is(x, -0);
  const a = Math.abs(x);
  if (a >= 16777216) return neg ? -0 : 0;
  const r = a % 2;
  let y;
  if (r === 0 || r === 1) y = 0;
  else if (r === 0.5) y = 1;
  else if (r === 1.5) y = -1;
  else if (r < 0.5) y = Math.sin(Math.PI * r);
  else if (r < 1) y = Math.sin(Math.PI * (1 - r));
  else if (r < 1.5) y = -Math.sin(Math.PI * (r - 1));
  else y = -Math.sin(Math.PI * (2 - r));
  return neg ? -y : y;
}

function f64_lgamma(x) {
  if (Number.isNaN(x)) return NaN;
  if (!Number.isFinite(x)) return Infinity;
  if (x === 1 || x === 2) return 0;
  if (x <= 0 && Number.isInteger(x)) return Infinity;
  if (x < 0.5) {
    return Math.log(Math.PI) - Math.log(Math.abs(f64_sinpi(x)))
      - f64_lgamma(1 - x);
  }
  const z = x - 1;
  let a = F32_GAMMA_C[0];
  for (let i = 1; i < F32_GAMMA_C.length; i++) a += F32_GAMMA_C[i] / (z + i);
  const t = z + 7.5;
  return 0.9189385332046727 + (z + 0.5) * Math.log(t) - t + Math.log(a);
}

function f64_tgamma(x) {
  if (Number.isNaN(x)) return NaN;
  if (x === Infinity) return Infinity;
  if (x === -Infinity) return NaN;
  if (x === 0) return Object.is(x, -0) ? -Infinity : Infinity;
  if (x < 0 && Number.isInteger(x)) return NaN;
  if (x < 0.5) return Math.PI / (f64_sinpi(x) * f64_tgamma(1 - x));
  return Math.exp(f64_lgamma(x));
}

function f32_tgamma(x) { return Math.fround(f64_tgamma(x)); }
function f32_lgamma(x) { return Math.fround(f64_lgamma(x)); }

function f32_sinpi(x) { return Math.fround(f64_sinpi(x)); }

function f32_cospi(x) {
  if (!Number.isFinite(x)) return NaN;
  const a = Math.abs(x);
  if (a >= 16777216) return 1;
  const r = a % 2;
  if (r === 0) return 1;
  if (r === 0.5 || r === 1.5) return 0;
  if (r === 1) return -1;
  if (r < 0.5) return Math.fround(Math.cos(Math.PI * r));
  if (r < 1) return Math.fround(-Math.cos(Math.PI * (1 - r)));
  if (r < 1.5) return Math.fround(-Math.cos(Math.PI * (r - 1)));
  return Math.fround(Math.cos(Math.PI * (2 - r)));
}

function f32_tanpi(x) {
  if (!Number.isFinite(x)) return NaN;
  if (x === 0) return x;
  const neg = x < 0 || Object.is(x, -0);
  const a = Math.abs(x);
  if (a >= 16777216) return neg ? -0 : 0; // all such F32 integers are even
  const p = a % 2;
  const r = a % 1;
  if (r === 0) {
    const odd = p === 1;
    return odd !== neg ? -0 : 0;
  }
  if (r === 0.5) {
    const floorOdd = p === 1.5;
    return floorOdd !== neg ? -Infinity : Infinity;
  }
  const y = r < 0.5 ? Math.tan(Math.PI * r) : -Math.tan(Math.PI * (1 - r));
  return Math.fround(neg ? -y : y);
}

`.slice(1);
