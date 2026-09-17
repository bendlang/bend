# Certify an optimizer for open SK combinator terms.
# A step contracts K x y to x or S x y z to (x z) (y z), anywhere.
# Construct a common reduct for any two finite reduction histories.
import Base

type Term is Data:
  Atom{name: +List<Bool>}
  K{}
  S{}
  Ap{fun: Term, arg: Term}

type Step is Data:
  Drop{x: Term, y: Term}
  Copy{x: Term, y: Term, z: Term}
  Left{step: Step, arg: Term}
  Right{fun: Term, step: Step}

type Parallel is Data:
  PAtom{name: +List<Bool>}
  PK{}
  PS{}
  PApp{fun: Parallel, arg: Parallel}
  PDrop{x: Parallel, y: Parallel}
  PCopy{x: Parallel, y: Parallel, z: Parallel}

type Certificate<-A: Data, -s: A -> Term, -t: A -> Term,
  -a: Term, -b: Term> is Data:
  Cert{proof: A, src: {a == s(proof) : Term}, dst: {b == t(proof) : Term}}

type Walk<-R: @-a: Term -> @-b: Term -> Data, -a: Term, -b: Term> is Data:
  Stop{eq: {a == b : Term}}
  More{mid: Term, step: R(a, mid), rest: Walk<R, mid, b>}

type Join<-R: @-a: Term -> @-b: Term -> Data, -a: Term, -b: Term> is Data:
  Joined{term: Term, left: Walk<R, a, term>, right: Walk<R, b, term>}

def source(step: Step) -> Term:
  match step:
    case Drop{x, y}: Ap{Ap{K{}, x}, y}
    case Copy{x, y, z}: Ap{Ap{Ap{S{}, x}, y}, z}
    case Left{step, arg}: Ap{source(step), arg}
    case Right{fun, step}: Ap{fun, source(step)}

def target(step: Step) -> Term:
  match step:
    case Drop{x, y}: x
    case Copy{x, y, +z}: Ap{Ap{x, z}, Ap{y, z}}
    case Left{step, arg}: Ap{target(step), arg}
    case Right{fun, step}: Ap{fun, target(step)}

def single(-a: Term, -b: Term) -> Data:
  Certificate<Step, source, target, a, b>

law confluence:
  for a: Term
  for b: Term
  for c: Term
  for left: Walk<single, a, b>
  for right: Walk<single, a, c>
  exs d: Term
  Walk<single, b, d> & Walk<single, c, d>

# solution

def psource(proof: Parallel) -> Term:
  match proof:
    case PAtom{name}: Atom{name}
    case PK{}: K{}
    case PS{}: S{}
    case PApp{fun, arg}: Ap{psource(fun), psource(arg)}
    case PDrop{x, y}: Ap{Ap{K{}, psource(x)}, psource(y)}
    case PCopy{x, y, z}: Ap{Ap{Ap{S{}, psource(x)}, psource(y)}, psource(z)}

def ptarget(proof: Parallel) -> Term:
  match proof:
    case PAtom{name}: Atom{name}
    case PK{}: K{}
    case PS{}: S{}
    case PApp{fun, arg}: Ap{ptarget(fun), ptarget(arg)}
    case PDrop{x, y}: ptarget(x)
    case PCopy{x, y, +z}: Ap{Ap{ptarget(x), ptarget(z)}, Ap{ptarget(y), ptarget(z)}}

def edge(-a: Term, -b: Term) -> Data:
  Certificate<Parallel, psource, ptarget, a, b>

def edge_cast(-a: Term, -b: Term, -c: Term, -d: Term,
  proof: edge(a, b), src: {a == c : Term}, dst: {b == d : Term}) -> edge(c, d):
  %src : edge(_, d)
  %dst : edge(a, _)
  proof

def ap_eq(-a: Term, -b: Term, -c: Term, -d: Term,
  left: {a == b : Term}, right: {c == d : Term}) -> {Ap{a, c} == Ap{b, d} : Term}:
  %left : {Ap{a, c} == Ap{_, d} : Term}
  %right : {Ap{a, c} == Ap{a, _} : Term}
  {==}

