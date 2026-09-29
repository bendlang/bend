# Reuse the existing book index for template membership

The current specializer keeps a plain list of template definitions in
KSpecState.templates. `sp_needed` walks every definition body and calls the
general `lookup` on that list for each reference. The list is unchanged for the
whole specialization. With the pinned Base it contains 25 entries, so most
ordinary references repeatedly traverse all 25 names before proving a miss.
The diagnostic profile attributes 0.90% self time to sp_needed and 0.52% to its
list worker; its lookup, allocation and trampoline costs are charged elsewhere.
These shares are not a forecast of recoverable time.

The only semantic consumer of the templates field is this membership lookup;
other consumers merely retain the same value. Wrap the template list once with
the existing `book_cached` index in sp_initial, using the bound it already
receives. Do not introduce a new set implementation, cache invalidation rule,
state field, term tag or pass. The source delta is one expression on one line.
The index remains immutable for the lifetime of this state and keeps complete
definitions, so the existing lookup and arity predicate retain their semantics.

Before building, instrument a copied checked API and count lookup_named and
index_find calls only during membership probes, excluding one-time state setup.
Use zero, one, eight, 32 and128 templates, hits at both ends, ordinary-definition
misses, absent names and nested references. Then compare the candidate against
the same frozen inputs. Complete specialized books/errors, names, active cycles,
growth limits and source ranges must remain unchanged. Reuse the relevant
template controls and the maintained focused workflow. Whole-host timing must
include index construction and test the final same source against its parent;
also retain the end-to-end Phase15/TS comparison. Small books may not benefit.

Parent is corrected wave4-source02. Its full adjacent gate is in progress and
the prior uncorrected image costs 11.88% more than Phase15 on identical source.
No Phase16 candidate is installed; the earlier guard/copy/ASCII reductions do not
yet establish performance recovery. Preserve every failed setup and counterexample.
