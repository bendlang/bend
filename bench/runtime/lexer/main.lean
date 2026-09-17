-- Lean twin of main.bend: same template generator into a ByteArray,
-- same three-mode tokenizer as a fold over the line's bytes, same
-- checksum, single-threaded. UInt32 wraps like Bend words.
def DEPTH : Nat := 23

def TPL : ByteArray := "i = ( n o i ) o ( n o i ) o ( n o i ) ;".toUTF8

def prng (x : UInt32) : UInt32 :=
  let b := x ^^^ (x <<< 13)
  let d := b ^^^ (b >>> 17)
  d ^^^ (d <<< 5)

def seed (i : UInt32) : UInt32 := prng ((i + 1) * 2654435761)

def salt (s k : UInt32) : UInt32 := prng (s ^^^ (k * 2654435761))

-- n random characters from the stream at t, base + u % modulus each
def draw (n : Nat) (t base modulus : UInt32) (buf : ByteArray) : ByteArray :=
  match n with
  | 0 => buf
  | n + 1 =>
    let u := prng t
    draw n u base modulus (buf.push (base + u % modulus).toUInt8)

-- one line of source from the template
def gen (s : UInt32) : ByteArray := Id.run do
  let mut buf := ByteArray.empty
  for k in [0:TPL.size] do
    let t := salt s k.toUInt32
    let c := TPL.get! k
    if c == 'i'.toNat.toUInt8 then
      buf := draw (1 + (t &&& 7).toNat) t 97 26 buf
    else if c == 'n'.toNat.toUInt8 then
      buf := draw (1 + (t % 6).toNat) t 48 10 buf
    else if c == 'o'.toNat.toUInt8 then
      buf := buf.push ("+-*/".toUTF8.get! (t &&& 3).toNat)
    else
      buf := buf.push c
  return buf

inductive Mode where
  | gap
  | inId (h : UInt32)
  | inNm (v : UInt32)

def mix (acc kind x : UInt32) : UInt32 :=
  (acc * 2654435761) ^^^ (kind * 40503 + x)

def fnv (h c : UInt32) : UInt32 := (h ^^^ c) * 16777619

def isLetter (c : UInt32) : Bool := 97 ≤ c && c ≤ 122

def isDigit (c : UInt32) : Bool := 48 ≤ c && c ≤ 57

-- what a character begins, between tokens
def start (c acc : UInt32) : Mode × UInt32 :=
  if isLetter c then (.inId (fnv 2166136261 c), acc)
  else if isDigit c then (.inNm (c - 48), acc)
  else if c == 32 then (.gap, acc)
  else (.gap, mix acc 3 c)

-- one byte through the machine
def step (st : Mode × UInt32) (b : UInt8) : Mode × UInt32 :=
  let c := b.toUInt32
  match st with
  | (.gap, acc) => start c acc
  | (.inId h, acc) =>
    if isLetter c then (.inId (fnv h c), acc) else start c (mix acc 1 h)
  | (.inNm v, acc) =>
    if isDigit c then (.inNm (v * 10 + (c - 48)), acc)
    else start c (mix acc 2 v)

-- end of line: close the open token
def flush : Mode × UInt32 → UInt32
  | (.gap, acc) => acc
  | (.inId h, acc) => mix acc 1 h
  | (.inNm v, acc) => mix acc 2 v

def lex (buf : ByteArray) : UInt32 := flush (buf.foldl step (.gap, 0))

def line (i : UInt32) : UInt32 := lex (gen (seed i))

def main : IO Unit := do
  let mut sum : UInt32 := 0
  for i in [0:2 ^ DEPTH] do
    sum := sum + line i.toUInt32
  IO.println sum
