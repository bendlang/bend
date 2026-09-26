// NOTE: Bend's runtime was designed by humans, but this file was mostly written
// by AI's, as it includes a ton of optimizations. It works and tests pass, yet,
// bugs ARE expected. It will take some time for the compiler to be stable.

// Comp
// ====

// Compiles a checked Book to C, one source for the host and
// the device, or to JS. The C and JS runtimes close the file.

import * as fs from "node:fs";

import * as Bend from "./bend.ts";

// Types
// =====

type Kind = "w32" | "w64" | "box";

type Lay = { ks: Kind[]; arms: Record<Name, Lay[]> | null };

type Val = { ws: string[]; lay: Lay; stat: boolean };

type Bind = { val: Val; n: number; A: HTerm };

type Seg = {
  fid: string;
  def: Name;
  ret: Lay;
  lines: string[];
  params: string[];
  ks: Kind[];
  frame: { pop: number; at: number[] } | null;
  refs: Set<string>;
  spin?: boolean;
  fork?: boolean;
};

type Spine = {
  h: HTerm;
  t: HTerm;
  all: HTerm[];
  args: HTerm[];
  tld: Bend.TLD | undefined;
  k: Name | null;
  xs: HTerm[];
  b?: boolean;
};

type HTerm = Bend.HTerm;

type Name = Bend.Name;

type File = {
  book: Bend.Book;
  js: boolean;
  bangs: Set<Name>;
  sites: Map<Name, number>;
  hot: Set<Name>;
  stat: Set<Name>;
  own: Set<string>;
  lend: Set<string>;
  segs: Seg[];
  spins: Seg[];
  spun: Map<string, string>;
  clos: Set<string>;
  tabs: Map<string, number>;
  tails: Map<Name, Set<Name>>;
  img: string[];
  lits: Map<string, number>;
  consts: Map<string, Map<HTerm, Val>>;
  fresh: Map<string, number>;
  brwl: Map<string, string>;
  seg: Seg;
  spares: { words: number; name: string; z: boolean }[];
  uses: Map<Of<"Var">, Bind>;
  rest: HTerm[];
  def: Name;
};

type Tpl = string | ((xs: string[]) => string);

type Native = Record<Name, {
  intr: Tpl;
  elim?: string[];
  cond?: string;
}>;

type Of<K> = Extract<HTerm, { $: K }>;

type Row = [HTerm, number, number, number];

type Intr = {
  C?: string | string[];
  call?: boolean;
  JS: string;
};

type Dom = [Bend.Quant, Name, HTerm];

type Fun = { n: number; h: HTerm | null; live: Dom[]; lays: Lay[]; ret: Lay };

// Constants
// =========

// CLO_APPLY and IO_EMIT are the runtime's own segments, named with a ~
// so that no file declares them. FOLD_FUEL caps the nodes that unfolds
// add to a segment, so a literal-bounded loop does not unroll into its
// caller. A spin of SPIN_FAR lines is a call (at 128, raytrace lost
// 31% on PAR-CPU). WIDE is the widest flat layout or segment; a node past
// it pads to its size class and keeps 240 plus log2 of it in CID_T.

const CLO_APPLY = "Clo~apply";

const IO_EMIT = "IO~emit";

const ATOM   = /^(?:[A-Za-z_$][A-Za-z0-9_$]*|\d+|\d+\.\d+)$/;
const STRLIT = new RegExp("^\"(?:[^\"\\\\]|\\\\.)*\"$");

