# nested ctor patterns with a literal inside: the inner column splits
# under the outer one
# ported from bend3: the numeric field becomes a ctor word, literal arm
# values become ctors (bend has no number patterns)
type W is Data:
  Z{}
  S{p: W}

type Token is Data:
  Num{n: W}
  Stop{}

type Env is Data:
  Env{t: Token, backup: Token}

type R is Data:
  K100{}
  KP{m: W}
  KK{k: W}
  K0{}

law main:
  for a: Env
  R

def main(a):
  match a:
    case Env{Num{Z{}}, backup}:
      K100{}
    case Env{Num{m}, backup}:
      KP{S{m}}
    case Env{Stop{}, Num{k}}:
      KK{k}
    case Env{Stop{}, Stop{}}:
      K0{}

#|\{Env: \{Num: \{Z: (backup => K100{}); (_10 => backup => KP{S{_10}})}; Stop: \{Num: (k => KK{k}); Stop: K0{}}}}
