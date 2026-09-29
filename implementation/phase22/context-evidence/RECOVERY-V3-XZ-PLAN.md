# Codec-only XZ preservation amendment

The full gzip proposal cannot fit available disk without losing evidence. Its
immutable estimate is150,088,149 compressed bytes. Streaming the same36 ordered
tar frames through XZ preset9/CRC64 produced23,465,700 bytes in161.17 seconds;
all24,509 proposed members and their1,236,314,909 logical bytes remain selected.
No archive was written by either estimator.

Fresh `context-preserve-v2.py` and `context-recover-v3.py` change only archive codec
and explicit format validation. Metadata requires tar/XZ, preset9,64MiB dictionary
and CRC64. Parts use `.tar.xz`; recovery accepts only `r:xz`. Member paths, order,
bytes, modes, selected-target links,38MB regular part bound,8MB retained bound,
40MB compressed bound and Git-plus-patch source reconstruction stay unchanged.
XZ compression uses more memory than gzip; its64MiB dictionary and compressor
working memory are RAM, separate from the bounded extraction disk policy.

Fresh controls repeat all27 v2 policy observations unchanged and add two refusals:
wrong codec metadata and gzip bytes inside an XZ-declared part. Both valid synthetic
tar streams must also match the retained v2 gzip streams byte-for-byte after
decompression. Prior tools, failed proposals and all earlier controls remain
immutable. No production capture/recovery is authorized by this amendment.

The final inventory must bind215 source members (currently1,325,428 bytes), actual
artifact retention and all new preparation/review metadata. Budget40MB for complete
capsule metadata/parts until preparation gives exact sizes; run bounded recovery
before the archive commit so recovery scratch and Git's extra compressed objects
need not coexist. Keep filesystem metadata/headroom in addition to payload bounds.
Outcome and index files remain outside immutable captured inputs.
