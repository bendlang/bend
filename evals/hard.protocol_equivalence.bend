# Compare finite nondeterministic protocols that take and return channel credits.
# need(p,k) is the least initial credit ensuring every branch stays nonnegative
# and finishes with at least k credits; sequencing runs its left side first.
# Return universal agreement or a concrete final-credit request separating them.
import Base

type Protocol is Data:
  Skip{}
  Take{}
  Put{}
  Seq{left: Protocol, right: Protocol}
  Choice{left: Protocol, right: Protocol}

type Summary is Data:
  Summary{need: Nat, left: Nat}

type Verdict<-f: Nat -> Nat, -g: Nat -> Nat> is Type:
  Same{proof: @k: Nat -> {f(k) == g(k) : Nat}}
  Different{request: Nat, proof: {f(request) == g(request) : Nat} -> Empty}

def pred(n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n+p: p

def maximum(a: Nat, b: Nat) -> Nat:
  match a b:
    case 0n b: b
    case 1n+a 0n: 1n+a
    case 1n+a 1n+b: 1n+maximum(a,b)

def need(p: Protocol, +k: Nat) -> Nat:
  match p:
    case Skip{}: k
    case Take{}: 1n+k
    case Put{}: pred(k)
    case Seq{p,q}: need(p,need(q,k))
    case Choice{p,q}: maximum(need(p,k),need(q,k))

law compare:
  for +p: Protocol
  for +q: Protocol
  Verdict<(k => need(p,k)), (k => need(q,k))>

# solution

# Normalize each protocol to the credit curve a + max(k-b, 0).
# Carry a pointwise correctness proof through sequencing and choice.
# Compare the resulting curves, preserving a concrete separating request.

def cut(n: Nat, m: Nat) -> Nat:
  match m:
    case 0n: n
    case 1n+m: pred(cut(n,m))

def curve(a: Nat, b: Nat, k: Nat) -> Nat:
  Nat.add(a,cut(k,b))

def denote(s: Summary, k: Nat) -> Nat:
  match s:
    case Summary{a,b}: curve(a,b,k)

def max_zero(+n: Nat) -> {maximum(n,0n) == n : Nat}:
  match n:
    case 0n: {==}
    case 1n+n: {==}

def max_same(+n: Nat) -> {maximum(n,n) == n : Nat}:
  match n:
    case 0n: {==}
    case 1n+n:
      %max_same(n) : {1n+maximum(n,n) == 1n+_ : Nat}
      {==}

def max_swap(+a: Nat, +b: Nat) -> {maximum(a,b) == maximum(b,a) : Nat}:
  match a b:
    case 0n b: Equal.sym(Nat,maximum(b,0n),b,max_zero(b))
    case 1n+a 0n: {==}
    case 1n+a 1n+b:
      %max_swap(a,b) : {1n+maximum(a,b) == 1n+_ : Nat}
      {==}

def cut_zero(+b: Nat) -> {cut(0n,b) == 0n : Nat}:
  match b:
    case 0n: {==}
    case 1n+b:
      %cut_zero(b) : {pred(cut(0n,b)) == pred(_) : Nat}
      {==}

def cut_step(+n: Nat, +b: Nat) -> {cut(1n+n,1n+b) == cut(n,b) : Nat}:
  match b:
    case 0n: {==}
    case 1n+b:
      %cut_step(n,b) : {pred(cut(1n+n,1n+b)) == pred(_) : Nat}
      {==}

def max_shift(+x: Nat, +y: Nat) -> {maximum(x,1n+y) == 1n+maximum(pred(x),y) : Nat}:
  match x:
    case 0n: {==}
    case 1n+x: {==}

def max_cut(+k: Nat, +d: Nat) -> {maximum(cut(k,d),k) == k : Nat}:
  match k:
    case 0n:
      %cut_zero(d) : {maximum(cut(0n,d),0n) == _ : Nat}
      max_zero(cut(0n,d))
    case 1n+k:
      match d:
        case 0n: max_same(1n+k)
        case 1n+d:
          +lhs = maximum(cut(1n+k,1n+d),1n+k)
          %max_cut(k,1n+d) : {lhs == 1n+_ : Nat}
          %max_shift(cut(k,d),k) : {lhs == _ : Nat}
          %cut_step(k,d) : {lhs == maximum(_,1n+k) : Nat}
          {==}

def shift_left(+x: Nat, +y: Nat) -> {maximum(1n+x,y) == 1n+maximum(x,pred(y)) : Nat}:
  match y:
    case 0n:
      %max_zero(x) : {1n+_ == 1n+maximum(x,0n) : Nat}
      {==}
    case 1n+y: {==}

def zero_tag(n: Nat) -> Type:
  match n:
    case 0n: Unit
    case 1n+n: Empty

def clash(+n: Nat, e: {0n == 1n+n : Nat}) -> Empty:
  %e : zero_tag(_)
  Unit{}

def zero_clash(+n: Nat, +m: Nat, z: {n == 0n : Nat}, e: {n == 1n+m : Nat}) -> Empty:
  clash(m, %z : {_ == 1n+m : Nat}
    e)

def cut_one(+d: Nat) -> {cut(1n,1n+d) == 0n : Nat}:
  %cut_zero(d) : {cut(1n,1n+d) == _ : Nat}
  cut_step(0n,d)

def delay(+b: Nat, +d: Nat, v: Verdict<(k => cut(k,b)), (k => cut(k,d))>) -> Verdict<(k => cut(k,1n+b)), (k => cut(k,1n+d))>:
  match v:
    case Same{eq}: Same{k => Equal.cong(Nat,Nat,pred,cut(k,b),cut(k,d),eq(k))}
    case Different{+k,ne}:
      Different{1n+k, e => ne(
        %cut_step(k,b) : {_ == cut(k,d) : Nat}
        %cut_step(k,d) : {cut(1n+k,1n+b) == _ : Nat}
        e)}

def compare_cut(+b: Nat, +d: Nat) -> Verdict<(k => cut(k,b)), (k => cut(k,d))>:
  match b d:
    case 0n 0n: Same{k => {==}}
    case 0n 1n+d:
      Different{1n, e => zero_clash(cut(1n,1n+d),0n,cut_one(d),Equal.sym(Nat,1n,cut(1n,1n+d),e))}
    case 1n+b 0n:
      Different{1n, e => zero_clash(cut(1n,1n+b),0n,cut_one(b),e)}
    case 1n+b 1n+d: delay(b,d,compare_cut(b,d))

def lift(+a: Nat, +c: Nat, +b: Nat, +d: Nat, v: Verdict<(k => curve(a,b,k)), (k => curve(c,d,k))>) -> Verdict<(k => curve(1n+a,b,k)), (k => curve(1n+c,d,k))>:
  match v:
    case Same{eq}:
      Same{+k =>
        %eq(k) : {1n+curve(a,b,k) == 1n+_ : Nat}
        {==}}
    case Different{+k,ne}:
      Different{k, e => ne(
        %e : {curve(a,b,k) == pred(_) : Nat}
        {==})}

def compare_curve(+a: Nat, +c: Nat, +b: Nat, +d: Nat) -> Verdict<(k => curve(a,b,k)), (k => curve(c,d,k))>:
  match a c:
    case 0n 0n: compare_cut(b,d)
    case 0n 1n+c:
      Different{0n, e => zero_clash(cut(0n,b),curve(c,d,0n),cut_zero(b),e)}
    case 1n+a 0n:
      Different{0n, e => zero_clash(cut(0n,d),curve(a,b,0n),cut_zero(d),Equal.sym(Nat,curve(1n+a,b,0n),cut(0n,d),e))}
    case 1n+a 1n+c: lift(a,c,b,d,compare_curve(a,c,b,d))

def compare_summary(+s: Summary, +t: Summary) -> Verdict<(k => denote(s,k)), (k => denote(t,k))>:
  match s t:
    case Summary{a,b} Summary{c,d}: compare_curve(a,c,b,d)

def Cert(-f: Nat -> Nat) -> Type:
  &s: Summary -> @k: Nat -> {denote(s,k) == f(k) : Nat}

def retarget(-f: Nat -> Nat, -g: Nat -> Nat, eq: @k: Nat -> {f(k) == g(k) : Nat}, v: Cert(f)) -> Cert(g):
  match v:
    case (+s,proof):
      (s,k =>
        +k = k
        %eq(k) : {denote(s,k) == _ : Nat}
        proof(k))

def raise_cert(-f: Nat -> Nat, -g: Nat -> Nat, eq: @k: Nat -> {1n+f(k) == g(k) : Nat}, v: Cert(f)) -> Cert(g):
  match v:
    case (s,proof):
      match s:
        case Summary{+a,+b}:
          (Summary{1n+a,b}, (k =>
            +k = k
            %eq(k) : {1n+curve(a,b,k) == _ : Nat}
            %proof(k) : {1n+curve(a,b,k) == 1n+_ : Nat}
            {==}))

def lower_cert(-f: Nat -> Nat, -g: Nat -> Nat, eq: @k: Nat -> {pred(f(k)) == g(k) : Nat}, v: Cert(f)) -> Cert(g):
  match v:
    case (s,proof):
      match s:
        case Summary{0n,+b}:
          (Summary{0n,1n+b},k =>
            +k = k
            %eq(k) : {cut(k,1n+b) == _ : Nat}
            %proof(k) : {cut(k,1n+b) == pred(_) : Nat}
            {==})
        case Summary{1n+a,+b}:
          (Summary{a,b},k =>
            +k = k
            %eq(k) : {curve(a,b,k) == _ : Nat}
            %proof(k) : {curve(a,b,k) == pred(_) : Nat}
            {==})

def apply_cert(+a: Nat, +b: Nat, +s: Summary) -> Cert(k => curve(a,b,denote(s,k))):
  match a:
    case 0n:
      match b:
        case 0n: (s,k => {==})
        case 1n+b:
          lower_cert((k => curve(0n,b,denote(s,k))),(k => curve(0n,1n+b,denote(s,k))),(k => {==}),apply_cert(0n,b,s))
    case 1n+a:
      raise_cert((k => curve(a,b,denote(s,k))),(k => curve(1n+a,b,denote(s,k))),(k => {==}),apply_cert(a,b,s))

def pred_max(+a: Nat, +b: Nat) -> {pred(maximum(a,b)) == maximum(pred(a),pred(b)) : Nat}:
  match a b:
    case 0n 0n: {==}
    case 0n 1n+b: {==}
    case 1n+a 0n: Equal.sym(Nat,maximum(a,0n),a,max_zero(a))
    case 1n+a 1n+b: {==}

def join_zero_left(+d: Nat, +k: Nat) -> {k == maximum(k,cut(k,d)) : Nat}:
  %max_cut(k,d) : {_ == maximum(k,cut(k,d)) : Nat}
  max_swap(cut(k,d),k)

def join_zero_right(+b: Nat, +k: Nat) -> {k == maximum(cut(k,b),k) : Nat}:
  Equal.sym(Nat,maximum(cut(k,b),k),k,max_cut(k,b))
def join_zero_cert(+b: Nat, +d: Nat) -> Cert(k => maximum(cut(k,b),cut(k,d))):
  match b d:
    case 0n d:
      (Summary{0n,0n},k => join_zero_left(d,k))
    case 1n+b 0n:
      (Summary{0n,0n},k => join_zero_right(1n+b,k))
    case 1n+b 1n+d:
      lower_cert((k => maximum(cut(k,b),cut(k,d))),(k => maximum(cut(k,1n+b),cut(k,1n+d))),+k => pred_max(cut(k,b),cut(k,d)),join_zero_cert(b,d))

def join_cert(+a: Nat, +c: Nat, +b: Nat, +d: Nat) -> Cert(k => maximum(curve(a,b,k),curve(c,d,k))):
  match a c:
    case 0n 0n: join_zero_cert(b,d)
    case 0n 1n+c:
      raise_cert((k => maximum(curve(0n,1n+b,k),curve(c,d,k))),(k => maximum(curve(0n,b,k),curve(1n+c,d,k))),
        +k =>
          %max_shift(cut(k,b),curve(c,d,k)) : {_ == maximum(cut(k,b),1n+curve(c,d,k)) : Nat}
          {==},join_cert(0n,c,1n+b,d))
    case 1n+a 0n:
      raise_cert((k => maximum(curve(a,b,k),curve(0n,1n+d,k))),(k => maximum(curve(1n+a,b,k),curve(0n,d,k))),
        +k =>
          %shift_left(curve(a,b,k),cut(k,d)) : {_ == maximum(1n+curve(a,b,k),cut(k,d)) : Nat}
          {==},join_cert(a,0n,b,1n+d))
    case 1n+a 1n+c:
      raise_cert((k => maximum(curve(a,b,k),curve(c,d,k))),(k => maximum(curve(1n+a,b,k),curve(1n+c,d,k))),(k => {==}),join_cert(a,c,b,d))

def compose_cert(+s: Summary, +t: Summary) -> Cert(k => denote(s,denote(t,k))):
  match s:
    case Summary{a,b}: apply_cert(a,b,t)

def union_cert(+s: Summary, +t: Summary) -> Cert(k => maximum(denote(s,k),denote(t,k))):
  match s t:
    case Summary{a,b} Summary{c,d}: join_cert(a,c,b,d)

def seq_merge(+p: Protocol, +q: Protocol, u: Cert(k => need(p,k)), v: Cert(k => need(q,k))) -> Cert(k => need(p,need(q,k))):
  match u:
    case (+s,ep):
      match v:
        case (+t,eq):
          retarget((k => denote(s,denote(t,k))),(k => need(p,need(q,k))),
            +k =>
              +lhs = denote(s,denote(t,k))
              %ep(need(q,k)) : {lhs == _ : Nat}
              %eq(k) : {lhs == denote(s,_) : Nat}
              {==}, compose_cert(s,t))

def choice_merge(+p: Protocol, +q: Protocol, u: Cert(k => need(p,k)), v: Cert(k => need(q,k))) -> Cert(k => maximum(need(p,k),need(q,k))):
  match u:
    case (+s,ep):
      match v:
        case (+t,eq):
          retarget((k => maximum(denote(s,k),denote(t,k))),(k => maximum(need(p,k),need(q,k))),
            +k =>
              +lhs = maximum(denote(s,k),denote(t,k))
              %eq(k) : {lhs == maximum(need(p,k),_) : Nat}
              %ep(k) : {lhs == maximum(_,denote(t,k)) : Nat}
              {==}, union_cert(s,t))

def compile(+p: Protocol) -> Cert(k => need(p,k)):
  match p:
    case Skip{}: (Summary{0n,0n},k => {==})
    case Take{}: (Summary{1n,0n},k => {==})
    case Put{}: (Summary{0n,1n},k => {==})
    case Seq{p,q}:
      seq_merge(p,q,compile(p),compile(q))
    case Choice{p,q}:
      choice_merge(p,q,compile(p),compile(q))

def finish(-f: Nat -> Nat, -g: Nat -> Nat, +s: Summary, +t: Summary, ep: @k: Nat -> {denote(s,k) == f(k) : Nat}, eq: @k: Nat -> {denote(t,k) == g(k) : Nat}, v: Verdict<(k => denote(s,k)),(k => denote(t,k))>) -> Verdict<f,g>:
  match v:
    case Same{same}:
      Same{+k =>
        %ep(k) : {_ == g(k) : Nat}
        %eq(k) : {denote(s,k) == _ : Nat}
        same(k)}
    case Different{+k,ne}:
      Different{k,
        %ep(k) : ({_ == g(k) : Nat} -> Empty)
        %eq(k) : ({denote(s,k) == _ : Nat} -> Empty)
        ne}

def certified_compare(-f: Nat -> Nat, -g: Nat -> Nat, u: Cert(f), v: Cert(g)) -> Verdict<f,g>:
  match u:
    case (+s,ep):
      match v:
        case (+t,eq): finish(f,g,s,t,ep,eq,compare_summary(s,t))

def compare(p,q):
  certified_compare((k => need(p,k)),(k => need(q,k)),compile(p),compile(q))
