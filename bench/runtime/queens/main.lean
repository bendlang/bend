-- Single-threaded Lean twin of main.bend. Same
-- algorithm, same shape: 4-row prefix decode + bitmask legality, then
-- the bitmask backtracker over the remaining rows threading per-branch
-- Stats{sols, nodes}; the Bend fork tree's smerge reduction is a plain
-- fold over the prefix index space. All UInt32. Same recursive
-- backtracker as the Bend bench.
-- Checksum = (sols * 2654435761) ^^^ nodes.
-- Expected at boardSize=17, prefixLimit=11730: 2063750025
-- (boardSize=8, prefixLimit=512: 2027808349).
def boardSize : UInt32 := 17
def prefixLimit : UInt32 := 11730
def forkDepth : UInt32 := 17

structure Stats where
  sols : UInt32
  nodes : UInt32
  deriving Inhabited

partial def board_solve (cand cols ld rd full sols nodes : UInt32) : Stats :=
  if cand == 0 then ⟨sols, nodes⟩ else
    let b := cand &&& (0 - cand)
    let nc := cols ||| b
    if nc == full then
      board_solve (cand - b) cols ld rd full (sols + 1) (nodes + 1)
    else
      let nl := (ld ||| b) <<< 1
      let nr := (rd ||| b) >>> 1
      let w := board_solve (full &&& ((nc ||| nl ||| nr) ^^^ 0xFFFFFFFF))
        nc nl nr full sols (nodes + 1)
      board_solve (cand - b) cols ld rd full w.sols w.nodes

-- one 4-row prefix: decode the column quad, filter illegal placements,
-- solve the remaining rows
def prefix_solve (j nn full bound : UInt32) : Stats :=
  let i := (j * 2654435761) &&& 131071 -- fork-order permutation (bijection)
  if !(i < bound) then ⟨0, 0⟩ else
  let nn2 := nn * nn
  let b0 : UInt32 := (1 : UInt32) <<< (i / (nn2 * nn))
  let b1 : UInt32 := (1 : UInt32) <<< ((i / nn2) % nn)
  if (b1 &&& (b0 ||| (b0 <<< 1) ||| (b0 >>> 1))) != 0 then ⟨0, 0⟩ else
  let b2 : UInt32 := (1 : UInt32) <<< ((i / nn) % nn)
  let c2 := b0 ||| b1
  let l2 := ((b0 <<< 1) ||| b1) <<< 1
  let r2 := ((b0 >>> 1) ||| b1) >>> 1
  if (b2 &&& (c2 ||| l2 ||| r2)) != 0 then ⟨0, 0⟩ else
  let b3 : UInt32 := (1 : UInt32) <<< (i % nn)
  let c3 := c2 ||| b2
  let l3 := (l2 ||| b2) <<< 1
  let r3 := (r2 ||| b2) >>> 1
  if (b3 &&& (c3 ||| l3 ||| r3)) != 0 then ⟨0, 0⟩ else
  let c4 := c3 ||| b3
  let l4 := (l3 ||| b3) <<< 1
  let r4 := (r3 ||| b3) >>> 1
  board_solve (full &&& ((c4 ||| l4 ||| r4) ^^^ 0xFFFFFFFF)) c4 l4 r4 full 0 0

def benchmark_run : UInt32 := Id.run do
  let nn := boardSize
  let full := ((1 : UInt32) <<< nn) - 1
  let nn2 := nn * nn
  let nnnn := nn2 * nn2
  let bound := if prefixLimit < nnnn then prefixLimit else nnnn
  let mut sols : UInt32 := 0
  let mut nodes : UInt32 := 0
  for i in [0:((1 : UInt32) <<< forkDepth).toNat] do
    let s := prefix_solve (UInt32.ofNat i) nn full bound
    sols := sols + s.sols
    nodes := nodes + s.nodes
  return (sols * 2654435761) ^^^ nodes

def main : IO Unit := IO.println benchmark_run
