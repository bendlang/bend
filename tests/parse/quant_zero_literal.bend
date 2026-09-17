# parse (&0): the three quantity literals all read. term_show prints
# None as &0, and a - binder's domain checks at Kind(&0), so an error
# report names that kind; with only &1 and &2 parsing, the checker
# printed a term it could not read back.
law q: Quant
def q(): &0

law main: Quant
def main(): q

#|&0
