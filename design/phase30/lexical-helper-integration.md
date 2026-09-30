# Integrate direct lexical calls without changing region admission

Prospective implementation plan following the isolated
[lexical helper experiment](lexical-private-helpers.md). Promotion depends on
the longer confirmation, not the short screen alone.

Replace the private null-prototype helper dictionary with private function
declarations inside the same owner IIFE. Keep `JCall` and its original source
name, the complete helper graph, all type lookup, guards, exact-entry permission,
loop representation and generic fallback unchanged. This is one spelling change
in the existing region lowering, not another optimization pass.

Use an injective JavaScript identifier: `$R` followed by an underscore and the
decimal Unicode codepoint of every source-name character. Delimit every codepoint
so different character sequences cannot collide. The fixed prefix handles empty
names and reserved words, and cannot collide with the emitter's `x`, `$s`, `$p`
or `$n` locals. Do not reuse foreign-name normalization: case folding and replacing
both dots and slashes with underscores lose identity. No name table, ordinal map,
new KTerm field or traversal state is needed.

Change only the `JCall` expression spelling and the existing helper-declaration
functions. Private declarations preserve parameter order, body expressions and
scope. Forward references are safe because the function bindings exist before
the returned public matcher can run. Public descriptors, code identities and
properties remain unchanged.

Build a new immutable checked B1 and run the usual 36 exact focused gates. Check
the actual emitted helper fixture with the existing arithmetic, public ABI and
exact-entry controls; compare against attempt07 and the pre-worker reference
where appropriate. Add a small name-identity control covering case, dot, slash,
underscore, digits and non-ASCII codepoints, plus a checked program whose helper
names would collide under the rejected foreign-name mapping. Record source and
generated-byte changes. Retime actual compiler output, first with the small
screen and then a longer confirmation. The saved JavaScript ablation is useful
evidence, but it cannot stand in for production-emission validation.

The new compiler should contain fewer runtime indirections and no additional
semantic admission concept. Retain the failed or inconclusive timing windows and
the original dictionary output in the campaign evidence capsule.
