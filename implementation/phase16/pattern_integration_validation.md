# Final compact compiler: parser pattern validation

Final compact API
`35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315`
preserves all 114 frozen pattern/checkpoint outcomes from the isolated marked
candidate byte-for-byte at the normalized comparison boundary: 71 exact matches,
43 retained known differences, zero changed outcomes, zero primitive changes.
The six frozen demand/identity/quantity controls also pass. Ordinary patterns
and lambdas still perform zero lexical lookups in those demand controls; marked
patterns retain fresh identity/Many quantity, and marked terms retain their
unbound sentinel. The normal lambda representation is KLambda in this union.

Evidence: `selfhost/build/phase16/marked-pattern-integrated-01`,
`marked-pattern-integrated-demand-01`, and
`marked-pattern-integration-audit-01.json`. Every paired worker completed 114
requests with zero failures, timeouts or errors. The known 43 differences remain
visible; this selected gate is not a full-conformance claim. All producers closed.
