import Base

type Box is Data:
  Box{+value: U32}

def unbox(b: Box) -> U32:
  match b:
    case Box{x}:
      x

@unsafe
def first(a: Array<Box>) -> Box:
  match a:
    case ALeaf{x}:
      x
    case ANode{l, r}:
      first(l)

def own_copy(pair: Array<Box> & Array<Box>, b: Array<Box>) -> U32:
  (same, copy) = pair
  x = first(same)
  y = first(copy)
  z = first(b)
  (unbox(x) + unbox(y) + unbox(z) : U32)

def own(pair: Array<Box> & Array<Box>) -> U32:
  (a, b) = pair
  own_copy(Array.clone(Box, a), b)

def joined(pair: Array<Box> & Array<Box>) -> U32:
  (a, b) = pair
  unbox(first(Array.join(Box, a, b)))

def node(pair: Array<Box> & Array<Box>) -> U32:
  (a, b) = pair
  unbox(first(ANode{a, b}))

def read_pair(pair: Array<U32> & U32) -> U32:
  (same, x) = pair
  x

def read(a: Array<U32>) -> U32:
  read_pair(Array.get(U32, a, 0))

def after(change: Array<U32>, original: Array<U32>, alias: Array<U32>) -> U32:
  +v = read(change)
  (read(original) * 100 + read(alias) * 10 + v : U32)

def clone_copy(pair: Array<U32> & Array<U32>, b: Array<U32>) -> U32:
  (same, copy) = pair
  after(Array.set(U32, copy, 0, 9), same, b)

def clone_alias(pair: Array<U32> & Array<U32>) -> U32:
  (a, b) = pair
  clone_copy(Array.clone(U32, a), b)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(own(Array.fork(Box, [Box{7} : Box*1n]))))
    Unit <- IO.print(U32.show(own(Array.fork(Box, [Box{7} : Box*4n]))))
    Unit <- IO.print(U32.show(joined(Array.fork(Box, [Box{7} : Box*4n]))))
    Unit <- IO.print(U32.show(node(Array.fork(Box, [Box{7} : Box*2n]))))
    IO.print(U32.show(clone_alias(Array.fork(U32, [1 : U32*1n]))))

#|21
#|21
#|7
#|7
#|119