def cert_elim(-A: Data, -s: A -> Term, -t: A -> Term, -a: Term, -b: Term,
  -R: Type, cert: Certificate<A, s, t, a, b>,
  use: @+p: A -> @+src: {a == s(p) : Term} -> @+dst: {b == t(p) : Term} -> R) -> R:
  match cert:
    case Cert{proof, src, dst}: use(proof, src, dst)

def edge_app(-a: Term, -b: Term, -c: Term, -d: Term,
  left: edge(a, b), right: edge(c, d)) -> edge(Ap{a, c}, Ap{b, d}):
  match left right:
    case Cert{+p, +sp, +tp} Cert{+q, +sq, +tq}:
      Cert{PApp{p, q}, ap_eq(a, psource(p), c, psource(q), sp, sq), ap_eq(b, ptarget(p), d, ptarget(q), tp, tq)}

def edge_drop(-a: Term, -b: Term, -c: Term, -d: Term,
  left: edge(a, b), right: edge(c, d)) -> edge(Ap{Ap{K{}, a}, c}, b):
  match left right:
    case Cert{+p, +sp, +tp} Cert{+q, +sq, +tq}:
      Cert{PDrop{p, q}, ap_eq(Ap{K{}, a}, Ap{K{}, psource(p)}, c, psource(q), ap_eq(K{}, K{}, a, psource(p), {==}, sp), sq), tp}

def edge_copy(-a: Term, -b: Term, -c: Term, -d: Term, -e: Term, -f: Term,
  x: edge(a, b), y: edge(c, d), z: edge(e, f)) -> edge(Ap{Ap{Ap{S{}, a}, c}, e}, Ap{Ap{b, f}, Ap{d, f}}):
  match x y z:
    case Cert{+p, +sp, +tp} Cert{+q, +sq, +tq} Cert{+r, +sr, +tr}:
      Cert{PCopy{p, q, r}, ap_eq(Ap{Ap{S{}, a}, c}, Ap{Ap{S{}, psource(p)}, psource(q)}, e, psource(r), ap_eq(Ap{S{}, a}, Ap{S{}, psource(p)}, c, psource(q), ap_eq(S{}, S{}, a, psource(p), {==}, sp), sq), sr), ap_eq(Ap{b, f}, Ap{ptarget(p), ptarget(r)}, Ap{d, f}, Ap{ptarget(q), ptarget(r)}, ap_eq(b, ptarget(p), f, ptarget(r), tp, tr), ap_eq(d, ptarget(q), f, ptarget(r), tq, tr))}

# Four application stages suffice because K and S consume two and three arguments.
# The third stage appends later arguments without contracting newly exposed redexes.
def stages() -> Type:
  Term & ((Term -> Term) & ((Term -> Term -> Term) & (Term -> Term -> @+z: Term -> Term)))

def stage0(value: stages()) -> Term:
  match value:
    case (a, b): a

def stage1(value: stages()) -> Term -> Term:
  match value:
    case (a, (b, c)): b

def stage2(value: stages()) -> Term -> Term -> Term:
  match value:
    case (a, (b, (c, d))): c

def stage3(value: stages()) -> Term -> Term -> @+z: Term -> Term:
  match value:
    case (a, (b, (c, d))): d

# Compute complete development; identity certificates follow separately.

def develop_view(+term: Term) -> stages():
  match term:
    case Atom{+name}:
      (Atom{name}, (x => Ap{Atom{name}, x}, (x => y => Ap{Ap{Atom{name}, x}, y}, x => y => z => Ap{Ap{Ap{Atom{name}, x}, y}, z})))
    case K{}:
      (K{}, (x => Ap{K{}, x}, (x => y => x, x => y => z => Ap{x, z})))
    case S{}:
      (S{}, (x => Ap{S{}, x}, (x => y => Ap{Ap{S{}, x}, y}, x => y => z => Ap{Ap{x, z}, Ap{y, z}})))
    case Ap{+fun, +arg}:
      +x = stage0(develop_view(arg))
      (stage1(develop_view(fun))(x), (y => stage2(develop_view(fun))(x, y), (y => z => stage3(develop_view(fun))(x, y, z), y => z => w => Ap{stage3(develop_view(fun))(x, y, z), w})))

