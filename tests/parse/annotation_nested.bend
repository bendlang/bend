# nested annotations parse in time that grows with the square of their
# depth, not with its power of two. A body first tries the type after a
# `:` as a typed let's type and goes back when no `=` follows; it used to
# try again on every later visit, so each annotation doubled the work of
# the ones inside it: 32 levels took 2^32 reads. Now a failed try is
# remembered, and a type is read once per annotation around it
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
