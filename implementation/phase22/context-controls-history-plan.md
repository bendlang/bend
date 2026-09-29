# Phase22 request-history controls

Freeze the original Phase16 paired-history method before running the final ABI2 candidate. The checked Phase21 parent and final Phase22 source09 each run under their own immutable snapshot host, copied into a fresh isolated project with an independently prepared and validated Base cache. No compiler or source image is changed.

Replay the original Phase12 sessions of 53 and 60 requests in their original order, with one persistent worker generation, 30-second deadlines, 4 MiB stack, 4 GiB heap/RSS bound and recycle threshold64. Run the long-string check once in a fresh isolated worker for each image. Total:226 historical requests plus two fresh checks. Bind all snapshot members, original request/identity/session files, original fixture hashes, exact Node/runtime/Base, the adapter and host, all copied members and the new per-image caches.

Retain every raw complete result and digest, and the original Phase12 comparisons. Each result's complete hostProvenance object must equal the actual variant driver/adapter hashes. The adapter must be identical across variants. Only the bound driverSha256 may differ in the paired result; every other result field is compared by exact deep equality. Do not normalize paths, diagnostic text, files, arrays, undefined/null, acceptance or trust. A changed result fails and remains recorded.

The historical Phase16 tools remain unchanged. The new tools are narrowly derived copies: CPU2, each API's own host/cache, explicit driver-provenance comparison, all copied snapshot members verified, and an exact host-delta manifest. The current host delta must be exactly tools/typed-driver.mjs. This gate does not establish full API compatibility for retired raw parser contracts, GPU behavior or performance.
