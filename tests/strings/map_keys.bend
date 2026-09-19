# Map.bit: the 33-bit key protocol -- position 33*i is "cell i exists",
# 33*i+1..33*i+32 are its U32 bits high first, past the end is False -- and
# the original key comes back beside the Bool. Map set/has/get/pop and key
# order are unchanged over shared long prefixes, "", NUL and supplementary.
import Base

def bits(+key: String, ps: List<&2, Nat>) -> List<&2, Bool>:
  match ps:
    case Nil{}:
      []
    case p <> t:
      Pair.snd(String, Bool, Map.bit(key, p)) <> bits(key, t)

# A partial application of the native is its closure on every lane.
def once(f: Nat -> String & Bool, p: Nat) -> String & Bool:
  f(p)

def long() -> String:
  "the_quick_brown_fox_jumps_over_the_lazy_dog_"

def table() -> Map<&2, Nat>:
  +p = long()
  Map.set(&2, Nat, Map.set(&2, Nat, Map.set(&2, Nat, Map.set(&2, Nat,
    Map.set(&2, Nat, Map.set(&2, Nat, Map.new(&2, Nat), p ++ "x", 1n),
    p ++ "y", 2n), p, 3n), "", 4n), "a\0b", 5n), "😀", 6n)

def Probe() -> Type:
  List<&2, String> & (Nat & (Nat & (Bool & (Bool & (Maybe<&2, Nat> & List<&2, String>)))))

def probe.pop(ks: List<&2, String>, x: Nat, y: Nat, h1: Bool, h2: Bool, r: Map<&2, Nat> & Maybe<&2, Nat>) -> Probe():
  (m, q) = r
  (ks, (x, (y, (h1, (h2, (q, Map.keys(&2, Nat, m)))))))

def probe.has2(ks: List<&2, String>, x: Nat, y: Nat, h1: Bool, r: Map<&2, Nat> & Bool) -> Probe():
  (m, h2) = r
  probe.pop(ks, x, y, h1, h2, Map.pop(&2, Nat, m, "a\0b"))

def probe.has1(ks: List<&2, String>, x: Nat, y: Nat, r: Map<&2, Nat> & Bool) -> Probe():
  (m, h1) = r
  probe.has2(ks, x, y, h1, Map.has(&2, Nat, m, "😀😀"))

def probe.get2(ks: List<&2, String>, x: Nat, r: Map<&2, Nat> & Nat) -> Probe():
  (m, y) = r
  probe.has1(ks, x, y, Map.has(&2, Nat, m, ""))

def probe.get1(ks: List<&2, String>, r: Map<&2, Nat> & Nat) -> Probe():
  (m, x) = r
  probe.get2(ks, x, Map.get(Nat, 0n, m, long() ++ "z"))

def probe(+m: Map<&2, Nat>) -> Probe():
  probe.get1(Map.keys(&2, Nat, m), Map.get(Nat, 0n, m, long() ++ "y"))

def main() -> (List<&2, Bool> & (List<&2, Bool> & (List<&2, Bool> & List<&2, Bool>))) & (List<&1, String & Bool> & (List<&2, String> & (Nat & (Nat & (Bool & (Bool & (Maybe<&2, Nat> & List<&2, String>))))))):
  ((bits("a", [0n, 1n, 25n, 26n, 32n, 33n, 34n]),
    (bits("", [0n, 1n, 33n]),
     (bits("😀", [0n, 15n, 16n, 21n, 22n, 33n]),
      bits("a\0b", [33n, 34n, 65n, 66n, 97n, 98n, 99n])))),
   ([once(Map.bit("ab"), 0n), once(Map.bit("ab"), 33n), once(Map.bit("ab"), 66n)],
    probe(table())))

#|(([True{}, False{}, False{}, True{}, True{}, False{}, False{}], [False{}, False{}, False{}], [True{}, False{}, True{}, False{}, True{}, False{}], [True{}, False{}, False{}, True{}, True{}, False{}, False{}]), [("ab", True{}), ("ab", True{}), ("ab", False{})], ["", "a\0b", "the_quick_brown_fox_jumps_over_the_lazy_dog_", "the_quick_brown_fox_jumps_over_the_lazy_dog_x", "the_quick_brown_fox_jumps_over_the_lazy_dog_y", "😀"], 2n, 0n, True{}, False{}, Some{5n}, ["", "the_quick_brown_fox_jumps_over_the_lazy_dog_", "the_quick_brown_fox_jumps_over_the_lazy_dog_x", "the_quick_brown_fox_jumps_over_the_lazy_dog_y", "😀"])
