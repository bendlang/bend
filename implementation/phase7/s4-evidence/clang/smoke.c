#include <stdint.h>
#include <stdio.h>
int main(void) {
  const unsigned _BitInt(128) wide = ((unsigned _BitInt(128))1 << 100) + 42;
  const uint64_t low = (uint64_t)wide;
  if (low != 42 || (wide >> 100) != 1) return 1;
  printf("clang-c-smoke:%llu\n", (unsigned long long)low);
  return 0;
}
