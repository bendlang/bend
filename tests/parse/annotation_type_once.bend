# the type after a `:` is read once. A body used to read it first as a
# typed let's type, find no `=` and go back, so each nested annotation
# doubled the work of the ones inside it: 32 levels took 2^32 reads. Now
# a body looks for the `=` before it reads, in braces and in groups
import Base

def main() -> U32:
  a = {x => x :
    {_ => U32 : {_ => U32 : {_ => U32 : {_ => U32 :
    {_ => U32 : {_ => U32 : {_ => U32 : {_ => U32 :
    {_ => U32 : {_ => U32 : {_ => U32 : {_ => U32 :
    {_ => U32 : {_ => U32 : {_ => U32 : {_ => U32 :
    {_ => U32 : {_ => U32 : {_ => U32 : {_ => U32 :
    {_ => U32 : {_ => U32 : {_ => U32 : {_ => U32 :
    {_ => U32 : {_ => U32 : {_ => U32 : {_ => U32 :
    {_ => U32 : {_ => U32 : {_ => U32 : {_ => U32 :
    U32
    -> Type}(0) -> Type}(0) -> Type}(0) -> Type}(0)
    -> Type}(0) -> Type}(0) -> Type}(0) -> Type}(0)
    -> Type}(0) -> Type}(0) -> Type}(0) -> Type}(0)
    -> Type}(0) -> Type}(0) -> Type}(0) -> Type}(0)
    -> Type}(0) -> Type}(0) -> Type}(0) -> Type}(0)
    -> Type}(0) -> Type}(0) -> Type}(0) -> Type}(0)
    -> Type}(0) -> Type}(0) -> Type}(0) -> Type}(0)
    -> Type}(0) -> Type}(0) -> Type}(0) -> Type}(0)
    -> U32}(3)
  U32.add(a, (4 :
    (U32 : (U32 : (U32 : (U32 : (U32 : (U32 : (U32 : (U32 :
    (U32 : (U32 : (U32 : (U32 : (U32 : (U32 : (U32 : (U32 :
    (U32 : (U32 : (U32 : (U32 : (U32 : (U32 : (U32 : (U32 :
    (U32 : (U32 : (U32 : (U32 : (U32 : (U32 : (U32 : (U32 :
    U32))))))))))))))))))))))))))))))))))

#|7
