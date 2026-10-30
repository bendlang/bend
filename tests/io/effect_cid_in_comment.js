// The same quote, "CID(...) names no constructor or def", in the JS twin.
function answer(n) {
  return (n + 2) >>> 0;
}

// U+2028 ends a JS comment: io_eff(CID(answer), answer);
