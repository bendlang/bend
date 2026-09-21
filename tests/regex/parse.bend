# Regex.compile: a pattern becomes Pike VM code after ISave{0n} (a run
# appends the ISave{1n} and IMatch) with its group count; groups number by
# their open paren, a lazy repeat's split tries the exit first. A bad
# pattern fails with CPython's message less the offending text, and the
# slice's cuts, which CPython accepts, fail too: counted repeats (and any
# `{` outside a set, a literal to CPython when no count follows), group
# extensions, \x, \A, possessive repeats, a repeat of a body that can
# match empty
import Base

def main() -> List<&2, Result<&2, &2, String, Regex>>:
  [Regex.compile(""), Regex.compile("a|b"), Regex.compile("a*?"),
   Regex.compile("(a)(?:b)"), Regex.compile("[^a-c\\d]"), Regex.compile("^\\b.$"),
   Regex.compile("a**"), Regex.compile("*a"), Regex.compile("^*"), Regex.compile("(a"),
   Regex.compile("a)"), Regex.compile("[a"), Regex.compile("[z-a]"), Regex.compile("\\q"),
   Regex.compile("a\\"), Regex.compile("a{2}"), Regex.compile("{"), Regex.compile("(?i)a"),
   Regex.compile("(?P<n>a)"), Regex.compile("\\x41"), Regex.compile("\\A"),
   Regex.compile("a*+"), Regex.compile("(a*)*"), Regex.compile("(?:)+")]

#|[Done{Regex{[ISave{0n}], 0n}}, Done{Regex{[ISave{0n}, ISplit{2n, 4n}, ISet{False{}, [(97, 97)]}, IJmp{5n}, ISet{False{}, [(98, 98)]}], 0n}}, Done{Regex{[ISave{0n}, ISplit{4n, 2n}, ISet{False{}, [(97, 97)]}, IJmp{1n}], 0n}}, Done{Regex{[ISave{0n}, ISave{2n}, ISet{False{}, [(97, 97)]}, ISave{3n}, ISet{False{}, [(98, 98)]}], 1n}}, Done{Regex{[ISave{0n}, ISet{True{}, [(48, 57), (97, 99)]}], 0n}}, Done{Regex{[ISave{0n}, IAsr{0n}, IAsr{2n}, ISet{True{}, [(10, 10)]}, IAsr{1n}], 0n}}, Fail{"multiple repeat"}, Fail{"nothing to repeat"}, Fail{"nothing to repeat"}, Fail{"missing ), unterminated subpattern"}, Fail{"unbalanced parenthesis"}, Fail{"unterminated character set"}, Fail{"bad character range or escape"}, Fail{"bad escape"}, Fail{"bad escape (end of pattern)"}, Fail{"counted repeats are not supported"}, Fail{"counted repeats are not supported"}, Fail{"unsupported group extension"}, Fail{"unsupported group extension"}, Fail{"bad escape"}, Fail{"bad escape"}, Fail{"multiple repeat"}, Fail{"repeat of a pattern that can match empty"}, Fail{"repeat of a pattern that can match empty"}]