def develop(term: Term) -> Term:
  stage0(develop_view(term))

def walk_cast(-R: @-a: Term -> @-b: Term -> Data,
  -a: Term, -b: Term, -c: Term, -d: Term, path: Walk<R, a, b>,
  src: {a == c : Term}, dst: {b == d : Term}) -> Walk<R, c, d>:
  %src : Walk<R, _, d>
  %dst : Walk<R, a, _>
  path

def identity(+term: Term) -> edge(term, term):
  match term:
    case Atom{name}: Cert{PAtom{name}, {==}, {==}}
    case K{}: Cert{PK{}, {==}, {==}}
    case S{}: Cert{PS{}, {==}, {==}}
    case Ap{fun, arg}: edge_app(fun, fun, arg, arg, identity(fun), identity(arg))

def embed(+step: Step) -> edge(source(step), target(step)):
  match step:
    case Drop{x, y}: edge_drop(x, x, y, y, identity(x), identity(y))
    case Copy{x, y, z}: edge_copy(x, x, y, y, z, z, identity(x), identity(y), identity(z))
    case Left{step, arg}: edge_app(source(step), target(step), arg, arg, embed(step), identity(arg))
    case Right{fun, step}: edge_app(fun, fun, source(step), target(step), identity(fun), embed(step))

# Lift walks into application contexts and parallel reduction.

def left_context(+arg: Term, -a: Term, -b: Term, path: Walk<single, a, b>) -> Walk<single, Ap{a, arg}, Ap{b, arg}>:
  match path:
    case Stop{+eq}:
      Stop{ap_eq(a, b, arg, arg, eq, {==})}
    case More{+mid, +step, +rest}:
      cert_elim(Step, source, target, a, mid, Walk<single, Ap{a, arg}, Ap{b, arg}>, step, proof => src => dst => More{Ap{mid, arg}, Cert{Left{proof, arg}, ap_eq(a, source(proof), arg, arg, src, {==}), ap_eq(mid, target(proof), arg, arg, dst, {==})}, left_context(arg, mid, b, rest)})

def right_context(+fun: Term, -a: Term, -b: Term, path: Walk<single, a, b>) -> Walk<single, Ap{fun, a}, Ap{fun, b}>:
  match path:
    case Stop{+eq}:
      Stop{ap_eq(fun, fun, a, b, {==}, eq)}
    case More{+mid, +step, +rest}:
      cert_elim(Step, source, target, a, mid, Walk<single, Ap{fun, a}, Ap{fun, b}>, step, proof => src => dst => More{Ap{fun, mid}, Cert{Right{fun, proof}, ap_eq(fun, fun, a, source(proof), {==}, src), ap_eq(fun, fun, mid, target(proof), {==}, dst)}, right_context(fun, mid, b, rest)})

def to_parallel(-a: Term, -b: Term, path: Walk<single, a, b>) -> Walk<edge, a, b>:
  match path:
    case Stop{+eq}:
      Stop{eq}
    case More{+mid, +step, +rest}:
      cert_elim(Step, source, target, a, mid, Walk<edge, a, b>, step, proof => src => dst => More{mid, edge_cast(source(proof), target(proof), a, mid, embed(proof), Equal.sym(Term, a, source(proof), src), Equal.sym(Term, mid, target(proof), dst)), to_parallel(mid, b, rest)})

def append_single(-a: Term, -b: Term, -c: Term, left: Walk<single, a, b>, right: Walk<single, b, c>) -> Walk<single, a, c>:
  match left:
    case Stop{+eq}:
      walk_cast(single, b, c, a, c, right, Equal.sym(Term, a, b, eq), {==})
    case More{+mid, +step, +rest}:
      More{mid, step, append_single(mid, b, c, rest, right)}

def path_app(-a: Term, +b: Term, +c: Term, -d: Term,
  left: Walk<single, a, b>, right: Walk<single, c, d>) -> Walk<single, Ap{a, c}, Ap{b, d}>:
  append_single(Ap{a, c}, Ap{b, c}, Ap{b, d}, left_context(c, a, b, left), right_context(b, c, d, right))

