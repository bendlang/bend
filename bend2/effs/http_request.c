// HTTP and HTTPS with libcurl; blocking transfers run on an IO helper.
#include <curl/curl.h>
#include <strings.h>

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

typedef struct HttpHeader {
  char* name;
  char* value;
  struct HttpHeader* next;
} HttpHeader;

typedef struct {
  char* method;
  char* url;
  char* body;
  char* ca;
  size_t body_len;
  size_t limit;
  size_t received;
  size_t used;
  size_t capacity;
  char* response;
  HttpHeader* headers;
  struct curl_slist* request_headers;
  long status;
  u32 error;
  const char* detail;
  u32 timeout;
} HttpCall;

static bool http_token(const char* s, u64 len) {
  if (len == 0 || io_nul(s, len)) return false;
  for (u64 i = 0; i < len; i += 1) {
    unsigned char c = (unsigned char)s[i];
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
      || (c >= '0' && c <= '9')) continue;
    if (strchr("!#$%&'*+-.^_`|~", c) == NULL) return false;
  }
  return true;
}

static bool http_value(const char* s, u64 len) {
  if (io_nul(s, len)) return false;
  for (u64 i = 0; i < len; i += 1) {
    unsigned char c = (unsigned char)s[i];
    if ((c < 32 && c != '\t') || c == 127) return false;
  }
  return true;
}

static void http_headers_free(HttpHeader* row) {
  while (row != NULL) {
    HttpHeader* next = row->next;
    free(row->name);
    free(row->value);
    free(row);
    row = next;
  }
}

static size_t http_write(char* bytes, size_t size, size_t count, void* user) {
  HttpCall* h = user;
  if (size && count > SIZE_MAX / size) { h->error = EFBIG; return 0; }
  size_t n = size * count;
  if (n > h->limit - h->received) { h->error = EFBIG; return 0; }
  if (n == 0) return 0;
  h->received += n;
  if (n > h->capacity - h->used) {
    size_t cap = h->capacity ? h->capacity : 64;
    while (cap - h->used < n) cap *= 2;
    h->response = io_mem(realloc(h->response, cap));
    h->capacity = cap;
  }
  memcpy(h->response + h->used, bytes, n);
  h->used += n;
  return n;
}

static size_t http_header(char* bytes, size_t size, size_t count, void* user) {
  HttpCall* h = user;
  if (size && count > SIZE_MAX / size) { h->error = EFBIG; return 0; }
  size_t n = size * count;
  if (n > h->limit - h->received) { h->error = EFBIG; return 0; }
  if (n == 0) return 0;
  h->received += n;
  if (n >= 5 && strncasecmp(bytes, "HTTP/", 5) == 0) {
    http_headers_free(h->headers);
    h->headers = NULL;
    return n;
  }
  char* colon = memchr(bytes, ':', n);
  if (colon == NULL || colon == bytes) return n;
  size_t key_len = colon - bytes;
  char* val = colon + 1;
  char* end = bytes + n;
  while (val < end && (*val == ' ' || *val == '\t')) val += 1;
  while (end > val && (end[-1] == '\r' || end[-1] == '\n'
    || end[-1] == ' ' || end[-1] == '\t')) end -= 1;
  size_t val_len = end - val;
  HttpHeader* row = io_mem(calloc(1, sizeof *row));
  row->name = io_mem(malloc(key_len + 1));
  row->value = io_mem(malloc(val_len + 1));
  memcpy(row->name, bytes, key_len);
  row->name[key_len] = 0;
  memcpy(row->value, val, val_len);
  row->value[val_len] = 0;
  row->next = h->headers;
  h->headers = row;
  return n;
}

static void http_request_call(IoWork* w) {
  HttpCall* h = (HttpCall*)w->data;
  CURL* easy = curl_easy_init();
  if (easy == NULL) { h->error = ENOMEM; return; }
  CURLcode rc = curl_easy_setopt(easy, CURLOPT_URL, h->url);
#if LIBCURL_VERSION_NUM >= 0x075500
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_PROTOCOLS_STR,
    "http,https");
#else
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_PROTOCOLS,
    CURLPROTO_HTTP | CURLPROTO_HTTPS);
