// Apify API client: https://api.apify.com/v2 with a bearer token.
// Errors come back as NULL plus a readable message in apify_last_error.
#ifndef APIFY_HC
#define APIFY_HC

#include "B:/src/Http/Http1"
#include "B:/src/Json/Json"

CConn *(*apify_open)(U8 *host, I64 port) = NULL;   // NULL: ConnTlsOpen if loaded, else ConnTcpOpen
U8 *apify_host = "api.apify.com";
I64 apify_port = 443;
U8 *apify_ip = NULL;                               // connect here but still send apify_host as SNI (labs without DNS)
U8 apify_last_error[512];

U0 ApifyErr(I64 status, U8 *msg)
{
  I64 n;
  if (status > 0)
    StrPrint(apify_last_error, "HTTP %d: ", status);
  else
    apify_last_error[0] = 0;
  n = StrLen(apify_last_error);
  for (; *msg && n < 511; msg++)
    apify_last_error[n++] = *msg;
  apify_last_error[n] = 0;
}

I64 ApifyFindFn(U8 *name)
{
  CHashFun *f = HashFind(name, Fs->hash_table, HTT_FUN);
  if (f)
    return f->exe_addr;
  return NULL;
}

// Plain-HTTP TCP to host:port, for tests against the lab mock.
U0 ApifyUsePlain(U8 *host, I64 port)
{
  apify_host = host;
  apify_port = port;
  apify_open = ApifyFindFn("ConnTcpOpen");
}

CConn *ApifyOpen()
{
  CConn *(*open_sni)(U8 *host, I64 port, U8 *sni);
  if (apify_ip && !apify_open) {
    open_sni = ApifyFindFn("ConnTlsOpenSni");
    if (open_sni)
      return (*open_sni)(apify_ip, apify_port, apify_host);
  }
  if (!apify_open)
    apify_open = ApifyFindFn("ConnTlsOpen");
  if (!apify_open)
    apify_open = ApifyFindFn("ConnTcpOpen");
  if (!apify_open)
    return NULL;
  return (*apify_open)(apify_host, apify_port);
}

Bool ApifyTokenOk(U8 *token)
{
  if (!*token)
    return FALSE;
  for (; *token; token++)
    if (*token <= 0x20 || *token >= 0x7F)
      return FALSE;
  return TRUE;
}

// Turns an error response body into apify_last_error: "HTTP 401: <error.message>".
U0 ApifyErrFromBody(CHttpResponse *r)
{
  CJson *j = JsonParse(r->body);
  U8 *msg = JsonStr(JsonGet(j, "error.message"));
  if (!msg)
    msg = JsonStr(JsonGet(j, "error.type"));
  if (!msg)
    msg = "request failed";
  ApifyErr(r->status, msg);
  JsonFree(j);
}

// One API call. Returns the 2xx response body (caller Frees) or NULL.
U8 *ApifyCall(U8 *method, U8 *path, U8 *token, U8 *input)
{
  CConn *c;
  CHttpResponse *r;
  U8 *hdr, *body = NULL;
  I64 len = 0;

  if (!ApifyTokenOk(token)) {
    ApifyErr(0, "invalid API token");
    return NULL;
  }
  c = ApifyOpen();
  if (!c) {
    ApifyErr(0, "cannot connect");
    return NULL;
  }
  // A synchronous Actor may send no response bytes until its 300-second API limit.
  if (input)
    ConnTcpSetReadTimeout(c, 310000);
  if (input) {
    hdr = MStrPrint("Authorization: Bearer %s\r\nAccept: application/json\r\nContent-Type: application/json\r\n", token);
    len = StrLen(input);
  } else
    hdr = MStrPrint("Authorization: Bearer %s\r\nAccept: application/json\r\n", token);
  r = HttpRequest(c, method, apify_host, path, hdr, input, len);
  c->close(c);
  Free(hdr);
  if (!r)
    ApifyErr(0, "no valid HTTP response");
  else if (r->status == HTTP_ERR_TOO_BIG)
    ApifyErr(0, "response too large");
  else if (r->status < 200 || r->status > 299)
    ApifyErrFromBody(r);
  else {
    body = r->body;
    r->body = NULL;
  }
  HttpResponseFree(r);
  return body;
}

// GET /v2/users/me. Returns the JSON body or NULL.
U8 *ApifyUsersMe(U8 *token)
{
  return ApifyCall("GET", "/v2/users/me", token, NULL);
}

// POST /v2/acts/<actor>/run-sync-get-dataset-items with input_json as the Actor input
// (NULL means {}). actor_id is "user~name" or "user/name" or a bare id. Returns the dataset
// items as a JSON array text (caller Frees) or NULL. The API itself gives up after 300 s.
U8 *ApifyRunSync(U8 *token, U8 *actor_id, U8 *input_json)
{
  U8 *id, *path, *body, *p;
  if (!actor_id || !*actor_id) {
    ApifyErr(0, "missing Actor id");
    return NULL;
  }
  id = StrNew(actor_id);
  for (p = id; *p; p++) {
    if (*p == '/')
      *p = '~';
    if (!((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') || (*p >= '0' && *p <= '9') ||
          *p == '~' || *p == '.' || *p == '_' || *p == '-')) {
      Free(id);
      ApifyErr(0, "invalid Actor id");
      return NULL;
    }
  }
  path = MStrPrint("/v2/acts/%s/run-sync-get-dataset-items", id);
  Free(id);
  if (!input_json)
    input_json = "{}";
  body = ApifyCall("POST", path, token, input_json);
  Free(path);
  return body;
}

#endif
