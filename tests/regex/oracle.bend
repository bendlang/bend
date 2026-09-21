# the CPython oracle: every row is (pattern, subject, at), run as
# search(s, at) | match(s, at) | fullmatch(s); a match prints its spans,
# group 0 first and - for a group that took no part, a failure none, a
# pattern that fails to compile err. The pins are CPython 3.11's `re`
# under re.ASCII on the same rows (160 rows, seed 7)
import Base

def Row() -> Data:
  Sigma<&2, &2, String, _ => Sigma<&2, &2, String, _ => Nat>>

def span(g: Maybe<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> String:
  match g:
    case Some{(a, b)}:
      Nat.show(a) ++ "-" ++ Nat.show(b)
    case None{}:
      "-"

def spans.go(gs: List<&2, Maybe<&2, Sigma<&2, &2, Nat, _ => Nat>>>) -> String:
  match gs:
    case Nil{}:
      ""
    case g <> t:
      " " ++ span(g) ++ spans.go(t)

def spans(m: Maybe<&2, Regex.Match>) -> String:
  match m:
    case Some{Match{a, b, gs}}:
      span(Some{(a, b)}) ++ spans.go(gs)
    case None{}:
      "none"

def row(r: Result<&2, &2, String, Regex>, +s: String, +at: Nat) -> String:
  match r:
    case Fail{e}:
      "err"
    case Done{+re}:
      spans(Regex.exec(re, s, at)) ++ " | " ++ spans(Regex.match_at(re, s, at))
        ++ " | " ++ spans(Regex.fullmatch(re, s))

def rows(xs: List<&2, Row()>) -> String:
  match xs:
    case Nil{}:
      ""
    case (p, (s, at)) <> t:
      row(Regex.compile(p), s, at) ++ "\n" ++ rows(t)

def main() -> IO(Unit):
  IO.print(rows([
    ("\\[$(?:([-A-C{{]b$)()??2|[_]+?\\W?\\w??)", ("é", 0n)),
    ("\\B(\\S,)?b", ("1bA", 3n)),
    ("|\\W", ("-é", 2n)),
    ("(())|\\b😀+?\\-+?", ("    b\n a", 0n)),
    ("(||)|\\*??_", ("\n", 1n)),
    ("(?:\\S(?:[^-(a-c ]+\\b|c*?|[]\\d ]*?)??)", ("bA\n", 0n)),
    ("|a?c(?:)??|.+?()?é*", ("éé", 0n)),
    ("[\\q]", ("\t", 0n)),
    ("(\\W$)*?", ("-\tbéb\t\ta", 0n)),
    ("(?:||é?\\*)", ("aa,2\t\tcB", 7n)),
    ("c??.", ("aA-ac", 0n)),
    ("(?:(?:A.[--/\\w])\\s())B", ("\t😀\n2aBab", 0n)),
    ("", ("aAaB", 0n)),
    ("[a-\\w]", ("Bba\tAb", 0n)),
    ("$+", ("1\tc1", 0n)),
    ("(\\w?)??\\B", ("1cA2cb _", 0n)),
    ("[\\q]", ("-baa", 5n)),
    ("\\$", ("aB_2é2A", 0n)),
    ("", (" a\nB\t", 0n)),
    ("", ("ab 😀", 0n)),
    ("a)", ("a😀\t", 1n)),
    ("[b((]|", ("aaa", 0n)),
    ("^é\\d+|", ("a\nBaBAcA", 7n)),
    ("a+?([],Ba-c]+?|[^b-b\\w)][+]?$|😀(\\D)+?)(?:[0-9A]._*)", ("", 0n)),
    ("\\w*? +^", ("", 1n)),
    ("\\W\\s", ("B A1", 3n)),
    ("", ("\t\né", 1n)),
    ("(?:())(..(?:[]2A-C\\b]?[??-]+)??|)]|", ("", 0n)),
    ("😀+?}", (" BA", 0n)),
    ("a)", ("B2A\n\tAé", 0n)),
    ("", ("", 0n)),
    ("|(?:( 😀),|(?:éb?[^--/a-c1\\S]|[^]b\\né]|.+_*)(.??|[b-bb-b]?[\\n-\\r\\W\\\\]))+?\\\\", (", B-\nb\n", 0n)),
    ("2", ("\t", 0n)),
    ("(?:\\b(|)([--/\\\\]?B.??|[^-0-9][a-cbb-b][^-\\n-\\r])+?)\\b(([^2é\\S]\\D)^)", ("-11-", 0n)),
    (".* ((\\b\\w[$]??)^(?:[?-]| ??))", ("b _bbAca", 0n)),
    ("", (",é1-1😀", 3n)),
    ("\\wAb*?", ("a", 0n)),
    ("\\S}+(?:a+cb+?|([b-b\\n-\\r?].)*|B\\b)", ("😀bBé _B ", 0n)),
    ("(|2+?(😀[^-a-ca-c])|(?:[^--/_]+?B?_|é\\[[a-c]|[^|}0-9]*?\\\\]))B*😀*", ("a\ta", 0n)),
    (" ", (" é\n", 0n)),
    ("\\b|.", ("ba", 0n)),
    ("aa?", ("céa b", 0n)),
    ("", ("1", 0n)),
    ("[0-90-9]1?", ("a-\tb_\n", 0n)),
    ("([b-b])b", ("A\nb", 0n)),
    ("|[c\\b]$|,^[+é]", ("b2,", 0n)),
    ("2*|(?:bb*)|(([^--/*(]\\**?-+?|,)*?(?:[-\\d*]|é?[-A-CA+]))*?", ("b \t", 0n)),
    (".(^(,|\\|*?)?|-[--/?\\Db-b])??", ("A12\n\n", 0n)),
    ("a", ("b\t_😀a", 0n)),
    ("[_]b+?", ("é", 0n)),
    ("", ("bébB-Ab", 7n)),
    ("A^(?:1*.+?())?|\\w2😀", ("1-2", 0n)),
    ("[\\](]*(?:^)", (" é😀a 1ba", 0n)),
    ("|ab(aB??.)?", ("😀\tab-😀 ", 0n)),
    ("[a", ("\n-", 0n)),
    ("a?", ("c", 0n)),
    ("\\S", ("", 0n)),
    (",*\\.", ("", 0n)),
    ("a|\\wb*?\\D+|[--/|]+?1", ("   ", 0n)),
    ("", ("BB-b😀", 0n)),
    ("[]?\\w?]??", ("a ,c", 0n)),
    ("|😀+[2a-c0-9]??", ("a\n_", 0n)),
    ("[^-\\]-]+", ("😀😀cBB-b", 0n)),
    ("(?:()??\\d+?.)^", (" b,b_AAb", 0n)),
    ("", ("", 1n)),
    ("(*a)", ("ac1😀😀", 0n)),
    ("..", ("a,", 0n)),
    ("", ("b,b a", 0n)),
    ("_(b)", ("baB", 0n)),
    ("\\s\\w?", ("é\n1", 0n)),
    ("A[^0-9]*\\D", ("1b_-a-cB", 0n)),
    ("a+", ("Bbcbc😀1", 0n)),
    ("[\\d-z]", ("a\t_21\n", 0n)),
    ("b|()?(a(?:\\W??[A-C]?[- \\n-\\r+]|))", ("Bbbb bé😀", 0n)),
    ("a*?😀\\?|2+|", ("\tb_A-", 0n)),
    ("(\\d|,?(a*[\\d]||[]B\\]0-9]+?\\B)_)*?|(?:(?:_2[a-c]||bbc*))??[-B\\w\\n-\\r]??|b\\D[\\]|-]*?", ("1bé1b-😀", 0n)),
    ("(a|b", ("A2c-a", 0n)),
    ("-\\S|[]+cA]$,+", ("\tab_2", 0n)),
    ("(-+[A-C\\d}]?)||1()", ("😀Bé\tb😀c-", 0n)),
    ("||", ("b", 2n)),
    ("\\.+[0-90-9{](|([1-])a.??)|()(^[]\\ba-c]([^a-c][^B+_]))(,|\\Bb?)|([1_]|c[b-b]|_+?)?A*?[^]0-9\\n-\\rb-]", ("b aé", 0n)),
    ("-+[0-9]??\\?", ("a- AB", 0n)),
    (",😀??\\w|(?:$)[0-9]??", ("a\t,", 0n)),
    ("$", ("bé-bb", 4n)),
    ("()|", ("1cb1", 0n)),
    ("\\b()??(?:(\\W[-|][]a]|[^}\\s.]*)\\B)??|\\w+^((?:|))", ("", 0n)),
    ("\\.??1c", ("2\t,-éb a", 0n)),
    ("b[--/A-Cb-bB]*\\B", ("BbAbcé", 0n)),
    ("", ("\tB\n", 1n)),
    ("||b+\\d+?\\D*?", ("bc😀\nab_a", 0n)),
    ("a+?*", ("", 0n)),
    ("\\tba?", ("_\t\t", 2n)),
    ("a\\", ("b_é2b", 0n)),
    ("(?:([\\n-\\r$]*\\?*?\\d?)??,a|[b]|.([\\n-\\r].😀|\\[?|b)?2+)2[^?_]", (" , 😀1b😀", 0n)),
    ("2(?:[^--/.*])", ("éabB", 0n)),
    ("(c()??|()?|[b-b\\b1] )22|", ("cb", 0n)),
    ("$2|a*,", ("\t\tBbB", 0n)),
    ("((a)", ("A ", 0n)),
    ("", ("\tcébB_bb", 0n)),
    ("_*?\\s?(?:)??", ("", 0n)),
    ("(_1*?)|\\s??", ("1a2a", 0n)),
    ("(a*?)??b?(\\s)?|[^--/éb2](|)?é+|(?:b)?[--/_-][]a-c]", ("a,é1é", 2n)),
    ("..b+?", ("", 0n)),
    ("a?|", ("é2,é2,", 0n)),
    ("\\B(?:😀a+|B*?)|$(?:$b|(.*?[$])*.+?(b| )|(?:2[b-b2]*)*?[*\\\\.]??)??(?:\\)\\B)?", ("😀", 2n)),
    ("a\\W? |\\B\\t+", ("", 0n)),
    ("$+", ("ac2\naé-", 2n)),
    ("[1 c].+?", ("", 0n)),
    ("c(?:ba?\\B)?[-A-C{]|(|)??", ("aé", 1n)),
    ("$", ("c\t", 0n)),
    ("*a", ("", 0n)),
    ("a??(2+?($[$é\\b])*?|}😀)a", ("1😀éa", 0n)),
    ("(||(?:[\\-0-9]+?^)([^]A][1\\b]*?[^A-Cb-b]|^))(A?)", ("Aab", 0n)),
    ("\\n$(|()?|[]1b-b-]\\w)|a*?", ("", 0n)),
    ("|\\??|\\Bb", ("a,😀b", 3n)),
    ("bA|\\B^.+?|a-?", ("\nab\n", 3n)),
    ("[]b-b]|(bb[\\D]*?|\\W+(?:^\\t_+)+?)*\\]", ("1_1 ", 0n)),
    ("[-a-c](?:([^\\n-\\r(]A\\B)(?:Ba*a|1*)[0-9$]|[]}]\\+*?-*|[^,A]_(?:)??)*(?:)|.[-B]*", ("c2", 0n)),
    ("a**", ("😀- ", 0n)),
    ("(?:)??", ("b Ba", 0n)),
    ("(|(?:||[B\\]][^A\\Wé])a|(?:.b|[)]+[-}\\S][a\\D2]*|)?)($\\b|[].]([]\\wé]+)|[A-C(\\n])", (" aaa,ac😀", 0n)),
    ("\\S?(?:\\t*?\\W+?a)??.+?", ("\n\nb", 0n)),
    ("a", ("aAb", 0n)),
    ("a+?*", ("AAaé😀-", 0n)),
    ("\\n😀\\D?", ("a", 0n)),
    ("||\\S\\\\", ("cbc-baé", 0n)),
    ("b", ("111b", 0n)),
    ("", ("a", 0n)),
    ("c+?\\.+?b*?|", ("1,", 0n)),
    ("(?:|\\S*?)??[\\n-\\r]", ("aA2aé", 0n)),
    ("(a|b", ("2_aéb,", 0n)),
    ("😀+?||(.b+?)", ("BaacB", 0n)),
    ("|[^)-]😀*b|.*?,\\\\?", ("_2B", 0n)),
    ("", ("😀1", 0n)),
    ("[z-a]", ("a", 0n)),
    ("()??|$([^_1b-b].)|", ("", 0n)),
    ("(([^\\s][-\\Sc] |$\\b[^]\\-]+?)b*?\\w|)?$", ("b_b 2a_", 0n)),
    ("[^]", (",", 0n)),
    ("[c\\b-]", ("_\t\nccc\n", 0n)),
    ("()\\???|", ("B,", 3n)),
    ("", ("-bb\t", 0n)),
    ("()", ("B😀AbB-", 0n)),
    ("", ("a1bb", 0n)),
    ("", ("A\n\t😀_\té", 3n)),
    ("(a", ("bBA-_\t", 0n)),
    ("()b[c]", ("__ ", 0n)),
    ("\\t+", ("a\n😀,2😀", 0n)),
    ("(|.)$|c", ("Bba,", 0n)),
    ("a??()A", ("a", 0n)),
    ("", ("_21-\nB2a", 0n)),
    ("", ("", 0n)),
    ("\\wa+?", (" 1aA1a", 0n)),
    ("(*a)", (",,A", 0n)),
    ("((😀|)?)c??B|", (",21", 0n)),
    ("", ("a1a2\t", 0n)),
    ("(?:)??1?-", ("\tA,2", 3n)),
    ("2?}b", ("", 0n)),
    ("\\w()?^", ("bé-bA", 1n)),
    ("[\\]-]+?b*|.éA", ("\nb22b2c-", 0n)),
    ("(?:)??(?:_[--/b-b]+?)+?|B|.??()??", ("éa", 0n))]))

#|none | none | none
#|none | none | none
#|2-2 | 2-2 | none
#|0-0 0-0 0-0 | 0-0 0-0 0-0 | none
#|1-1 1-1 | 1-1 1-1 | none
#|0-1 | 0-1 | none
#|0-0 - | 0-0 - | 0-2 1-1
#|err
#|0-0 - | 0-0 - | none
#|7-7 | 7-7 | none
#|0-1 | 0-1 | none
#|none | none | none
#|0-0 | 0-0 | none
#|err
#|err
#|0-1 0-1 | 0-1 0-1 | none
#|err
#|none | none | none
#|0-0 | 0-0 | none
#|0-0 | 0-0 | none
#|err
#|0-0 | 0-0 | none
#|7-7 | 7-7 | none
#|none | none | none
#|none | none | none
#|none | none | none
#|1-1 | 1-1 | none
#|0-0 - - | 0-0 - - | 0-0 - -
#|none | none | none
#|err
#|0-0 | 0-0 | 0-0
#|0-0 - - | 0-0 - - | none
#|none | none | none
#|none | none | none
#|none | none | none
#|3-3 | 3-3 | none
#|none | none | none
#|none | none | none
#|0-0 0-0 - | 0-0 0-0 - | none
#|0-1 | 0-1 | none
#|0-0 | 0-0 | none
#|2-3 | none | none
#|0-0 | 0-0 | none
#|none | none | none
#|none | none | none
#|0-0 | 0-0 | none
#|0-0 - - | 0-0 - - | none
#|0-1 - - | 0-1 - - | none
#|4-5 | none | none
#|none | none | none
#|7-7 | 7-7 | none
#|none | none | none
#|0-0 | 0-0 | none
#|0-0 - | 0-0 - | none
#|err
#|0-0 | 0-0 | none
#|none | none | none
#|none | none | none
#|none | none | none
#|0-0 | 0-0 | none
#|0-0 | 0-0 | none
#|0-0 | 0-0 | none
#|0-5 | 0-5 | none
#|none | none | none
#|0-0 | 0-0 | 0-0
#|err
#|0-2 | 0-2 | 0-2
#|0-0 | 0-0 | none
#|none | none | none
#|1-3 | none | none
#|none | none | none
#|none | none | none
#|err
#|1-2 - - | none | none
#|0-0 | 0-0 | none
#|0-0 - - | 0-0 - - | none
#|err
#|none | none | none
#|0-0 - - | 0-0 - - | none
#|1-1 | 1-1 | none
#|1-2 - - - - - - - | none | none
#|none | none | none
#|3-3 | none | none
#|5-5 | none | none
#|0-0 0-0 | 0-0 0-0 | none
#|none | none | none
#|none | none | none
#|1-4 | none | none
#|1-1 | 1-1 | none
#|0-0 | 0-0 | none
#|err
#|none | none | none
#|err
#|none | none | none
#|none | none | none
#|0-0 - - - | 0-0 - - - | none
#|none | none | none
#|err
#|0-0 | 0-0 | none
#|0-0 | 0-0 | 0-0
#|0-0 - | 0-0 - | none
#|2-2 - - - | 2-2 - - - | none
#|none | none | none
#|0-0 | 0-0 | none
#|1-1 - - | 1-1 - - | none
#|none | none | none
#|err
#|none | none | none
#|1-1 - | 1-1 - | none
#|2-2 | none | none
#|err
#|none | none | none
#|0-1 0-0 - 0-1 | 0-1 0-0 - 0-1 | none
#|0-0 - - | 0-0 - - | 0-0 - -
#|3-3 | 3-3 | none
#|none | none | none
#|none | none | none
#|0-1 - | 0-1 - | none
#|err
#|0-0 | 0-0 | none
#|none | none | none
#|2-3 | none | none
#|0-1 | 0-1 | none
#|err
#|none | none | none
#|0-0 | 0-0 | none
#|3-4 | none | none
#|0-0 | 0-0 | none
#|0-0 | 0-0 | none
#|none | none | none
#|err
#|0-0 - | 0-0 - | none
#|0-0 | 0-0 | none
#|0-0 | 0-0 | none
#|err
#|0-0 - - | 0-0 - - | 0-0 - -
#|7-7 7-7 - | none | none
#|err
#|3-4 | none | none
#|2-2 2-2 | 2-2 2-2 | none
#|0-0 | 0-0 | none
#|0-0 0-0 | 0-0 0-0 | none
#|0-0 | 0-0 | none
#|3-3 | 3-3 | none
#|err
#|none | none | none
#|none | none | none
#|3-4 3-4 | none | none
#|none | none | none
#|0-0 | 0-0 | none
#|0-0 | 0-0 | 0-0
#|1-3 | none | none
#|err
#|0-0 - - | 0-0 - - | none
#|0-0 | 0-0 | none
#|none | none | none
#|none | none | none
#|none | none | none
#|7-8 | none | none
#|0-0 - | 0-0 - | none