#endif
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_FOLLOWLOCATION, 0L);
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_NOSIGNAL, 1L);
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_TIMEOUT_MS,
    (long)h->timeout);
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_SSL_VERIFYPEER, 1L);
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_SSL_VERIFYHOST, 2L);
  if (rc == CURLE_OK && h->ca[0] != 0)
    rc = curl_easy_setopt(easy, CURLOPT_CAINFO, h->ca);
  if (rc == CURLE_OK && h->request_headers != NULL)
    rc = curl_easy_setopt(easy, CURLOPT_HTTPHEADER, h->request_headers);
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_WRITEFUNCTION,
    http_write);
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_WRITEDATA, h);
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_HEADERFUNCTION,
    http_header);
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_HEADERDATA, h);
  if (rc == CURLE_OK && (h->body_len || strcmp(h->method, "GET") != 0
    && strcmp(h->method, "HEAD") != 0)) {
    rc = curl_easy_setopt(easy, CURLOPT_POSTFIELDSIZE_LARGE,
      (curl_off_t)h->body_len);
    if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_POSTFIELDS, h->body);
  }
  if (rc == CURLE_OK && strcmp(h->method, "HEAD") == 0)
    rc = curl_easy_setopt(easy, CURLOPT_NOBODY, 1L);
  if (rc == CURLE_OK) rc = curl_easy_setopt(easy, CURLOPT_CUSTOMREQUEST,
    h->method);
  if (rc == CURLE_OK) rc = curl_easy_perform(easy);
  if (rc == CURLE_OK) rc = curl_easy_getinfo(easy, CURLINFO_RESPONSE_CODE,
    &h->status);
  if (!h->error && rc != CURLE_OK) {
    h->error = bend_curl_error(rc);
    h->detail = curl_easy_strerror(rc);
  }
  curl_easy_cleanup(easy);
}

static Term http_response(Env e, u32 status, Term headers, Term body) {
  Loc l = heap_alloc(e, cls_fit(3));
  e.mem[l] = io_seal(e, status, CID_RESPONSE);
  e.mem[l + 1] = io_seal(e, headers, CID_RESPONSE);
  e.mem[l + 2] = io_seal(e, body, CID_RESPONSE);
  return term_ctr(CID_RESPONSE, l);
}

static Term http_request_pack(Env e, IoWork* w) {
  HttpCall* h = (HttpCall*)w->data;
  Term result;
  if (h->error) {
    result = io_fail(e, h->error, h->detail);
  } else {
    Term headers = term_pak(CID_NIL, 0);
    for (HttpHeader* row = h->headers; row != NULL; row = row->next) {
      Term name = io_str(e, row->name, strlen(row->name));
      Term value = io_str(e, row->value, strlen(row->value));
      headers = io_node(e, CID_CON, io_node(e, CID_HEADER, name, value), headers);
    }
    Term body = io_str(e, h->response ? h->response : "", h->used);
    result = io_done(e, http_response(e, (u32)h->status, headers, body));
  }
  http_headers_free(h->headers);
  curl_slist_free_all(h->request_headers);
  free(h->method);
  free(h->url);
  free(h->body);
  free(h->ca);
  free(h->response);
  free(h);
  return result;
}

Term http_request_run(Env e, Term* f, IoWork* w) {
  HttpCall* h = io_mem(calloc(1, sizeof *h));
  u64 method_len, url_len, ca_len;
  h->method = io_cstr(e, f[0], &method_len);
  h->url = io_cstr(e, f[1], &url_len);
  h->body = io_cstr(e, f[3], &h->body_len);
  h->ca = io_cstr(e, f[6], &ca_len);
  h->limit = (u32)f[4];
  h->timeout = (u32)f[5];
  if (!http_token(h->method, method_len) || io_nul(h->url, url_len)
    || !(url_len >= 7 && strncasecmp(h->url, "http://", 7) == 0)
    && !(url_len >= 8 && strncasecmp(h->url, "https://", 8) == 0)
    || io_nul(h->ca, ca_len) || h->limit == 0 || h->timeout == 0
    || strcmp(h->method, "HEAD") == 0 && h->body_len != 0) h->error = EINVAL;
  if (!h->error) {
    pthread_once(&bend_curl_once, bend_curl_init);
    if (bend_curl_init_code != CURLE_OK) h->error = EIO;
  }
  Term xs = f[2];
  while (term_aux(xs) == CID_CON) {
    Term node[2], field[2];
    spare_free(e, cls_fit(2), ctr_take(e, xs, 2, node));
    spare_free(e, cls_fit(2), ctr_take(e, node[0], 2, field));
    u64 key_len, val_len;
    char* key = io_cstr(e, field[0], &key_len);
    char* val = io_cstr(e, field[1], &val_len);
    if (!http_token(key, key_len) || !http_value(val, val_len)) {
      h->error = EINVAL;
    } else if (!h->error) {
      char* joined = io_mem(malloc(key_len + val_len + 3));
      memcpy(joined, key, key_len);
      joined[key_len] = ':';
      joined[key_len + 1] = ' ';
      memcpy(joined + key_len + 2, val, val_len);
      joined[key_len + val_len + 2] = 0;
      struct curl_slist* next = curl_slist_append(h->request_headers, joined);
      h->request_headers = io_mem(next);
      free(joined);
    }
    free(key);
    free(val);
    xs = node[1];
  }
  w->data = (char*)h;
  if (h->error) return http_request_pack(e, w);
  return io_work(w, http_request_call, http_request_pack);
}

static void __attribute__((constructor)) http_request_use(void) {
  io_eff(CID_HTTP_REQUEST, http_request_run, 0);
}
