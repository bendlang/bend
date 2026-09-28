// Same qualified-name seam as the native companion.
function phase8_tags(n) { return { $: n === 0 ? CID(Pick) : CID(pick) }; }
io_eff(CID(get), phase8_tags);
