// TLS over libcurl's connect-only HTTPS socket. The easy handle owns the fd.
#include <curl/curl.h>
#include <poll.h>
#include <limits.h>

#ifndef BEND_CURL_COMMON
#define BEND_CURL_COMMON
static pthread_once_t bend_curl_once = PTHREAD_ONCE_INIT;
static CURLcode bend_curl_init_code;
static void bend_curl_init(void) {
  bend_curl_init_code = curl_global_init(CURL_GLOBAL_DEFAULT);
}
static u32 bend_curl_error(CURLcode code) {
  if (code == CURLE_OPERATION_TIMEDOUT) return ETIMEDOUT;
  if (code == CURLE_PEER_FAILED_VERIFICATION || code == CURLE_SSL_CACERT_BADFILE)
    return EACCES;
  return EIO;
}
#endif

static bool tls_host_ok(const char* host, u64 len) {
  if (len == 0 || len > 253 || io_nul(host, len)) return false;
  if (strchr(host, ':')) {
    struct in6_addr address;
    return inet_pton(AF_INET6, host, &address) == 1;
  }
  for (u64 i = 0; i < len; i += 1) {
    unsigned char c = (unsigned char)host[i];
    if (!(c >= 'a' && c <= 'z') && !(c >= 'A' && c <= 'Z')
      && !(c >= '0' && c <= '9') && c != '.' && c != '-') return false;
  }
  return true;
}

static int tls_wait(CURL* easy, short events, u64 deadline) {
  curl_socket_t fd = CURL_SOCKET_BAD;
  if (curl_easy_getinfo(easy, CURLINFO_ACTIVESOCKET, &fd) != CURLE_OK
    || fd == CURL_SOCKET_BAD) return EIO;
  for (;;) {
    u64 now = io_tick();
    if (now >= deadline) return ETIMEDOUT;
    u64 ms = (deadline - now + 999999) / 1000000;
    struct pollfd pfd = { .fd = fd, .events = events };
    int n = poll(&pfd, 1, ms > INT_MAX ? INT_MAX : (int)ms);
    if (n > 0) return pfd.revents & (POLLERR | POLLHUP | POLLNVAL) ? EIO : 0;
    if (n == 0) return ETIMEDOUT;
    if (errno != EINTR) return errno;
  }
}

#ifdef CID_TLS_CONNECT
static void tls_connect_call(IoWork* w) {
  CURL* easy = curl_easy_init();
  if (easy == NULL) { w->code = ENOMEM; return; }
  char url[320];
  bool ipv6 = strchr(w->data, ':') != NULL;
  snprintf(url, sizeof url, ipv6 ? "https://[%s]:%u/" : "https://%s:%u/",
    w->data, (u32)w->made);
  CURLcode code = curl_easy_setopt(easy, CURLOPT_URL, url);
  if (code == CURLE_OK) code = curl_easy_setopt(easy, CURLOPT_CONNECT_ONLY, 1L);
  if (code == CURLE_OK) code = curl_easy_setopt(easy, CURLOPT_SSL_ENABLE_ALPN, 0L);
  if (code == CURLE_OK) code = curl_easy_setopt(easy, CURLOPT_SSL_VERIFYPEER, 1L);
  if (code == CURLE_OK) code = curl_easy_setopt(easy, CURLOPT_SSL_VERIFYHOST, 2L);
  if (code == CURLE_OK && w->text[0] != 0)
    code = curl_easy_setopt(easy, CURLOPT_CAINFO, w->text);
  if (code == CURLE_OK)
    code = curl_easy_setopt(easy, CURLOPT_CONNECTTIMEOUT_MS, (long)w->word);
  if (code == CURLE_OK)
    code = curl_easy_setopt(easy, CURLOPT_TIMEOUT_MS, (long)w->word);
  if (code == CURLE_OK) code = curl_easy_perform(easy);
  if (code != CURLE_OK) {
    w->code = bend_curl_error(code);
    w->made = (intptr_t)code;
    curl_easy_cleanup(easy);
  } else {
    w->hand = (intptr_t)easy;
  }
}

static Term tls_connect_pack(Env e, IoWork* w) {
  Term result = w->code
    ? io_fail(e, w->code, w->made ? curl_easy_strerror((CURLcode)w->made) : NULL)
    : io_done(e, io_hand(w->hand));
  free(w->data);
  free(w->text);
  return result;
}

Term tls_connect_run(Env e, Term* f, IoWork* w) {
  u64 ca_len;
  w->data = io_cstr(e, f[0], &w->size);
  w->text = io_cstr(e, f[2], &ca_len);
  w->made = (u32)f[1];
  w->word = (u32)f[3];
  w->code = 0;
  w->hand = 0;
  if (!tls_host_ok(w->data, w->size) || io_nul(w->text, ca_len)
    || w->made == 0 || w->made > 65535 || w->word == 0) {
    w->code = EINVAL;
    return tls_connect_pack(e, w);
  }
  pthread_once(&bend_curl_once, bend_curl_init);
  if (bend_curl_init_code != CURLE_OK) {
    w->code = EIO;
    return tls_connect_pack(e, w);
  }
  return io_work(w, tls_connect_call, tls_connect_pack);
}

