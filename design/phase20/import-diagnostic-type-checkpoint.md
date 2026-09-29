# Datatype constructor checkpoint: read-only investigation

The accepted decorator candidate remains immutable at import-diagnostic-source01.
The remaining default import-after-type diagnostic is produced at a different
grammar checkpoint. Pinned parse_book's datatype loop (2521–2527) stops only at a
non-name-head character or the next def/type/law. Otherwise it calls parse_name,
then expects `{`. Our f_type_ctors instead requires positive indentation and an
immediately following `{`; failing that, it returns to the top-level dispatcher.

Before recommending any source change, compare the checked source01 parser and
pinned parse_book on frozen strings covering ordinary indented/unindented/same-line
constructors, empty types, each legal declaration terminator, the decorator
terminator, import and other reserved names with/without braces, malformed dotted
names, missing opening brace, punctuation, duplicate constructors, and comments.
Preserve both acceptance and complete diagnostic text, including successful
constructor inventories. This is an exploratory census, so mismatches are results
and cannot make it claim conformance.

A diagnostic rewrite in f_import_leading would lack the lost datatype context and
is not acceptable. The principled shared alternative is a constructor-start test
matching the pin, followed by existing name validation and brace expectation.
That alternative could change grammar acceptance and must be separately approved,
tested, and counted. No source mutation is authorized by this investigation file.
