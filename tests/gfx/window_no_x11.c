// Whether libX11 is absent from the modules the process has loaded. On
// Linux a Window binary built before the lazy-Xlib fix carries libX11 in
// DT_NEEDED, so the loader loads it before main and this answers False.
#ifdef __linux__
#include <link.h>
#include <string.h>

static int x11_seen(struct dl_phdr_info* info, size_t size, void* data) {
  (void)size;
  if (info->dlpi_name != NULL
    && strstr(info->dlpi_name, "libX11.so") != NULL) {
    *(bool*)data = true;
    return 1;
  }
  return 0;
}
#endif

Term x11_absent_run(Env e, Term* f, IoWork* w) {
  (void)e;
  (void)f;
  (void)w;
  bool seen = false;
#ifdef __linux__
  dl_iterate_phdr(x11_seen, &seen);
#endif
  return term_pak(seen ? CID(False) : CID(True), 0);
}

static void __attribute__((constructor)) x11_absent_use(void) {
  io_eff(CID(x11.absent), x11_absent_run);
}