# Strengthen the triangle lemma with zero through three pending applications.
def triangle_type0(-p: Parallel) -> Data:
  edge(ptarget(p), stage0(develop_view(psource(p))))

def triangle_type1(-p: Parallel) -> Type:
  @+a0: Term -> @+b0: Term -> edge(a0, b0) -> edge(Ap{ptarget(p), a0}, stage1(develop_view(psource(p)))(b0))

def triangle_type2(-p: Parallel) -> Type:
  @+a0: Term -> @+b0: Term -> edge(a0, b0) -> @+a1: Term -> @+b1: Term -> edge(a1, b1) -> edge(Ap{Ap{ptarget(p), a0}, a1}, stage2(develop_view(psource(p)))(b0, b1))

def triangle_type3(-p: Parallel) -> Type:
  @+a0: Term -> @+b0: Term -> edge(a0, b0) -> @+a1: Term -> @+b1: Term -> edge(a1, b1) -> @+a2: Term -> @+b2: Term -> edge(a2, b2) -> edge(Ap{Ap{Ap{ptarget(p), a0}, a1}, a2}, stage3(develop_view(psource(p)))(b0, b1, b2))

def triangle_parts_type(-p: Parallel) -> Type:
  triangle_type0(p) & (triangle_type1(p) & (triangle_type2(p) & (triangle_type3(p))))

def triangle_get0(-p: Parallel, value: triangle_parts_type(p)) -> triangle_type0(p):
  match value:
    case (a, b): a

def triangle_get1(-p: Parallel, value: triangle_parts_type(p)) -> triangle_type1(p):
  match value:
    case (a, (b, c)): b

def triangle_get2(-p: Parallel, value: triangle_parts_type(p)) -> triangle_type2(p):
  match value:
    case (a, (b, (c, d))): c

def triangle_get3(-p: Parallel, value: triangle_parts_type(p)) -> triangle_type3(p):
  match value:
    case (a, (b, (c, d))): d

# Extend parallel edges through pending application arguments.
def extensions(-a: Term, -b: Term, +p: edge(a, b)) -> edge(a, b) & ((@+x: Term -> @+y: Term -> edge(x, y) -> edge(Ap{a, x}, Ap{b, y})) & ((@+x: Term -> @+y: Term -> edge(x, y) -> @+u: Term -> @+v: Term -> edge(u, v) -> edge(Ap{Ap{a, x}, u}, Ap{Ap{b, y}, v})) & (@+x: Term -> @+y: Term -> edge(x, y) -> @+u: Term -> @+v: Term -> edge(u, v) -> @+z: Term -> @+w: Term -> edge(z, w) -> edge(Ap{Ap{Ap{a, x}, u}, z}, Ap{Ap{Ap{b, y}, v}, w})))):
  (p, (x => y => q => edge_app(a, b, x, y, p, q), (x => y => q => u => v => r => edge_app(Ap{a, x}, Ap{b, y}, u, v, edge_app(a, b, x, y, p, q), r), x => y => q => u => v => r => z => w => t => edge_app(Ap{Ap{a, x}, u}, Ap{Ap{b, y}, v}, z, w, edge_app(Ap{a, x}, Ap{b, y}, u, v, edge_app(a, b, x, y, p, q), r), t))))

