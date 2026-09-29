# Root producer-freeze handoff

The collector adaptation is prepared but no collector prepare/capture or
recovery may run until root supplies and authorizes a final freeze. Preserve
that original JSON verbatim as root-release-freeze.json. Required facts:

- allProducersClosed:true for the exact selected Phase21 group-* roots.
- finalAttempt:selfhost/build/phase21/group-range-build-02.
- finalSource:selfhost/build/phase21/group-range-source-02/project.
- finalApiSha256:44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0.
- anchorStatus:installed-group-range-release, after installation completes.
- releaseCommit:the completed release commit.
- files and inputs:exact repository file/sha256 identities (optional bytes).
- Closed roots or an explicit declaration that every listed group-* root is
  closed, including promotion, CLI, final report and matrix.

The preparation adapter will check every identity, copy the original freeze,
record exact current closed root paths and closed phase-specific tools/docs,
verify214 source members against committed Phase20 bytes, and create the
collector's root-freeze.json with path/sha256 inputs and authorized:true under
root's explicit preservation grant. Collector topics use empty prefix lists;
all trees are explicit. New future work cannot be captured implicitly.

Inventory preparation is separate from capture. Carets independently reviews
coverage, unsafe paths/links, dependency expansion, maximum member and source
reconstruction before any archive is created. Existing algorithm requires each
member strictly below64,000,000 bytes and each archive below99,000,000 bytes.