const TAB_BAD = /\b(?!(?:fround|imul)\()\w+\(/;

const FOLD_FUEL = 8192;

const SPIN_FAR = 256;

const USE0 = Bend.Emp<number>();

const W32: Lay = { ks: ["w32"], arms: null };

const BOX: Lay = { ks: ["box"], arms: null };

const W64: Lay = { ks: ["w64"], arms: null };

const WORDS: Record<string, Lay> = Object.setPrototypeOf(
  { U32: W32, F32: W32, Nat: W64 }, null);

const WIDE = 247;

const ERRS = ("|*|*|out of memory: run again with a bigger span, as in"
  + " --gpu 8GB|a function the device does not hold|a Nat past the"
  + " largest immediate 2^48-1|*|memory fault (machine stack overflow?)|an"
  + " array past the deepest block class 31").split("|")
  .map((e) => e === "*" ? "runtime fail-stop" : e);

// Operations
// ----------

// The Array operations have no C text: arr_op lays them out by element.

const CMPS = "is_eq:==:=== is_ne:!=:!== is_lt:< is_le:<= is_gt:> is_ge:>=";

const OPERATIONS: Record<string, Intr> = Object.setPrototypeOf({
  ...tpl_ops("u32_", "add:+ sub:- and:& or:| xor:^",
    "U32_BIN($0, $o, $1)", "(($0 $o $1) >>> 0)"),
  ...tpl_ops("u32_", CMPS, "U32_BIN($0, $o, $1)", "($0 $o $1)"),
  u32_mul: {
    C:  "U32_BIN($0, *, $1)",
    JS: "(Math.imul($0, $1) >>> 0)",
  },
  u32_div: {
    C:  "((u32)($1) == 0 ? 0 : (u64)U32_QUO((u32)($0), (u32)($1)))",
    JS: "($1 === 0 ? 0 : ($0 / $1) >>> 0)",
  },
  u32_mod: {
    C:  "((u32)($1) == 0 ? $0 : U32_BIN($0, -,"
      + " U32_QUO((u32)($0), (u32)($1)) * $1))",
    JS: "($1 === 0 ? $0 : $0 % $1)",
  },
  ...tpl_ops("u32_", "inc:+ shl:<< shr:>>:>>>", "U32_BIN($0, $o, 1)",
    "(($0 $o 1) >>> 0)"),
  ...tpl_ops("u32_", "shln:<< shrn:>>:>>>",
    "($1 >= 32 ? 0 : U32_BIN($0, $o, $1))",
    "($1 >= 32 ? 0 : ($0 $o $1) >>> 0)"),
  u32_not: {
    C:  "((u64)~(u32)($0))",
    JS: "(~$0 >>> 0)",
  },
  u32_is_zero: {
    C:  "U32_BIN($0, ==, 0)",
    JS: "($0 === 0)",
  },
  u32_cmp: {
    C:  "(U32_BIN($0, >, $1) + U32_BIN($0, >=, $1))",
    JS: "cmp_new($0, $1)",
  },
  u32_to_f32: {
    C:  "f32_rewrap((f32)(u32)($0))",
    JS: "Math.fround($0)",
  },
  u32_to_nat: {
    C:  "$0",
    JS: "$0",
  },
  u32_from_nat: {
    C:  "((u64)(u32)($0))",
    JS: "($0 >>> 0)",
  },
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
  ...tpl_ops("f32_", "pow atan2",
    "f32_rewrap((f32)$o(f32_unbox($0), f32_unbox($1)))",
    "Math.fround(Math.$o($0, $1))"),
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
  nat_add: {
    C:  "nat_chk(e, $0 + $1)",
    JS: "nat_chk($0 + $1)",
  },
  nat_sub: {
    C:  "($0 < $1 ? 0 : $0 - $1)",
    JS: "($0 < $1 ? 0 : $0 - $1)",
  },
  nat_mul: {
    C:  "nat_mul(e, $0, $1)",
    JS: "nat_chk($0 * $1)",
  },
  nat_double: {
    C:  "nat_chk(e, $0 + $0)",
    JS: "nat_chk($0 + $0)",
  },
  nat_cmp: {
    C:  "(($0 > $1) + ($0 >= $1))",
    JS: "cmp_new($0, $1)",
  },
  nat_is_lt: {
    C:  "($0 < $1)",
    JS: "($0 < $1)",
  },
  ...tpl_ops("nat_", "min:< max:>", "($0 $o $1 ? $0 : $1)",
    "($0 $o $1 ? $0 : $1)"),
  nat_divmod: {
    C:    ["($1 == 0 ? 0 : $0 / $1)", "($1 == 0 ? $0 : $0 % $1)"],
    call: true,
    JS:   "nat_divmod($0, $1)",
  },
  ...tpl_ops("bool_", "or:|:|| xor:^:!==", "(($0) $o ($1))", "($0 $o $1)"),
  string_append: {
    JS: "($0 + $1)",
  },
  string_length: {
    JS: "[...$0].length",
  },
  ...Object.fromEntries(Object.entries({
    new: "array_new($0, $1)", set: "($0[$1 % $0.length] = $2, $0)",
    get: "{$: \"Tuple\", fst: $0, snd: $0[$1 % $0.length]}",
    swap: "array_rmw($0, $1, () => $2)",
    size: "{$: \"Tuple\", fst: $0, snd: $0.length}",
  }).map(([k, JS]) => ["array_" + k, { call: true, JS }])),
  array_clone: {
    C:    ["$0", "blk_copy(e, $0)"],
    call: true,
    JS:   "{$: \"Tuple\", fst: $0, snd: $0.slice()}",
  },
  ...Object.fromEntries(Object.entries({
    add: "(o + $2) >>> 0", min: "Math.min(o, $2)", max: "Math.max(o, $2)",
    and: "(o & $2) >>> 0", or: "(o | $2) >>> 0", xor: "(o ^ $2) >>> 0",
    exch: "$2", cmpx: "o === $2 ? $3 : o", fadd: "Math.fround(o + $2)",
  }).map(([k, js]) => ["array_atomic_" + k.replace("cmpx", "cas"), {
    C:    ["$0", "a32_" + k + "(blk_ptr(e.mem, blk_loc(e.mem, $0),"
      + " blk_at($0, $1, 0)), (u32)$2" + (k === "cmpx" ? ", (u32)$3)" : ")")],
    call: true,
    JS:   "array_rmw($0, $1, (o) => " + js + ")",
  }])),
}, null);

// Optimized
// ---------

// Per native constructor: its builder, field readers and optional
// test. RUNTIME_ADTS are the datatypes the runtime or the elaborator
// lays out itself; OWNED are the Base names the compiler encodes,
// which a file without `import Base` may declare but not compile.

const OPTIMIZED: Record<Name, Native> = Object.setPrototypeOf({
  Nat: {
    Zero: { intr: "0" },
    Succ: { intr: tpl_nat("", "nat_chk($0 + 1)") },
  },
  Bool: {
    False: { intr: "false", cond: "!$0" },
    True: { intr: "true", cond: "$0" },
  },
  U32: {
    U32: { intr: "word_to_u32($0)" },
  },
  F32: {
    F32: { intr: "f32_from_bits(word_to_u32($0))" },
  },
  Char: {
    Chr: {
      intr: ([c]: string[]) => {
        const n = Number(c);
        return /^\d+$/.test(c)
          && (n < 0xd800 || n >= 0xe000 && n <= 0x10ffff)
          ? JSON.stringify(String.fromCodePoint(n))
          : "char_new(" + c + ")";
      },
      elim: ["$0.codePointAt(0)"],
    },
  },
  Array: {
    ALeaf: { intr: "[$0]", elim: ["$0[0]"], cond: "$0.length === 1" },
    ANode: {
      intr: "array_node($0, $1)",
      elim: ["$0.slice(0, $0.length >> 1)", "$0.slice($0.length >> 1)"],
      cond: "$0.length !== 1",
    },
  },
  String: {
    SNil: { intr: "\"\"", cond: "$0 === \"\"" },
    SCon: {
      intr: ([h, t]: string[]) => STRLIT.test(h) && STRLIT.test(t)
        ? JSON.stringify(JSON.parse(h) + JSON.parse(t))
        : "(" + h + " + " + t + ")",
      elim: ["($0.codePointAt(0) > 0xFFFF ? $0.slice(0, 2) : $0[0])",
        "($0.codePointAt(0) > 0xFFFF ? $0.slice(2) : $0.slice(1))"],
      cond: "$0 !== \"\"",
    },
  },
} satisfies Record<Name, Native>, null);

const RUNTIME_ADTS = ["Sigma", "String", "Word.Con", "IO.OP", "Result",
  "Maybe", "Bool", "Unit"];

const OWNED = ["IO", ...RUNTIME_ADTS, ...Object.keys(OPTIMIZED)];

// Native
// ------

// On Metal, sin, cos and tan are fast:: (cheap, the same pixels)
// and the rest precise::. Metal's atan2 is NaN at the origin,
// where libm answers +-0 or +-pi, so atan2_c99 answers as libm
// does. Metal folds a constant dividend within 128 of 2^32 through
// an f32, so U32_QUO divides its half and then fixes the odd bit.

const SHIMS = "sqrt exp log log2 log10 sin cos tan pow fmod".split(" ")
  .map((n) => "#define " + n.padEnd(5) + (["sin", "cos", "tan"].includes(n)
    ? " fast::" : " precise::") + n).join("\n")
  + "\n#define atan2 atan2_c99";

const NATIVE = {
  C: String.raw`
#ifdef __METAL_VERSION__
INLINE f32 atan2_c99(f32 y, f32 x) {
  return y == 0.0f && x == x
    ? copysign(signbit(x) ? M_PI_F : 0.0f, y) : atan2(y, x);
}
${SHIMS}
#endif

#define U32_BIN(a, o, b) ((u64)((u32)(a) o (u32)(b)))

#define U32_QUO(a, b) \
  ((a) / 2 / (b) * 2 + ((a) - (a) / 2 / (b) * 2 * (b) >= (b)))

INLINE f32 f32_unbox(u64 x) {
  union { u32 u; f32 f; } p = { (u32)x };
  return p.f;
}

INLINE u64 f32_rewrap(f32 x) {
  union { f32 f; u32 u; } p = { x };
  return p.u;
}

INLINE u64 f32_to_u32(u64 a) {
  f32 v = f32_unbox(a);
  return v >= 0.0f && v < 4294967296.0f ? (u32)v : 0;
}

INLINE u64 nat_chk(Env e, u64 n) {
  if (n > NAT_IMM) {
    err_post(e.mem, ERR_NATS);
    return NAT_IMM;
  }
  return n;
}

INLINE u64 nat_mul(Env e, u64 a, u64 b) {
  return nat_chk(e, b != 0 && a > NAT_IMM / b ? NAT_IMM + 1 : a * b);
}

#if DEVICE

#define f32_show(e, x) (err_post(e.mem, ERR_FIDS), 0)
#define f32_read(e, s) (err_post(e.mem, ERR_FIDS), 0)

#else

static Term f32_show(Env e, Term x);
static Term f32_read(Env e, Term s);

#endif
`.slice(1),
  IO: String.raw`
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
    ? io_box(e, CID(Some), f32_rewrap(v)) : term_pak(CID(None), 0);
  free(text);
  return out;
}
`.slice(1),
  JS: String.raw`
function word_to_u32(w) {
  let x = 0;
  for (let i = 0; w.$ === "WCon"; i++) {
    x |= Number(w.head) << i;
    w = w.tail;
  }
  return x >>> 0;
}

function u32_to_word(x) {
  let w = {$: "WNil"};
  for (let i = 31; i >= 0; i--) {
    w = {$: "WCon", head: ((x >>> i) & 1) === 1, tail: w};
  }
  return w;
}

function cmp_new(a, b) {
  return {$: a < b ? "LT"
    : a === b ? "EQ" : "GT"};
}

function nat_divmod(a, b) {
  return b === 0 ? {$: "Tuple", fst: 0, snd: a}
    : {$: "Tuple", fst: Math.trunc(a / b), snd: a % b};
}

function nat_chk(n) {
  if (n > 281474976710655) {
    throw "bend: ${ERRS[5]}";
  }
  return n;
}

function nat_host(n) {
  const int = typeof n === "bigint" || Number.isInteger(n);
  if (int && n >= 0 && n <= 2 ** 53) {
    return Number(n);
  }
  return { [Symbol.toPrimitive]() { throw "bend: ${ERRS[5]}"; } };
}

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

function f32_read(s) {
  const re = /^\s*[+-]?((\d+\.?\d*|\.\d+)(e[+-]?\d+)?|inf(inity)?|nan)$/i;
  const v = Number(s.replace(/inf\w*/i, "Infinity"));
  return re.test(s) ? {$: "Some", value: Math.fround(v)} : {$: "None"};
}

function char_new(code) {
  if (code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF)) {
    throw "bend: " + code + " is not a Unicode scalar value";
  }
  return String.fromCodePoint(code);
}
`.slice(1),
};

// Caches
// ------

const IDS: Map<string, string> = new Map();

const TAKEN: Set<string> = new Set();

const PROBES: Of<"Var">[] = [];

const DUMMY = probe("~");

const OPENS: Map<Of<"Lam"> | Of<"Let">, { ps: Of<"Var">[]; b: HTerm }> =
  new Map();

const USES: Map<HTerm, Bend.PMap<number>> = new Map();

const TELES: Map<HTerm, { doms: Dom[]; ret: HTerm }> = new Map();

const SRCS: Map<Name, Set<Name> | null> = new Map();

const LOOPS: Map<Name, Name[]> = new Map();

const FOLDS: Map<HTerm, HTerm | null> = new Map();

const FLATS: Map<Name, boolean> = new Map();

const FUNS: Map<Name, Fun> = new Map();

const BRWS: Map<Name, boolean[]> = new Map();

const SPINES: Map<HTerm, Spine> = new Map();

const NODES: Map<Name, Lay> = new Map();

const LAYS: Map<string, Lay> = new Map();

const CONSTS: Map<HTerm, boolean> = new Map();

const LITS = new Map<HTerm, HTerm>();

let FUEL = 0;

// Name
// ====

// A C id is CID_ or FID_ and the name uppercased, numbered when
// taken (Done and done, a.b and a_b), so no two names share one.

function name_clean(k: string): string {
  return k.replace(/[^A-Za-z0-9_]/g, "_");
}

function name_local(fl: File, k: Name): string {
  const base = name_clean(k).replace(/^_+/, "");
  const n = fl.fresh.get(base) ?? 0;
  fl.fresh.set(base, n + 1);
  return "_" + base + "_" + n;
}

function name_id(pre: string, k: string): string {
  return memo(IDS, pre + k, () => {
    const base = pre + name_clean(k).toUpperCase();
    let id = base;
    for (let n = 1; TAKEN.has(id); n += 1) {
      id = base + "_" + n;
    }
    TAKEN.add(id);
    return id;
  });
}

function cid_mac(k: string): string {
  return name_id("CID_", k);
}

// Tpl
// ===

// tpl_nat folds Succ over a literal or a checked sum into one more.

function tpl_ops(pre: string, names: string, C: string, JS: string):
  Record<string, Intr> {
  const out: Record<string, Intr> = {};
  for (const p of names.split(" ")) {
    const [k, o = k, jo = o] = p.split(":");
    out[pre + k] = { C: C.replaceAll("$o", o), JS: JS.replaceAll("$o", jo) };
  }
  return out;
}

function tpl(t: Tpl, xs: string[]): string {
  return typeof t !== "string" ? t(xs)
    : t.split(/\$(\d)/).map((p, i) => (i % 2 === 1 ? xs[+p] : p)).join("");
}

function tpl_nat(u: string, f: string): Tpl {
  return ([p]) => {
    if (/^\d/.test(p)) {
      return (BigInt(parseInt(p)) + 1n) + u;
    }
    if (/^nat_chk\(.* \+ \d+n?\)$/.test(p)) {
      return p.replace(/\d+(?=n?\)$)/, (k) => String(+k + 1));
    }
    return tpl(f, [p]);
  };
}

// Probe
// =====

function probe(k: Name): Of<"Var"> {
  const p = Bend.Var(k, PROBES.length) as Of<"Var">;
  PROBES.push(p);
  return p;
}

function probe_of(t: HTerm): Of<"Var"> {
  return PROBES[(term_force(t) as Of<"Var">).i];
}

// Term
// ====

// A literal is a constant tree, except a Nat past the cap: U32.to_nat of
// its word. A spine calls its def directly when the live arguments meet
// the def's parameters, else Clo~apply over the outermost live one.

function lit_call(s: Of<"Lit">): HTerm | null {
  return s.k === "Nat" && s.v > Bend.NAT_LITERAL_MAX
    ? Bend.App(Bend.Ref("U32.to_nat"), Bend.Lit("U32", s.v)) : null;
}

function term_force(t: HTerm): HTerm {
  const s = Bend.term_force(t);
  if (s.$ !== "Lit") {
    return s;
  }
  return memo(LITS, s, () => lit_call(s) ?? Bend.lit_step(s));
}

function term_strip(t: HTerm): HTerm {
  return term_force(Bend.term_strip(t));
}

function term_open(t: Of<"Lam"> | Of<"Let">): { ps: Of<"Var">[]; b: HTerm } {
  return memo(OPENS, t, () => {
    const ps = (t.$ === "Lam" ? [t.k] : t.k).map(probe);
    return { ps, b: t.$ === "Lam" ? t.f(ps[0]) : t.f(ps) };
  });
}

function let_open(ps: Of<"Var">[], vs: HTerm[], b: HTerm): Of<"Let"> {
  const l = Bend.Let(ps.map((p) => p.k), ps.map(() => 0), vs,
    () => die("a pre-opened let")) as Of<"Let">;
  OPENS.set(l, { ps, b });
  return l;
}

function let_live(fl: File, t: Of<"Let">): boolean[] {
  const o = term_open(t);
  const u = term_uses(fl, o.b);
  return t.q.map((_, j) => term_use(u, o.ps[j]) > 0);
}

function term_spine(fl: File, tm: HTerm): Spine {
  return memo(SPINES, tm, () => {
    const apps: Of<"App">[] = [];
    let h = tm;
    let c = term_force(tm);
    while (c.$ === "Ann" || c.$ === "App") {
      if (c.$ === "App") {
        apps.push(c);
        h = c.f;
      }
      c = term_force(c.$ === "App" ? c.f : c.x);
    }
    apps.reverse();
    const tld = c.$ === "Ref" ? fl.book.tlds[c.k] : undefined;
    const T = tld?.$ === "Def" ? tld.T : ty_ann(h);
    const qs = T === null ? [] : tele_unbind(fl.book, T).doms;
    const live = apps.map((_, i) => i >= qs.length || quant_live(qs[i][0]));
    const all = apps.map((a) => a.x);
    const args = all.filter((_, i) => live[i]);
    const def = c.$ === "Ref" && intr_of(fl, c.k) === undefined
      && (done_live(tld) || def_foreign(tld)) ? c.k : null;
    const need = def === null ? 0 : fun_of(fl, def).lays.length;
    const a = apps[live.lastIndexOf(true)];
    const m: Spine = { h, t: c, all, args, tld, k: null, xs: args };
    if (def !== null && args.length === need) {
      return { ...m, k: def, b: (c as Of<"Ref">).b };
    }
    if (args.length > need && (def !== null || c.$ !== "Ref")) {
      return { ...m, k: CLO_APPLY, xs: [a.f, a.x] };
    }
    return m;
  });
}

function term_eta(book: Bend.Book, t: HTerm, T: HTerm, n: number): HTerm {
  if (n === 0) {
    return t;
  }
  const all = ty_all(book, T);
  return Bend.Ann(Bend.Lam("x", 0, (y: HTerm) =>
    term_eta(book, Bend.App(t, y), all.B(y), n - 1)), T);
}

function call_eta(fl: File, t: HTerm): HTerm | null {
  const m = term_spine(fl, t);
  const f = m.t.$ === "Ref" ? fun_of(fl, m.t.k) : null;
  if (m.tld?.$ !== "Def" || f === null || m.args.length >= f.live.length) {
    return null;
  }
  return term_eta(fl.book, t, Bend.tele_fill(fl.book, m.tld.T, m.all,
    Bend.ctx_nil()), f.n - m.all.length);
}

function term_kids(fl: File, tm: HTerm): HTerm[] {
  const t = term_force(tm);
  switch (t.$) {
    case "Ann": {
      return [t.x];
    }
    case "Lam": {
      return [term_open(t).b];
    }
    case "Let": {
      const on = let_live(fl, t);
      return [...t.v.filter((_, j) => on[j]), term_open(t).b];
    }
    case "App": {
      const m = term_spine(fl, t);
      return [m.h, ...m.args];
    }
    case "Ctr": {
      return term_const(t) ? [] : ctr_flds(fl.book, t.k, t.x);
    }
    case "Mat": {
      return [t.h, t.m];
    }
    case "Rwt": {
      return [t.f];
    }
    default: {
      return [];
    }
  }
}

function term_any(fl: File, t: HTerm, p: (s: HTerm, tail: boolean) => boolean,
  tail = true): boolean {
  const s = term_force(t);
  const kids = term_kids(fl, s);
  return p(s, tail) || kids.some((x, i) => term_any(fl, x, p, tail && (s.$
    === "Let" ? i === kids.length - 1 : "Ann Lam Mat Rwt".includes(s.$))));
}

function term_nodes(fl: File, t: HTerm): number {
  let n = 0;
  term_any(fl, t, () => (n += 1) < 0);
  return n;
}

function term_const(t: HTerm): boolean {
  const s = Bend.term_strip(t);
  return s.$ === "Lit" ? lit_call(s) === null
    : s.$ === "Ctr" && memo(CONSTS, s, () => s.x.every(term_const));
}

function term_use(u: Bend.PMap<number>, p: Of<"Var">): number {
  return Bend.pmap_get(u, p.i) ?? 0;
}

function term_uses(fl: File, tm: HTerm): Bend.PMap<number> {
  return memo(USES, tm, () => {
    const t = term_force(tm);
    switch (t.$) {
      case "Var": {
        const p = probe_of(t);
        return p === DUMMY ? USE0 : Bend.pmap_set(USE0, p.i, 1);
      }
      case "Mat": {
        return Bend.pmap_union(term_uses(fl, t.h),
          term_uses(fl, t.m), Math.max);
      }
      default: {
        return term_kids(fl, t).reduce((u, x) =>
          Bend.pmap_union(u, term_uses(fl, x), (a, b) => a + b), USE0);
      }
    }
  });
}

function rest_use(fl: File, rest: HTerm[], p: Of<"Var">): number {
  return rest.reduce((n, r) => n + term_use(term_uses(fl, r), p), 0);
}

function fun_live(book: Bend.Book, x: HTerm, ty: HTerm | null): boolean {
  return mat_head(x) || (x.$ === "Lam"
    && quant_live(ty_all(book, ty).q));
}

function flat_call(fl: File, t: HTerm): boolean {
  const ck = term_spine(fl, t);
  return ck.k !== null && ck.b !== true && flat_of(ck.k);
}

// Dom
// ===

function live_dom([q]: Dom): boolean {
  return quant_live(q);
}

// Quant
// =====

function quant_live(q: Bend.Quant): boolean {
  return q.$ !== "None";
}

// Intr
// ====

function intr_of(fl: File, k: Name, js = false): Intr | undefined {
  const tld = fl.book.tlds[k];
  const it = tld?.$ === "Def" && tld.i === undefined && tld.b
    ? OPERATIONS[op_name(k)] : undefined;
  return it !== undefined && (js || it.C !== undefined || it.call === true)
    ? it : undefined;
}

function op_name(k: Name): string {
  return k.toLowerCase().replace(/[./]/g, "_");
}

// Tele
// ====

function tele_unbind(book: Bend.Book, T: HTerm): { doms: Dom[]; ret: HTerm } {
  return memo(TELES, T, () => Bend.tele_unbind(book, T));
}

// Ty
// ==

function ty_ann(t: HTerm): HTerm | null {
  const v = term_force(t);
  return v.$ === "Ann" ? v.T : null;
}

function ty_wnf(book: Bend.Book, ty: HTerm | null): HTerm | null {
  return ty && Bend.term_wnf(book, ty);
}

function ty_all(book: Bend.Book, ty: HTerm | null): Of<"All"> {
  return Bend.tele_open(book, ty!)!;
}

function ty_peel(tm: HTerm, ty: HTerm | null): [HTerm, HTerm | null] {
  let x = term_force(tm);
  while (x.$ === "Ann" || x.$ === "Rwt") {
    ty = x.$ === "Ann" ? x.T : ty;
    x = term_force(x.$ === "Ann" ? x.x : x.f);
  }
  return [x, ty];
}

function ty_adt(book: Bend.Book, A: HTerm | null): Of<"ADT"> | null {
  const t = ty_wnf(book, A);
  return t?.$ === "ADT" ? t : null;
}

function adt_of(book: Bend.Book, A: HTerm | null): Of<"ADT"> {
  const adt = ty_adt(book, A)!;
  if (adt.k === "Array") {
    lay_el(book, adt.x[0]);
  }
  return adt;
}

function ty_holds(book: Bend.Book, A: HTerm | null,
  p: (t: HTerm | null) => boolean | null, seen = new Set<Name>()): boolean {
  const t = ty_wnf(book, A);
  const got = p(t);
  if (got !== null || t?.$ !== "ADT") {
    return got === true;
  }
  if (t.x.some((x) => ty_holds(book, x, p, seen))) {
    return true;
  }
  const tld = book.tlds[t.k];
  if (tld?.$ !== "ADT" || seen.has(t.k)) {
    return false;
  }
  seen.add(t.k);
  return tld.c.some((c) =>
    ctr_doms(book, c, t.x).some((f) => ty_holds(book, f, p, seen)));
}

function ty_clo(book: Bend.Book, A: HTerm | null): boolean {
  return ty_holds(book, A, (t) => t?.$ === "ADT"
    ? WORDS[t.k] !== undefined ? false : null
    : !["Typ", "Qua", "Min", "Eql"].includes(t?.$ ?? ""));
}

function type_adts(fl: File, T: HTerm): Name[] {
  const t = ty_wnf(fl.book, T);
  switch (t?.$) {
    case "All": {
      return [...type_adts(fl, t.A), ...type_adts(fl, t.B(DUMMY))];
    }
    case "Lam": {
      return type_adts(fl, t.f(DUMMY));
    }
    case "ADT": {
      return [...WORDS[t.k] === undefined && t.k !== "Array"
        ? [t.k] : [], ...t.x.flatMap((x) => type_adts(fl, x))];
    }
    default: {
      return [];
    }
  }
}

// Lay
// ===

// An Array, an IO.OP, a recursive datatype, and a datatype with a field
// that re-enters it under layout (a family hid the cycle) are one box.
// An Array cell takes the open layout of its element type (the return
// type of its constructors), so all callers agree. lay_el refuses an
// open element type; adt_of and js_expr call it only for that check.

function lay_of(book: Bend.Book, A: HTerm | null): Lay {
  const t = ty_adt(book, A);
  if (t === null) {
    return BOX;
  }
  const key = Bend.term_key(Bend.term_lower(t));
  return WORDS[t.k] ?? memo(LAYS, key, () => {
    const tld = book.tlds[t.k];
    if (t.k === "Array" || t.k === "IO.OP" || tld?.$ !== "ADT"
      || tld.c.some((c) => ctr_doms(book, c).some((F) => ty_holds(book, F,
        (u) => u?.$ !== "ADT" || WORDS[u.k] ? false : u.k === t.k || null)))) {
      return BOX;
    }
    LAYS.set(key, BOX);
    const lay = lay_pack(tld.c.map((c) =>
      [c.k, ctr_doms(book, c, t.x).map((A) => lay_of(book, A))]));
    return lay.ks.length > WIDE ? BOX : lay;
  });
}

function lay_el(book: Bend.Book, A: HTerm | null): Lay {
  const t = ty_adt(book, A) ?? die("an open Array element type");
  const tld = book.tlds[t.k];
  return lay_of(book, tld?.$ === "ADT" && tld.c[0]
    ? tele_unbind(book, tld.c[0].T).ret : A);
}

function lay_pack(arms: [Name, Lay[]][]): Lay {
  const tag = arms.length > 1 ? 1 : 0;
  const ks: Kind[] = tag === 1 ? ["w32"] : [];
  for (const [, lays] of arms) {
    let at = tag;
    for (const k of lays.flatMap((lay) => lay.ks)) {
      const old = ks[at] ?? "w32";
      ks[at++] = old === "box" || k === "box" ? "box"
        : old === "w64" || k === "w64" ? "w64" : "w32";
    }
  }
  return { ks, arms: Object.fromEntries(arms) };
}

function lay_node(book: Bend.Book, k: Name): Lay {
  return memo(NODES, k, () => {
    const lay = lay_pack([[k, (book.ctrs[k] ? ctr_doms(book, book.ctrs[k])
      : []).map((A) => lay_of(book, A))]]);
    while (lay.ks.length > WIDE && lay.ks.length & (lay.ks.length - 1)) {
      lay.ks.push("w32");
    }
    return lay;
  });
}

function lay_eq(a: Lay, b: Lay): boolean {
  return a === b || JSON.stringify(a) === JSON.stringify(b);
}

function lay_c(k: Kind): string {
  return k === "w32" ? "u32" : "Term";
}

function lay_box(lay: Lay): boolean {
  return lay.arms === null && lay.ks[0] === "box";
}

function lay_arr(lay: Lay): { arr: boolean; lgs: number } {
  return { arr: lay.ks.some((k) => k !== "w32"),
    lgs: cls_fit(Math.max(1, lay.ks.length)) };
}

// Ctr
// ===

function ctr_adt(fl: File, x: Of<"Ctr">,
  ty: HTerm | null): [Of<"ADT">, number | null] {
  const ctr = fl.book.ctrs[x.k];
  const adt = adt_of(fl.book, ty ?? (ctr ? tele_unbind(fl.book, ctr.T).ret
    : null));
  if (ty === null && adt.x.length > 0) {
    die("a constructor outside a datatype");
  }
  return [adt, adt.k === "U32" || adt.k === "F32"
    ? Bend.u32_from_term(x, adt.k) : null];
}

function ctr_tail(book: Bend.Book, ctr: Bend.Ctr, xs?: HTerm[]): Dom[] {
  const doms = tele_unbind(book, xs === undefined ? ctr.T
    : Bend.tele_fill(book, ctr.T, xs, Bend.ctx_nil())).doms;
  return doms.slice(doms.length - ctr.n);
}

function ctr_doms(book: Bend.Book, ctr: Bend.Ctr, xs?: HTerm[]): HTerm[] {
  return ctr_tail(book, ctr, xs).filter(live_dom).map(([, , A]) => A);
}

function ctr_flds(book: Bend.Book, k: Name, xs: HTerm[]): HTerm[] {
  const ds = book.ctrs[k] ? ctr_tail(book, book.ctrs[k]) : [];
  return xs.filter((_, j) => ds[j] === undefined || live_dom(ds[j]));
}

function ctr_build(fl: File, k: Name, exprs: string[], stat = false): string {
  const cid = cid_mac(k);
  const node = lay_node(fl.book, k);
  if (exprs.length === 0 || (node.ks.length === 1 && node.ks[0] === "w32")) {
    return `term_pak(${cid}, ${exprs[0] ?? 0})`;
  }
  if (stat) {
    fl.stat.add(k);
    const at = memo(fl.lits, exprs.join(", "), () =>
      fl.img.push(...exprs) - exprs.length);
    return `term_ctr(${cid}, STAT_OFF + ${at})`;
  }
  const alloc = `heap_alloc(e, cls_fit(${exprs.length}))`;
  const at = fl.spares.findIndex((s) =>
    cls_fit(s.words) === cls_fit(exprs.length));
  const s = at < 0 ? null : fl.spares.splice(at, 1)[0];
  const got = s === null ? alloc
    : s.z ? `${s.name} >= HEAP_OFF ? ${s.name} : ${alloc}` : s.name;
  return `term_ctr(${cid}, ${node_fill(fl, "nd", got, exprs,
    fl.hot.has(k))})`;
}

function facts_packed(fl: File, t: HTerm): boolean {
  const s = term_strip(t);
  return s.$ === "Ctr"
    && ["", "w32"].includes(lay_node(fl.book, s.k).ks.join());
}

// Mat
// ===

// A Nat or word match's rows hold the arm, the low bits known (32: a
// hit), their value and the fields bound; a Nat row knows its level
// and binds the scrutinee less it. A default covers the deeper rows
// that are its instance (the flattener's substitution replayed). A U32
// match reads a table when its hits cover over half of 0..max and all
// other rows share one body. The default arm of a match is named "".

function mat_head(t: HTerm): boolean {
  return t.$ === "Mat" || t.$ === "Efq";
}

function mat_arms(t: HTerm): { arms: [Name, HTerm][]; end: HTerm } {
  const arms: [Name, HTerm][] = [];
  let cur = t;
  for (let m = term_strip(cur); m.$ === "Mat"; m = term_strip(cur)) {
    arms.push([m.k, m.h]);
    cur = m.m;
  }
  return { arms, end: cur };
}

function mat_nats(x: HTerm): Row[] {
  const rows: Row[] = [];
  for (let m = x, n = 0; ; n++) {
    const { arms, end } = mat_arms(m);
    const { Zero, Succ } = Object.fromEntries(arms);
    rows.push([Zero ?? end, 64, n, Zero ? 0 : 1]);
    m = term_strip(Succ ?? end);
    if (Succ === undefined || m.$ !== "Mat") {
      return [...rows, [Succ ?? end, 0, Succ ? n + 1 : n, 1]];
    }
  }
}

function mat_lits(x: HTerm): Row[] {
  const ws: Row[] = [];
  const key = (t: HTerm): string => JSON.stringify(Bend.term_lower(t),
    (k, v) => k === "s" ? undefined : v?.$ === "Ann" ? Bend.term_strip(v) : v);
  const walk = (t: HTerm, j: number, n: number,
    cov: ((w: Of<"Ctr">) => HTerm) | null): void => {
    const h = mat_arms(t).arms[0]?.[1];
    if (h !== undefined && j === 32) {
      ws.push([h, j, n, 0]);
      return;
    }
    const { arms, end } = mat_arms(h ?? t);
    const e = h === undefined ? 1 : 2;
    const inst = (w: Of<"Ctr">): HTerm => (e === 1 ? [w] : w.x)
      .reduce((f, a) => Bend.term_apply(f, a), end);
    const w = Bend.Ctr("WCon", [probe("b"), probe("t")]) as Of<"Ctr">;
    const own = arms.length < 2 && (cov === null
      || key(cov(w)) !== key(inst(w)));
    const sub = own ? inst : cov;
    for (const [k, a] of arms) {
      walk(a, j + 1, n + (k === "True" ? 2 ** j : 0), sub && ((v) =>
        sub(Bend.Ctr("WCon", [Bend.Ctr(k, []), v]) as Of<"Ctr">)));
    }
    if (own) {
      ws.push([end, j, n, e]);
    }
  };
  walk(mat_arms(x).arms[0][1], 0, 0, null);
  return ws;
}

function mat_rows(fl: File, x: HTerm, ty: HTerm | null) {
  const all = ty_all(fl.book, ty);
  const adt = adt_of(fl.book, all.A);
  const ret = all.B(DUMMY);
  if (adt.k === "Nat") {
    const rows = mat_nats(x);
    return { adt, ret, rows, cells: rows.map(([h]) => h) };
  }
  const rows = WORDS[adt.k] === W32 ? mat_lits(x) : null;
  if (adt.k !== "U32" || rows === null) {
    return { adt, ret, rows, cells: null };
  }
  const hit = new Map(rows.flatMap(([h, j, n]) => j === 32 ? [[n, h]] : []));
  const out = rows.filter(([, j]) => j < 32);
  const rs = new Set(out.map(([o]) => emit_row(fl, o, ret)));
  const len = Math.max(-1, ...hit.keys()) + 1;
  return { adt, ret, rows, cells: hit.size * 2 > len && rs.size === 1
    ? [...Array(len + 1)].map((_, i) => hit.get(i) ?? out[0][0]) : null };
}

function lits_cond(w: string, j: number, n: number): string {
  return j >= 32 ? `${w} == ${n}` : `(${w} & ${2 ** j - 1}) == ${n}`;
}

function mat_ctrs(fl: File, x: HTerm, adt: Of<"ADT">,
  keep = false): [Name, HTerm][] {
  const { arms, end } = mat_arms(x);
  return keep || arms.length < Bend.book_adt(fl.book, adt, Bend.Emp()).c.length
    ? [...arms, ["", end]] : arms;
}

// Fun
// ===

// fun_of raises a def: its arity grows by the lambdas its body opens
// past its parameters, under every arm. A def is flat when it and every
// def it calls have no fork, no bang call and only tail self-calls.
// loop_of gives a def's tail cycle (Tarjan over its tail callees).

function fun_of(fl: File, k: Name): Fun {
  return memo(FUNS, k, () => {
    const tld = fl.book.tlds[k];
    if (tld?.$ !== "Def") {
      return { n: 0, h: null, live: [], lays: [BOX, BOX], ret: BOX };
    }
    const doms = tele_unbind(fl.book, tld.T).doms;
    const h = tld.e === undefined ? null : Bend.term_higher(tld.e);
    const n = tld.n + (h === null ? 0
      : Math.min(def_raise(fl.book, h, tld.n), doms.length - tld.n));
    const live = doms.slice(0, n).filter(live_dom);
    const lays = live.map(([, , A]) => lay_of(fl.book, A));
    if (def_foreign(tld)) {
      return { n, h, live, lays: [...lays.map(() => BOX), BOX], ret: BOX };
    }
    const ret = lay_of(fl.book, Bend.tele_fill(fl.book, tld.T,
      Array(n).fill(DUMMY), Bend.ctx_nil()));
    const wide = lays.flatMap((l) => l.ks).length > WIDE;
    return { n, h, live, lays: wide ? lays.map((l) => l.ks.length > 1 ? BOX
      : l) : lays, ret: ret.ks.length === 0 ? BOX : ret };
  });
}

function brw_of(fl: File, k: Name): boolean[] {
  return memo(BRWS, k, () => {
    const { live, lays } = fun_of(fl, k);
    return lays.map((l, i) => done_live(fl.book.tlds[k])
      && l.ks.includes("box") && ty_adt(fl.book, live[i][2])?.k !== "Array"
      && !fl.own.has(k + "~" + i));
  });
}

function def_raise(book: Bend.Book, t: HTerm, left: number): number {
  const s = term_strip(t);
  if (s.$ === "Lam") {
    const b = term_open(s).b;
    return left > 0 ? def_raise(book, b, left - 1) : 1 + def_raise(book, b, 0);
  }
  if (s.$ === "Mat") {
    return Math.min(def_raise(book, s.h, left - 1 + book.ctrs[s.k].n),
      def_raise(book, s.m, left));
  }
  return s.$ === "Efq" ? 99 : 0;
}

function def_foreign(tld: Bend.TLD | undefined):
  tld is Bend.Def & { i: string[] } {
  return tld?.$ === "Def" && tld.i !== undefined;
}

function done_live(tld: Bend.TLD | undefined): tld is Bend.Def {
  return tld?.$ === "Def" && tld.v !== null;
}

function done_defs(fl: File, live = done_live): [Name, Bend.Def][] {
  return [...SRCS.keys()].map((k) => [k, fl.book.tlds[k]] as [Name, Bend.Def])
    .filter((p) => live(p[1]));
}

function loop_of(fl: File, k: Name): Name[] {
  const stack: Name[] = [];
  const visit = (k: Name): number => {
    const id = stack.push(k) - 1;
    let low = id;
    let self = false;
    if (done_live(fl.book.tlds[k])) {
      term_any(fl, fun_of(fl, k).h!, (s, tail) => {
        const d = tail ? term_spine(fl, s).k : null;
        if (d !== null && done_live(fl.book.tlds[d])) {
          const at = stack.indexOf(d);
          self ||= d === k;
          low = Math.min(low, at >= 0 ? at : LOOPS.has(d) ? low : visit(d));
        }
        return false;
      });
    }
    if (low === id) {
      const all = stack.splice(id);
      all.forEach((d) => LOOPS.set(d, all.length > 1 || self ? all : []));
    }
    return low;
  };
  return memo(LOOPS, k, () => (visit(k), LOOPS.get(k)!));
}

function flat_of(k: Name): boolean {
  return memo(FLATS, k, () => {
    const deps = SRCS.get(k);
    FLATS.set(k, false);
    return deps != null && [...deps].every(flat_of);
  });
}

// Io
// ==

export function io_base(book: Bend.Book, t: HTerm): HTerm[] | null {
  const io = book.tlds["IO"];
  if (io?.$ !== "Def" || io.b !== true) {
    return null;
  }
  const tlds = Object.assign(Object.create(null), book.tlds,
    { IO: { ...io, v: null } });
  const [h, xs] = Bend.term_unapply(Bend.term_wnf({ ...book, tlds }, t));
  return h.$ === "Ref" && h.k === "IO" ? xs : null;
}

export function io_type(book: Bend.Book): HTerm | null {
  const main = book.tlds["main"];
  const xs = main?.$ === "Def" ? io_base(book, main.T) : null;
  if (xs !== null && def_foreign(main as Bend.Def)) {
    die("main must be a filled def: a foreign main cannot anchor IO");
  }
  return xs?.length === 1 ? xs[0] : null;
}

export function io_run(book: Bend.Book, args: string[] = []): number {
  const src = js_lib(book, ["main"], null) + "\n" + RUNTIME_MAIN
    + "\ncli_args = " + JSON.stringify(args) + ";\nreturn io_run("
    + js_sat("main") + ");";
  return new Function("require", src)(import.meta.require) as number;
}

// File
// ====

// A nested scope is a copy of its File. The emitter is the analysis: a
// boxed parameter starts borrowed (brwl) and becomes owned (own) when
// owned or unlent; a lend is asked by a holder or passed on from a lent
// root (k~i<j~q). A shared value heats its type (hot); a family stuck
// on an open index heats its arms' types once, its arguments at every
// instantiation. compile_book emits until a pass changes no fact.

function file_book(src: Bend.Book, roots: Name[], js: boolean): File {
  book_owned(src);
  [TELES, SRCS, LOOPS, NODES, LAYS, FLATS, FUNS, BRWS, IDS, TAKEN]
    .forEach((m) => m.clear());
  "FID_EXIT FID_ENTER FID_T CID_T".split(" ").forEach((id) => TAKEN.add(id));
  PROBES.length = 1;
  const fl: File = {
    book: src,
    js,
    bangs: new Set(),
    sites: new Map(),
    hot: new Set(),
    stat: new Set(),
    own: new Set(),
    lend: new Set(),
    segs: [],
    spins: [],
    spun: new Map(),
    clos: new Set(),
    tabs: new Map(),
    tails: new Map(),
    img: [],
    lits: new Map(),
    consts: new Map(),
    fresh: new Map(),
    brwl: new Map(),
    seg: seg_new("", BOX, []),
    spares: [],
    uses: new Map(),
    rest: [],
    def: "",
  };
  for (const queue = roots.slice(); queue.length > 0;) {
    const d = queue.shift() as Name;
    if (SRCS.has(d)) {
      continue;
    }
    memo_gc();
    const tld = fl.book.tlds[d];
    const deps = new Set<Name>();
    const refs = new Set<Name>();
    let flat = done_live(tld);
    SRCS.set(d, null);
    for (const x of tld?.$ === "ADT" ? tld.c : tld ? [tld] : []) {
      queue.push(...type_adts(fl, x.T));
    }
    if (!done_live(tld)) {
      continue;
    }
    term_any(fl, fun_of(fl, d).h!, (s, tail) => {
      if (s.$ === "Ann") {
        queue.push(...type_adts(fl, s.T));
      }
      if (s.$ === "Ref") {
        if (s.b) {
          fl.bangs.add(s.k);
        }
        if (intr_of(fl, s.k) === undefined) {
          refs.add(s.k);
          fl.sites.set(s.k, (fl.sites.get(s.k) ?? 0) + 1);
        }
      }
      const ck = term_spine(fl, s);
      if (ck.k !== null && ck.k !== d) {
        deps.add(ck.k);
      }
      if ((s.$ === "Let" && s.k.length >= 2)
        || (ck.k !== null && (ck.b === true || (ck.k === d && !tail)))) {
        flat = false;
      }
      return false;
    });
    SRCS.set(d, flat ? deps : null);
    queue.push(...refs);
  }
  return fl;
}

function book_owned(src: Bend.Book): void {
  for (const k of OWNED) {
    if (src.tlds[k] !== undefined && src.tlds[k].b !== true) {
      die(k + " is a name the compiler encodes itself: name yours apart");
    }
  }
  for (const [k, tld] of Object.entries(src.tlds)) {
    if (def_foreign(tld) && k in src.ctrs) {
      die(k + " names both a constructor and a foreign def: name one apart");
    }
  }
}

function facts_hot(fl: File, B: HTerm | null, force: boolean,
  local = false): void {
  const w = ty_wnf(fl.book, B);
  if (w?.$ === "Lam") {
    return facts_hot(fl, w.f(DUMMY), force, local);
  }
  if (w?.$ !== "ADT") {
    if (!force || (w?.$ === "App" && facts_fam(fl, w, local))) {
      return;
    }
    if (w?.$ === "Mat") {
      return term_kids(fl, w).forEach((h) => facts_hot(fl, h, true, local));
    }
    const dom = w?.$ === "Var" && !local && tele_unbind(fl.book,
      fl.book.tlds[fl.def].T).doms[w.i];
    if (dom && dom[1] === w.k && !live_dom(dom)) {
      fl.hot.add(fl.def + "~" + w.i);
    } else if ("All Var App".includes(w?.$!)) {
      fl.hot.add("*");
    }
    return;
  }
  const tk = "t:" + w.k;
  const hot = force || fl.hot.has(tk);
  w.x.forEach((x) => facts_hot(fl, x, hot, local));
  if (!hot || fl.hot.has(tk)) {
    return;
  }
  fl.hot.add(tk);
  const tld = fl.book.tlds[w.k];
  if (tld?.$ === "ADT") {
    for (const c of tld.c) {
      fl.hot.add(c.k);
      facts_ctr(fl, c, w.x);
    }
  }
}

function facts_fam(fl: File, w: HTerm, local: boolean): boolean {
  const m = term_spine(fl, w);
  const fam = m.tld?.$ === "Def" && m.tld.v !== null && term_strip(
    Bend.term_unapply(m.all.reduce((b, x) => Bend.term_apply(b, x),
      m.tld.v))[0]);
  if (!fam || fam.$ !== "Mat") {
    return false;
  }
  m.all.forEach((x) => facts_hot(fl, x, true, local));
  const key = "m:" + (m.t as Of<"Ref">).k;
  if (!fl.hot.has(key)) {
    fl.hot.add(key);
    facts_hot(fl, fam, true, local);
  }
  return true;
}

function facts_ctr(fl: File, c: Bend.Ctr, xs: HTerm[]): void {
  const own = ctr_tail(fl.book, c, xs).some((d) => !live_dom(d));
  ctr_doms(fl.book, c, xs).forEach((A) => facts_hot(fl, A, true, own));
}

function facts_lend(fl: File): void {
  for (let n = -1; n !== fl.lend.size;) {
    n = fl.lend.size;
    fl.lend.forEach((l) => {
      const [a, r] = l.split("<");
      if (r !== undefined && fl.lend.has(r)) {
        fl.lend.add(a);
      }
    });
  }
  BRWS.forEach((bs, k) => bs.forEach((b, i) => {
    if (b && !fl.lend.has(k + "~" + i)) {
      fl.own.add(k + "~" + i);
    }
  }));
}

function file_push(fl: File, line: string): void {
  fl.seg.lines.push(line);
}

function block(fl: File, open: string, go: () => void): void {
  file_push(fl, open);
  go();
  file_push(fl, "}");
}

// Cls
// ===

function cls_fit(words: number): number {
  return 32 - Math.clz32(words - 1);
}

// Spare
// =====

function spare_free(fl: File, words: number, name: string, z: boolean): void {
  file_push(fl,
    `${z ? "spare_free" : "heap_free"}(e, cls_fit(${words}), ${name});`);
}

function spare_flush(fl: File): void {
  for (const s of fl.spares.splice(0).reverse()) {
    spare_free(fl, s.words, s.name, s.z);
  }
}

// Seg
// ===

// A segment enters by popping its frame and reading its
// parameters from the frame slots, then from the bank (r0..).

function seg_new(name: string, ret: Lay, params: string[],
  ks: Kind[] = params.map(() => "w64"), frame: Seg["frame"] = null): Seg {
  return { fid: seg_fid(name), def: name, ret, lines: [], params, ks, frame,
    refs: new Set() };
}

function seg_fid(k: Name): string {
  return name_id("FID_", k);
}

function seg_take(seg: Seg): string[] {
  const { pop, at } = seg.frame ?? { pop: 0, at: [] };
  return [...pop > 0 ? [`WL_POPN(${pop});`] : [], ...seg.params.map((p, i) =>
    `${lay_c(seg.ks[i])} ${p} = ${i < at.length ? `STK(${at[i]})`
      : `r${i - at.length}`};`)];
}

function seg_text(lines: string[], tab: number): string[] {
  return lines.map((l) => {
    tab -= Number(l.startsWith("}"));
    const out = "  ".repeat(tab) + l;
    tab += Number(l.endsWith("{"));
    return out;
  });
}

function seg_ref(fl: File, fid: string): string {
  fl.seg.refs.add(fid);
  return fid;
}

function seg_clo(fl: File, fid: string, words: string[]): string {
  fl.clos.add(fid);
  return `term_clo(${seg_ref(fl, fid)}, ${words.length === 0 ? 0 : node_fill(
    fl, "nd", `heap_alloc(e, cls_fit(${words.length}))`, words)})`;
}

function seg_name(fl: File, stem: string): string {
  return fl.seg.def.split("$")[0] + "$" + stem + fl.segs.length;
}

function seg_open(fl: File, name: string, ret: Lay, frame: Seg["frame"],
  live: [Of<"Var">, Bind][], res: Val, rest: HTerm[]): File {
  const olds = live.flatMap(([, b]) => b.val.ws);
  const news = olds.map((w) => name_local(fl, w.replace(/_\d+$/, "")));
  const seg = seg_new(name, ret, [...news, ...res.ws],
    [...live.flatMap(([, b]) => b.val.lay.ks), ...res.lay.ks], frame);
  fl.segs.push(seg);
  fl = { ...fl, seg, spares: [], uses: new Map() };
  olds.forEach((w, i) => {
    if (fl.brwl.has(w)) {
      fl.brwl.set(news[i], fl.brwl.get(w)!);
    }
  });
  let i = 0;
  live.forEach(([p, b]) => bind_uses(fl, p,
    val_new(news.slice(i, i += b.val.ws.length), b.val.lay), rest, b.A,
    false));
  return fl;
}

// Node
// ====

function node_fill(fl: File, k: string, alloc: string,
  exprs: string[], shr = false): string {
  const nd = name_local(fl, k);
  file_push(fl, `u64 ${nd} = ${alloc};`);
  exprs.forEach((w, j) => {
    file_push(fl, `e.mem[${nd} + ${j}] = ${shr ? `rfc_seal(e, ${w})` : w};`);
  });
  return nd;
}

function node_fields(fl: File, t: string, k: Name, tail = false): Val[] {
  const node = lay_node(fl.book, k);
  const n = node.ks.length;
  if (n === 0 || (n === 1 && node.ks[0] === "w32")) {
    return node.arms![k].map((lay) =>
      val_new(lay.ks.map(() => `term_loc(${t})`), lay));
  }
  const r = fl.brwl.get(t);
  const z = r === undefined && (fl.hot.has(k) || fl.stat.has(k));
  const sp = name_local(fl, "sp");
  let fb = `e.mem[${sp} + `;
  if (z) {
    fb = name_local(fl, "fb") + "[";
    file_push(fl, `Term ${fb}${n}];`);
    file_push(fl, `u64 ${sp} = ctr_take(e, ${t}, ${n}, ${fb.slice(0, -1)});`);
  } else {
    file_push(fl, `u64 ${sp} = ${r === undefined ? "term_loc(" : "term_peek(e, "
    }${t});`);
  }
  const ws = emit_hold(fl, node.ks.map((_, j) => `${fb}${j}]`), "f", node.ks);
  if (r !== undefined) {
    ws.forEach((w, j) => {
      if (node.ks[j] === "box") {
        fl.brwl.set(w, r);
      }
    });
  } else if (tail) {
    fl.spares.push({ words: n, name: sp, z });
  } else {
    spare_free(fl, n, sp, z);
  }
  return val_arm(val_new(ws, node));
}

// Val
// ===

// A word rooted in a borrowed parameter (brwl) is not owned. val_own is
// the one gate: at an owned position a rooted word owns its root; lent
// at `at`, a rooted word passes its lend on, and an unheld owned box
// owns `at`. A destination every arm fills from one root stays rooted.

function val_new(ws: string[], lay: Lay, stat = false): Val {
  return { ws, lay, stat };
}

function val_arm(v: Val, k = Object.keys(v.lay.arms!)[0]): Val[] {
  let at = Object.keys(v.lay.arms!).length > 1 ? 1 : 0;
  return v.lay.arms![k].map((lay) =>
    val_new(v.ws.slice(at, at += lay.ks.length), lay));
}

function val_hold(fl: File, v: Val, k: string): Val {
  return val_new(v.ws.map((w, j) => emit_alias(fl, w, k, v.lay.ks[j])),
    v.lay);
}

function val_own(fl: File, v: Val, at: string | null = null,
  held = false): string[] {
  v.ws.forEach((w, j) => {
    const r = fl.brwl.get(w);
    if (r !== undefined && at !== null) {
      fl.lend.add(at + "<" + r);
    } else if (r !== undefined
      || (at !== null && !held && v.lay.ks[j] === "box")) {
      fl.own.add(r ?? at!);
    }
  });
  return v.ws;
}

function val_owned(fl: File, v: Val): string[] {
  return v.ws.filter((w, j) => v.lay.ks[j] === "box" && !fl.brwl.has(w));
}

function val_brw(fl: File, v: Val): boolean {
  return val_owned(fl, v).length === 0;
}

function val_sink(fl: File, v: Val): void {
  val_owned(fl, v).forEach((w) => file_push(fl, `term_sink(e, ${w});`));
}

function val_to(fl: File, v: Val, lay: Lay): Val {
  if (lay_eq(v.lay, lay)) {
    return v;
  }
  if (lay_box(lay)) {
    return val_new([val_box(fl, v)], BOX);
  }
  if (lay_box(v.lay)) {
    return val_unbox(fl, v, lay);
  }
  return val_arms(fl, lay, v.ws[0], (t, i) => `${t} == ${i}`, (k) =>
    val_arm(v, k).map((f, j) => val_to(fl, f, lay.arms![k][j])));
}

function val_arms(fl: File, lay: Lay, sel: string,
  cond: (t: string, i: number) => string, read: (k: Name) => Val[]): Val {
  const arms = Object.keys(lay.arms!);
  if (arms.length <= 1) {
    return val_new(arms.flatMap(read).flatMap((g) => g.ws), lay);
  }
  const out = emit_dst(fl, lay, "o").ws;
  const t = emit_alias(fl, sel, "t");
  const rs: string[][] = out.map(() => []);
  const bodies = arms.map((k, i) => () => {
    file_push(fl, `${out[0]} = ${i};`);
    read(k).flatMap((g) => g.ws).forEach((w, n) => {
      rs[1 + n].push(fl.brwl.get(w) ?? "");
      file_push(fl, `${out[1 + n]} = ${w};`);
    });
  });
  emit_chain(fl, (i) => cond(t, i), bodies);
  rs.forEach((r, k) => {
    if (r[0] && r.every((x) => x === r[0])) {
      fl.brwl.set(out[k], r[0]);
    } else {
      r.filter((x) => x).forEach((x) => fl.own.add(x));
    }
  });
  return val_new(out, lay);
}

function val_box(fl: File, v: Val): string {
  if (v.lay.arms === null) {
    return val_own(fl, v)[0];
  }
  const arms = Object.keys(v.lay.arms);
  const build = (bl: File, k: Name): string => {
    const fs = lay_node(fl.book, k).arms![k];
    return ctr_build(bl, k, val_arm(v, k).flatMap((f, j) =>
      val_own(bl, val_to(bl, f, fs[j]))));
  };
  if (arms.length <= 1) {
    return arms.map((k) => build(fl, k))[0] ?? "0";
  }
  const out = emit_hold(fl, ["0"], "b")[0];
  const tag = emit_alias(fl, v.ws[0], "t");
  emit_chain(fl, (i) => `${tag} == ${i}`, arms.map((k) => () => {
    const bl = { ...fl, spares: [] };
    file_push(bl, `${out} = ${build(bl, k)};`);
    spare_flush(bl);
  }));
  return out;
}

function val_unbox(fl: File, v: Val, lay: Lay): Val {
  if (lay.arms === null) {
    return val_new(v.ws, lay);
  }
  const t = emit_alias(fl, v.ws[0], "u");
  return val_arms(fl, lay, t, (_, i) =>
    `term_aux(${t}) == ${cid_mac(Object.keys(lay.arms!)[i])}`, (k) =>
    node_fields(fl, t, k).map((f, j) => val_to(fl, f, lay.arms![k][j])));
}

// Arr
// ===

function arr_lay(el: Lay): Lay {
  return lay_pack([["Tuple", [BOX, el]]]);
}

function arr_cells(fl: File, l: string, at: string, el: Lay, box: string): Val {
  const { arr } = lay_arr(el);
  return val_new(emit_hold(fl, el.ks.map((k, j) => k === "box"
    ? box.replaceAll("$", `${l} + ${at} + ${j}`)
    : `blk_read(e.mem, ${Number(arr)}, ${l}, ${at} + ${j})`), "c",
  el.ks), el);
}

function arr_new(fl: File, d: string, v: Val, el: Lay): string {
  const { arr, lgs } = lay_arr(el);
  const ws = val_own(fl, val_to(fl, v, el));
  const fv = name_local(fl, "fv");
  file_push(fl, `Term ${fv}[${Math.max(1, ws.length)}];`);
  ws.forEach((w, j) => file_push(fl, `${fv}[${j}] = ${w};`));
  return `blk_new(e, ${Number(arr)}, ${d}, ${lgs}, ${ws.length}, ${fv})`;
}

function arr_op(fl: File, k: string, el: Lay, args: Val[]): Val {
  const { arr, lgs } = lay_arr(el);
  if (k === "array_new") {
    return val_new([arr_new(fl, args[0].ws[0], args[1], el)], BOX);
  }
  const a = emit_alias(fl, val_own(fl, args[0])[0], "a");
  if (k === "array_size") {
    return val_new([a, `(1ull << (blk_cls(${a}) - ${lgs}))`], arr_lay(W32));
  }
  const [l, at] = emit_hold(fl, [`blk_loc(e.mem, ${a})`,
    `blk_at(${a}, ${args[1].ws[0]}, ${lgs})`], "at");
  const old = arr_cells(fl, l, at, el,
    k === "array_get" ? "blk_keep(e, $)" : "e.mem[$]");
  if (k !== "array_get") {
    val_own(fl, val_to(fl, args[2], el)).forEach((w, j) => {
      file_push(fl, `blk_write(e.mem, ${Number(arr)}, ${l}, `
        + `${at} + ${j}, ${w});`);
    });
    if (k !== "array_swap") {
      val_sink(fl, old);
      return val_new([a], BOX);
    }
  }
  return val_new([a, ...old.ws], arr_lay(el));
}

function arr_leaf(fl: File, s: string, el: Lay): Val {
  const got = arr_cells(fl, `blk_loc(e.mem, ${s})`, "0", el,
    `blk_shr(${s}) ? blk_keep(e, $) : e.mem[$]`);
  file_push(fl, `blk_free(e, ${s});`);
  return got;
}

// Bind
// ====

// A binding counts its uses: the last takes the value, an earlier
// one shares it. A fresh binding of a shared box of a flat type
// unboxes before its first share, so its words copy, not its node.

function bind_pop(fl: File, x: HTerm): Val {
  const p = probe_of(x);
  const b = fl.uses.get(p)!;
  if (b.n <= 1) {
    fl.uses.delete(p);
    return b.val;
  }
  fl.uses.set(p, { ...b, n: b.n - 1 });
  val_owned(fl, b.val).forEach((w) => {
    file_push(fl, `${w} = term_keep(e, ${w}, 1);`);
    facts_hot(fl, b.A, true);
  });
  return b.val;
}

function bind_uses(fl: File, p: Of<"Var">, v: Val, rest: HTerm[], A: HTerm,
  fresh = true): void {
  const n = rest_use(fl, rest, p);
  const lay = lay_of(fl.book, A);
  if (fresh && n > 1 && lay_box(v.lay) && !lay_box(lay) && !val_brw(fl, v)) {
    v = val_unbox(fl, v, lay);
  }
  facts_hot(fl, A, fl.hot.has("*"));
  if (n > 0) {
    fl.uses.set(p, { val: v, n, A });
  } else {
    val_sink(fl, v);
  }
}

function bind_dead(fl: File, rest: HTerm[]): void {
  for (const [p, b] of [...fl.uses]) {
    const n = rest_use(fl, rest, p);
    if (n === 0) {
      fl.uses.delete(p);
      val_sink(fl, b.val);
    } else if (n < b.n) {
      fl.uses.set(p, { ...b, n });
    }
  }
}

// Die
// ===

function die(m: string): never {
  throw new Error(m);
}

// Memo
// ====

function memo<K, V>(m: Map<K, V>, k: K, f: () => V): V {
  const got = m.get(k);
  if (got !== undefined) {
    return got;
  }
  const out = f();
  m.set(k, out);
  return out;
}

function memo_gc(): void {
  [OPENS, USES, FOLDS, SPINES, CONSTS, LITS].forEach((m) => m.clear());
}

// Show
// ====

// A pure main prints through a descriptor of its type, a node per (type,
// boxed?): 0 U32, 1 F32, 2 Nat, 3 Char, 4 String, 5 Eql, 6 Array (element,
// lgs), 7 Data (boxed?, arms; per arm name, cid, fields, bracket, then an
// (offset, node) per field). An IO main has none; an unprintable type (a
// function, a Type, an erased or dependent field) refuses the build.

function show_main(book: Bend.Book): (number | Name)[] | null {
  const main = book.tlds["main"];
  if (main?.$ !== "Def" || (main.v === null && main.i === undefined)
    || book.tlds["IO"] === undefined) {
    die(book.tlds["IO"] === undefined ? "a build needs import Base"
      : "no main to run");
  }
  if (io_type(book) !== null) {
    return null;
  }
  const show: (number | Name)[] = [];
  let names = 0;
  const ids = new Map<string, number>();
  const refuse = (): never => die("main's type " + Bend.term_show(
    Bend.term_lower(main.T)) + " cannot be printed (a function, a Type, an"
    + " erased or dependent field)");
  const node = (T: HTerm, lay: Lay): number => {
    const t = ty_wnf(book, T) as HTerm;
    const box = lay_box(lay);
    const key = String(box) + Bend.term_key(Bend.term_lower(t));
    const adt = ty_adt(book, t);
    const tld = adt && book.tlds[adt.k];
    const kind = t.$ === "Eql" ? 5 : "U32 F32 Nat Char String . Array"
      .split(" ").indexOf(adt?.k ?? "") & 7;
    if (ids.has(key)) {
      return ids.get(key)!;
    }
    if (kind !== 5 && (adt === null || adt.k === "IO.OP" || tld?.$ !== "ADT")) {
      return refuse();
    }
    const id = show.push(kind) - 1;
    ids.set(key, id);
    const refs: [number, HTerm, Lay][] = [];
    if (kind === 3) {
      show.push(Number(box));
    } else if (kind === 6) {
      const el = lay_el(book, adt!.x[0]);
      refs.push([show.push(0, lay_arr(el).lgs) - 2, adt!.x[0], el]);
    } else if (kind === 7 && tld?.$ === "ADT") {
      show.push(Number(box), tld.c.length);
      for (const c of tld.c) {
        const fs = (box ? lay_node(book, c.k) : lay).arms![c.k];
        const doms = ctr_tail(book, c, adt!.x);
        let at = box || tld.c.length < 2 ? 0 : 1;
        show.push(names++, c.k, doms.length,
          c.k === "Tuple" ? 2 : Number(c.k === "Con" || c.k === "Nil"));
        for (const [f, d] of doms.entries()) {
          if (!live_dom(d)) {
            refuse();
          }
          refs.push([show.push(at, 0) - 1, d[2], fs[f]]);
          at += fs[f].ks.length;
        }
      }
    }
    for (const [at, T2, l] of refs) {
      show[at] = node(T2, l);
    }
    return id;
  };
  const lay = lay_of(book, main.T);
  node(main.T, lay.ks.length === 0 ? BOX : lay);
  return show;
}

// ANF
// ===

// A statement in normal form is a fork, a cut, a let of a
// value, or a tail. An over-application cuts its call prefix;
// a variable applied to erased arguments is the variable.

function anf(fl: File, t: HTerm, ty: HTerm | null = null): HTerm {
  const binds: [Of<"Var">, HTerm][] = [];
  const cut = (r: HTerm, T: HTerm | null): HTerm => {
    if (term_spine(fl, r).k === null || flat_call(fl, r)) {
      return r;
    }
    const p = probe("h");
    binds.push([p, Bend.Ann(r, T!)]);
    return Bend.Ann(p, T!);
  };
  const go = (u: HTerm, top: boolean, T: HTerm | null): HTerm => {
    const s = term_force(u);
    if (term_const(s)) {
      return s;
    }
    switch (s.$) {
      case "Ann": {
        const x = go(s.x, top, s.T);
        return x === s.x ? s : Bend.Ann(x, s.T, s.s);
      }
      case "Rwt": {
        return go(s.f, top, T);
      }
      case "Ctr": {
        const on = ctr_flds(fl.book, s.k, s.x);
        const xs = s.x.map((x) => on.includes(x) ? go(x, false, null) : x);
        return xs.every((x, j) => x === s.x[j]) ? s : Bend.Ctr(s.k, xs, s.s);
      }
      case "Ref":
      case "App": {
        const m = term_spine(fl, s);
        const spine = (v: HTerm): HTerm => {
          const f = term_force(v);
          if (f.$ === "Ann") {
            const x = spine(f.x);
            return x === f.x ? f : Bend.Ann(x, f.T, f.s);
          }
          if (f.$ !== "App") {
            return f;
          }
          if (m.t.$ === "Var" && !m.args.includes(f.x)) {
            return spine(f.f);
          }
          const g = cut(spine(f.f), ty_ann(f.f));
          const x = m.args.includes(f.x) ? go(f.x, false, null) : f.x;
          return g === f.f && x === f.x ? f : Bend.App(g, x, f.s);
        };
        const r = spine(s);
        return top ? r : cut(r, T);
      }
      case "Let": {
        const o = term_open(s);
        const on = let_live(fl, s);
        for (const [j, v] of s.v.entries()) {
          if (on[j]) {
            binds.push([o.ps[j], go(v, true, null)]);
          }
        }
        return go(o.b, top, T);
      }
      case "Lam": {
        const all = T && Bend.tele_open(fl.book, T);
        if (all === null || quant_live(all.q)) {
          return s;
        }
        return Bend.Ann(go(s.f(DUMMY), top, all.B(DUMMY)), all.B(DUMMY));
      }
      default: {
        return s;
      }
    }
  };
  const wrap = (b: HTerm): HTerm =>
    binds.reduceRight((b2, [p, v]) => let_open([p], [v], b2), b);
  const x = term_force(t);
  if (x.$ !== "Let") {
    const b = go(x, true, ty);
    return wrap(binds.length === 0 || ty === null ? b : Bend.Ann(b, ty));
  }
  const o = term_open(x);
  const on = let_live(fl, x);
  const ps = o.ps.filter((_, j) => on[j]);
  const vs = x.v.filter((_, j) => on[j]);
  if (ps.length === 0) {
    return o.b;
  }
  if (ps.length >= 2 && !vs.every((v) => term_spine(fl, v).k !== null)) {
    return anf(fl, ps.reduceRight((b, p, j) => let_open([p], [vs[j]], b), o.b));
  }
  const ws = vs.map((v) => go(v, true, null));
  return wrap(on.every(Boolean) && ws.every((w, j) => w === x.v[j]) ? x
    : let_open(ps, ws, o.b));
}

// Emit
// ====

// A call emits its nested arguments first, then pops the owned ones
// before it reads the borrowed ones (a read asks a lend). A closure
// moves its captures into a node, each one use of its binding. A jump's
// returns must agree or both be one word (a box holds a word as is);
// else the call becomes a cut. A fork runs a join task and a kid per
// call in parallel; in sequence, one frame serves every step and the
// last jumps into the joiner. A self-jump reads its parameters back, so
// the device's loop carries them typed (raytrace GPU 1.72x). A foreign
// def short of its continuation is an IO action that awaits it. On the C
// lane, an F32 table row is its bits, as a NaN payload has no JS number.

function emit_hold(fl: File, exprs: string[], k: string,
  ks?: Kind[]): string[] {
  return exprs.map((ex, i) => {
    const al = name_local(fl, k);
    const ty = fl.js ? "const" : lay_c(ks?.[i] ?? "w64");
    file_push(fl, `${ty} ${al} = ${ex};`);
    return al;
  });
}

function emit_alias(fl: File, e: string, k: string, kd?: Kind): string {
  return /^\w*_\d+$/.test(e) ? e : emit_hold(fl, [e], k, kd && [kd])[0];
}

function emit_task(fl: File, fid: string, rem: number, words: string[],
  cont = "WL_CONT", idx: string | number = "WL_IDX"): string {
  return node_fill(fl, "t",
    `task_node(e, ${seg_ref(fl, fid)}, ${cont}, ${idx}, ${rem})`, words);
}

function emit_frame(fl: File, words: string[], next: string): void {
  const ws = [...words, seg_ref(fl, next)];
  file_push(fl, `WL_ROOM(${ws.length});`);
  ws.forEach((w, i) => file_push(fl, `STK(${i}) = ${w};`));
  file_push(fl, `WL_PUSHN(${ws.length});`);
}

function emit_jump(fl: File, args: string[], k: Name, bang?: boolean): void {
  const fid = seg_fid(k);
  fl.seg.fork ||= bang;
  if (bang || fl.seg.def !== k) {
    block(fl, `if (${bang ? "!seq"
      : `!DEVICE && !seq && fid_nofk(${fid})`}) {`, () =>
      file_push(fl, `return term_tsk(${fid}, ${
        emit_task(fl, fid, 0, args)});`));
  }
  args.forEach((a, i) => file_push(fl, `r${i} = ${a};`));
  if (fl.seg.def !== k) {
    return file_push(fl, `WL_JMP(${seg_ref(fl, fid)});`);
  }
  fl.seg.spin = true;
  fl.seg.params.forEach((p, i) => file_push(fl, `${p} = r${i};`));
  file_push(fl, `WL_AGAIN(${fl.seg.fid});`);
}

function emit_args(fl: File, ck: Spine, jump = false, fork = false): string[] {
  const k = ck.k!;
  const brw = brw_of(fl, k);
  ck.all.forEach((a, q) => {
    if (fl.hot.has(k + "~" + q)) {
      facts_hot(fl, a, true);
    }
  });
  const xs = ck.xs.map((a) => term_strip(a));
  const vars = xs.filter((x) => x.$ === "Var");
  const lays = fun_of(fl, k).lays;
  const vs = ck.xs.map((a, i): Val | null => {
    if (xs[i].$ === "Var") {
      return null;
    }
    const rest = [...xs.slice(i + 1).filter((x) => x.$ !== "Var"), ...vars,
      ...fl.rest];
    return emit_expr({ ...fl, rest }, a, null, lays[i]);
  });
  xs.forEach((x, i) => {
    if (!brw[i]) {
      vs[i] ??= bind_pop(fl, x);
    }
  });
  return xs.flatMap((x, i) => {
    const at = k + "~" + i;
    let b = vs[i];
    if (b === null) {
      const p = probe_of(x);
      const bd = fl.uses.get(p)!;
      const twin = vars.filter((y) => probe_of(y) === p).length > 1;
      const dead = rest_use(fl, fl.rest, p) === 0;
      if (!dead || (!jump && twin)) {
        fl.lend.add(at);
      } else {
        val_own(fl, bd.val, at, !jump);
      }
      if (dead && !twin && val_brw(fl, bd.val)) {
        fl.uses.delete(p);
      } else if (!fork) {
        fl.uses.set(p, { ...bd, n: Math.max(bd.n - 1, 1) });
      }
      b = bd.val;
    }
    const v = val_to(fl, b, lays[i]);
    if (!brw[i]) {
      return val_own(fl, v);
    }
    return (vs[i] === null && v === b) || facts_packed(fl, x) ? v.ws
      : val_own(fl, v, at);
  });
}

function emit_each(fl: File, xs: HTerm[], ats: Lay[] | null): Val[] {
  return xs.map((x, i) => emit_expr({ ...fl, rest: [...xs.slice(i + 1),
    ...fl.rest] }, x, null, ats && ats[i]));
}

function emit_put(fl: File, dst: Val | null, v: Val): void {
  if (dst === null) {
    spare_flush(fl);
  }
  const ws = val_own(fl, val_to(fl, v, dst?.lay ?? fl.seg.ret));
  ws.forEach((w, j) => file_push(fl, `${dst?.ws[j] ?? "r" + j} = ${w};`));
  if (dst === null) {
    file_push(fl, `WL_RETN(${ws.length});`);
  }
}

function emit_fuse(fl: File, ck: Spine, dst: Val | null, tail = false): void {
  const k = ck.k!;
  const T = fl.book.tlds[k].T;
  const doms = tele_unbind(fl.book, T).doms;
  const { n, h, lays, ret } = fun_of(fl, k);
  const ers = ck.all.filter((_, i) => i < n && !quant_live(doms[i][0]));
  const flat = flat_of(k);
  const ws = emit_args(fl, ck, tail && !flat);
  if (!flat) {
    return emit_body({ ...fl, def: k }, h!, T, ers,
      lays.map((lay) => val_new(ws.splice(0, lay.ks.length), lay)), dst);
  }
  const out = emit_dst(fl, ret);
  const name = emit_native(fl, k, ers);
  const o = name_local(fl, "o");
  file_push(fl, `Term ${o}[${out.ws.length}];`);
  block(fl, `if (${name}(${["e", o, ...ws].join(", ")}) == 0) {`, () => {
    file_push(fl, "return 0;");
  });
  out.ws.forEach((v, j) => file_push(fl, `${v} = ${o}[${j}];`));
  if (tail) {
    bind_dead(fl, []);
  }
  emit_put(fl, dst, out);
}

function emit_open(fl: File, k: Name): [File, Val[]] {
  FUEL = FOLD_FUEL;
  const { live, lays, ret } = fun_of(fl, k);
  const vals = lays.map((l, i) =>
    val_new(l.ks.map(() => name_local(fl, live[i][1])), l));
  brw_of(fl, k).forEach((b, i) => vals[i].ws.forEach((w, j) => {
    if (b && lays[i].ks[j] === "box") {
      fl.brwl.set(w, k + "~" + i);
    }
  }));
  const seg = seg_new(k, ret, vals.flatMap((v) => v.ws),
    vals.flatMap((v) => v.lay.ks));
  return [{ ...fl, seg, spares: [], uses: new Map(), def: k }, vals];
}

function emit_native(fl: File, k: Name, ers: HTerm[]): string {
  const key = [k, ...ers.map((e) => JSON.stringify(lay_of(fl.book, e)))]
    .join("|");
  const got = fl.spun.get(key);
  if (got !== undefined) {
    return seg_ref(fl, got);
  }
  const name = seg_ref(fl, `spin_${fl.spun.size}`);
  fl.spun.set(key, name);
  const fuel = FUEL;
  const [sl, vals] = emit_open(fl, k);
  const seg = sl.seg;
  seg.fid = name;
  const dst = val_new(seg.ret.ks.map(() => name_local(fl, "v")), seg.ret);
  emit_body(sl, fun_of(fl, k).h!, fl.book.tlds[k].T, ers, vals, dst);
  FUEL = fuel;
  fl.spins.push({ ...seg, lines: [`${seg.lines.length < SPIN_FAR
    ? "INLINE" : "FAR"} Term ${name}(Env e, THR Term* o${
    seg.ks.map((k, i) => `, ${lay_c(k)} r${i}`).join("")}) {`,
  "  u32 wpoll = 0;",
  ...dst.ws.map((v, j) => `  ${lay_c(seg.ret.ks[j])} ${v} = 0;`),
  ...seg_take(seg).map((l) => "  " + l),
  "  WL_SPIN", ...seg_text(seg.lines, 2), "  break;", "  }",
  ...dst.ws.map((v, j) => `  o[${j}] = ${v};`),
  "  return 1;", "}"] });
  return name;
}

function emit_dst(fl: File, lay: Lay, k = "v"): Val {
  return val_new(emit_hold(fl, lay.ks.map(() => "0"), k, lay.ks), lay);
}

function emit_intr(fl: File, it: Intr, m: Spine, ty: HTerm | null): Val {
  const k = (m.t as Of<"Ref">).k;
  const args = emit_each(fl, m.args, null);
  const op = op_name(k);
  if ("array_get array_new array_clone".includes(op)
    && lay_el(fl.book, m.all[0]).ks.includes("box")
    && !(op === "array_new" && facts_packed(fl, m.all[2]))) {
    facts_hot(fl, m.all[0], true);
  }
  if (it.call === true && it.C === undefined) {
    return arr_op(fl, op, lay_el(fl.book, m.all[0]), args);
  }
  const ws = args.map((v, i) =>
    val_own(fl, val_to(fl, v, fun_of(fl, k).lays[i]))[0]);
  if (Array.isArray(it.C)) {
    const as = ws.map((z) => emit_alias(fl, z, "a"));
    const vs: string[] = [];
    for (const p of it.C) {
      vs.push(emit_alias(fl, tpl(p, [...as, ...vs]), "a"));
    }
    const lay = lay_of(fl.book, ty ?? tele_unbind(fl.book,
      (fl.book.tlds[k] as Bend.Def).T).ret);
    return val_new(vs, lay);
  }
  const C = it.C as string;
  const out = tpl(C, /\$(\d)[^]*\$\1/.test(C)
    ? ws.map((a) => emit_alias(fl, a, "a")) : ws);
  const lay = lay_of(fl.book, ty);
  return val_new([out], lay.ks.length === 1 ? lay : BOX);
}

function emit_clo(fl: File, x: HTerm, ty: HTerm | null): Val {
  const u = term_uses(fl, x);
  const live = [...fl.uses].filter(([p]) => term_use(u, p) > 0)
    .map(([p, b]): [Of<"Var">, Bind] => {
      fl.uses.set(p, { ...b, n: b.n - term_use(u, p) + 1 });
      return [p, { ...b, val: bind_pop(fl, p) }];
    });
  const words = live.flatMap(([, b]) => val_own(fl, b.val));
  const name = seg_name(fl, "c");
  const clo = seg_clo(fl, seg_fid(name), words);
  const arg = val_new([name_local(fl, "x")], BOX);
  emit_body(seg_open(fl, name, BOX, null, live, arg, [x]), x, ty, [], [arg],
    null);
  return val_new([clo], BOX);
}

function emit_ctr(fl: File, x: Of<"Ctr">, ty: HTerm | null,
  at: Lay | null): Val {
  const [adt, u] = ctr_adt(fl, x, ty);
  if (u !== null) {
    return val_new([`${u}ull`], W32, true);
  }
  const flds = ctr_flds(fl.book, x.k, x.x);
  if (WORDS[adt.k] !== undefined) {
    const vs = emit_each(fl, flds, null);
    const lay = WORDS[adt.k];
    if (vs.length === 1 && vs[0].ws.length > 1) {
      return val_new([`(${vs[0].ws.map((w, i) => `((u64)${w} << ${i})`)
        .join(" | ")})`], lay);
    }
    if (vs.length === 0) {
      return val_new(["0"], lay, true);
    }
    const w = adt.k === "Nat" ? tpl(tpl_nat("ull", "nat_chk(e, $0 + 1)"),
      [vs[0].ws[0]]) : `term_word(e, ${vs[0].ws[0]})`;
    return val_new([w], lay, /^\d/.test(w));
  }
  if (adt.k === "Array") {
    const vs = emit_each(fl, flds, null);
    return val_new([x.k === "ALeaf"
      ? arr_new(fl, "0", vs[0], lay_el(fl.book, adt.x[0]))
      : `blk_node(e, ${val_own(fl, vs[0])[0]}, ${val_own(fl, vs[1])[0]})`],
    BOX);
  }
  if (fl.hot.has(x.k)) {
    facts_ctr(fl, fl.book.ctrs[x.k], adt.x);
  }
  const pos = at ?? lay_of(fl.book, adt);
  const seen = memo(fl.consts, JSON.stringify(pos), () => new Map());
  const got = seen.get(x);
  if (got !== undefined) {
    return got;
  }
  const lay = lay_box(pos) ? lay_node(fl.book, x.k) : pos;
  const arms = Object.keys(lay.arms!);
  const vs = emit_each(fl, flds, lay.arms![x.k]);
  const ws = [...arms.length > 1 ? [String(arms.indexOf(x.k))] : [],
    ...vs.flatMap((f, j) => val_to(fl, f, lay.arms![x.k][j]).ws)];
  const v = val_new(lay.ks.map((_, j) => ws[j] ?? "0"), lay,
    vs.every((f) => f.stat));
  const out = lay === pos ? v
    : val_new([ctr_build(fl, x.k, val_own(fl, v), v.stat)], BOX, v.stat);
  if (out.stat) {
    seen.set(x, out);
  }
  return out;
}

function emit_fold(fl: File, t: HTerm): HTerm | null {
  const s = term_strip(t);
  const r = memo(FOLDS, s, () => {
    if (term_const(s)) {
      return s;
    }
    const m = term_spine(fl, s);
    const it = m.t.$ === "Ref" ? intr_of(fl, m.t.k) : undefined;
    if (it === undefined) {
      const b = emit_unfold(fl, m);
      FUEL -= b === null ? 0 : term_nodes(fl, b);
      return b === null || term_any(fl, b, (y) => {
        if (y.$ === "App" || y.$ === "Ref") {
          emit_fold(fl, y);
        }
        return FUEL < 0;
      }) ? null : b;
    }
    const as = m.all.map((a) =>
      m.args.includes(a) ? emit_fold(fl, a) ?? a : a);
    return it.call === true ? null : as.every((a, i) => a === m.all[i]) ? s
      : as.reduce((f, x) => Bend.App(f, x), m.t as HTerm);
  });
  return r === s ? t : r;
}

function emit_unfold(fl: File, m: Spine): HTerm | null {
  const f = m.t.$ === "Ref" ? fun_of(fl, m.t.k) : null;
  const d = f?.h;
  if (d == null || m.all.length !== f!.n || !flat_of((m.t as Of<"Ref">).k)) {
    return null;
  }
  const fs = m.all.map((a) => m.args.includes(a) ? emit_fold(fl, a) ?? a : a);
  const walk = (ys: HTerm[]): HTerm | null => {
    let b = d;
    let xs = ys;
    let hit = m.args.every((a) => term_const(fs[m.all.indexOf(a)]));
    for (let w = term_strip(b); xs.length > 0; w = term_strip(b)) {
      if (w.$ === "Lam") {
        b = w.f(xs[0]);
        xs = xs.slice(1);
        continue;
      }
      const c = w.$ === "Mat" ? term_strip(xs[0]) : null;
      if (c === null || c.$ !== "Ctr" || !term_const(c)) {
        return null;
      }
      const { arms, end } = mat_arms(w);
      const arm = arms.find(([k]) => k === c.k);
      b = arm === undefined ? end : arm[1];
      xs = arm === undefined ? xs
        : [...ctr_flds(fl.book, c.k, c.x), ...xs.slice(1)];
      hit = true;
    }
    return !hit || term_any(fl, b, (y) => y.$ === "Lam" || mat_head(y))
      ? null : b;
  };
  const doms = tele_unbind(fl.book, m.tld!.T).doms;
  const bind = (i: number, ys: HTerm[]): HTerm => {
    const a = fs[i];
    if (i === fs.length) {
      return walk(ys) as HTerm;
    }
    if (!m.args.includes(m.all[i]) || term_const(a)
      || term_strip(a).$ === "Var") {
      return bind(i + 1, [...ys, a]);
    }
    return Bend.Let(["a"], [0], [Bend.Ann(a, doms[i][2])], (xs: HTerm[]) =>
      bind(i + 1, [...ys, xs[0]]), undefined, [Bend.Many()]);
  };
  return walk(fs) === null ? null : bind(0, []);
}

function emit_expr(fl: File, tm: HTerm, ty0: HTerm | null,
  at: Lay | null): Val {
  const [x, ty] = ty_peel(tm, ty0);
  switch (x.$) {
    case "Var": {
      return bind_pop(fl, x);
    }
    case "Ref":
    case "App": {
      const got = emit_fold(fl, x);
      if (got !== null && got !== x) {
        const a = term_uses(fl, x);
        const b = term_uses(fl, got);
        fl.uses.forEach((bd, p) => {
          const n = bd.n - term_use(a, p) + term_use(b, p);
          n > 0 ? fl.uses.set(p, { ...bd, n })
            : (fl.uses.delete(p), val_sink(fl, bd.val));
        });
        return emit_expr(fl, got, ty, at);
      }
      const m = term_spine(fl, x);
      if (flat_call(fl, x)) {
        const dst = emit_dst(fl, fun_of(fl, m.k!).ret);
        emit_fuse(fl, m, dst);
        return dst;
      }
      const y = call_eta(fl, x)
        ?? (m.t.$ !== "Ref" && m.args.length === 0 ? m.h : null);
      if (y !== null) {
        return emit_expr(fl, y, ty, at);
      }
      const g = m.t as Of<"Ref">;
      const intr = intr_of(fl, g.k);
      if (intr !== undefined) {
        return emit_intr(fl, intr, m, ty);
      }
      if (m.tld?.$ === "ADT") {
        return emit_zero(fl, ty);
      }
      if (!def_foreign(m.tld)) {
        die(`a live call into the law ${g.k}`);
      }
      return val_new([seg_clo(fl, seg_fid(g.k),
        emit_each(fl, m.args, m.args.map(() => BOX))
          .map((v) => val_box(fl, v)))], BOX);
    }
    case "Ctr": {
      return emit_ctr(fl, x, ty, at);
    }
    case "Let": {
      const o = term_open(x);
      if (let_live(fl, x)[0]) {
        emit_let({ ...fl, rest: [o.b, ...fl.rest] }, x);
      }
      return emit_expr(fl, o.b, null, at);
    }
    case "Lam":
    case "Mat":
    case "Efq": {
      if (!fun_live(fl.book, x, ty)) {
        return emit_expr(fl, (x as Of<"Lam">).f(DUMMY),
          ty_all(fl.book, ty).B(DUMMY), at);
      }
      return emit_clo(fl, x, ty);
    }
    default: {
      return emit_zero(fl, ty);
    }
  }
}

function emit_zero(fl: File, ty: HTerm | null): Val {
  const lay = lay_of(fl.book, ty);
  return val_new(lay.ks.map(() => "0ull"), lay);
}

function emit_let(fl: File, x: Of<"Let">): void {
  const o = term_open(x);
  const v = val_hold(fl, emit_expr(fl, x.v[0], null, null), x.k[0]);
  bind_uses(fl, o.ps[0], v, [o.b], ty_ann(x.v[0])!);
}

function emit_body(fl: File, tm: HTerm, ty0: HTerm | null,
  ers: HTerm[], args: Val[], dst: Val | null): void {
  const [x, ty] = ty_peel(tm, ty0);
  if (args.length === 0 && fun_live(fl.book, x, ty)) {
    return emit_put(fl, dst, emit_clo(fl, x, ty));
  }
  const l = x.$ === "Let" || (args.length === 0 && x.$ !== "Lam")
    ? anf(fl, x, ty) : x;
  if (l !== x) {
    return emit_body(fl, l, ty, ers, args, dst);
  }
  switch (x.$) {
    case "Lam": {
      const all = ty_all(fl.book, ty);
      if (!quant_live(all.q)) {
        const t = ers[0] ?? Bend.Var(x.k, x.i);
        return emit_body(fl, x.f(t), all.B(t), ers.slice(1), args, dst);
      }
      const o = term_open(x);
      const v = val_hold(fl, val_to(fl, args[0], lay_of(fl.book, all.A)), x.k);
      bind_uses(fl, o.ps[0], v, [o.b], all.A);
      return emit_body(fl, o.b, all.B(DUMMY), ers, args.slice(1), dst);
    }
    case "Mat":
    case "Efq": {
      return emit_match(fl, x, ty, ers, args, dst);
    }
    case "Let": {
      if (x.k.length >= 2
        || (term_spine(fl, x.v[0]).k !== null && !flat_call(fl, x.v[0]))) {
        return emit_fork(fl, x, ers);
      }
      const o = term_open(x);
      emit_let({ ...fl, rest: [o.b] }, x);
      bind_dead(fl, [o.b]);
      return emit_body(fl, o.b, null, ers, [], dst);
    }
    default: {
      if (args.length > 0) {
        return emit_body(fl, term_eta(fl.book, x,
          ty!, 1), ty, ers, args, dst);
      }
      fl = { ...fl, rest: [] };
      const ck = term_spine(fl, x);
      if (ck.k === null) {
        const v = emit_expr(fl, x, ty, dst?.lay ?? fl.seg.ret);
        bind_dead(fl, []);
        return emit_put(fl, dst, v);
      }
      const ret = fun_of(fl, ck.k).ret;
      const once = fl.sites.get(ck.k) === 1 && !ck.b
        && !def_foreign(fl.book.tlds[ck.k])
        && (!lay_box(ret) || lay_box(fl.seg.ret));
      if (fl.seg.def !== ck.k && (flat_call(fl, x) || (dst === null && once))) {
        return emit_fuse(fl, ck, dst, true);
      }
      if (!lay_eq(fl.seg.ret, ret)
        && (fl.seg.ret.arms !== null || ret.arms !== null)) {
        return emit_body(fl, Bend.Let(["r"], [0], [Bend.Ann(x,
          ty!)], (xs) => xs[0]), ty,
          ers, args, dst);
      }
      const cargs = emit_args(fl, ck, true);
      spare_flush(fl);
      emit_jump(fl, cargs, ck.k, ck.b);
    }
  }
}

function emit_fork(fl: File, x: Of<"Let">, ers: HTerm[]): void {
  const o = term_open(x);
  const calls = x.v.map((v) => term_spine(fl, v));
  const fork = calls.length > 1;
  const name = seg_name(fl, "j");
  let hold: Of<"Var">[] = [];
  if (fork) {
    spare_flush(fl);
    fl.seg.fork = true;
    const pl = { ...fl, uses: new Map(fl.uses) };
    block(pl, "if (!seq) {", () => {
      const margs = calls.map((c, j) => emit_args({ ...pl,
        rest: [...x.v.filter((_, i) => i !== j), o.b] }, c, false, true));
      const live = [...pl.uses].filter(([p, b]) =>
        !val_brw(pl, b.val) || rest_use(pl, [o.b], p) > 0);
      hold = live.map(([p]) => p);
      const caps = live.flatMap(([, b]) => b.val.ws);
      spare_flush(pl);
      const jn = emit_task(pl, seg_fid(name), calls.length, caps);
      const jt = `term_tsk(${seg_fid(name)}, ${jn})`;
      let idx = caps.length;
      calls.forEach((c, j) => {
        const fj = seg_fid(c.k!);
        file_push(pl, `e.mem[${jn} + ${idx}] = term_tsk(${fj}, ${
          emit_task(pl, fj, 0, margs[j], jt, idx)});`);
        idx += fun_of(pl, c.k!).ret.ks.length;
      });
      file_push(pl, `return ${jt};`);
    });
  }
  const chain = calls.map(() => o.b);
  for (let j = calls.length - 2; j >= 0; j -= 1) {
    chain[j] = let_open([o.ps[j + 1]], [x.v[j + 1]], chain[j + 1]);
  }
  const pos = new Map<Of<"Var">, number>();
  let depth = 0;
  calls.forEach((c, i) => {
    const cargs = emit_args({ ...fl, rest: [chain[i]] }, c);
    const vs = i === 0 ? [...fl.uses]
      : [[o.ps[i - 1], fl.uses.get(o.ps[i - 1]) as Bind] as [Of<"Var">, Bind]];
    const kn = seg_name(fl, "k");
    spare_flush(fl);
    const ws = vs.flatMap(([p, b]) =>
      (pos.set(p, depth), depth += b.val.ws.length, b.val.ws));
    emit_chain(fl, () => "seq", [() => emit_frame(fl, ws, seg_fid(kn)),
      ...fork ? [] : [() => {
        file_push(fl, `WL_CONT = term_tsk(${seg_fid(kn)}, ${
          emit_task(fl, seg_fid(kn), 1, ws)});`);
        file_push(fl, `WL_IDX = ${ws.length};`);
      }]]);
    emit_jump(fl, cargs, c.k!, !fork && c.b);
    const last = i === calls.length - 1;
    const held = [...fl.uses].filter(([p]) => pos.has(p));
    const at = held.flatMap(([p, b]) => b.val.ws.map((_, j) =>
      (pos.get(p) as number) + j - (last ? 0 : depth)));
    const ret = fun_of(fl, c.k!).ret;
    const rest = [...hold, chain[i]];
    const rs = val_new(ret.ks.map(() => name_local(fl, o.ps[i].k)), ret);
    fl = seg_open(fl, kn, fl.seg.ret, { pop: last ? depth : 0, at }, held, rs,
      rest);
    bind_uses(fl, o.ps[i], rs, rest, ty_ann(x.v[i])!);
  });
  if (fork) {
    const live = [...fl.uses];
    emit_jump(fl, live.flatMap(([, b]) => b.val.ws), name);
    fl = seg_open(fl, name, fl.seg.ret, null, live, val_new([], lay_pack([])),
      [o.b]);
  }
  emit_body(fl, o.b, null, ers, [], null);
}

function emit_row(fl: File, t: HTerm, ty: HTerm | null): string | null {
  const k = ty_adt(fl.book, ty)?.k ?? "";
  if (ty !== null && WORDS[k] === undefined) {
    return null;
  }
  let s = term_strip(t);
  while (s.$ === "Lam") {
    s = term_strip(term_open(s).b);
  }
  s = emit_fold(fl, s) ?? s;
  const bits = k === "F32" && !fl.js;
  if (term_const(s)) {
    return bits ? String(Bend.u32_from_term(s, "F32")) : js_expr(fl, s, ty);
  }
  const m = term_spine(fl, s);
  const it = m.t.$ === "Ref" ? intr_of(fl, m.t.k) : undefined;
  if (it === undefined || TAB_BAD.test(it.JS)) {
    return null;
  }
  const xs = m.args.map((a) => emit_row(fl, a, null));
  const r = xs.includes(null) ? null : tpl(it.JS, xs as string[]);
  return r !== null && bits ? `f32_bits(${r})` : r;
}

function emit_tab(fl: File, cells: HTerm[] | null, ty: HTerm,
  s: string): string | null {
  const ls = (cells ?? []).map((t) => emit_row(fl, t, ty));
  if (cells === null || ls.includes(null)) {
    return null;
  }
  const key = fl.js ? ls.join(", ") : Function("f32_bits",
    "return [" + ls + "]")(Bend.f32_to_bits).map((v: number) => BigInt(v)
    + "ull").join(", ");
  const tab = "TAB_" + memo(fl.tabs, key, () => fl.tabs.size);
  return fl.js ? `${tab}[Math.min(${s}, ${cells.length - 1})]`
    : `TAB_AT(${tab}, ${s}, ${cells.length - 1})`;
}

function emit_match(fl: File, x: Of<"Mat"> | Of<"Efq">,
  ty: HTerm | null, ers: HTerm[], args: Val[], dst: Val | null): void {
  if (x.$ === "Efq") {
    file_push(fl, "err_post(e.mem, ERR_TAGS);");
    return file_push(fl, "return 0;");
  }
  const { adt, ret, rows, cells } = mat_rows(fl, x, ty);
  const word = WORDS[adt.k] === W32;
  const lay = word ? lay_node(fl.book, adt.k) : lay_of(fl.book, adt);
  const u = val_hold(fl, val_to(fl, args[0], word ? W32 : lay), "s");
  const sw = u.ws[0];
  const tab = emit_tab(fl, cells, ret, sw);
  if (tab !== null) {
    bind_dead(fl, []);
    return emit_put(fl, dst, val_new([tab], lay_of(fl.book, ret)));
  }
  let lv: [string, HTerm, (al: File) => Val[]][];
  if (rows !== null) {
    lv = rows.map(([h, j, n, e]) => [lits_cond(sw, j, n), h, () => {
      if (!word) {
        return [val_new([`(${sw} - ${n})`], lay)].slice(0, e);
      }
      let v = val_new(lay.ks.map((_, i) => `((${sw} >> ${i}) & 1)`),
        lay.arms![adt.k][0]);
      for (let i = 0; i < j; i++) {
        v = val_arm(v)[1];
      }
      return e === 1 ? [v] : val_arm(v).slice(0, e);
    }]);
  } else {
    lv = mat_ctrs(fl, x, adt, adt.k === "IO.OP").map(([k, h]) => {
      if (k === "") {
        return ["", h, () => [u]];
      }
      if (adt.k === "Array") {
        const el = lay_el(fl.book, adt.x[0]);
        const leaf = k === "ALeaf";
        return [`blk_cls(${sw}) ${leaf ? "==" : "!="} ${lay_arr(el).lgs}`, h,
          () => {
            val_own(fl, u);
            return leaf ? [arr_leaf(fl, sw, el)] : emit_hold(fl,
              [0, 1].map((hi) => `blk_half(e, ${sw}, ${hi})`), "h")
              .map((w) => val_new([w], BOX));
          }];
      }
      if (lay_box(lay)) {
        return [`term_aux(${sw}) == ${cid_mac(k)}`, h,
          (al) => node_fields(al, sw, k, true)];
      }
      return [`${sw} == ${Object.keys(lay.arms!).indexOf(k)}`, h,
        () => val_arm(u, k)];
    });
  }
  emit_chain(fl, (i) => lv[i][0], lv.map(([, h, fs]) => () => {
    const al = { ...fl, uses: new Map(fl.uses), spares: fl.spares.slice() };
    bind_dead(al, [h]);
    emit_body(al, h, null, ers, [...fs(al), ...args.slice(1)], dst);
    if (dst !== null) {
      spare_flush(al);
    }
  }));
  if (dst !== null) {
    fl.spares.splice(0);
  }
}

function emit_chain(fl: File, cond: (i: number) => string,
  bodies: (() => void)[]): void {
  if (bodies.length === 1) {
    return bodies[0]();
  }
  bodies.forEach((body, i) => {
    if (i === bodies.length - 1) {
      file_push(fl, "} else {");
    } else {
      file_push(fl, `${i === 0 ? "if" : "} else if"} (${cond(i)}) {`);
    }
    body();
  });
  file_push(fl, "}");
}

// Compile
// =======

// Hand-written C and JS name ids as CID(k) and FID(k): k in the source's
// namespace, else as is. An effect source is read once, in one namespace.

function c_ids(fl: File, src: string, m = ""): string {
  return src.replace(/\b([CF]ID)\(([\w./~-]+)\)/g, (_, p, k) => {
    const q = [m === "" ? k : m + "." + k, k].find((q) => q in fl.book.ctrs
      || q in fl.book.tlds || IDS.has(p + "_" + q))
      ?? die(p + "(" + k + ") names no constructor or def");
    return fl.js ? JSON.stringify(q) : name_id(p + "_", q);
  });
}

function effect_srcs(fl: File, ext: string, miss: string): string[] {
  const seen = new Map<string, string>();
  for (const [k, tld] of done_defs(fl, def_foreign)) {
    const path = fs.realpathSync(tld.i!.find((x) => x.endsWith(ext))
      ?? die(miss + k));
    const m = tld.m ?? "";
    if ((seen.get(path) ?? m) !== m) {
      die(path + " is imported from two namespaces, '" + seen.get(path)
        + "' and '" + m + "'");
    }
    seen.set(path, m);
  }
  return [...seen].map(([p, m]) => c_ids(fl, fs.readFileSync(p, "utf8"), m));
}

// C
// -

// A segment may fork if one it reaches does; Clo~apply reaches every
// closure. The device holds what the bangs reach, and every closure when a
// bang's parameter may hold one. One bank serves both lanes: rp pads the
// host's twelfth slot, which keeps rax free for the tail call. WL_LOAD is a
// ladder, as clang builds the phi cascade of a fallthrough switch in O(n^2).
// In the generated C the word undefined is a leaked JS undefined; the effect
// sources (reqs) are hand-written, and may say it.

function compile_reqs(fl: File): string {
  const reqs = effect_srcs(fl, ".c", "no .c import: ").join("");
  for (const [k] of done_defs(fl, def_foreign)) {
    const qp = [...fun_of(fl, k).live.map(([, n]) => n), "k"].map((n) =>
      name_local(fl, n));
    const rl = { ...fl, seg: seg_new(k, BOX, qp), spares: [] };
    fl.segs.push(rl.seg);
    file_push(rl, `r0 = ${ctr_build(rl, k, qp)};`);
    file_push(rl, "WL_RETN(1);");
  }
  return reqs;
}

function compile_tables(fl: File, entries: Seg[]): string[] {
  const cids = new Map<Name, number>();
  for (const k of SRCS.keys()) {
    for (const c of (fl.book.tlds[k] as Bend.ADT).c ?? []) {
      cids.set(c.k, lay_node(fl.book, c.k).ks.length);
    }
  }
  for (const [k] of done_defs(fl, def_foreign)) {
    cids.set(k, fun_of(fl, k).lays.length);
  }
  const forky = new Set(fl.segs.filter((s) => s.fork).map((s) => s.fid));
  for (let n = -1; n !== forky.size;) {
    n = forky.size;
    for (const s of [...fl.segs, { fid: seg_fid(CLO_APPLY), refs: fl.clos }]) {
      if (!forky.has(s.fid) && [...s.refs].some((r) => forky.has(r))) {
        forky.add(s.fid);
      }
    }
  }
  const ars = [...cids.values()].map((n) => n > WIDE ? 240 + Math.log2(n) : n);
  if (entries.some((s) => s.params.length > WIDE) || ars.some((n) => n > 255)) {
    die("an arity over " + WIDE);
  }
  const defs: string[] = [];
  for (const ms of [[...cids.keys()].map(cid_mac),
    [...entries.map((s) => s.fid), "FID_EXIT", "FID_ENTER"]]) {
    if (ms.length > 65536) {
      die("an id over 65535");
    }
    defs.push(...ms.map((m, i) => `#define ${m} ${i}`));
  }
  defs.push(`CONSTV u8 FID_T[][3] = { ${entries.map((s) =>
    `{ ${s.params.length}, ${s.frame === null ? 0
      : s.params.length - s.frame.at.length}, ${Number(fl.bangs.has(s.def))
      | Number(!forky.has(s.fid)) << 1} }`).join(", ")} };`,
  `CONSTV u8 CID_T[][2] = { ${[...cids.keys()].map((k, i) =>
    `{ ${ars[i]}, ${Number(fl.hot.has(k))} }`).join(", ")} };`);
  defs.push(`#define STAT_LEN ${fl.img.length}`, "");
  const resw = Math.max(...entries.map((s) => s.ret.ks.length));
  const n = Math.max(resw, ...entries.filter((s) => s.frame === null)
    .map((s) => s.params.length));
  const rs = [...Array(n).keys()].map((i) => "r" + i);
  const ws = n > 6 ? [...rs.slice(0, 6), "rp", ...rs.slice(6)] : rs;
  const load = rs.map((r, i) =>
    `    if ((N) <= ${i}) break; ${r} = e.mem[(A) + ${i}]; \\\n`).join("");
  const last = rs.map((r, i) =>
    `    case ${i}: ${r} = (X); \\\n      break; \\\n`).join("");
  defs.push(`#define WL_RESW ${resw}`, `#define BANGS   ${fl.bangs.size}`, "",
  `#define WL_BANK Term ${ws.join(", ")};`, "",
  `#define WL_LOAD(A, N) \\\n  do { \\\n${load}  } while (0);`, "",
  `#define WL_LAST(X) \\\n  switch (war) { \\\n${last}  }`, "",
  `#define WL_SAVE(V) ${rs.slice(0, resw).map((r, j) =>
    `(V)[${j}] = ${r};`).join(" ")}`, "",
  `#define WL_TAKE(V) ${rs.slice(0, resw).map((r, j) =>
    `${r} = (V)[${j}];`).join(" ")}`, "",
  `#define WL_SIG Env e, DEV Term* sp, u32 seq, u32 rn, ${ws.map((w) =>
    "Term " + w).join(", ")}`, "", `#define WL_ALL e, sp, seq, rn, ${ws
    .join(", ")}`, "",
  `#define WL_TABLE ${entries.map((s) => `WL_X(${s.fid})`).join(" ")}`
    + " WL_X(FID_EXIT)");
  return defs;
}

function compile_segs(fl: File, dev: Set<string>): string {
  return fl.segs.map((seg) => {
    const out = [`  WL_CASE(${seg.fid})`, "  {",
      ...seg_take(seg).map((l) => "    " + l),
      "    WL_OPEN", ...seg.spin ? ["    WL_SPIN"] : [],
      ...seg_text(seg.lines, 2), ...seg.spin ? ["    WL_SPUN"] : [], "  }}"];
    return (dev.has(seg.fid) ? out : ["#if !DEVICE", ...out, "#endif"])
      .join("\n");
  }).join("\n\n");
}

export function compile_book(book: Bend.Book): string {
  const fl = file_book(book, ["main", ...RUNTIME_ADTS], false);
  const show = show_main(book);
  const facts = () => fl.own.size + fl.hot.size + fl.stat.size;
  let was: number;
  let reqs: string;
  do {
    was = facts();
    [fl.lend, fl.spun, fl.clos, fl.tabs, fl.lits, fl.consts, BRWS]
      .forEach((m) => m.clear());
    fl.segs = [];
    fl.spins = [];
    fl.img = [];
    for (const [k, tld] of done_defs(fl).reverse()) {
      memo_gc();
      const [dl, vals] = emit_open({ ...fl, fresh: new Map(),
        brwl: new Map(), rest: [] }, k);
      fl.segs.push(dl.seg);
      emit_body(dl, fun_of(fl, k).h!, tld.T, [], vals, null);
    }
    reqs = compile_reqs(fl);
    facts_lend(fl);
  } while (was !== facts());
  const reach = (from: string[], set = new Set<string>()): Set<string> => {
    const grab = (fid: string) => set.has(fid) || (set.add(fid)
      && [...fl.segs, ...fl.spins].find((s) => s.fid === fid)?.refs
        .forEach(grab));
    from.forEach(grab);
    return set;
  };
  const live = reach([seg_fid("main")]);
  const wide = [...fl.bangs].some((k) =>
    fun_of(fl, k).live.some(([, , A]) => ty_clo(fl.book, A)));
  const dev = reach([...[...fl.bangs].map(seg_fid), ...wide ? fl.clos : []]);
  fl.segs = fl.segs.filter((s) => live.has(s.fid));
  fl.spins = fl.spins.filter((s) => live.has(s.fid));
  const entries = [...fl.segs, seg_new(IO_EMIT, BOX, [""]),
    seg_new(CLO_APPLY, BOX, ["", ""])];
  const desc = show === null ? [] : ["#if !DEVICE",
    `static const u32 SHOW_DESC[] = { ${show.map((c) =>
      typeof c === "string" ? cid_mac(c) : c).join(", ")} };`,
    `static const char* SHOW_NAMES[] = { ${show.filter((c) =>
      typeof c === "string").map((n) => JSON.stringify(n)).join(", ")} };`,
    "#endif"];
  const defs = compile_tables(fl, entries);
  defs.push(`#define MAIN_FID ${seg_fid("main")}`, `#define MAIN_PURE ${
    Number(show !== null)}`,
    `#define BLK_SHR ${Number(fl.hot.has("t:Array"))}`);
  const tabs = [defs.join("\n"), ...[...fl.tabs].map(([r, i]) =>
    `CONSTV u64 TAB_${i}[] = { ${r} };`)].join("\n\n");
  const spins = [`CONSTV u64 STAT_IMG[] = { ${fl.img.join(", ") || 0} };`,
    ...fl.spins.map((s) => s.lines.join("\n"))].join("\n\n");
  const segs = compile_segs(fl, dev);
  if (/\bundefined\b/.test([tabs, spins, segs].join("\n"))) {
    die("an unbound name in the emitted C");
  }
  return c_ids(fl, runtime_c([tabs, ...desc].join("\n\n"), spins, segs,
    reqs));
}

// JS
// --

// A def's JS name is its key between $s: each . a $, and any other
// non-word char a $ and its three-digit code, so no two keys share one.
// Each effect source runs once in a closure of its own and registers
// its effects with io_eff(CID(k), run, need?), as a C source does. A
// def on a tail cycle is one loop over the cycle's bodies ($pc picks
// one), each turn binding its parameters afresh, so a closure keeps its
// own; any other call is direct. Only a closure's tail call bounces
// (run_tail), so a call passes through run_loop only when its callee
// may return one: a marker per call resolves once every def is out.

function js_sat(k: Name): string {
  return "$" + k.replace(/\W/g, (c) => c === "." ? "$"
    : "$" + String(c.charCodeAt(0)).padStart(3, "0")) + "$";
}

function js_call(fl: File, k: Name, args: HTerm[], tail: boolean): string {
  let exprs = args.map((x) => js_expr(fl, x, null));
  if (k === CLO_APPLY) {
    const [f, x] = exprs;
    return tail ? js_tail(fl, k, "run_tail(" + f + ", " + x + ")")
      : f + "(" + x + ")";
  }
  const tld = fl.book.tlds[k];
  if (tld.$ === "ADT") {
    return "null";
  }
  const intr = intr_of(fl, k, true)?.JS ?? null;
  if (intr === null && tld.v === null && tld.i === undefined) {
    die("a live call into the law " + k);
  }
  const live = fun_of(fl, k).lays.length;
  const v = def_foreign(tld) && exprs.length === live - 1
    ? name_local(fl, "x") : "";
  if (v !== "") {
    exprs = [...exprs, v];
  }
  if (intr !== null) {
    const xs = exprs.map((e) => ATOM.test(e) || STRLIT.test(e)
      ? e : emit_hold(fl, [e], "x")[0]);
    return tpl(intr, xs);
  }
  const call = js_sat(k) + "(" + exprs.join(", ") + ")";
  if (v !== "") {
    return "(" + v + ") => " + call;
  }
  return def_foreign(tld) ? call : tail ? js_tail(fl, k, call)
    : "\x01" + k + "\x02(" + call + ")";
}

function js_tail(fl: File, k: Name, ret: string): string {
  if (fl.seg.def !== "") {
    memo(fl.tails, fl.seg.def, () => new Set()).add(k);
  }
  return ret;
}

function js_open(fl: File, x: Of<"Let">): HTerm {
  const on = let_live(fl, x);
  return x.f(x.v.map((v, j): HTerm => !on[j] ? v
    : Bend.Var(emit_hold(fl, [js_expr(fl, v, null)], x.k[j])[0], 0)));
}

function js_ctr(book: Bend.Book, c: Bend.Ctr, xs?: HTerm[]): Dom[] {
  return ctr_tail(book, c, xs).filter(live_dom);
}

function js_key(n: Name): string {
  return (n === "__proto__" ? `["${n}"]` : `"${n}"`) + ": ";
}

function js_expr(fl: File, tm: HTerm, ty0: HTerm | null): string {
  const [x, ty] = ty_peel(tm, ty0);
  switch (x.$) {
    case "Var": {
      return x.k;
    }
    case "Ref":
    case "App": {
      const m = term_spine(fl, x);
      if (m.k !== null) {
        return js_call(fl, m.k, m.xs, false);
      }
      const y = call_eta(fl, x) ?? (m.t.$ !== "Ref" ? m.h : null);
      if (y !== null) {
        return js_expr(fl, y, ty);
      }
      const k = (m.t as Of<"Ref">).k;
      const it = intr_of(fl, k, true);
      if (it?.call === true && it.C === undefined) {
        lay_el(fl.book, m.all[0]);
      }
      return js_call(fl, k, m.args, false);
    }
    case "Ctr": {
      const [adt, u] = ctr_adt(fl, x, ty);
      if (u !== null) {
        const v = adt.k === "F32" ? Bend.f32_from_bits(u) : u;
        return Object.is(v, -0) ? "-0" : String(v);
      }
      const exprs = ctr_flds(fl.book, x.k, x.x)
        .map((f) => js_expr(fl, f, null));
      const native = OPTIMIZED[adt.k];
      if (native !== undefined) {
        return tpl(native[x.k].intr, exprs);
      }
      const fs = js_ctr(fl.book, fl.book.ctrs[x.k]);
      return exprs.reduce((e, z, j) => e + ", " + js_key(fs[j][1]) + z,
        "{$: \"" + x.k + "\"") + "}";
    }
    case "Let": {
      return js_expr(fl, js_open(fl, x), ty);
    }
    case "Lam":
    case "Mat":
    case "Efq": {
      if (!fun_live(fl.book, x, ty)) {
        return js_expr(fl, (x as Of<"Lam">).f(Bend.Var("null", 0)),
          ty_all(fl.book, ty).B(DUMMY));
      }
      const arg = name_local(fl, "x");
      const cl = { ...fl, seg: seg_new("", BOX, []) };
      js_func(cl, x, ty, [arg]);
      return `run_clo((${arg}) => {\n${seg_text(cl.seg.lines, 1)
        .join("\n")}\n})`;
    }
    default: {
      return "null";
    }
  }
}

function js_func(fl: File, tm: HTerm, ty0: HTerm | null, args: string[]): void {
  const [x, ty] = ty_peel(tm, ty0);
  if (args.length === 0 && fun_live(fl.book, x, ty)) {
    return file_push(fl, "return " + js_expr(fl, x, ty) + ";");
  }
  if (x.$ === "Lam") {
    const all = ty_all(fl.book, ty);
    const e = quant_live(all.q) ? args[0] : "null";
    const k = /^(\w*_\d+|null)$/.test(e) ? e : name_local(fl, x.k);
    const at = fl.seg.lines.length;
    js_func(fl, x.f(Bend.Var(k, 0)), all.B(Bend.Var(k, 0)),
      quant_live(all.q) ? args.slice(1) : args);
    if (k !== e && fl.seg.lines.slice(at).some((l) => l.includes(k))) {
      fl.seg.lines.splice(at, 0, `const ${k} = ${e};`);
    }
    return;
  }
  if (mat_head(x)) {
    return js_match(fl, x, ty, args);
  }
  if (x.$ === "Let") {
    return js_func(fl, js_open(fl, x), ty, args);
  }
  if (args.length > 0) {
    return js_func(fl, term_eta(fl.book, x, ty!, 1), ty, args);
  }
  const ck = term_spine(fl, x);
  const at = ck.k === null ? -1 : loop_of(fl, fl.seg.def).indexOf(ck.k);
  if (at >= 0) {
    const xs = ck.xs.map((a) => js_expr(fl, a, null));
    xs.forEach((e, i) => file_push(fl, "$" + i + " = " + e + ";"));
    const loop = loop_of(fl, fl.seg.def);
    return file_push(fl, (loop.length > 1 ? "$pc = " + at + "; " : "")
      + "continue;");
  }
  file_push(fl, "return " + (ck.k === null ? js_expr(fl, x, ty)
    : js_call(fl, ck.k, ck.xs, true)) + ";");
}

function js_match(fl: File, x: HTerm, ty: HTerm | null, args: string[]): void {
  if (x.$ === "Efq") {
    return file_push(fl, `throw "bend: ${ERRS[2]}";`);
  }
  const { adt, ret, rows, cells } = mat_rows(fl, x, ty);
  const s = emit_alias(fl, args[0], "$t");
  if (adt.k === "IO.OP") {
    block(fl, `if (${s}.$ === "$FFI") {`, () => file_push(fl, `throw ${s};`));
  }
  const tab = emit_tab(fl, cells, ret, s);
  if (tab !== null) {
    return file_push(fl, `return ${tab};`);
  }
  let lv: [string, HTerm, string[]][];
  if (adt.k === "Nat") {
    lv = rows!.map(([h, , n, e]) => [`${s} === ${n}`, h,
      [`(${s} - ${n})`].slice(0, e)]);
  } else if (rows !== null) {
    const bits = adt.k === "F32" ? `f32_bits(${s})` : s;
    const wd = (j: number): string =>
      `u32_to_word(${bits})` + "[\"tail\"]".repeat(j);
    lv = rows.map(([h, j, n, e]) => [lits_cond(bits, j, n), h, e === 1
      ? [wd(j)] : [wd(j) + "[\"head\"]", wd(j + 1)].slice(0, e)]);
  } else {
    const native = OPTIMIZED[adt.k];
    lv = mat_ctrs(fl, x, adt).map(([k, h]): [string, HTerm, string[]] => {
      if (k === "") {
        return ["", h, [s]];
      }
      if (native === undefined) {
        return [`${s}.$ === "${k}"`, h,
          js_ctr(fl.book, fl.book.ctrs[k]).map(([, f]) => `${s}["${f}"]`)];
      }
      return [tpl(native[k].cond ?? "", [s]), h,
        (native[k].elim ?? []).map((e) => tpl(e, [s]))];
    });
  }
  emit_chain(fl, (i) => lv[i][0], lv.map(([, h, fs]) => () =>
    js_func(fl, h, null, [...fs, ...args.slice(1)])));
}

function js_def(fl: File, k: Name, def: Bend.Def): void {
  if (intr_of(fl, k, true) !== undefined) {
    return;
  }
  FUEL = FOLD_FUEL;
  fl = { ...fl, fresh: new Map() };
  fl.seg.def = k;
  const { live, h } = fun_of(fl, k);
  const loop = loop_of(fl, k);
  const n = Math.max(0, ...loop.map((d) => fun_of(fl, d).live.length));
  const params = loop.length > 0 ? [...Array(n).keys()].map((i) => "$" + i)
    : live.map(([, x]) => name_local(fl, x));
  if (def.i !== undefined) {
    const doms = [...live, tele_unbind(fl.book, def.T).doms.at(-1)!];
    params.push(name_local(fl, "k"));
    const xs = params.map((p, i) =>
      `${js_marshal(fl, doms[i][2], true)}(${p})`);
    const n = JSON.stringify(k);
    const args = xs.slice(0, -1).join(", ");
    return block(fl, `function ${js_sat(k)}(${params.join(", ")}) {`, () =>
      file_push(fl, `return { $: "$FFI", run: $0eff[${n}].run, need: $0eff[${
        n}].need, args: [${args}], kont: ${xs.at(-1)} };`));
  }
  block(fl, `function ${js_sat(k)}(${params.join(", ")}) {`, () => {
    if (loop.length === 0) {
      return js_func(fl, h!, def.T, params);
    }
    const pc = loop.length > 1;
    if (pc) {
      file_push(fl, `let $pc = ${loop.indexOf(k)};`);
    }
    block(fl, pc ? "for (;;) switch ($pc) {" : "for (;;) {", () =>
      loop.forEach((d, i) => {
        memo_gc();
        FUEL = FOLD_FUEL;
        const fx = { ...fl, fresh: new Map() };
        const ps = fun_of(fx, d).live.map(([, x]) => name_local(fx, x));
        block(fx, pc ? `case ${i}: {` : "{", () => {
          ps.forEach((p, j) => file_push(fx, `const ${p} = $${j};`));
          js_func(fx, fun_of(fx, d).h!, fl.book.tlds[d].T, ps);
        });
      }));
  });
  file_push(fl, "");
}

function js_marshal(fl: File, A: HTerm | null, out: boolean): string {
  const book = fl.book;
  const t = ty_wnf(book, A);
  if (t?.$ === "All") {
    const y = js_marshal(fl, t.B(DUMMY), out);
    const x = quant_live(t.q) ? js_marshal(fl, t.A, !out) : "";
    return !quant_live(t.q) || x + y === "" ? y
      : `((f) => (x) => ${y}(f(${x}(x))))`;
  }
  const seen = new Set<Name>();
  const nat = (u: HTerm | null): boolean | null => u?.$ === "All"
    ? [u.A, u.B(DUMMY)].some((v) => ty_holds(book, v, nat, seen))
    : u?.$ !== "ADT" ? false : WORDS[u.k] ? u.k === "Nat" : null;
  if (t?.$ !== "ADT" || !ty_holds(book, t, nat, seen)) {
    return "";
  }
  if (t.k === "Nat" || t.k === "Array") {
    return t.k === "Nat" ? (out ? "BigInt" : "nat_host")
      : `((a) => (a.forEach((x, i) => a[i] = ${js_marshal(fl, t.x[0], out)
      }(x)), a))`;
  }
  const key = (out ? "out " : "in ") + Bend.term_key(Bend.term_lower(t));
  const got = fl.spun.get(key);
  if (got !== undefined) {
    return got;
  }
  const name = "$0m" + fl.spun.size;
  fl.spun.set(key, name);
  const arms = (book.tlds[t.k] as Bend.ADT).c.flatMap((c) => {
    const fs = js_ctr(book, c, t.x).flatMap(([, n, B]) => {
      const f = js_marshal(fl, B, out);
      return f === "" ? [] : [[n, f]];
    });
    const [n] = fs.filter(([, f]) => f === name).pop() ?? [];
    const copy = fs.filter(([m]) => m !== n).map(([m, f]) =>
      `, ${js_key(m)}${f}(v["${m}"])`).join("");
    const end = n === undefined ? "return top[0];"
      : `key = "${n}"; v = v[key]; continue;`;
    return fs.length === 0 ? []
      : [`case "${c.k}": at = at[key] = {...v${copy}}; ${end}`];
  });
  fl.spins.push({ ...seg_new("", BOX, ["v"]), lines: [`function ${name}(v) {`,
    "const top = [v];", "for (let at = top, key = 0;;) {", "switch (v.$) {",
    ...arms, "default: at[key] = v; return top[0];", "}", "}", "}", ""] });
  return name;
}

function js_host(fl: File, k: Name): string {
  const { n, live } = fun_of(fl, k);
  const ps = live.map((_, i) => "a" + i);
  const xs = live.map(([, , A], i) => `${js_marshal(fl, A, false)}(${ps[i]})`);
  const ret = Bend.tele_fill(fl.book, fl.book.tlds[k].T, Array(n).fill(DUMMY),
    Bend.ctx_nil());
  const back = live.map(([, , A], i) =>
    `${js_marshal(fl, A, true)}(${ps[i]});`);
  return `(${ps.join(", ")}) => { const r = ${js_marshal(fl, ret, true)
    }(run_loop(${js_sat(k)}(${xs.join(", ")}))); ${back.join(" ")} return r; }`;
}

export function js_lib(book: Bend.Book, roots: Name[],
  outs: Name[] | null): string {
  const fl = file_book(book, roots, true);
  for (const [k, def] of done_defs(fl, (t) => done_live(t) || def_foreign(t))) {
    memo_gc();
    js_def(fl, k, def);
  }
  const srcs = effect_srcs(fl, ".js", "a foreign def without a .js import: ");
  const effs = srcs.map((t) => "(() => {\n" + t + "\n})();\n\n").join("")
    + (srcs.length === 0 ? "" : "for (const k of "
    + JSON.stringify(done_defs(fl, def_foreign).map(([k]) => k))
    + ") {\n  if (!(k in $0eff)) {\n"
    + "    throw new Error(\"bend: no effect registers \" + k);\n  }\n}\n\n");
  const tabs = [...fl.tabs].map(([r, i]) => `const TAB_${i} = [${r}];`);
  const lib = outs === null ? "" : "export default {\n" + outs.map((k) =>
    `  "${k}": run_lib(${js_host(fl, k)}, ${fun_of(fl, k).lays.length}),`)
    .join("\n") + "\n};\n";
  const jmps = new Map<Name, boolean>();
  const jmp = (k: Name): boolean => k === CLO_APPLY || memo(jmps, k, () =>
    (jmps.set(k, true), [...fl.tails.get(k) ?? []].some(jmp)));
  const funs = [fl.seg, ...fl.spins].flatMap((f) => seg_text(f.lines, 0))
    .join("\n").replace(/\x01([^\x02]*)\x02/g, (_, k) => jmp(k) ? "run_loop"
      : "");
  return RUNTIME + effs + "// Program\n// =======\n\n"
    + [funs, ...tabs].join("\n") + lib;
}

export function js_book(book: Bend.Book): string {
  const lib = js_lib(book, ["main"], null);
  const show = show_main(book);
  return lib + "\n" + RUNTIME_MAIN
    + "\ncli(process.argv.slice(2));\nio_exit(" + js_sat("main") + ", "
    + JSON.stringify(show && [show.map((c) => typeof c === "string"
      ? 0 : c), show.filter((c) => typeof c === "string")]) + ");";
}

// RuntimeC
// ========

// The runtime around the program's tables, spins, segments and requests.

function a32_ops(f: (k: string) => string): string {
  return ["add", "sub", "and", "or", "xor", "min", "max"].map((k) =>
    "#define " + f(k)).join("\n");
}

const runtime_c = (tabs: string, spins: string, segs: string,
  reqs: string): string => String.raw`

// Imports
// =======

// The Objective-C headers take #include, not #import: a build
// (-o) reads an #import as the framework of an effect.

#pragma clang fp contract(off)

#if defined(__CUDACC_RTC__)
#define BEND_RTC 1
#endif

#ifdef __METAL_VERSION__
#include <metal_stdlib>
using namespace metal;
#elif !defined(BEND_RTC)
#ifdef __APPLE__
#define _DARWIN_UNLIMITED_SELECT
#else
#define _GNU_SOURCE
#endif
#include <stdint.h>
#include <stdbool.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <sched.h>
#include <stdatomic.h>
#include <unistd.h>
#include <signal.h>
#include <sys/mman.h>
#include <time.h>
#include <poll.h>
#include <sys/select.h>
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif
#ifdef __OBJC__
#include <Metal/Metal.h>
#include <Foundation/Foundation.h>
#elif BEND_CUDA
#include <cuda.h>
#include <nvrtc.h>
#include <fcntl.h>
#include <sys/stat.h>
#endif
#endif

// Dialect
// =======

// Metal needs coherent(device) (MSL 3.2), or M1-class parts lose stores
// across the threadgroups of a dispatch. CUDA keeps plain data cacheable
// in L1: lanes hand off through a32 and FENCE. Only clang 19+ has both
// preserve_none and preserve_most, and compiles preserve_most soundly. A
// segment is a case of the device's switch; on the host, a preserve_none
// function (WL_SIG) entered by musttail, its words fresh at WL_OPEN.

#ifdef __METAL_VERSION__
#if __METAL_VERSION__ >= 320
#define DEV     coherent(device) device
#else
#define DEV     device
#endif
#define THR     thread
#define TG      threadgroup
#define INLINE  inline
#define OUTLINE static
#define CONSTV  constant
#define DEVICE  1
#define CLZ(x)  clz(x)
#define FENCE() atomic_thread_fence(mem_flags::mem_device, memory_order_seq_cst)
#define BAR()   threadgroup_barrier(mem_flags::mem_threadgroup)
#define BARD()  threadgroup_barrier(mem_flags::mem_device \
  | mem_flags::mem_threadgroup)
#else
#define DEV
#define THR
#define TG
#define INLINE  static inline
#define CONSTV  static const
#ifdef BEND_RTC
#define OUTLINE static __attribute__((noinline))
#define DEVICE  1
#define CLZ(x)  (u32)__clz((int)(x))
#define FENCE() __threadfence()
#define BAR()   __syncthreads()
#define BARD()  \
  { __threadfence(); __syncthreads(); }
#else
#if __has_attribute(preserve_none) && __has_attribute(preserve_most)
#define PRESERVE(A) __attribute__((A))
#else
#define PRESERVE(A)
#endif
#define OUTLINE static __attribute__((noinline, cold)) PRESERVE(preserve_most)
#define DEVICE  0
#define CLZ(x)  (u32)__builtin_clz(x)
#define FENCE() ((void)0)
#endif
#endif
#define FAR static __attribute__((noinline))

#if DEVICE
#define LOCK(l)
#define UNLOCK(l)
#define WL_CASE(F) case F:
#define WL_OPEN    {
#define WL_JMP(F)  { fid = (F); break; }
#define WL_DYN     WL_JMP
#else
#define LOCK(l)    while (__atomic_exchange_n(&(l), 1, __ATOMIC_ACQUIRE)) {}
#define UNLOCK(l)  __atomic_store_n(&(l), 0, __ATOMIC_RELEASE)
#define WL_FN      static PRESERVE(preserve_none) __attribute__((noinline)) Term
#define WL_CASE(F) WL_FN WL_##F(WL_SIG)
#define WL_OPEN    { WL_BANK u32 rn;
#define WL_JMP(F)  __attribute__((musttail)) return WL_##F(WL_ALL)
#define WL_DYN(F)  __attribute__((musttail)) return wl_tab[F](WL_ALL)
#endif
#define WL_SPIN     for (;;) { if (err_spun(e.mem, &wpoll)) { return 0; }
#define WL_SPUN     } break;
#define WL_AGAIN(F) continue

#define LANE_STEP (DEVICE ? (long)CUBE : 1)
#define STK(I)    sp[(long)(I) * LANE_STEP]

#define WL_RETN(N)  { rn = (N); sp -= LANE_STEP; WL_DYN((u32)STK(0)); }
#define WL_CONT     STK(-3)
#define WL_IDX      STK(-2)
#define WL_POPN(N)  sp -= N * LANE_STEP
#define WL_PUSHN(N) sp += N * LANE_STEP
#define WL_FRAME(T) \
  u64 wtl = task_tail(T); \
  u64 wtw = e.mem[wtl + 1]; \
  STK(0) = e.mem[wtl]; \
  STK(1) = (wtw >> 32) & 0xFFFF; \
  STK(2) = FID_EXIT; \
  sp += 3 * LANE_STEP;
#define WL_ARGS(A, N) \
  for (u32 wi = 0; wi + 1 < N; wi += 1) { \
    STK(wi) = e.mem[A + wi]; \
  } \
  sp += (N - 1) * LANE_STEP;
#define WL_ROOM(N) \
  if (DEVICE && sp + (N) * CUBE >= e.mem + STAT_OFF + CUBE) { \
    err_post(e.mem, ERR_DEEP); \
    return 0; \
  }

// Types
// =====

#ifdef __METAL_VERSION__
typedef ulong u64;
typedef uint  u32;
typedef uchar u8;
#elif defined(BEND_RTC)
typedef unsigned long long u64;
typedef unsigned int       u32;
typedef unsigned char      u8;
#else
typedef uint64_t u64;
typedef uint32_t u32;
typedef uint8_t  u8;
#endif
typedef float f32;

typedef u64 Term;

typedef struct {
  DEV u64* mem;
  DEV u64* alc;
} Env;

typedef struct {
  u64 off;
  u32 rd;
  u32 wr;
  u32 top;
} Bank;

#if DEVICE
typedef u32 u32a;
#else
typedef u32 __attribute__((may_alias)) u32a;
#endif

// Constants
// =========

#define TAG_PAK 1ull
#define TAG_CTR 2ull
#define TAG_CLO 3ull
#define TAG_BUF 4ull
#define TAG_TSK 5ull
#define TAG_ARR 6ull

#define TERM_HOLE (~0ull)
#define LOC_MASK  ((1ull << 40) - 1)
#define RFC_BIT   (1ull << 63)
#define RFC_CNT   ((1u << 24) - 1)
#define NAT_IMM   ((1ull << 48) - 1)

#define ERR_RING 1
#define ERR_TAGS 2
#define ERR_HEAP 3
#define ERR_FIDS 4
#define ERR_NATS 5
#define ERR_RFCS 6
#define ERR_DEEP 7
#define ERR_ARRS 8

#define LINE      16
#define PAGE_BITS 7
#define PAGE_LEN  (1ull << PAGE_BITS)
#define CUBE_T    128
#define CUBE      ((u64)CUBE_T * CUBE_T)
#define CUBE_G    (1u << CUBE_LOG)
#define LANES     ((u64)CUBE_T << CUBE_LOG)
#define RING_LOG  (17 - CUBE_LOG)
#define RING_LEN  (1ull << RING_LOG)
#define STAK_LEN  (1ull << 11)
#define NCLS      8
#define NCLS_ALL  32
#define IO_HELP   64

#define TG_HOLD   2304
#define CHUNK     256
#define CAP_WORDS 32768
#define QUANTUM   (DEVICE ? PAGE_LEN \
  : KEEP_WORDS < 32 * PAGE_LEN ? KEEP_WORDS : 32 * PAGE_LEN)
#if DEVICE
#define KEEP_WORDS CHUNK
#endif
#define RING_WORDS ((1ull << 10) + 2)

#define H_BUMP       0
#define H_CAP        1
#define H_CURSOR     LINE
#define H_ROOT_DONE  (2 * LINE)
#define H_ERROR_CODE (3 * LINE)
#define H_ROOT_WORD  (4 * LINE)
#define H_BANK       (H_ROOT_WORD + WL_RESW)

#define PAGE_UP(n) (((n) + PAGE_LEN - 1) & ~(PAGE_LEN - 1))
#define ALC_OFF  PAGE_UP(H_BANK + 3 * NCLS_ALL)
#define RING_OFF (ALC_OFF + CUBE * 2 * NCLS_ALL)
#define STAK_OFF (RING_OFF + CUBE * RING_WORDS)
#define STAT_OFF (STAK_OFF + CUBE * STAK_LEN)
#define HEAP_OFF (STAT_OFF + PAGE_UP(STAT_LEN))

// Globals
// =======

// The bag is 2^CUBE_LOG groups of CUBE_T lanes (a -D constant on the
// device). The device program compiles from the binary's own text.

#if !DEVICE

static u64*    CORPUS;
static u64    ALC[CUBE_T + 1][3 * NCLS_ALL] __attribute__((aligned(128)));
static u32    KEEP_WORDS;
static u32    CUBE_LOG = 7;
static u32    bank_lock;

static u32             pool_size;
static u32             pool_row;
static bool            pool_grow;
static u32             pool_tick;
static u32             pool_done;
static pthread_mutex_t pool_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  pool_wake = PTHREAD_COND_INITIALIZER;

#if BEND_METAL || BEND_CUDA
#pragma clang diagnostic ignored "-Wc23-extensions"
static const char BEND_SRC[] = {
#embed __FILE__
, 0 };
#endif

#ifdef __OBJC__
static id<MTLDevice>               gpu_dev;
static id<MTLCommandQueue>         gpu_que;
static id<MTLComputePipelineState> gpu_pso;
static id<MTLBuffer>               gpu_buf;
static id<MTLComputeCommandEncoder> gpu_enc;
#elif BEND_CUDA
static CUdevice   gpu_dev;
static CUmodule   gpu_lib;
static CUfunction gpu_pso;
#endif
static bool io_gpu;
static DEV Term*  io_stk;

static const char* CLI_HELP =
  "usage: %s [options] [arguments]\n"
  "  --threads N       worker threads, 1 to 128 (default: the CPU count)\n"
  "  --gpu on|off|4GB  run ! calls on the GPU, over this much of its memory\n"
  "                    (default: on if present, over 2GB on Metal)\n"
  "  --gpu-build       write the GPU program and exit\n"
  "  --bend-help       show this text\n"
  "  --                the rest are the program's arguments (IO.args)\n";

#endif

// Tables
// ======

${tabs}

#define TAB_AT(T, S, I) T[S < I ? S : I]

#define fid_arity(x) ((u32)FID_T[x][0])
#define fid_resw(x)  ((u32)FID_T[x][1])
#define fid_bangs(x) ((bool)(FID_T[x][2] & 1))
#define fid_nofk(x)  ((bool)(FID_T[x][2] & 2))
#define cid_arity(x) ((u32)CID_T[x][0])
#define cid_hot(x)   ((bool)CID_T[x][1])

// A32
// ===

// C11's atomics on every lane; a device FENCE releases or acquires.
// Metal's a32_load reads through a volatile local, or the M1 pipeline
// build dies. A weak CAS may fail with the cell still x: a32_cmpx loops.

#define A32_LOOP(k, x) \
  INLINE u32 a32_##k(DEV u32* p, u32 v) { \
    u32 o = a32_load(p); \
    while (!a32_cas(p, &o, x)) { \
    } \
    return o; \
  }

#ifdef __METAL_VERSION__

INLINE DEV atomic_uint* A32(DEV u32* p) {
  return (DEV atomic_uint*)p;
}

INLINE TG atomic_uint* A32(TG u32* p) {
  return (TG atomic_uint*)p;
}

#define a32_load(p) \
  ({ volatile thread u32 _a32v = atomic_load_explicit(A32(p), RLX); _a32v; })

#else

#define a32_load(p) atomic_load_explicit(A32(p), RLX)

#ifdef BEND_RTC

#define A32(p) (p)
#define atomic_load_explicit(p, o)     (*(volatile u32*)(p))
#define atomic_store_explicit(p, v, o) (*(volatile u32*)(p) = (v))
${a32_ops((k) => `atomic_fetch_${k}_explicit(p, v, o) atomic${k[0]
  .toUpperCase()}${k.slice(1)}((u32*)(p), v)`)}
#define atomic_compare_exchange_weak_explicit(p, e, v, s, f) a32_swp(p, e, v)

INLINE bool a32_swp(DEV u32* p, u32* e, u32 v) {
  u32 x = *e;
  *e = atomicCAS((u32*)p, x, v);
  return *e == x;
}

#else

#define A32(p) ((_Atomic u32*)(p))
#define atomic_fetch_min_explicit __c11_atomic_fetch_min
#define atomic_fetch_max_explicit __c11_atomic_fetch_max

#endif

#endif

#define RLX memory_order_relaxed

#if DEVICE
#define REL RLX
#define ACQ RLX
#define ACR RLX
#define a32_acq(p) FENCE()
#else
#define REL memory_order_release
#define ACQ memory_order_acquire
#define ACR memory_order_acq_rel
#define a32_acq(p) ((void)a32_load_acq(p))
#endif

#define a32_store(p, v)     atomic_store_explicit(A32(p), v, RLX)
${a32_ops((k) => `a32_${k}(p, v) atomic_fetch_${k}_explicit(A32(p), v, RLX)`)}
#define a32_sub_rel(p, v)   (FENCE(), atomic_fetch_sub_explicit(A32(p), v, REL))
#define a32_store_rel(p, v) (FENCE(), atomic_store_explicit(A32(p), v, REL))
#define a32_at(H, word)     ((DEV u32*)&(H)[word])

INLINE u32 a32_load_acq(DEV u32* p) {
  u32 v = atomic_load_explicit(A32(p), ACQ);
  FENCE();
  return v;
}

INLINE bool a32_cas(DEV u32* p, THR u32* e, u32 v) {
  FENCE();
  bool ok = atomic_compare_exchange_weak_explicit(A32(p), e, v, ACR, ACQ);
  FENCE();
  return ok;
}

A32_LOOP(exch, v)

INLINE u32 a32_cmpx(DEV u32* p, u32 x, u32 v) {
  u32 o = x;
  while (!a32_cas(p, &o, v) && o == x) {
  }
  return o;
}

// Err
// ===

#if DEVICE

INLINE void err_post(DEV u64* H, u32 code) {
  a32_cmpx(a32_at(H, H_ERROR_CODE), 0, code);
}

#else

static const char* ERR_TEXT[] = { ${ERRS.map((s) => JSON.stringify(s))
  .join(",\n  ")} };

static void err_fail(const char* msg) {
  fflush(stdout);
  fprintf(stderr, "bend: %s\n", msg);
  _exit(1);
}

static void err_post(u64* H, u32 code) {
  err_fail(ERR_TEXT[code]);
}

static void err_trap(int sig) {
  err_post(NULL, ERR_DEEP);
}

#endif

#define err_seen(H)    (DEVICE && a32_load(a32_at(H, H_ERROR_CODE)) != 0)
#define err_spun(H, n) ((++*(n) & 4095) == 0 && err_seen(H))

${NATIVE.C}
A32_LOOP(fadd, f32_rewrap(f32_unbox(o) + f32_unbox(v)))

// Bank
// ====

// A stack of exact generations per class. The host pops and pushes at rd;
// a device pass pops below rd and pushes above top, compacted after it.

#define bank_at(H, c) ((DEV Bank*)((H) + H_BANK) + (c))

INLINE u64 bank_pop(DEV u64* H, u32 c) {
  DEV Bank* b = bank_at(H, c);
  u64 got = 0;
  LOCK(bank_lock);
  u32 t = a32_sub(&b->rd, 1);
  if ((int)t > 0) {
    got = H[b->off + t - 1];
  } else {
    a32_add(&b->rd, 1);
  }
  if (!DEVICE) {
    b->wr = b->top = b->rd;
  }
  UNLOCK(bank_lock);
  return got;
}

INLINE void bank_push(DEV u64* H, u32 c, u64 head) {
  DEV Bank* b = bank_at(H, c);
  LOCK(bank_lock);
  H[b->off + a32_add(&b->wr, 1)] = head;
  if (!DEVICE) {
    b->rd = b->top = b->wr;
  }
  UNLOCK(bank_lock);
}

// Heap
// ====

// Per lane and class: HOT, a LIFO free chain; LEN, its length in words;
// on the host COLD, one parked generation. A host free reaching KEEP_WORDS
// parks HOT as COLD and banks the old COLD. A miss takes COLD, a bank entry
// or a fresh quantum. A device lane banks its complete generations at the
// kernel end (dev_cut). The bump grows only when all of these are empty.

#define ALC_AT(e, i)   (e).alc[(i) * LANE_STEP]
#define ALC_LEN(e, c)  ALC_AT(e, NCLS_ALL + (c))
#define ALC_COLD(e, c) ALC_AT(e, 2 * NCLS_ALL + (c))
#define KEEP(c)        (KEEP_WORDS >> (c) ? KEEP_WORDS >> (c) : 1)

INLINE u32 cls_fit(u32 words) {
  return words > 1 ? 32 - CLZ(words - 1) : 0;
}

OUTLINE void heap_hand(Env e, u32 cls) {
  u64 cold = ALC_COLD(e, cls);
  if (cold) {
    bank_push(e.mem, cls, cold);
  }
  ALC_COLD(e, cls) = ALC_AT(e, cls);
  ALC_AT(e, cls)   = 0;
  ALC_LEN(e, cls)  = 0;
}

#if DEVICE
#define corpus_grow(H, n) false
#else
static bool corpus_grow(u64* H, u64 need);
#endif

OUTLINE u64 heap_alloc_miss(Env e, u32 cls) {
  DEV u64* H = e.mem;
  u64  got = 0;
  if (!DEVICE) {
    got = ALC_COLD(e, cls);
    ALC_COLD(e, cls) = 0;
  }
  if (!got) {
    got = bank_pop(H, cls);
  }
  u32 n = got ? KEEP(cls) : cls < NCLS ? QUANTUM >> cls : 1;
  if (!got) {
    u32 pages = (n << cls) >> PAGE_BITS;
    u32 p     = a32_add(a32_at(H, H_BUMP), pages);
    if ((u64)p + pages > a32_load_acq(a32_at(H, H_CAP))
      && !corpus_grow(H, (u64)p + pages)) {
      err_post(H, ERR_HEAP);
      return HEAP_OFF;
    }
    got = HEAP_OFF + ((u64)p << PAGE_BITS);
    for (u32 i = 1; i <= n; i += 1) {
      H[got + ((u64)(i - 1) << cls)] = i < n ? got + ((u64)i << cls) : 0;
    }
  }
  ALC_AT(e, cls)  = H[got];
  ALC_LEN(e, cls) = (u64)(n - 1) << cls;
  return got;
}

INLINE u64 heap_alloc(Env e, u32 cls) {
  u64 h = ALC_AT(e, cls);
  if (h) {
    ALC_AT(e, cls)   = e.mem[h];
    ALC_LEN(e, cls) -= 1ull << cls;
    return h;
  }
  return heap_alloc_miss(e, cls);
}

INLINE void heap_free(Env e, u32 cls, u64 loc) {
  if (err_seen(e.mem)) {
    return;
  }
  e.mem[loc]       = ALC_AT(e, cls);
  ALC_AT(e, cls)   = loc;
  ALC_LEN(e, cls) += 1ull << cls;
  if (!DEVICE && ALC_LEN(e, cls) >= KEEP_WORDS) {
    heap_hand(e, cls);
  }
}

INLINE void spare_free(Env e, u32 cls, u64 loc) {
  if (loc >= HEAP_OFF) {
    heap_free(e, cls, loc);
  }
}

// Term
// ====

// A static node (below the heap) is trivial, as is a captureless
// closure. A fork's Array handle (BLK_SHR: an Array binder is hot)
// is a redirect: loaded plainly, copied and dropped by a match.

#define term_make(tag, aux, loc) \
  (((u64)(tag) << 56) | ((u64)(aux) << 40) | (u64)(loc))

#define term_ctr(cid, loc) term_make(TAG_CTR, cid, loc)
#define term_pak(cid, loc) term_make(TAG_PAK, cid, loc)
#define term_clo(fid, loc) term_make(TAG_CLO, fid, loc)
#define term_buf(cls, loc) term_make(TAG_BUF, cls, loc)
#define term_tsk(fid, loc) term_make(TAG_TSK, fid, loc)

INLINE Term term_blk(bool arr, u32 cls, u64 loc) {
  return term_buf(cls, loc) | ((u64)arr << 57);
}

INLINE u64 term_tag(Term t) {
  return (t >> 56) & 0x7f;
}

INLINE bool term_rfc(Term t) {
  return (t & RFC_BIT) != 0;
}

INLINE u64 term_aux(Term t) {
  return (t >> 40) & 0xFFFF;
}

INLINE u64 term_loc(Term t) {
  return t & LOC_MASK;
}

INLINE bool term_triv(Term t) {
  return term_tag(t) <= TAG_PAK || t == TERM_HOLE || term_loc(t) < HEAP_OFF;
}

OUTLINE Term rfc_wrap(Env e, Term t, u32 cnt) {
  if (term_tag(t) == TAG_CLO || term_tag(t) == TAG_TSK) {
    err_post(e.mem, ERR_RFCS);
    return t;
  }
  u64 r = heap_alloc(e, 0);
  e.mem[r] = ((u64)term_loc(t) << 24) | cnt;
  return (t & ~LOC_MASK) | RFC_BIT | r;
}

INLINE Term rfc_seal(Env e, Term t) {
  if (term_tag(t) != TAG_CTR || term_rfc(t)) {
    return t;
  }
  return rfc_wrap(e, t, 1);
}

INLINE u64 rfc_view(Env e, u64 r) {
  DEV u32* w = a32_at(e.mem, r);
  u64 cell = ((u64)a32_load(w + 1) << 32) | a32_load(w);
  if ((cell & RFC_CNT) == 1) {
    a32_acq(w);
  }
  return cell;
}

INLINE void rfc_bump(Env e, u64 r, u32 k) {
  u32 c = a32_add(a32_at(e.mem, r), k);
  if ((c & RFC_CNT) >= RFC_CNT - k) {
    err_post(e.mem, ERR_RFCS);
  }
}

INLINE Term term_keep(Env e, Term t, u32 k) {
  if (term_rfc(t)) {
    rfc_bump(e, term_loc(t), k);
    return t;
  }
  if (term_triv(t)) {
    return t;
  }
  return rfc_wrap(e, t, 1 + k);
}

INLINE u64 term_peek(Env e, Term t) {
  if (term_rfc(t)) {
    return rfc_view(e, term_loc(t)) >> 24;
  }
  return term_loc(t);
}

#define blk_shr(t) (BLK_SHR && term_rfc(t))

INLINE u64 blk_loc(DEV u64* H, Term a) {
  return blk_shr(a) ? H[term_loc(a)] >> 24 : term_loc(a);
}

INLINE u32 blk_cls(Term t) {
  return (u32)term_aux(t) & 31;
}

#define buf_wcls(c) ((c) == 0 ? 0 : (c) - 1)

INLINE u32 blk_span(Term t) {
  u32 c = blk_cls(t);
  return term_tag(t) == TAG_ARR ? c : buf_wcls(c);
}

FAR void term_drop(Env e, Term t) {
  DEV u64* H = e.mem;
  u64  cur = 0;
  Term c0  = 0;
  u32  step = 0;
  for (;;) {
    if (!term_triv(t) && term_rfc(t)) {
      u64      r = term_loc(t);
      DEV u32* p = a32_at(H, r);
      if ((a32_sub_rel(p, 1) & RFC_CNT) != 1) {
        t = 0;
      } else {
        a32_acq(p);
        t = (t & ~(RFC_BIT | LOC_MASK)) | (H[r] >> 24);
        heap_free(e, 0, r);
      }
    }
    if (!term_triv(t)) {
      u64 tag = term_tag(t);
      if (tag == TAG_BUF) {
        heap_free(e, blk_span(t), term_loc(t));
      } else {
        u32 aux = (u32)term_aux(t);
        u64 loc = term_loc(t);
        u32 n   = tag == TAG_ARR ? 0 : tag == TAG_CTR ? cid_arity(aux)
          : fid_arity(aux) - (tag == TAG_CLO);
        u32 cls = tag == TAG_ARR ? 64 | blk_cls(t)
          : n > ${WIDE} ? 64 | (n - 240)
          : cls_fit(tag == TAG_TSK ? n + 2 : n);
        c0 = H[loc];
        H[loc] = cur;
        cur = loc | ((u64)n << 48) | ((u64)cls << 56);
      }
    }
    for (;;) {
      if (err_spun(H, &step)) {
        return;
      }
      if (cur == 0) {
        return;
      }
      u64  loc = cur & LOC_MASK;
      u32  i   = (u8)(cur >> 40);
      u32  n   = (u8)(cur >> 48);
      u32  cls = (u32)(cur >> 56);
      bool arr = cls > 63;
      u32  j   = i;
      if (arr) {
        cls &= 63;
        n   = 1u << cls;
        if (i == 2) {
          j = (u32)H[loc + 1];
        }
      }
      if (j < n) {
        Term c = j == 0 ? c0 : H[loc + j];
        if (arr && j > 0) {
          H[loc + 1] = j + 1;
        }
        if (!arr || i < 2) {
          cur += 1ull << 40;
        }
        if (!term_triv(c)) {
          t = c;
          break;
        }
      } else {
        u64 up = H[loc];
        heap_free(e, cls, loc);
        cur = up;
      }
    }
  }
}

INLINE void term_sink(Env e, Term t) {
  if (!term_triv(t)) {
    term_drop(e, t);
  }
}

OUTLINE void span_fade(Env e, Term t, u64 src, u32 n) {
  for (u32 j = 0; j < n; j += 1) {
    Term f = e.mem[src + j];
    if (term_rfc(f)) {
      rfc_bump(e, term_loc(f), 1);
    } else if (!term_triv(f)) {
      err_post(e.mem, ERR_RFCS);
    }
  }
  term_drop(e, t);
}

INLINE u64 ctr_take(Env e, Term t, u32 n, THR Term* out) {
  DEV u64* H = e.mem;
  if (!term_rfc(t)) {
    for (u32 j = 0; j < n; j += 1) {
      out[j] = H[term_loc(t) + j];
    }
    return term_loc(t);
  }
  u64 r    = term_loc(t);
  u64 cell = rfc_view(e, r);
  u64 src  = cell >> 24;
  for (u32 j = 0; j < n; j += 1) {
    out[j] = H[src + j];
  }
  if ((cell & RFC_CNT) == 1) {
    heap_free(e, 0, r);
    return src;
  }
  span_fade(e, t, src, n);
  return 0;
}

INLINE Term term_word(Env e, Term w) {
  u32 x = 0;
  Term t = w;
  for (u32 i = 0; i < 32 && term_aux(t) == CID(WCon); i += 1) {
    u64 l = term_peek(e, t);
    x |= (u32)(e.mem[l] & 1) << i;
    t = e.mem[l + 1];
  }
  term_sink(e, w);
  return x;
}

// Blk
// ===

// A block owns one allocation in its class (an ARR 2^c Terms, a BUF 2^c
// u32). Matching ANode is blk_half twice (the high call frees the source);
// ANode{l, r} is blk_node; Array.clone is blk_copy.

#define BLK_ALLOC(n, w) \
  u64 n = heap_alloc(e, w); \
  if (err_seen(e.mem)) { \
    return term_buf(0, n); \
  }

INLINE DEV u32a* blk_ptr(DEV u64* H, u64 loc, u32 i) {
  return (DEV u32a*)(H + loc) + i;
}

INLINE Term blk_read(DEV u64* H, bool arr, u64 loc, u32 i) {
  if (arr) {
    return H[loc + i];
  }
  return (u64)*blk_ptr(H, loc, i);
}

INLINE void blk_write(DEV u64* H, bool arr, u64 loc, u32 i, Term v) {
  if (arr) {
    H[loc + i] = v;
  } else {
    *blk_ptr(H, loc, i) = (u32)v;
  }
}

INLINE u32 blk_at(Term a, u64 i, u32 lgs) {
  return ((u32)i & (u32)((1ull << (blk_cls(a) - lgs)) - 1)) << lgs;
}

INLINE Term blk_keep(Env e, u64 at) {
  Term w = e.mem[at];
  Term v = term_keep(e, w, 1);
  if (v != w) {
    e.mem[at] = v;
  }
  return v;
}

INLINE void blk_fill(Env e, u64 dst, u64 src, u64 n, bool keep) {
  for (u64 j = 0; j < n; j += 1) {
    e.mem[dst + j] = keep ? blk_keep(e, src + j) : e.mem[src + j];
  }
}

INLINE void blk_free(Env e, Term t) {
  blk_shr(t) ? term_drop(e, t) : heap_free(e, blk_span(t), term_loc(t));
}

OUTLINE Term blk_copy(Env e, Term a) {
  bool arr = term_tag(a) == TAG_ARR;
  u32 cls = blk_span(a);
  BLK_ALLOC(dst, cls)
  blk_fill(e, dst, blk_loc(e.mem, a), 1ull << cls, arr);
  return term_blk(arr, blk_cls(a), dst);
}

INLINE Term blk_node(Env e, Term l, Term r) {
  DEV u64* H = e.mem;
  bool arr = term_tag(l) == TAG_ARR;
  u32 c = blk_cls(l);
  if (c != blk_cls(r) || c + 1 >= NCLS_ALL) {
    err_post(H, ERR_TAGS);
    return l;
  }
  u64 pl = blk_loc(H, l);
  u64 pr = blk_loc(H, r);
  BLK_ALLOC(n, arr ? c + 1 : c)
  if (!arr && c == 0) {
    H[n] = (u64)*blk_ptr(H, pl, 0) | ((u64)*blk_ptr(H, pr, 0) << 32);
  } else {
    u64 cw = 1ull << blk_span(l);
    blk_fill(e, n, pl, cw, arr && blk_shr(l));
    blk_fill(e, n + cw, pr, cw, arr && blk_shr(r));
  }
  blk_free(e, l);
  blk_free(e, r);
  return term_blk(arr, c + 1, n);
}

INLINE Term blk_half(Env e, Term a, u32 hi) {
  DEV u64* H = e.mem;
  bool arr = term_tag(a) == TAG_ARR;
  u32 c = blk_cls(a);
  if (c == 0) {
    err_post(H, ERR_TAGS);
    return a;
  }
  c -= 1;
  u32 cw = arr ? c : buf_wcls(c);
  u64 src = blk_loc(H, a);
  BLK_ALLOC(n, cw)
  if (!arr && c == 0) {
    H[n] = (u64)*blk_ptr(H, src, hi);
  } else {
    blk_fill(e, n, src + ((u64)hi << cw), 1ull << cw, arr && blk_shr(a));
  }
  if (hi) {
    blk_free(e, a);
  }
  return term_blk(arr, c, n);
}

INLINE Term blk_new(Env e, bool arr, u64 d, u32 lgs, u32 n, THR Term* v) {
  DEV u64* H = e.mem;
  if (d + lgs > 31) {
    err_post(H, ERR_ARRS);
    d = 0;
  }
  u32 c = (u32)d + lgs;
  BLK_ALLOC(l, arr ? c : buf_wcls(c))
  for (u32 j = 0; arr && d > 0 && j < n; j += 1) {
    if (d >= 24 && !term_triv(v[j])) {
      err_post(H, ERR_RFCS);
    }
    v[j] = term_keep(e, v[j], (1u << d) - 1);
  }
  for (u64 i = 0; i < (1ull << c); i += 1) {
    blk_write(H, arr, l, (u32)i, i % (1u << lgs) < n ? v[i % (1u << lgs)] : 0);
  }
  return term_blk(arr, c, l);
}

// Ring
// ====

// planes LANES wide: a smaller bag has deeper rings in the same region
#define ring_word(H, r, w) ((H) + RING_OFF + (w) * LANES + (r))
#define ring_slot(H, r, p) ring_word(H, r, (p) & (RING_LEN - 1))
#define ring_get(H, r)     ((DEV u32*)ring_word(H, r, RING_LEN))
#define ring_put(H, r)     ((DEV u32*)ring_word(H, r, RING_LEN + 1))

INLINE u32 ring_lap(u32 pos) {
  return ~(u32)(pos / RING_LEN) & 1;
}

INLINE void ring_push(DEV u64* H, u32 r, Term tsk) {
  u32 pos = a32_add(ring_put(H, r), 1);
  if (pos - a32_load(ring_get(H, r)) >= RING_LEN) {
    err_post(H, ERR_RING);
    return;
  }
  DEV u32* lo = (DEV u32*)ring_slot(H, r, pos);
  a32_store(lo, (u32)tsk);
  a32_store_rel(lo + 1, (u32)(tsk >> 32) | (ring_lap(pos) << 31));
}

INLINE u32 ring_flip(u32 i) {
  return (i % CUBE_T << CUBE_LOG) + i / CUBE_T;
}

#define ring_pick(b, s, c) ((b) + (s) * (a32_add(c, 1) & (CUBE_T - 1)))

// Task
// ====

INLINE u64 task_node(Env e, u32 fid, Term cont, u32 idx, u32 rem) {
  u32 ar  = fid_arity(fid);
  u64 loc = heap_alloc(e, cls_fit(ar + 2));
  for (u32 i = 0; rem && i < ar; i += 1) {
    e.mem[loc + i] = TERM_HOLE;
  }
  e.mem[loc + ar]     = cont;
  e.mem[loc + ar + 1] = ((u64)idx << 32) | rem;
  return loc;
}

INLINE u64 task_tail(Term t) {
  return term_loc(t) + fid_arity((u32)term_aux(t));
}

INLINE Term task_deliver(DEV u64* H, Term cont, u32 idx, THR Term* v, u32 n) {
  u64 at = cont == TERM_HOLE ? H_ROOT_WORD : term_loc(cont) + idx;
  for (u32 j = 0; j < WL_RESW; j += 1) {
    if (j < n) {
      H[at + j] = v[j];
    }
  }
  if (cont == TERM_HOLE) {
    a32_store_rel(a32_at(H, H_ROOT_DONE), n + 1);
    return 0;
  }
  u64 tl = task_tail(cont);
  if (a32_sub_rel(a32_at(H, tl + 1), 1) == 1) {
    a32_acq(a32_at(H, tl + 1));
    return cont;
  }
  return 0;
}

INLINE void task_deal(DEV u64* H, Term join, u32 base, u32 stride, TG u32* cur) {
  u64 loc = term_loc(join);
  u32 ar  = fid_arity((u32)term_aux(join));
  u32 g   = 0;
  if (stride == 0) {
    u32 rem = (u32)H[loc + ar + 1];
    g = a32_add(a32_at(H, H_CURSOR), rem);
  }
  for (u32 i = 0; i < ar; i += 1) {
    Term k = H[loc + i];
    if (term_tag(k) == TAG_TSK) {
      H[loc + i] = TERM_HOLE;
      u32 to;
      if (stride != 0) {
        to = ring_pick(base, stride, cur);
      } else {
        to = ring_flip(g & (u32)(LANES - 1));
        g += 1;
      }
      ring_push(H, to, k);
    }
  }
}

// Root
// ====

INLINE bool root_done(DEV u64* H) {
  return a32_load_acq(a32_at(H, H_ROOT_DONE)) != 0;
}

static u32 root_take(DEV u64* H, THR Term* v) {
  u32 n = a32_load_acq(a32_at(H, H_ROOT_DONE)) - 1;
  for (u32 j = 0; j < n; j += 1) {
    v[j] = H[H_ROOT_WORD + j];
  }
  a32_store(a32_at(H, H_ROOT_DONE), 0);
  return n;
}

// Spins
// =====

${spins}

// Work
// ====

// A host self-jump is a tail call: as a loop, clang hoisted constants into
// symreg's entry (3.05 s against 2.51 s).
#if !DEVICE
#undef  WL_SPIN
#undef  WL_SPUN
#undef  WL_AGAIN
#define WL_SPIN
#define WL_SPUN
#define WL_AGAIN(F) __attribute__((musttail)) return WL_##F(WL_ALL)

typedef Term (PRESERVE(preserve_none) *WlFn)(WL_SIG);
#define WL_X(F) WL_FN WL_##F(WL_SIG);
WL_TABLE WL_X(FID_ENTER)
#undef WL_X
#define WL_X(F) WL_##F,
static const WlFn wl_tab[] = { WL_TABLE };
#undef WL_X
#endif

static Term work_loop(Env e, DEV Term* sp, Term t, u32 seq) {
  WL_BANK
  u32 rn = 0;
  r0 = t;
#if DEVICE
  u32 fid   = FID_ENTER;
  u32 wpoll = 0;
  for (;;) {
  if (err_spun(e.mem, &wpoll)) {
    return 0;
  }
  switch (fid) {
#else
  return WL_FID_ENTER(WL_ALL);
}
#endif

// Segments
// ========

// A task enters through its words: a continuation's results ride r0..
// and its parameters the stack; any other segment's parameters ride r0..

${segs}

  WL_CASE(FID_ENTER)
  {
    Term t = r0;
    WL_OPEN
    u32 f   = (u32)term_aux(t);
    u64 a   = term_loc(t);
    u32 war = fid_arity(f);
    WL_FRAME(t)
    seq |= fid_nofk(f) << 1;
    if (fid_resw(f)) {
      u32 rw = fid_resw(f);
      WL_LOAD(a + war - rw, rw)
      WL_ARGS(a, war - rw + 1)
    } else {
      WL_LOAD(a, war)
    }
    heap_free(e, cls_fit(war + 2), a);
    WL_DYN(f);
  }}

  WL_CASE(FID(IO~emit))
  {
    Term x = r0;
    WL_OPEN
    u64 l = heap_alloc(e, 0);
    e.mem[l] = x;
    r0 = term_ctr(CID(Emit), l);
    WL_RETN(1);
  }}

  WL_CASE(FID(Clo~apply))
  {
    Term fun = r0;
    Term arg = r1;
    WL_OPEN
    u32 f    = (u32)term_aux(fun);
    u32 war  = fid_arity(f) - 1;
    u64 a    = term_loc(fun);
    WL_LOAD(a, war)
    spare_free(e, cls_fit(war), a);
    WL_LAST(arg)
    WL_DYN(f);
  }}

  WL_CASE(FID_EXIT)
  {
    u32  n = rn;
    Term rv[WL_RESW];
    WL_SAVE(rv)
    WL_OPEN
    if (err_seen(e.mem)) {
      return 0;
    }
    sp -= 2 * LANE_STEP;
    Term cont = STK(0);
    u32  idx  = (u32)STK(1);
    if (cont != TERM_HOLE && fid_resw((u32)term_aux(cont))) {
      u32 wf = (u32)term_aux(cont);
      u64 wa = term_loc(cont);
      u32 wn = fid_arity(wf);
      WL_FRAME(cont)
      seq = (seq & 1) | fid_nofk(wf) << 1;
      WL_ARGS(wa, wn - n + 1)
      heap_free(e, cls_fit(wn + 2), wa);
      WL_TAKE(rv)
      WL_DYN(wf);
    }
    return task_deliver(e.mem, cont, idx, rv, n);
  }}

#if DEVICE
  default: {
    err_post(e.mem, ERR_FIDS);
    return 0;
  }
  }
  }
}
#endif

// Monk
// ====

// One turn on a ring: its head task below put0 runs (a growing
// lane skips a fork-free one). The host grows a row ring by
// ring and drains a ring; a device lane does both.
INLINE u32 monk_step(Env e, DEV Term* stk, u32 rg, u32 put0, u32 base, u32 stride,
  TG u32* cur) {
  DEV u64* H   = e.mem;
  bool     seq = stride == 0;
  DEV u32* get = ring_get(H, rg);
  if (*get == put0) {
    return 0;
  }
  DEV u32* lo = (DEV u32*)ring_slot(H, rg, *get);
  u32      hi = a32_load_acq(lo + 1);
  Term     t  = (((u64)hi << 32) | a32_load(lo)) & ~RFC_BIT;
  if ((hi >> 31) != ring_lap(*get) || (!seq && fid_nofk((u32)term_aux(t)))) {
    return 0;
  }
  a32_store(get, *get + 1);
  u32 spin = 0;
  for (;;) {
    Term r = work_loop(e, stk, t, seq);
    if (r == 0) {
      return 2;
    }
    if ((u32)H[task_tail(r) + 1] == 0) {
      if (err_spun(H, &spin)) {
        return 2;
      }
      if (stride != 0 && fid_nofk((u32)term_aux(r))) {
        ring_push(H, ring_pick(base, stride, cur), r);
        return 2;
      }
      t      = r;
      seq    = false;
      stride = 0;
      continue;
    }
    task_deal(H, r, base, stride, cur);
    return 1;
  }
}

// Dev
// ===

// One kernel: pass 0 grows the frontier, pass 1 drains each lane's ring,
// pass 2 packs the banks: in one group, each bank's [top, wr) slides onto
// rd, CUBE_T entries a step (loads, barrier, stores: rd <= top), off the
// host's pages. A grow pass ends when its group is full or nothing grew,
// so a spine of forks unrolls whole. TG_HOLD words of threadgroup memory
// hold one group per Apple core (bitonic 1.35x without).

#if DEVICE

INLINE void dev_cut(Env e) {
  if (err_seen(e.mem)) {
    return;
  }
  for (u32 c = 0; c < NCLS_ALL; c += 1) {
    u64 gen = (u64)KEEP(c) << c;
    while (ALC_LEN(e, c) >= gen) {
      u64 head = ALC_AT(e, c);
      u64 tail = head;
      for (u32 i = KEEP(c); --i;) {
        tail = e.mem[tail];
      }
      ALC_AT(e, c)    = e.mem[tail];
      ALC_LEN(e, c)  -= gen;
      e.mem[tail]     = 0;
      bank_push(e.mem, c, head);
    }
  }
}

INLINE void bank_pack(DEV u64* H, u32 lane) {
  for (u32 c = 0; c < NCLS_ALL; c += 1) {
    DEV Bank* b  = bank_at(H, c);
    u32       rd = b->rd;
    u32       n  = b->wr - b->top;
    for (u32 i = 0; i < n; i += CUBE_T) {
      Term v = i + lane < n ? H[b->off + b->top + i + lane] : 0;
      BAR();
      if (i + lane < n) {
        H[b->off + rd + i + lane] = v;
      }
    }
    BAR();
    if (lane == 0) {
      b->rd = b->wr = b->top = rd + n;
    }
  }
}

#ifdef __METAL_VERSION__
kernel void bend_dev(DEV u64* H [[buffer(0)]], constant u32& pass [[buffer(1)]],
  TG u32* vote [[threadgroup(0)]],
  u32 grids [[threadgroups_per_grid]],
  u32 row [[threadgroup_position_in_grid]],
  u32 lane [[thread_position_in_threadgroup]]) {
#else
extern "C" __global__ void bend_dev(DEV u64* H, u32 pass) {
  extern __shared__ u32 vote[];
  u32 grids = gridDim.x;
  u32 row   = blockIdx.x;
  u32 lane  = threadIdx.x;
#endif
  if (pass == 2) {
    bank_pack(H, lane);
    return;
  }
  u32  stride = grids == 1 ? CUBE_G : 1;
  u32  me     = row * CUBE_T + stride * lane;
  u32 rg     = pass ? ring_flip(me) : me;
  Env  e      = { H, H + ALC_OFF + me };
  DEV Term*  stk    = (DEV Term*)(H + STAK_OFF + me);
  if (lane == 0) {
    for (u32 i = 0; i < 3; i += 1) {
      a32_store(vote + i, 0);
    }
  }
  BAR();
  u32 put0      = a32_load(ring_put(H, rg));
  u32 seen_has  = 0;
  u32 seen_grew = 0;
  for (;;) {
    if (pass) {
      if (*ring_get(H, rg) == put0 || err_seen(H)) {
        break;
      }
    } else {
      put0 = a32_load(ring_put(H, rg));
      u32 has = put0 != a32_load(ring_get(H, rg));
      if (lane == 0 && (err_seen(H) || root_done(H))) {
        has = CUBE_T;
      }
      a32_add(vote + 2, has);
      BAR();
      has = a32_load(vote + 2);
      if (has - seen_has >= CUBE_T) {
        break;
      }
      seen_has = has;
    }
    u32 ran = monk_step(e, stk, rg, put0, row * CUBE_T, pass ? 0 : stride,
      vote);
    if (!pass) {
      if (ran == 1) {
        a32_add(vote + 1, 1);
      }
      BARD();
      u32 grew = a32_load(vote + 1);
      if (grew == seen_grew) {
        break;
      }
      seen_grew = grew;
    }
  }
  dev_cut(e);
}

#endif

// Window
// ======

// Linux's window fill (the Mac's is window_msl): an Image is a quadtree over
// 2^k x 2^k (Qua splits tl, tr, bl, br; Pix is 0xRRGGBB).
#if defined(__linux__) || defined(BEND_RTC)

INLINE u32 window_pix(DEV u64* H, Term t, u32 k, u32 x, u32 y) {
  for (u32 i = k; term_tag(t) == TAG_CTR;) {
    u32 j = 0;
    if (i > 0) {
      i -= 1;
      j = ((y >> i) & 1) * 2 + ((x >> i) & 1);
    }
    u64 l = term_rfc(t) ? H[term_loc(t)] >> 24 : term_loc(t);
    t = H[l + j];
  }
  return (u32)term_loc(t) & 0xFFFFFF;
}

#ifdef BEND_RTC
extern "C" __global__ void window_dev(DEV u64* H, Term root, u32 w, u32 h,
  u32 k, u32* out) {
  u32 x = blockIdx.x * blockDim.x + threadIdx.x;
  u32 y = blockIdx.y * blockDim.y + threadIdx.y;
  if (x < w && y < h) {
    out[y * w + x] = window_pix(H, root, k, x, y);
  }
}
#endif

#endif

#if !DEVICE

// Row
// ===

static void row_grow(Env e, DEV Term* stk, u32 base, u32 stride, u32 want) {
  u64* H = e.mem;
  u32 cur = 0;
  for (;;) {
    u32 put0[CUBE_T];
    u32 has = 0;
    for (u32 i = 0; i < CUBE_T; i += 1) {
      put0[i] = *ring_put(H, base + i * stride);
      has += put0[i] != *ring_get(H, base + i * stride);
    }
    if (root_done(H) || has >= want) {
      return;
    }
    u32 grew = 0;
    u32 ran  = 0;
    for (u32 i = 0; i < CUBE_T && ran != 2; i += 1) {
      ran   = monk_step(e, stk, base + i * stride, put0[i], base, stride,
        &cur);
      grew += ran == 1;
    }
    if (grew == 0) {
      return;
    }
  }
}

// Pool
// ====

// cpu_count caps the CPU count by the affinity mask and the cgroup quota.

static void* pool_try(void* at, u64 bytes) {
  return mmap(at, bytes, PROT_READ | PROT_WRITE,
    MAP_PRIVATE | MAP_ANON | MAP_NORESERVE, -1, 0);
}

static void* pool_mmap(u64 bytes) {
  void* p = pool_try(NULL, bytes);
  if (p == MAP_FAILED) {
    err_fail("reservation failed");
  }
  return p;
}

static Term* pool_stack(void) {
  u64   len = 1ull << 31;
  char* p   = pool_mmap(len + 16384 + SIGSTKSZ);
  if (mprotect(p + len, 16384, PROT_NONE) != 0) {
    err_fail("stack guard failed");
  }
  stack_t ss = { .ss_sp = p + len + 16384, .ss_size = SIGSTKSZ };
  sigaltstack(&ss, NULL);
  struct sigaction sa = { .sa_handler = err_trap, .sa_flags = SA_ONSTACK };
  sigaction(SIGSEGV, &sa, NULL);
  sigaction(SIGBUS, &sa, NULL);
  return (Term*)p;
}

static void* pool_work(void* arg) {
  Term* stk  = pool_stack();
  u32   seen = 0;
  for (;;) {
    pthread_mutex_lock(&pool_lock);
    while (pool_tick == seen) {
      pthread_cond_wait(&pool_wake, &pool_lock);
    }
    seen = pool_tick;
    pthread_mutex_unlock(&pool_lock);
    Env e = { CORPUS, ALC[1 + (u32)(uintptr_t)arg] };
    for (;;) {
      u32 r = a32_add(&pool_row, 1);
      if (r >= (pool_grow ? CUBE_G : LANES / LINE)) {
        break;
      }
      if (pool_grow) {
        row_grow(e, stk, r * CUBE_T, 1, CUBE_T);
      } else {
        u32  step = CUBE_T / LINE;
        u32 row  = r / step * CUBE_T;
        for (u32 rg = row + r % step; rg < row + CUBE_T; rg += step) {
          u32 put0 = a32_load(ring_put(e.mem, rg));
          while (*ring_get(e.mem, rg) != put0 && !err_seen(e.mem)) {
            monk_step(e, stk, rg, put0, rg, 0, NULL);
          }
        }
      }
    }
    if (a32_sub_rel(&pool_done, 1) == 1) {
      pthread_mutex_lock(&pool_lock);
      pthread_cond_broadcast(&pool_wake);
      pthread_mutex_unlock(&pool_lock);
    }
  }
}

OUTLINE void pool_open(void) {
  static bool up;
  if (up) {
    return;
  }
  up = true;
  for (u32 w = 0; w < pool_size; w += 1) {
    pthread_t tid;
    if (pthread_create(&tid, NULL, pool_work, (void*)(uintptr_t)w)) {
      err_fail("pthread_create");
    }
  }
}

static int cpu_read(const char* path, long* a, long* b) {
  FILE* f = fopen(path, "r");
  int   n = f == NULL ? 0 : fscanf(f, "%ld %ld", a, b);
  if (f != NULL) {
    fclose(f);
  }
  return n;
}

static long cpu_count(void) {
  long n = sysconf(_SC_NPROCESSORS_ONLN);
#ifdef __linux__
  cpu_set_t set;
  if (sched_getaffinity(0, sizeof set, &set) == 0) {
    n = CPU_COUNT(&set);
  }
  long q = 0;
  long p = 0;
  if (cpu_read("/sys/fs/cgroup/cpu.max", &q, &p) != 2) {
    cpu_read("/sys/fs/cgroup/cpu/cpu.cfs_quota_us", &q, &p);
    cpu_read("/sys/fs/cgroup/cpu/cpu.cfs_period_us", &p, &p);
  }
  if (q > 0 && p > 0 && (q + p - 1) / p < n) {
    n = (q + p - 1) / p;
  }
#endif
  return n;
}

OUTLINE void pool_turn(bool grow) {
  pool_grow = grow;
  a32_store(&pool_row, 0);
  a32_store(&pool_done, pool_size);
  pthread_mutex_lock(&pool_lock);
  pool_tick += 1;
  pthread_cond_broadcast(&pool_wake);
  while (a32_load_acq(&pool_done) != 0) {
    pthread_cond_wait(&pool_wake, &pool_lock);
  }
  pthread_mutex_unlock(&pool_lock);
}

// Gpu
// ===

// gpu_make compiles the device program into <binary>.gpu
// (--gpu-build): Metal's binary archive, or CUDA's cubin behind a
// hash of the text. A launch loads it, else notes and compiles. CUDA
// shapes the bag by the device: a group of 128 lanes per 64 KB of
// L2, a power of two in 16..128 (Apple keeps the tuned 128). CUDA
// runs one stream: the default 8 cost about half of the startup.

static const char* gpu_path(void) {
  static char path[4096];
  u32 n = sizeof path - 8;
#ifdef __APPLE__
  _NSGetExecutablePath(path, &n);
#else
  path[readlink("/proc/self/exe", path, n)] = 0;
#endif
  return strcat(path, ".gpu");
}

static void gpu_note(const char* path) {
  fprintf(stderr, "bend: compiling the GPU program (%s is missing or"
    " stale)\n", path);
}

#if !BEND_CUDA
#define gpu_map pool_mmap
#endif

#if BEND_METAL || BEND_CUDA

static void gpu_kernel(u32 pass, u32 groups);

static void gpu_run(u32 f) {
  if (f < CUBE_T) {
    gpu_kernel(0, 1);
  }
  if (f < LANES) {
    gpu_kernel(0, CUBE_G);
  }
  gpu_kernel(1, CUBE_G);
  gpu_kernel(2, 1);
}

#endif

#if BEND_CUDA

static u64 gpu_hash(void) {
  u64 key = 14695981039346656037ull ^ CUBE_LOG;
  for (const char* p = BEND_SRC; *p != 0; p += 1) {
    key = (key ^ (u8)*p) * 1099511628211ull;
  }
  return key;
}

#endif

#if BEND_METAL

static void gpu_fail(NSError* err) {
  err_fail([[err localizedDescription] UTF8String]);
}

static bool gpu_probe(void) {
  return (gpu_dev = MTLCreateSystemDefaultDevice()) != nil;
}

static MTLComputePipelineDescriptor* gpu_desc(void) {
  NSError* err = nil;
  MTLCompileOptions* opts = [MTLCompileOptions new];
  opts.mathMode = MTLMathModeSafe;
  opts.preprocessorMacros = @{ @"CUBE_LOG": @(CUBE_LOG) };
  id<MTLLibrary> lib = [gpu_dev newLibraryWithSource:@(BEND_SRC) options:opts
    error:&err];
  if (!lib) {
    gpu_fail(err);
  }
  MTLComputePipelineDescriptor* d = [MTLComputePipelineDescriptor new];
  d.computeFunction = [lib newFunctionWithName:@"bend_dev"];
  return d;
}

static bool gpu_make(const char* path) {
  NSError* err = nil;
  id<MTLBinaryArchive> ar = [gpu_dev
    newBinaryArchiveWithDescriptor:[MTLBinaryArchiveDescriptor new] error:&err];
  if (![ar addComputePipelineFunctionsWithDescriptor:gpu_desc() error:&err]) {
    gpu_fail(err);
  }
  return [ar serializeToURL:[NSURL fileURLWithPath:@(path)] error:&err];
}

static id<MTLComputePipelineState> gpu_pipe(MTLComputePipelineDescriptor* d,
  id<MTLBinaryArchive> ar) {
  NSError* err = nil;
  d.binaryArchives = ar ? @[ar] : @[];
  id<MTLComputePipelineState> pso = [gpu_dev
    newComputePipelineStateWithDescriptor:d
    options:ar ? MTLPipelineOptionFailOnBinaryArchiveMiss : 0 reflection:nil
    error:&err];
  if (!pso && !ar) {
    gpu_fail(err);
  }
  return pso;
}

static u64 gpu_span(void) {
  u64 span = [gpu_dev recommendedMaxWorkingSetSize];
  u64 most = [gpu_dev maxBufferLength];
  span = span < most ? span : most;
  return span < (2ull << 30) ? span : 2ull << 30;
}

static void gpu_load(u64 bytes) {
  gpu_buf = [gpu_dev newBufferWithBytesNoCopy:CORPUS length:bytes
    options:MTLResourceStorageModeShared
      | MTLResourceHazardTrackingModeUntracked deallocator:nil];
  u64 most = [gpu_dev maxBufferLength];
  if (!gpu_buf && bytes > most) {
    char msg[96];
    snprintf(msg, sizeof msg, "--gpu %lluMB is over the device's %lluMB",
      (unsigned long long)(bytes >> 20), (unsigned long long)(most >> 20));
    err_fail(msg);
  }
  if (!gpu_buf) {
    err_fail("the GPU span is more than the device has");
  }
  @autoreleasepool {
    gpu_que = [gpu_dev newCommandQueue];
    const char* path = gpu_path();
    MTLBinaryArchiveDescriptor* ad = [MTLBinaryArchiveDescriptor new];
    ad.url = [NSURL fileURLWithPath:@(path)];
    MTLComputePipelineDescriptor* d = gpu_desc();
    id<MTLBinaryArchive> ar = [gpu_dev newBinaryArchiveWithDescriptor:ad
      error:nil];
    gpu_pso = ar ? gpu_pipe(d, ar) : nil;
    if (!gpu_pso) {
      gpu_note(path);
      gpu_pso = gpu_pipe(d, nil);
    }
  }
}

static void gpu_kernel(u32 pass, u32 groups) {
  [gpu_enc setComputePipelineState:gpu_pso];
  [gpu_enc setBuffer:gpu_buf offset:0 atIndex:0];
  [gpu_enc setBytes:&pass length:sizeof pass atIndex:1];
  [gpu_enc setThreadgroupMemoryLength:TG_HOLD * 8 atIndex:0];
  [gpu_enc dispatchThreadgroups:MTLSizeMake(groups, 1, 1)
    threadsPerThreadgroup:MTLSizeMake(CUBE_T, 1, 1)];
  [gpu_enc memoryBarrierWithScope:MTLBarrierScopeBuffers];
}

static void gpu_pass(u32 f) {
  @autoreleasepool {
    id<MTLCommandBuffer> cb = [gpu_que commandBuffer];
    gpu_enc = [cb computeCommandEncoder];
    gpu_run(f);
    [gpu_enc endEncoding];
    [cb commit];
    [cb waitUntilCompleted];
    if ([cb error]) {
      gpu_fail([cb error]);
    }
  }
}

#elif BEND_CUDA

static void gpu_shape(int units) {
  CUBE_LOG = 31 - CLZ(units < 16 ? 16 : units > 128 ? 128 : units);
}

static bool gpu_probe(void) {
  int       managed = 0;
  CUcontext ctx;
  setenv("CUDA_DEVICE_MAX_CONNECTIONS", "1", 0);
  if (cuInit(0) == CUDA_SUCCESS && cuDeviceGet(&gpu_dev, 0) == CUDA_SUCCESS) {
    cuDeviceGetAttribute(&managed,
      CU_DEVICE_ATTRIBUTE_CONCURRENT_MANAGED_ACCESS, gpu_dev);
  }
  int l2 = 1 << 23;
  cuDeviceGetAttribute(&l2, CU_DEVICE_ATTRIBUTE_L2_CACHE_SIZE, gpu_dev);
  gpu_shape(l2 >> 16);
  return managed != 0
    && cuDevicePrimaryCtxRetain(&ctx, gpu_dev) == CUDA_SUCCESS
    && cuCtxSetCurrent(ctx) == CUDA_SUCCESS;
}

static u64* gpu_map(u64 bytes) {
  CUdeviceptr p = 0;
  if (cuMemAllocManaged(&p, bytes, CU_MEM_ATTACH_GLOBAL) != CUDA_SUCCESS) {
    err_fail("corpus reservation failed");
  }
#if CUDA_VERSION >= 13000
  cuMemAdvise(p, bytes, CU_MEM_ADVISE_SET_PREFERRED_LOCATION,
    (CUmemLocation){ CU_MEM_LOCATION_TYPE_DEVICE, gpu_dev });
#else
  cuMemAdvise(p, bytes, CU_MEM_ADVISE_SET_PREFERRED_LOCATION, gpu_dev);
#endif
  return (u64*)(uintptr_t)p;
}

static bool gpu_make(const char* path) {
  int cc[2] = {0, 0};
  cuDeviceGetAttribute(cc,
    CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR, gpu_dev);
  cuDeviceGetAttribute(cc + 1,
    CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR, gpu_dev);
  char arch[40];
  char bag[24];
  snprintf(arch, sizeof arch, "--gpu-architecture=sm_%d%d", cc[0], cc[1]);
  snprintf(bag, sizeof bag, "-DCUBE_LOG=%u", CUBE_LOG);
  const char* opts[] = { arch, bag, "--fmad=false", "-default-device" };
  nvrtcProgram prog;
  if (nvrtcCreateProgram(&prog, BEND_SRC, "bend.cu", 0, NULL, NULL)
    != NVRTC_SUCCESS) {
    err_fail("cannot compile the CUDA library");
  }
  if (nvrtcCompileProgram(prog, 4, opts) != NVRTC_SUCCESS) {
    size_t n = 0;
    nvrtcGetProgramLogSize(prog, &n);
    char* log = calloc(n + 1, 1);
    if (log != NULL && nvrtcGetProgramLog(prog, log) == NVRTC_SUCCESS) {
      fprintf(stderr, "%s\n", log);
    }
    err_fail("cannot compile the CUDA library");
  }
  size_t len = 0;
  nvrtcGetCUBINSize(prog, &len);
  char* bin = malloc(len);
  if (bin == NULL || nvrtcGetCUBIN(prog, bin) != NVRTC_SUCCESS) {
    err_fail("cannot load the CUDA library");
  }
  nvrtcDestroyProgram(&prog);
  u64   key = gpu_hash();
  FILE* out = path == NULL ? NULL : fopen(path, "wb");
  bool  ok  = out != NULL && fwrite(&key, 8, 1, out) == 1
    && fwrite(bin, 1, len, out) == len && fclose(out) == 0;
  if (cuModuleLoadData(&gpu_lib, bin) != CUDA_SUCCESS) {
    err_fail("cannot load the CUDA library");
  }
  free(bin);
  return path == NULL || ok;
}

static u64 gpu_span(void) {
  size_t span = 0;
  cuDeviceTotalMem(&span, gpu_dev);
  return span;
}

static void gpu_load(u64 bytes) {
  const char* path = gpu_path();
  int         fd   = open(path, O_RDONLY);
  struct stat st   = { 0 };
  u64         key  = 0;
  char*       bin  = fd < 0 || fstat(fd, &st) != 0 || st.st_size <= 8 ? NULL
    : mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
  if (bin != NULL && bin != MAP_FAILED) {
    memcpy(&key, bin, 8);
  }
  if (key != gpu_hash()
    || cuModuleLoadData(&gpu_lib, bin + 8) != CUDA_SUCCESS) {
    gpu_note(path);
    gpu_make(path);
  }
  if (cuModuleGetFunction(&gpu_pso, gpu_lib, "bend_dev") != CUDA_SUCCESS) {
    err_fail("cannot load the GPU program");
  }
}

static void gpu_kernel(u32 pass, u32 groups) {
  void* args[] = { &CORPUS, &pass };
  if (cuLaunchKernel(gpu_pso, groups, 1, 1, CUBE_T, 1, 1, TG_HOLD * 8, NULL,
    args, NULL) != CUDA_SUCCESS) {
    err_fail("device launch failed");
  }
}

static void gpu_pass(u32 f) {
  gpu_run(f);
  if (cuCtxSynchronize() != CUDA_SUCCESS) {
    err_fail("device fault");
  }
}

#else

#define gpu_probe() false
#define gpu_make(p) true
#define gpu_span()  0
#define gpu_load(b)
#define gpu_pass(f)

#endif

// Cube
// ====

// Under a unit (CUBE_T / LINE a row) per thread, the host's column grows
// to the rows that give one, no more: each touches a page of every plane.

static void cube_run(u64* H, bool gpu) {
  for (;;) {
    u32 f = a32_exch(a32_at(H, H_CURSOR), 0);
    if (root_done(H)) {
      return;
    }
    if (f == 0) {
      err_fail("frontier drained without a result");
    }
    if (gpu) {
      gpu_pass(f);
    } else {
      if (f * (CUBE_T / LINE) < pool_size) {
        row_grow((Env){ H, ALC[0] }, io_stk, 0, CUBE_G,
          (pool_size + CUBE_T / LINE - 1) / (CUBE_T / LINE));
      }
      if (f < CUBE) {
        pool_turn(true);
      }
      pool_turn(false);
    }
    u32 ec = a32_load(a32_at(H, H_ERROR_CODE));
    if (ec != 0) {
      err_post(H, ec);
    }
  }
}

// Corpus
// ======

// The cores map 8 GiB at a high base and double it in place, so one
// base holds every location; the banks move up past the pages. The GPU maps
// its whole span at once, and never grows it.

static u64 corpus_size;

static void* corpus_map(u64 size) {
  u64   hint = 1ull << 45;
  void* p    = pool_try((void*)hint, size);
  while (p != (void*)hint && hint > size) {
    if (p != MAP_FAILED) {
      munmap(p, size);
    }
    hint /= 2;
    p     = pool_try((void*)hint, size);
  }
  if (p == MAP_FAILED) {
    err_fail("reservation failed");
  }
  return p;
}

static void corpus_lay(u64* H, u64 size) {
  u64 span = size / 8;
  u64 cap  = span > HEAP_OFF ? (span - HEAP_OFF) / (PAGE_LEN + 10) : 0;
  if (cap <= CUBE) {
    err_fail("the GPU span is under the rings, stacks and a page per lane");
  }
  cap = cap < ~0u ? cap : ~0u - 1;
  u64 at = HEAP_OFF + (cap << PAGE_BITS);
  for (u32 c = 0; c < NCLS_ALL; c += 1) {
    Bank* b = bank_at(H, c);
    memcpy(H + at, H + b->off, b->wr * sizeof(u64));
    b->off  = at;
    at     += 2 * (cap >> ((c < NCLS ? NCLS : c) - PAGE_BITS));
  }
  corpus_size = size;
  a32_store_rel(a32_at(H, H_CAP), (u32)cap);
}

static bool corpus_grow(u64* H, u64 need) {
  bool ok = true;
  LOCK(bank_lock);
  while (ok && need > a32_load(a32_at(H, H_CAP))) {
    u64   more = corpus_size;
    char* at   = (char*)H + more;
    void* got  = io_gpu || more >= 1ull << 43 ? MAP_FAILED
      : pool_try(at, more);
    ok = got == at;
    if (ok) {
      corpus_lay(H, more * 2);
    } else if (got != MAP_FAILED) {
      munmap(got, more);
    }
  }
  UNLOCK(bank_lock);
  return ok;
}

static u64* corpus_setup(bool gpu, long threads, u64 bytes) {
  io_gpu     = gpu;
  KEEP_WORDS = gpu ? CHUNK : CAP_WORDS;
  u64 dflt   = gpu ? gpu_span() : 1ull << 33;
  u64 size   = (gpu && bytes != 0 ? bytes : dflt) & ~16383ull;
  CORPUS     = gpu ? gpu_map(size) : corpus_map(size);
  u64* H     = CORPUS;
#if BEND_CUDA
  if (gpu) {
    cuMemsetD8((CUdeviceptr)(uintptr_t)H, 0, STAK_OFF * 8);
    cuCtxSynchronize();
  }
#endif
  corpus_lay(H, size);
  memcpy(H + STAT_OFF, STAT_IMG, STAT_LEN * sizeof(u64));
  a32_store(a32_at(H, H_BUMP), 1);
  if (gpu) {
    gpu_load(size);
  }
  pool_size = threads < 1 ? 1 : threads < CUBE_T ? threads : CUBE_T;
  return H;
}

OUTLINE Term corpus_eval(u64* H, Term t) {
  Env  e = { H, ALC[0] };
  Term rv[WL_RESW];
  for (;;) {
    Term r = work_loop(e, io_stk, t, !BANGS && pool_size == 1);
    if (r == 0) {
      if (root_done(H)) {
        break;
      }
      err_fail("solo delivery lost");
    }
    if ((u32)H[task_tail(r) + 1] == 0) {
      t = r;
      if (io_gpu && fid_bangs((u32)term_aux(t))) {
        u64  tl   = task_tail(t);
        Term cont = H[tl];
        u32  idx  = (u32)(H[tl + 1] >> 32) & 0xFFFF;
        H[tl]     = TERM_HOLE;
        a32_store(a32_at(H, H_CURSOR), 1);
        ring_push(H, 0, t);
        cube_run(H, true);
        Term p = task_deliver(H, cont, idx, rv, root_take(H, rv));
        if (root_done(H)) {
          break;
        }
        if (p == 0) {
          err_fail("seam delivery lost");
        }
        t = p;
      }
      continue;
    }
    task_deal(H, r, 0, 0, NULL);
    pool_open();
    cube_run(H, false);
    break;
  }
  root_take(H, rv);
  return rv[0];
}

// Io
// ==

// Base's opaque, linear handles pack host fds or pointers into aux and loc:
// no forging, copying, reuse or host wrapper. A request's cont applied to
// its item is the next request. A parked request keeps its fd, deadline and
// readiness in word, time and evts; the loop then calls pack: a value
// resumes, IO_PARK parks again. The edge is UTF-8, decoded as WHATWG does: a
// broken sequence yields one U+FFFD and its breaking byte is read again as a
// lead. inet_aton reads a leading zero as octal, so io_sys_addr refuses it.
// macOS poll misses FIFO EOF, so io_wait selects, its sets sized to the
// highest fd (_DARWIN_UNLIMITED_SELECT allows fds past FD_SETSIZE).

#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>

#define IO_READ 1
#define IO_TIME 2
#define IO_PARK TERM_HOLE

#define io_hand(v)   term_make(TAG_PAK, (u64)(v) >> 40, (u64)(v) & LOC_MASK)
#define io_hand_v(t) (((u64)term_aux(t) << 40) | term_loc(t))

struct IoWork;
typedef void (*IoCall)(struct IoWork* w);
typedef Term (*IoPack)(Env e, struct IoWork* w);

typedef struct IoWork {
  intptr_t       hand;
  intptr_t       made;
  u32            word;
  u64            size;
  char*          data;
  char*          text;
  u32            code;
  IoCall         call;
  IoPack         pack;
  Term           cont;
  Term           item;
  u64            time;
  short          evts;
  struct IoWork* next;
} IoWork;

typedef Term (*Effect)(Env e, Term* f, IoWork* w);

typedef struct {
  Effect run;
  u32    ask;
} IoEff;

static IoEff io_eff_rows[1 << 16];
static u32   io_live;

static u64 io_tick(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (u64)ts.tv_sec * 1000000000ull + (u64)ts.tv_nsec;
}

OUTLINE void* io_mem(void* mem) {
  if (mem == NULL) {
    err_fail("host allocation failed");
  }
  return mem;
}

static int io_sys_addr(const char* host, u32 port, struct sockaddr_in* at) {
  memset(at, 0, sizeof(*at));
  at->sin_family = AF_INET;
  at->sin_port   = htons((uint16_t)port);
  for (const char* p = host; *p != 0; p += 1) {
    if ((p == host || p[-1] == '.') && *p == '0'
      && p[1] >= '0' && p[1] <= '9') {
      return -1;
    }
  }
  return port > 65535 || inet_pton(AF_INET, host, &at->sin_addr) != 1
    ? -1 : 0;
}

static int    io_argc;
static char** io_argv;

static void io_eff(u32 cid, Effect run, u32 need) {
  if (io_eff_rows[cid].run != NULL) {
    err_fail("two effects register one request");
  }
  io_eff_rows[cid] = (IoEff){ run, need };
}

static u64 io_sys_end(IoWork* w, ssize_t n) {
  w->code = n < 0 ? (u32)errno : 0;
  return n < 0 ? 0 : (u64)n;
}

static IoWork* io_runs;
static IoWork* io_park;
static IoWork* io_jobs;

static void io_push(IoWork** q, IoWork* a) {
  IoWork* l = *q != NULL ? *q : a;
  a->next = l->next;
  l->next = a;
  *q      = a;
}

static IoWork* io_pop(IoWork** q) {
  IoWork* a  = (*q)->next;
  (*q)->next = a->next;
  *q         = a != *q ? *q : NULL;
  return a;
}

static void io_spawn(Term m) {
  IoWork* a = io_mem(calloc(1, sizeof(IoWork)));
  a->cont  = m;
  a->item  = term_clo(FID(IO~emit), 0);
  io_push(&io_runs, a);
  io_live += 1;
}

static Term io_wait_on(IoWork* w, int fd, short evts, u64 time, IoPack more) {
  w->word = (u32)fd;
  w->pack = more;
  w->time = time;
  w->evts = evts;
  io_push(&io_park, w);
  return IO_PARK;
}

OUTLINE void io_out(FILE* h, const char* data, u64 len) {
  if (fwrite(data, 1, len, h) != len) {
    err_fail("a short write on a standard stream");
  }
}

OUTLINE void io_sync(void) {
  if (fflush(stdout) != 0) {
    err_fail("a short write on a standard stream");
  }
}

// A String is a chain of Unicode scalar values (lit_of), so a code past
// U+10FFFF or a surrogate is the refusal the interpreter and the JS
// lane already make, spelled as char_new spells it. show_chr escapes
// what it is given, so only a printed String brings one here.
static u64 io_utf8(char* buf, u64 c) {
  if (c > 0x10FFFF || (c >= 0xD800 && c <= 0xDFFF)) {
    fflush(stdout);
    fprintf(stderr, "bend: %llu is not a Unicode scalar value\n",
      (unsigned long long)c);
    _exit(1);
  }
  u64 k = c < 0x80 ? 1 : c < 0x800 ? 2 : c < 0x10000 ? 3 : 4;
  for (u64 i = k; i > 1; i -= 1) {
    buf[i - 1] = (char)(0x80 | (c & 0x3F));
    c >>= 6;
  }
  buf[0] = (char)(k == 1 ? c : (0xF00 >> k) | c);
  return k;
}

OUTLINE char* io_cstr(Env e, Term s, u64* len) {
  u64   cap = 64;
  u64   n   = 0;
  char* buf = io_mem(malloc(cap));
  while (term_aux(s) == CID(SCon)) {
    Term fb[2];
    spare_free(e, cls_fit(2), ctr_take(e, s, 2, fb));
    if (n + 5 > cap) {
      cap *= 2;
      buf = io_mem(realloc(buf, cap));
    }
    n += io_utf8(buf + n, fb[0]);
    s = fb[1];
  }
  buf[n] = 0;
  *len = n;
  return buf;
}

OUTLINE void io_errs(Env e, Term s) {
  u64   n    = 0;
  char* text = io_cstr(e, s, &n);
  io_sync();
  io_out(stderr, text, n);
  io_out(stderr, "\n", 1);
  free(text);
}

#define io_nul(s, n) (strlen(s) != (n))

#define io_seal(e, t, cid) (cid_hot(cid) ? rfc_seal(e, t) : (t))

static Term io_node(Env e, u64 cid, Term a, Term b) {
  u64 l = heap_alloc(e, 1);
  e.mem[l]     = io_seal(e, a, cid);
  e.mem[l + 1] = io_seal(e, b, cid);
  return term_ctr(cid, l);
}

static Term io_str(Env e, const char* p, u64 n) {
  Term s    = term_pak(CID(SNil), 0);
  u64  hole = 0;
  u64  c = 0, need = 0, lo = 0x80, hi = 0xBF;
  for (u64 i = 0; i < n || need > 0; i += 1) {
    u64 b = i < n ? (uint8_t)p[i] : 0x100;
    if (need > 0 && (b < lo || b > hi)) {
      need = 0;
      c    = 0xFFFD;
      i   -= 1;
    } else if (need > 0) {
      lo = 0x80;
      hi = 0xBF;
      c  = (c << 6) | (b & 0x3F);
      if (--need > 0) {
        continue;
      }
    } else if (b < 0x80) {
      c = b;
    } else if (b < 0xC2 || b > 0xF4) {
      c = 0xFFFD;
    } else {
      need = b < 0xE0 ? 1 : b < 0xF0 ? 2 : 3;
      lo   = b == 0xE0 ? 0xA0 : b == 0xF0 ? 0x90 : 0x80;
      hi   = b == 0xED ? 0x9F : b == 0xF4 ? 0x8F : 0xBF;
      c    = b & (0x3F >> need);
      continue;
    }
    u64  l = heap_alloc(e, 1);
    Term t = term_ctr(CID(SCon), l);
    e.mem[l] = c;
    if (hole == 0) {
      s = t;
    } else {
      e.mem[hole] = io_seal(e, t, CID(SCon));
    }
    hole = l + 1;
  }
  if (hole != 0) {
    e.mem[hole] = io_seal(e, term_pak(CID(SNil), 0), CID(SCon));
  }
  return s;
}

#define io_tup(e, a, b) io_node(e, CID(Tuple), a, b)
#define io_done(e, v)   io_box(e, CID(Done), v)

static Term io_box(Env e, u64 cid, Term v) {
  u64 l = heap_alloc(e, 0);
  e.mem[l] = io_seal(e, v, cid);
  return term_ctr(cid, l);
}

static Term io_fail(Env e, u32 code, const char* text) {
  const char* s = text != NULL ? text : strerror((int)code);
  Term t = io_tup(e, code, io_str(e, s, strlen(s)));
  return io_box(e, CID(Fail), t);
}

static pthread_mutex_t io_gate = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  io_bell = PTHREAD_COND_INITIALIZER;
static u32             io_busy;
static u32             io_size;
static int             io_wake_fd[2];

static void io_take(Env e) {
  IoWork* acts[64];
  ssize_t n;
  while ((n = read(io_wake_fd[0], acts, sizeof acts)) > 0) {
    for (u32 i = 0; i < (u32)n / sizeof(IoWork*); i += 1) {
      IoWork* a = acts[i];
      a->item   = a->pack(e, a);
      io_push(&io_runs, a);
      io_busy -= 1;
    }
  }
}

static void* io_help(void* arg) {
  for (;;) {
    pthread_mutex_lock(&io_gate);
    while (io_jobs == NULL) {
      pthread_cond_wait(&io_bell, &io_gate);
    }
    IoWork* a = io_pop(&io_jobs);
    pthread_mutex_unlock(&io_gate);
    a->call(a);
    while (write(io_wake_fd[1], &a, sizeof a) != sizeof a) {
    }
  }
}

static Term io_work(IoWork* w, IoCall call, IoPack pack) {
  w->call  = call;
  w->pack  = pack;
  io_busy += 1;
  if (io_busy > io_size && io_size < IO_HELP) {
    pthread_t tid;
    if (pthread_create(&tid, NULL, io_help, NULL)) {
      err_fail("pthread_create");
    }
    pthread_detach(tid);
    io_size += 1;
  }
  pthread_mutex_lock(&io_gate);
  io_push(&io_jobs, w);
  pthread_cond_signal(&io_bell);
  pthread_mutex_unlock(&io_gate);
  return IO_PARK;
}

static Term io_exec(Env e, IoWork* w) {
  Term fs[256];
  u32  c = (u32)term_aux(w->cont);
  u32  n = cid_arity(c);
  spare_free(e, cls_fit(n), ctr_take(e, w->cont, n, fs));
  w->cont = fs[n - 1];
  return io_eff_rows[c].run(e, fs, w);
}

static bool io_bit(u8* set, int fd, bool put) {
  u8* at = set + fd / 8;
  *at |= put << fd % 8;
  return *at >> fd % 8 & 1;
}

static void io_wait(Env e) {
  int top  = io_wake_fd[0];
  u64 soon = 0;
  for (IoWork* a = io_park; a != NULL;
    a = a->next != io_park ? a->next : NULL) {
    if (a->time != 0 && (soon == 0 || a->time < soon)) {
      soon = a->time;
    }
    if (a->evts != 0 && (int)a->word > top) {
      top = (int)a->word;
    }
  }
  u64 len = (u64)top / 64 * 8 + 8;
  u8* set[2] = { io_mem(calloc(2, len)), NULL };
  set[1] = set[0] + len;
  io_bit(set[0], io_wake_fd[0], true);
  for (IoWork* a = io_park; a != NULL;
    a = a->next != io_park ? a->next : NULL) {
    if (a->evts != 0) {
      io_bit(set[a->evts == POLLOUT], (int)a->word, true);
    }
  }
  u64 tick = io_tick();
  u64 ms = soon > tick ? (soon - tick) / 1000000 + 1 : 0;
  struct timeval tv = { ms / 1000, ms % 1000 * 1000 };
  io_sync();
  if (select(top + 1, (fd_set*)set[0], (fd_set*)set[1], NULL,
    soon == 0 ? NULL : &tv) < 0) {
    if (errno != EINTR) {
      err_fail("the poller failed");
    }
    memset(set[0], 0, 2 * len);
  }
  if (io_bit(set[0], io_wake_fd[0], false)) {
    io_take(e);
  }
  u64     now  = io_tick();
  IoWork* todo = io_park;
  io_park = NULL;
  while (todo != NULL) {
    IoWork* a   = io_pop(&todo);
    bool    due = (a->evts != 0
        && io_bit(set[a->evts == POLLOUT], (int)a->word, false))
      || (a->time != 0 && a->time <= now);
    if (!due) {
      io_push(&io_park, a);
      continue;
    }
    Term x = a->pack(e, a);
    if (x != IO_PARK) {
      a->item = x;
      io_push(&io_runs, a);
    }
  }
  free(set[0]);
}

${NATIVE.IO}

// Show
// ====

// show_val prints a pure main's value as term_show spells it: d
// is a SHOW_DESC node (see show_main), w its words, and chain the
// bracket of the [a, b] or (a, b) the value continues, or 0. Con
// or Nil spell a list, Tuple a tuple, and their tails continue
// it. show_chr escapes as char_show does; show_f32 prints the
// shortest text that reads back, with a point before an e.

#if MAIN_PURE

static void show_val(Env e, u32 d, const Term* w, char chain);

static void show_chr(u64 c, char q) {
  char b[4];
  int  k = c == 10 ? 'n' : c == 9 ? 't' : c == 13 ? 'r' : c == 0 ? '0'
    : c == 92 || c == (u64)q ? (int)c : 0;
  if (k != 0) {
    printf("\\%c", k);
  } else if (c < 32 || c == 127 || (c >= 0xD800 && c <= 0xDFFF)
    || c > 0x10FFFF) {
    printf("\\u{%llx}", (unsigned long long)c);
  } else {
    fwrite(b, 1, io_utf8(b, c), stdout);
  }
}

static void show_f32(u32 x) {
  char  buf[40];
  int   n  = f32_text(buf, f32_unbox(x));
  char* ep = memchr(buf, 'e', n);
  int   m  = ep == NULL ? n : (int)(ep - buf);
  buf[n] = 0;
  if (strpbrk(buf, ".ni") == NULL) {
    printf("%.*s.0%s", m, buf, buf + m);
  } else {
    fputs(buf, stdout);
  }
}

static void show_val(Env e, u32 d, const Term* w, char chain) {
  const u32* D = SHOW_DESC;
  Term one;
  char zs[4];
  u32  zn = 0;
  for (bool tail = true; tail;) switch (tail = false, D[d]) {
    case 0:
      printf("%u", (u32)w[0]);
      break;
    case 1:
      show_f32((u32)w[0]);
      break;
    case 2:
      printf("%llun", (unsigned long long)w[0]);
      break;
    case 3:
      putchar('\'');
      show_chr(D[d + 1] != 0 ? term_loc(w[0]) : w[0], '\'');
      putchar('\'');
      break;
    case 4:
      putchar('"');
      for (Term s = w[0]; term_aux(s) == CID(SCon);) {
        u64 l = term_peek(e, s);
        show_chr(e.mem[l], '"');
        s = e.mem[l + 1];
      }
      putchar('"');
      break;
    case 5:
      fputs("{==}", stdout);
      break;
    case 6:
      putchar('[');
      for (u32 i = 0, g = D[d + 2]; i < 1u << (blk_cls(w[0]) - g); i += 1) {
        Term v[1u << g];
        for (u32 j = 0; j < 1u << g; j += 1) {
          v[j] = blk_read(e.mem, term_tag(w[0]) == TAG_ARR,
            term_peek(e, w[0]), (i << g) + j);
        }
        fputs(i > 0 ? ", " : "", stdout);
        show_val(e, D[d + 1], v, 0);
      }
      putchar(']');
      break;
    default: {
      Term t   = w[0];
      bool box = D[d + 1] != 0;
      u32  key = box ? (u32)term_aux(t) : D[d + 2] > 1 ? (u32)t : 0;
      u32  a   = d + 3;
      for (u32 i = 0; box ? D[a + 1] != key : i != key; i += 1) {
        a += 4 + 2 * D[a + 2];
      }
      if (box) {
        one = term_loc(t);
        w   = term_tag(t) == TAG_PAK ? &one : e.mem + term_peek(e, t);
      }
      char o = "{[("[D[a + 3]];
      if (o == '{') {
        printf("%s{", SHOW_NAMES[D[a]]);
      } else if (chain != o) {
        putchar(o);
      }
      if (o == '{' || chain != o) {
        zs[zn++] = "}])"[D[a + 3]];
      }
      for (u32 j = 0; j < D[a + 2]; j += 1) {
        if (o == '[' ? j == 0 && chain == o : j > 0) {
          fputs(", ", stdout);
        }
        if (j == 1 && o != '{') {
          tail  = true;
          chain = o;
          d     = D[a + 5 + 2 * j];
          w     = w + D[a + 4 + 2 * j];
        } else {
          show_val(e, D[a + 5 + 2 * j], w + D[a + 4 + 2 * j], 0);
        }
      }
    }
  }
  while (zn > 0) {
    putchar(zs[--zn]);
  }
}

#endif

// Run
// ===

static void io_step(Env e, IoWork* a) {
  for (;;) {
    u64  ap  = task_node(e, FID(Clo~apply), TERM_HOLE, 0, 0);
    e.mem[ap]     = a->cont;
    e.mem[ap + 1] = a->item;
    Term req = corpus_eval(e.mem, term_tsk(FID(Clo~apply), ap));
    u32  c   = (u32)term_aux(req);
    u64  at  = term_peek(e, req);
    if (c == CID(Emit)) {
      term_drop(e, req);
      free(a);
      io_live -= 1;
      return;
    }
    if (c == CID(Halt)) {
      io_errs(e, e.mem[at + 1]);
      exit((int)(u32)e.mem[at]);
    }
    if (io_eff_rows[c].run == NULL) {
      err_fail("an alien request");
    }
    u32 need = io_eff_rows[c].ask;
    u32 word = (u32)(need & IO_READ ? io_hand_v(e.mem[at]) : e.mem[at]);
    a->cont  = req;
    if (need != 0) {
      io_wait_on(a, (int)word, need & IO_READ ? POLLIN : 0,
        need & IO_TIME ? io_tick() + (u64)word * 1000000ull : 0, io_exec);
      return;
    }
    Term x = io_exec(e, a);
    if (x == IO_PARK) {
      return;
    }
    a->item = x;
  }
}

OUTLINE void io_loop(u64* H) {
  Env e = { H, ALC[0] };
  io_stk = pool_stack();
  signal(SIGPIPE, SIG_IGN);
  if (pipe(io_wake_fd) | fcntl(io_wake_fd[0], F_SETFL, O_NONBLOCK)) {
    err_fail("the event loop failed to open");
  }
  Term m = corpus_eval(H, term_tsk(MAIN_FID, task_node(e, MAIN_FID,
    TERM_HOLE, 0, 0)));
#if MAIN_PURE
  show_val(e, 0, H + H_ROOT_WORD, 0);
  putchar('\n');
  return;
#endif
  io_spawn(m);
  for (u32 n = 0;; n += 1) {
    if (io_runs == NULL) {
      if (io_live == 0) {
        return;
      }
      if (io_park == NULL && io_busy == 0) {
        io_sync();
        err_fail("deadlock: every computation waits on a channel");
      }
      io_wait(e);
      continue;
    }
    if ((n & 63) == 0 && io_busy != 0) {
      io_take(e);
    }
    io_step(e, io_pop(&io_runs));
  }
}

// Requests
// ========

${reqs}

// Main
// ====

int main(int argc, char** argv) {
  long thr = 0;
  int  gpu = -1;
  u64  mem = 0;
  io_argv = argv + 1;
  for (int i = 1; i < argc; i += 1) {
    const char* a = argv[i];
    const char* v = i + 1 < argc ? argv[i + 1] : NULL;
    if (strcmp(a, "--") == 0) {
      while (i + 1 < argc) {
        io_argv[io_argc++] = argv[++i];
      }
    } else if (strcmp(a, "--bend-help") == 0) {
      printf(CLI_HELP, argv[0]);
      return 0;
    } else if (strcmp(a, "--gpu-build") == 0) {
      if (gpu_probe() && !gpu_make(gpu_path())) {
        fprintf(stderr, "bend: cannot write %s\n", gpu_path());
        return 1;
      }
      return 0;
    } else if (strcmp(a, "--threads") == 0) {
      char* end = NULL;
      thr = v != NULL ? strtol(v, &end, 10) : 0;
      if (thr < 1 || end == NULL || *end != '\0') {
        err_fail("expected a thread count of 1 or more after --threads");
      }
      i += 1;
    } else if (strcmp(a, "--gpu") == 0) {
      char*  end = NULL;
      double n   = v != NULL ? strtod(v, &end) : 0;
      u64    mul = end == NULL ? 0 : strcmp(end, "GB") == 0 ? 1ull << 30
        : strcmp(end, "MB") == 0 ? 1ull << 20 : 0;
      if (v != NULL && strcmp(v, "off") == 0) {
        gpu = 0;
      } else if (v != NULL && (strcmp(v, "on") == 0 || (mul != 0 && n > 0))) {
        gpu = 1;
        mem = (u64)(n * (double)mul);
      } else {
        err_fail("expected on, off or a size like 4GB after --gpu");
      }
      i += 1;
    } else {
      io_argv[io_argc++] = argv[i];
    }
  }
  bool dev = gpu != 0 && BANGS != 0 && gpu_probe();
  if (gpu == 1 && BANGS != 0 && !dev) {
    err_fail("--gpu on, but this binary found no GPU device");
  }
  io_loop(corpus_setup(dev, thr > 0 ? thr : cpu_count(), mem));
  io_sync();
  return 0;
}

#endif
`.slice(1);

// RuntimeJs
// =========

const RUNTIME: string = String.raw`
${NATIVE.JS}
// Array
// =====

function array_new(d, v) {
  if (d > 31) {
    throw "bend: ${ERRS[8]}";
  }
  return Array(2 ** d).fill(v);
}

function array_node(a, b) {
  if (a.length !== b.length) {
    throw "bend: ${ERRS[2]}";
  }
  return a.concat(b);
}

function array_rmw(a, i, f) {
  const at = i % a.length;
  const old = a[at];
  a[at] = f(old);
  return {$: "Tuple", fst: a, snd: old};
}

// Run
// ===

function run_tail(f, x) {
  return {$: "$JMP", f: f.j?.f === f ? f.j : f, x: [x]};
}

function run_clo(j) {
  const f = (x) => run_loop(j(x));
  f.j = j;
  j.f = f;
  return f;
}

function run_loop(r) {
  while (r !== null && typeof r === "object" && r.$ === "$JMP") {
    r = r.f(...r.x);
  }
  return r;
}

function run_lib(f, n) {
  return (...a) => a.length < n ? run_lib((...b) => f(...a, ...b), n - a.length)
    : f(...a);
}

// Effect
// ======

// An effect source registers each effect under its def's key, as in C.
const $0eff = Object.create(null);

function io_eff(k, run, need) {
  if (k in $0eff) {
    throw new Error("bend: two effects register " + k);
  }
  $0eff[k] = { run, need };
}
`.slice(1);

const RUNTIME_MAIN: string = String.raw`
// Cli
// ===

// A JS program runs one thread and no GPU: --threads and --gpu do nothing.
let cli_args = [];

function cli(argv) {
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === "--") {
      cli_args.push(...argv.slice(i + 1));
      break;
    } else if (argv[i] === "--bend-help") {
      io_out(1, io_bytes("usage: " + process.argv[1] + "\n"));
      process.exit(0);
    } else if (argv[i] === "--threads" || argv[i] === "--gpu") {
      i += 1;
    } else {
      cli_args.push(argv[i]);
    }
  }
}

// Show
// ====

// show_val prints a pure main's value as term_show does (see show_main);
// chain is the bracket it continues, or 0. show_chr escapes as char_show.

function show_chr(c, q) {
  const k = { 10: "n", 9: "t", 13: "r", 0: "0", 92: "\\" }[c]
    ?? (c === q.codePointAt(0) ? q : null);
  return k !== null ? "\\" + k : c < 32 || c === 127
    || (c >= 0xD800 && c <= 0xDFFF) || c > 0x10FFFF
    ? "\\u{" + c.toString(16) + "}" : String.fromCodePoint(c);
}

function show_val(D, N, d, v, chain) {
  if (D[d] === 7) {
    const fs = Object.values(typeof v === "boolean"
      ? { $: v ? "True" : "False" } : v);
    let a = d + 3;
    for (; N[D[a]] !== fs[0]; a += 4 + 2 * D[a + 2]) {}
    const o = "{[("[D[a + 3]];
    let s = o === "{" ? fs[0] + "{" : chain === o ? "" : o;
    for (const [j, f] of fs.slice(1).entries()) {
      if (o === "[" ? j === 0 && chain === o : j > 0) {
        s += ", ";
      }
      s += show_val(D, N, D[a + 5 + 2 * j], f, j === 1 && o !== "{" ? o : 0);
    }
    return o === "{" || chain !== o ? s + "}])"[D[a + 3]] : s;
  }
  return D[d] === 0 ? String(v)
    : D[d] === 1 ? f32_show(v).replace(/^-?\d+(?=e|$)/, "$&.0")
    : D[d] === 2 ? v + "n"
    : D[d] === 3 ? "'" + show_chr(v.codePointAt(0), "'") + "'"
    : D[d] === 4 ? "\"" + [...v].map((c) =>
      show_chr(c.codePointAt(0), "\"")).join("") + "\""
    : D[d] === 5 ? "{==}"
    : "[" + v.map((x) => show_val(D, N, D[d + 1], x, 0)).join(", ") + "]";
}

// Io
// ==

// Apple arm64 passes variadic fcntl flags on the stack, so io_sys
// binds fcntl there with the flags as the ninth fixed argument. A
// parked effect waits for fd (a write when out) or until at
// (performance.now()), either one undefined when unused; io_wake
// resumes k with the value of more, and undefined parks it again.

function io_exit(main, show) {
  try {
    if (show !== null) {
      io_out(1, io_bytes(show_val(...show, 0, run_loop(main()), 0) + "\n"));
      process.exit(0);
    }
    process.exit(io_run(main));
  } catch (e) {
    io_errs(String(e));
    process.exit(1);
  }
}

function io_out(fd, data) {
  const fs = require("fs");
  let at = 0;
  while (at < data.length) {
    try {
      at += fs.writeSync(fd, data, at, data.length - at);
    } catch (e) {
      if (e.code === "EAGAIN" || e.code === "EINTR") {
        continue;
      }
      try {
        fs.writeSync(2, "bend: a short write on a standard stream\n");
      } catch (o) {
      }
      process.exit(1);
    }
  }
}

function io_errs(message) {
  io_out(2, io_bytes(message + "\n"));
}

function io_sys() {
  if (globalThis.BEND_SYS === undefined) {
    const ffi = require("bun:ffi");
    const mac = process.platform === "darwin";
    const err = mac ? "__error" : "__errno_location";
    const sel = mac ? "select$DARWIN_EXTSN" : "select";
    const T = { i: "i32", u: "u32", U: "u64", I: "i64", p: "ptr",
      c: "cstring" };
    const vari = mac && process.arch === "arm64";
    const lib = ffi.dlopen(mac ? "libSystem.dylib" : "libc.so.6",
      Object.fromEntries(("socket:iii>i bind:ipu>i listen:ii>i connect:ipu>i"
        + " accept:ipp>i send:ipUi>I recv:ipUi>I read:ipU>I pread:ipUI>I"
        + " sendto:ipUipu>I recvfrom:ipUipp>I close:i>i setsockopt:iiipu>i"
        + " " + sel + ":ipppp>i"
        + (vari ? " fcntl:iiiiiiiii>i" : " fcntl:iii>i") + " getsockopt:iiipp>i"
        + " strerror:i>c " + err + ":>p").split(" ").map((s) => {
        const [name, args, ret] = s.split(/[:>]/);
        return [name, { args: [...args].map((a) => T[a]), returns: T[ret] }];
      }))).symbols;
    const fcntl = (fd, cmd, arg) => vari
      ? lib.fcntl(fd, cmd, 0, 0, 0, 0, 0, 0, arg)
      : lib.fcntl(fd, cmd, arg);
    globalThis.BEND_SYS = { ...lib, fcntl, select: lib[sel],
      ptr: ffi.ptr, mac,
      errno: () => ffi.read.i32(lib[err](), 0) };
  }
  return globalThis.BEND_SYS;
}

function io_fail(code) {
  return { $: "Fail",
    error: io_tup(code >>> 0, String(io_sys().strerror(code))) };
}

function io_done(value) {
  return { $: "Done", value };
}

function io_tup(...xs) {
  return xs.reduceRight((snd, fst) => ({ $: "Tuple", fst, snd }));
}

function io_bytes(text) {
  return new TextEncoder().encode(text);
}

function io_text(b, n) {
  return new TextDecoder("utf-8", { ignoreBOM: true }).decode(b.subarray(0, n));
}

function io_addr(host, port) {
  const part = host.split(".");
  const deci = (p) => /^(0|[1-9]\d{0,2})$/.test(p) && Number(p) < 256;
  if (port > 65535 || part.length !== 4 || !part.every(deci)) {
    return null;
  }
  const b = new Uint8Array(16);
  const head = io_sys().mac ? [16, 2] : [2, 0];
  b.set([...head, port >> 8, port & 255, ...part.map(Number)]);
  return b;
}

function io_push(fun, arg, fresh) {
  const io = globalThis.BEND_IO;
  io.runs.push({ fun, arg });
  io.live += fresh ? 1 : 0;
}

function io_wait(io) {
  const soon = io.waits.reduce((m, w) => Math.min(m, w.at ?? m), Infinity);
  const ms = soon === Infinity ? -1
    : Math.max(0, Math.ceil(soon - performance.now()));
  const fds = io.waits.filter((w) => w.fd !== undefined);
  const top = fds.reduce((m, w) => Math.max(m, w.fd), 0);
  const len = (top >> 6 << 3) + 8;
  const set = new Uint8Array(2 * len);
  const at = (w) => (w.out ? len : 0) + (w.fd >> 3);
  for (const w of fds) {
    set[at(w)] |= 1 << (w.fd & 7);
  }
  const tv = new BigInt64Array([BigInt(ms / 1000 | 0),
    BigInt(ms % 1000 * 1000)]);
  const sys = io_sys();
  if (sys.select(top + 1, sys.ptr(set), sys.ptr(set, len), null,
    ms < 0 ? null : sys.ptr(tv)) < 0) {
    if (sys.errno() !== 4) {
      throw "bend: the poller failed";
    }
    set.fill(0);
  }
  const now = performance.now();
  io.waits = io.waits.filter((w) => {
    const ready = w.at <= now || w.fd !== undefined
      && set[at(w)] & 1 << (w.fd & 7);
    if (ready) {
      io_push(io_wake, w, false);
    }
    return !ready;
  });
}

function io_wake(w) {
  const x = w.more();
  return x === undefined ? undefined : w.k(x);
}

function io_park_on(fd, out, k, more, at) {
  globalThis.BEND_IO.waits.push({ fd, out, k, more, at });
}

function io_run(m) {
  const io = { runs: [], live: 0, waits: [] };
  globalThis.BEND_IO = io;
  try {
    io_push(run_loop(m()), (x) => ({ $: "Emit", value: x }), true);
    for (;;) {
      if (io.runs.length === 0) {
        if (io.live === 0) {
          return 0;
        }
        if (io.waits.length === 0) {
          io_errs("bend: deadlock: every computation waits on a channel");
          return 1;
        }
        io_wait(io);
        continue;
      }
      const s = io.runs.shift();
      let op = s.fun(s.arg);
      while (op !== undefined) {
        if (op.$ === "Emit") {
          io.live -= 1;
          break;
        }
        if (op.$ === "Halt") {
          io_errs(op.message);
          return op.code;
        }
        const need = op.need?.() ?? {};
        if (need.time || need.read) {
          const more = () => op.run(...op.args, op.kont);
          io_park_on(need.read ? op.args[0] : undefined, false, op.kont, more,
            need.read ? undefined : performance.now() + Number(op.args[0]));
          break;
        }
        const x = op.run(...op.args, op.kont);
        if (x === undefined) {
          break;
        }
        op = op.kont(x);
      }
    }
  } catch (req) {
    if (req instanceof RangeError) {
      throw "bend: ${ERRS[7]}";
    }
    if (req?.$ !== "$FFI") {
      throw req;
    }
    io_errs("bend: ${ERRS[2]}");
    return 1;
  }
}
`.slice(1);