def triangle_stages(+p: Parallel) -> triangle_parts_type(p):
  match p:
    case PAtom{+name}:
      extensions(Atom{name}, Atom{name}, Cert{PAtom{name}, {==}, {==}})
    case PK{}:
      (Cert{PK{}, {==}, {==}}, (a0 => b0 => e0 => edge_app(ptarget(PK{}), psource(PK{}), a0, b0, Cert{PK{}, {==}, {==}}, e0), (a0 => b0 => e0 => a1 => b1 => e1 => edge_drop(a0, b0, a1, b1, e0, e1), a0 => b0 => e0 => a1 => b1 => e1 => a2 => b2 => e2 => edge_app(Ap{Ap{K{}, a0}, a1}, b0, a2, b2, edge_drop(a0, b0, a1, b1, e0, e1), e2))))
    case PS{}:
      (Cert{PS{}, {==}, {==}}, (a0 => b0 => e0 => edge_app(ptarget(PS{}), psource(PS{}), a0, b0, Cert{PS{}, {==}, {==}}, e0), (a0 => b0 => e0 => a1 => b1 => e1 => edge_app(Ap{ptarget(PS{}), a0}, Ap{psource(PS{}), b0}, a1, b1, edge_app(ptarget(PS{}), psource(PS{}), a0, b0, Cert{PS{}, {==}, {==}}, e0), e1), a0 => b0 => e0 => a1 => b1 => e1 => a2 => b2 => e2 => edge_copy(a0, b0, a1, b1, a2, b2, e0, e1, e2))))
    case PApp{+f, +x}:
      (triangle_get1(f, triangle_stages(f))(ptarget(x), develop(psource(x)), triangle_get0(x, triangle_stages(x))), (a0 => b0 => e0 => triangle_get2(f, triangle_stages(f))(ptarget(x), develop(psource(x)), triangle_get0(x, triangle_stages(x)), a0, b0, e0), (a0 => b0 => e0 => a1 => b1 => e1 => triangle_get3(f, triangle_stages(f))(ptarget(x), develop(psource(x)), triangle_get0(x, triangle_stages(x)), a0, b0, e0, a1, b1, e1), a0 => b0 => e0 => a1 => b1 => e1 => a2 => b2 => e2 => edge_app(Ap{Ap{Ap{ptarget(f), ptarget(x)}, a0}, a1}, stage3(develop_view(psource(f)))(develop(psource(x)), b0, b1), a2, b2, triangle_get3(f, triangle_stages(f))(ptarget(x), develop(psource(x)), triangle_get0(x, triangle_stages(x)), a0, b0, e0, a1, b1, e1), e2))))
    case PDrop{+x, y}:
      +base = triangle_get0(x, triangle_stages(x))
      extensions(ptarget(x), develop(psource(x)), base)
    case PCopy{+x, +y, +z}:
      +base = edge_app(Ap{ptarget(x), ptarget(z)}, Ap{develop(psource(x)), develop(psource(z))}, Ap{ptarget(y), ptarget(z)}, Ap{develop(psource(y)), develop(psource(z))}, edge_app(ptarget(x), develop(psource(x)), ptarget(z), develop(psource(z)), triangle_get0(x, triangle_stages(x)), triangle_get0(z, triangle_stages(z))), edge_app(ptarget(y), develop(psource(y)), ptarget(z), develop(psource(z)), triangle_get0(y, triangle_stages(y)), triangle_get0(z, triangle_stages(z))))
      extensions(ptarget(PCopy{x, y, z}), develop(psource(PCopy{x, y, z})), base)

def triangle(+p: Parallel) -> edge(ptarget(p), develop(psource(p))):
  triangle_get0(p, triangle_stages(p))

def sequential(+p: Parallel) -> Walk<single, psource(p), ptarget(p)>:
  match p:
    case PAtom{+name}:
      Stop{{==}}
    case PK{}:
      Stop{{==}}
    case PS{}:
      Stop{{==}}
    case PApp{+f, +x}:
      path_app(psource(f), ptarget(f), psource(x), ptarget(x), sequential(f), sequential(x))
    case PDrop{+x, y}:
      More{psource(x), Cert{Drop{psource(x), psource(y)}, {==}, {==}}, sequential(x)}
    case PCopy{+x, +y, +z}:
      +sz = sequential(z)
      More{Ap{Ap{psource(x), psource(z)}, Ap{psource(y), psource(z)}}, Cert{Copy{psource(x), psource(y), psource(z)}, {==}, {==}}, path_app(Ap{psource(x), psource(z)}, Ap{ptarget(x), ptarget(z)}, Ap{psource(y), psource(z)}, Ap{ptarget(y), ptarget(z)}, path_app(psource(x), ptarget(x), psource(z), ptarget(z), sequential(x), sz), path_app(psource(y), ptarget(y), psource(z), ptarget(z), sequential(y), sz))}

def edge_triangle(-a: Term, -b: Term, step: edge(a, b)) -> edge(b, develop(a)):
  cert_elim(Parallel, psource, ptarget, a, b, edge(b, develop(a)), step, proof => src => dst => edge_cast(ptarget(proof), develop(psource(proof)), b, develop(a), triangle(proof), Equal.sym(Term, b, ptarget(proof), dst), Equal.cong(Term, Term, x => develop(x), psource(proof), a, Equal.sym(Term, a, psource(proof), src))))

