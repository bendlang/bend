# a template's specialization key and a compiled main's show descriptor
# key are term_show output, which flattened every Array tree with the
# same leaves to one `[1, 2, 3]` (#834): two shapes shared one
# specialization and one descriptor, so the second got the first's type
# and layout. The key now prints array trees as constructors.
import Base

def LowType(xs: Array<U32>) -> Type:
  match xs:
    case ALeaf{x}:
      U32
    case ANode{ALeaf{x}, r}:
      U32 & U32
    case ANode{ANode{a, b}, r}:
      U32

def Baked(~xs: Array<U32>) -> Type:
  LowType(xs)

type Box<-xs: Array<U32>> is Type:
  Box{value: LowType(xs)}

type Out is Type:
  Out{
    first: Baked(~ANode{ALeaf{1}, ANode{ALeaf{2}, ALeaf{3}}}),
    second: Baked(~ANode{ANode{ALeaf{1}, ALeaf{2}}, ALeaf{3}}),
    wide: Box<ANode{ALeaf{1}, ANode{ALeaf{2}, ALeaf{3}}}>,
    narrow: Box<ANode{ANode{ALeaf{1}, ALeaf{2}}, ALeaf{3}}>
  }

def main() -> Out:
  Out{(8, 9), 7, Box{(8, 9)}, Box{7}}

#|Out{(8, 9), 7, Box{(8, 9)}, Box{7}}
