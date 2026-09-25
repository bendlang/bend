# parse (keywords): every word the parser dispatches on is reserved.
# law, for, exs, where, is and import were missing from
# KEYWORDS, so a declaration could name itself after the word that
# heads it, and the parser then read the name as the word. "as" stays
# free: only book_load's import line reads it, never parse_name.
law law : Type
def law(): Type

#|Error:
#|- expected : a name (got the keyword 'law')
#|- observed : 'law'
#|Location:
#|5 | # free: only book_load's import line reads it, never parse_name.
#|6>| law law : Type
#|  |     ^^^
#|7 | def law(): Type
#|exit 1