# A private join is consumed directly through its common reduct and two walks.
def joining(-a: Term, -b: Term) -> Type:
  @-R: Type -> (@+term: Term -> Walk<edge, a, term> -> Walk<edge, b, term> -> R) -> R

def join_elim(-a: Term, -b: Term, -R: Type, joined: joining(a, b),
  use: @+d: Term -> Walk<edge, a, d> -> Walk<edge, b, d> -> R) -> R:
  joined(R, use)

# Convert parallel walks and prove the strip lemma.

def from_parallel(-a: Term, -b: Term, path: Walk<edge, a, b>) -> Walk<single, a, b>:
  match path:
    case Stop{+eq}:
      Stop{eq}
    case More{+mid, +step, +rest}:
      cert_elim(Parallel, psource, ptarget, a, mid, Walk<single, a, b>, step, proof => src => dst => append_single(a, mid, b, walk_cast(single, psource(proof), ptarget(proof), a, mid, sequential(proof), Equal.sym(Term, a, psource(proof), src), Equal.sym(Term, mid, ptarget(proof), dst)), from_parallel(mid, b, rest)))

def strip(-a: Term, -b: Term, -c: Term, path: Walk<edge, a, c>, step: edge(a, b)) -> joining(b, c):
  match path:
    case Stop{+eq}:
      cert_elim(Parallel, psource, ptarget, a, b, joining(b, c), step, proof => src => dst => (R => use => use(ptarget(proof), Stop{dst}, More{ptarget(proof), Cert{proof, Equal.trans(Term, c, a, psource(proof), Equal.sym(Term, a, c, eq), src), {==}}, Stop{{==}}})))
    case More{+mid, +first, +rest}:
      cert_elim(Parallel, psource, ptarget, a, b, joining(b, c), step, proof => src => dst => join_elim(develop(psource(proof)), c, joining(b, c), strip(mid, develop(psource(proof)), c, rest, edge_cast(mid, develop(a), mid, develop(psource(proof)), edge_triangle(a, mid, first), {==}, Equal.cong(Term, Term, x => develop(x), a, psource(proof), src))), +d => left => right => (R => use => use(d, More{develop(psource(proof)), edge_cast(ptarget(proof), develop(psource(proof)), b, develop(psource(proof)), triangle(proof), Equal.sym(Term, b, ptarget(proof), dst), {==}), left}, right))))

def append_edge(-a: Term, -b: Term, -c: Term, left: Walk<edge, a, b>, right: Walk<edge, b, c>) -> Walk<edge, a, c>:
  match left:
    case Stop{+eq}:
      walk_cast(edge, b, c, a, c, right, Equal.sym(Term, a, b, eq), {==})
    case More{+mid, +step, +rest}:
      More{mid, step, append_edge(mid, b, c, rest, right)}

def parallel_confluence(-a: Term, -b: Term, -c: Term,
  left: Walk<edge, a, b>, right: Walk<edge, a, c>, +end: Term, +end_eq: {c == end : Term}) -> joining(b, c):
  match left:
    case Stop{eq}:
      (R => use => use(end, walk_cast(edge, a, c, b, end, right, eq, end_eq), Stop{end_eq}))
    case More{+mid, step, rest}:
      join_elim(mid, c, joining(b, c), strip(a, mid, c, right, step), +d => mid_path => c_path => join_elim(b, d, joining(b, c), parallel_confluence(mid, b, d, rest, mid_path, d, {==}), +e => b_path => d_path => (R => use => use(e, b_path, append_edge(c, d, e, c_path, d_path)))))

def confluence(a, b, c, left, right):
  +aa = a
  +bb = b
  +cc = c
  join_elim(bb, cc, (&d: Term -> Walk<single, bb, d> & Walk<single, cc, d>), parallel_confluence(aa, bb, cc, to_parallel(aa, bb, left), to_parallel(aa, cc, right), cc, {==}), +d => p => q => (d, (from_parallel(bb, d, p), from_parallel(cc, d, q))))
