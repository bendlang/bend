# String at runtime: length/concat/reverse/eq/contains/trim/upper/split/
# take/drop/join, each law one bit
# ported from bend3: bend-base's String helpers are inlined over bend's
# String (SNil/SCon, Chr codes); find yields Maybe<&2, U32>; split takes the
# separator's char code; take/drop counts become Nat
# (97 <= x is spelled U32.is_le(97, x): tocl lacks u32_is_ge, see
# run_word_compare's yellow); strict -- the continuation defs folded
# into their callers' case trees, shared codes and the find
# needle bind + (U32 and String are Data)
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law slen:
  for s: String
  U32

def slen(s):
  match s:
    case SNil{}:
      0
    case SCon{h, t}:
      U32.add(1, slen(t))

law srev.go:
  for s   : String
  for acc : String
  String

def srev.go(s, acc):
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      srev.go(t, SCon{h, acc})

law srev:
  for s: String
  String

def srev(s):
  srev.go(s, SNil{})

law seq_:
  for a: String
  for b: String
  Bool

def seq_(a, b):
  match a b:
    case SNil{} SNil{}:
      True{}
    case SNil{} SCon{h, t}:
      False{}
    case SCon{h, t} SNil{}:
      False{}
    case SCon{Chr{x}, t1} SCon{Chr{y}, t2}:
      Bool.and(U32.is_eq(x, y), seq_(t1, t2))

law starts:
  for p: String
  for s: String
  Bool

def starts(p, s):
  match p s:
    case SNil{} _:
      True{}
    case SCon{h, t} SNil{}:
      False{}
    case SCon{Chr{x}, t1} SCon{Chr{y}, t2}:
      Bool.and(U32.is_eq(x, y), starts(t1, t2))

law sfind.z:
  for f: Bool
  Maybe<&2, U32>

def sfind.z(f):
  match f:
    case True{}:
      Some{0}
    case False{}:
      None{}

law sfind.step:
  for f: Bool
  for r: Maybe<&2, U32>
  Maybe<&2, U32>

def sfind.step(f, r):
  match f:
    case True{}:
      Some{0}
    case False{}:
      match r:
        case None{}:
          None{}
        case Some{i}:
          Some{U32.add(i, 1)}

law sfind:
  for +p: String
  for  s: String
  Maybe<&2, U32>

def sfind(p, s):
  match s:
    case SNil{}:
      sfind.z(starts(p, SNil{}))
    case SCon{h, +t0}:
      sfind.step(starts(p, SCon{h, t0}), sfind(p, t0))

law triml.go:
  for  s: String
  for +x: U32
  for  f: Bool
  String

def triml.go(s, x, f):
  match s f:
    case SNil{} True{}:
      SNil{}
    case SNil{} False{}:
      SCon{Chr{x}, SNil{}}
    case SCon{Chr{+y0}, t} True{}:
      triml.go(t, y0, U32.is_eq(y0, 32))
    case SCon{Chr{+y0}, t} False{}:
      SCon{Chr{x}, SCon{Chr{y0}, t}}

law triml:
  for s: String
  String

def triml(s):
  match s:
    case SNil{}:
      SNil{}
    case SCon{Chr{+x0}, t}:
      triml.go(t, x0, U32.is_eq(x0, 32))

law strim:
  for s: String
  String

def strim(s):
  srev(triml(srev(triml(s))))

law supper.put:
  for +x: U32
  for  r: String
  for  f: Bool
  String

def supper.put(x, r, f):
  match f:
    case True{}:
      SCon{Chr{U32.sub(x, 32)}, r}
    case False{}:
      SCon{Chr{x}, r}

law supper:
  for s: String
  String

def supper(s):
  match s:
    case SNil{}:
      SNil{}
    case SCon{Chr{+x0}, t}:
      supper.put(x0, supper(t), Bool.and(U32.is_le(97, x0), U32.is_le(x0, 122)))

law ssplit.push:
  for c  : Char
  for ps : List<&2, String>
  List<&2, String>

def ssplit.push(c, ps):
  match ps:
    case Nil{}:
      [SCon{c, SNil{}}]
    case h <> t:
      SCon{c, h} <> t

law ssplit.put:
  for +x: U32
  for  r: List<&2, String>
  for  f: Bool
  List<&2, String>

def ssplit.put(x, r, f):
  match f:
    case True{}:
      SNil{} <> r
    case False{}:
      ssplit.push(Chr{x}, r)

law ssplit:
  for +sep : U32
  for s    : String
  List<&2, String>

def ssplit(sep, s):
  match s:
    case SNil{}:
      [SNil{}]
    case SCon{Chr{+x0}, t}:
      ssplit.put(x0, ssplit(sep, t), U32.is_eq(x0, sep))

law sjoin.go:
  for +sep : String
  for t    : List<&2, String>
  for h    : String
  String

def sjoin.go(sep, t, h):
  match t:
    case Nil{}:
      h
    case h2 <> t2:
      String.append(h, String.append(sep, sjoin.go(sep, t2, h2)))

law sjoin:
  for +sep : String
  for xs   : List<&2, String>
  String

def sjoin(sep, xs):
  match xs:
    case Nil{}:
      SNil{}
    case h <> t:
      sjoin.go(sep, t, h)

law stake:
  for n: Nat
  for s: String
  String

def stake(n, s):
  match n s:
    case 0n _:
      SNil{}
    case 1n+p SNil{}:
      SNil{}
    case 1n+p SCon{h, t}:
      SCon{h, stake(p, t)}

law sdrop:
  for n: Nat
  for s: String
  String

def sdrop(n, s):
  match n s:
    case 0n s2:
      s2
    case 1n+p SNil{}:
      SNil{}
    case 1n+p SCon{h, t}:
      sdrop(p, t)

law llens:
  for xs: List<&2, String>
  U32

def llens(xs):
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, llens(t))

law main.out:
  U32

def main.out():
  b0 = bu(U32.is_eq(slen(String.append("foo", "bar")), 6))
  b1 = bu(seq_(srev("abc"), "cba"))
  b2 = bu(Maybe.is_some(&2, U32, sfind("an", "banana")))
  b3 = U32.sub(1, bu(Maybe.is_some(&2, U32, sfind("xy", "banana"))))
  b4 = bu(U32.is_eq(slen(strim("  hi  ")), 2))
  b5 = bu(seq_(supper("ab"), "AB"))
  b6 = bu(U32.is_eq(llens(ssplit(44, "a,bb,c")), 3))
  b7 = bu(seq_(stake(2n, "abcd"), "ab"))
  b8 = bu(seq_(sdrop(2n, "abcd"), "cd"))
  b9 = bu(seq_(sjoin(",", ["a", "b"]), "a,b"))
  b10 = bu(U32.is_eq(Maybe.default(&2, U32, sfind("an", "banana"), 99), 1))
  U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(b0, b1), b2), b3), b4), b5), b6), b7), b8), b9), b10)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|11
