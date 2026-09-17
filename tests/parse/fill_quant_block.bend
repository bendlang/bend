# parse (fill): D<..> fills a datatype's leading Quant parameters as a
# block, so a family with two of them must take two &1 from D<Type>.
# The count came from xs.slice(0, tld.g).length, the smaller of what
# was written and what was leading, so D<Type> filled one and the
# arity check then rejected a spelling the sugar itself produced.
type D<g, h, A:Type> is Type:
  D{}

law main: Type
def main(): D<Type>

#|D<&1, &1, Type>