static void __attribute__((constructor)) tls_connect_use(void) {
  io_eff(CID_TLS_CONNECT, tls_connect_run, 0);
}
#endif

#ifdef CID_TLS_SEND
static void tls_send_call(IoWork* w) {
  CURL* easy = (CURL*)w->hand;
  u64 deadline = io_tick() + (u64)w->word * 1000000ull;
  while ((u64)w->made < w->size) {
    size_t n = 0;
    CURLcode code = curl_easy_send(easy, w->data + w->made,
      w->size - (u64)w->made, &n);
    w->made += n;
    if (code == CURLE_AGAIN) {
      w->code = tls_wait(easy, POLLOUT, deadline);
      if (w->code) break;
    } else if (code != CURLE_OK) {
      w->code = bend_curl_error(code);
      w->text = (char*)curl_easy_strerror(code);
      break;
    }
    if (code == CURLE_OK && n == 0) { w->code = EPIPE; break; }
  }
}

static Term tls_send_pack(Env e, IoWork* w) {
  Term result = w->code ? io_fail(e, w->code, w->text)
    : io_done(e, term_pak(CID_UNIT, 0));
  free(w->data);
  return io_tup(e, io_hand(w->hand), result);
}

Term tls_send_run(Env e, Term* f, IoWork* w) {
  u64 cap = 64;
  Term xs = f[1];
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->word = (u32)f[2];
  w->size = 0;
  w->made = 0;
  w->code = w->word == 0 ? EINVAL : 0;
  w->text = NULL;
  w->data = io_mem(malloc(cap));
  while (term_aux(xs) == CID_CON) {
    Term fields[2];
    spare_free(e, cls_fit(2), ctr_take(e, xs, 2, fields));
    if (w->size == cap) {
      cap *= 2;
      w->data = io_mem(realloc(w->data, cap));
    }
    if (fields[0] > 255) w->code = EINVAL;
    w->data[w->size++] = (char)fields[0];
    xs = fields[1];
  }
  return w->code ? tls_send_pack(e, w)
    : io_work(w, tls_send_call, tls_send_pack);
}

static void __attribute__((constructor)) tls_send_use(void) {
  io_eff(CID_TLS_SEND, tls_send_run, 0);
}
#endif

#ifdef CID_TLS_RECV
static void tls_recv_call(IoWork* w) {
  CURL* easy = (CURL*)w->hand;
  u64 deadline = io_tick() + (u64)w->word * 1000000ull;
  size_t cap = w->size;
  for (;;) {
    size_t n = 0;
    CURLcode code = curl_easy_recv(easy, w->data, cap, &n);
    if (code == CURLE_OK) { w->size = n; return; }
    if (code != CURLE_AGAIN) {
      w->code = bend_curl_error(code);
      w->text = (char*)curl_easy_strerror(code);
      return;
    }
    w->code = tls_wait(easy, POLLIN, deadline);
    if (w->code) return;
  }
}

static Term tls_recv_pack(Env e, IoWork* w) {
  Term result;
  if (w->code) {
    result = io_fail(e, w->code, w->text);
  } else {
    Term bytes = term_pak(CID_NIL, 0);
    for (u64 i = w->size; i > 0; i -= 1) {
      bytes = io_node(e, CID_CON, ((uint8_t*)w->data)[i - 1], bytes);
    }
    result = io_done(e, bytes);
  }
  free(w->data);
  return io_tup(e, io_hand(w->hand), result);
}

Term tls_recv_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->word = (u32)f[2];
  w->code = 0;
  w->text = NULL;
  w->size = (u32)f[1];
  if (w->size == 0 || w->word == 0) {
    w->code = EINVAL;
    w->data = NULL;
    return tls_recv_pack(e, w);
  }
  if (w->size > 65536) w->size = 65536;
  w->data = io_mem(malloc(w->size));
  return io_work(w, tls_recv_call, tls_recv_pack);
}

static void __attribute__((constructor)) tls_recv_use(void) {
  io_eff(CID_TLS_RECV, tls_recv_run, 0);
}
#endif

#ifdef CID_TLS_CLOSE
static void tls_close_call(IoWork* w) {
  curl_easy_cleanup((CURL*)w->hand);
}
static Term tls_close_pack(Env e, IoWork* w) {
  return term_pak(CID_UNIT, 0);
}
Term tls_close_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  return io_work(w, tls_close_call, tls_close_pack);
}
static void __attribute__((constructor)) tls_close_use(void) {
  io_eff(CID_TLS_CLOSE, tls_close_run, 0);
}
#endif
