// Apify for TempleOS: include this one file, then:
//   ApifyToken("apify_api_...");                        remember the API token (RAM only)
//   ApifyMe;                                            who am I
//   ApifyRun("apify/website-content-crawler", "{...}"); run an Actor, print its dataset
// Needs the PCnet card (QEMU: -device pcnet). The TLS client does NOT validate certificates: experimental only.
#ifndef HOLYAPIFY_HC
#define HOLYAPIFY_HC

#include "B:/src/HolyNet"
#include "B:/src/Apify/Apify"

#define APIFY_SHOW_COLS 76

U8 *apify_token = NULL;

U0 ApifyToken(U8 *token)
{
  Free(apify_token);
  apify_token = StrNew(token);
}

// Only for labs without DNS: connect to this address but still say api.apify.com in the handshake.
U0 ApifyViaAddress(U8 *ip)
{
  apify_ip = ip;
}

// One line of printable ASCII, cut at max characters. TempleOS cannot draw UTF-8; the dollar sign needs doubling.
U0 ApifyPutLine(U8 *s, I64 max)
{
  I64 n = 0;
  for (; *s && n < max; s++, n++) {
    if (*s == 36)
      Print("%c%c", 36, 36);
    else if (*s == '\n' || *s == '\r' || *s == '\t')
      Print(" ");
    else if (*s >= 0x80 && *s < 0xC0)
      n--;                                   // UTF-8 continuation byte: the lead byte already printed one "?"
    else if (*s < 0x20 || *s >= 0x7F)
      Print("?");
    else
      Print("%c", *s);
  }
  if (*s)
    Print("...");
  Print("\n");
}

U0 ApifyShowValue(CJson *v)
{
  U8 *t;
  if (v->type == JSON_STR)
    ApifyPutLine(v->str, APIFY_SHOW_COLS - 12);
  else if (v->type == JSON_NUM)
    ApifyPutLine(v->str, APIFY_SHOW_COLS);
  else if (v->type == JSON_BOOL)
    if (v->n)
      Print("true\n");
    else
      Print("false\n");
  else if (v->type == JSON_NULL)
    Print("null\n");
  else {
    if (v->type == JSON_ARR)
      t = MStrPrint("list with %d entries", v->n);
    else
      t = MStrPrint("object with %d entries", v->n);
    ApifyPutLine(t, APIFY_SHOW_COLS);
    Free(t);
  }
}

U0 ApifyShowItem(CJson *item, I64 idx)
{
  CJson *m;
  Print("$$FG,6$$-- item %d --$$FG$$\n", idx);
  if (item->type != JSON_OBJ) {
    ApifyShowValue(item);
    return;
  }
  for (m = item->first; m; m = m->next) {
    Print("$$FG,2$$%s$$FG$$: ", m->key);
    ApifyShowValue(m);
  }
}

// Prints a dataset (a JSON array) item by item.
U0 ApifyShow(U8 *json)
{
  CJson *j = JsonParse(json), *it;
  I64 i = 0;
  if (!j) {
    Print("$$FG,4$$Not JSON: %d bytes$$FG$$\n", StrLen(json));
    return;
  }
  if (j->type == JSON_ARR) {
    for (it = j->first; it; it = it->next)
      ApifyShowItem(it, ++i);
    Print("$$FG,6$$%d items$$FG$$\n", j->n);
  } else
    ApifyShowItem(j, 0);
  JsonFree(j);
}

Bool ApifyReady()
{
  if (!apify_token) {
    Print("$$FG,4$$No token: ApifyToken(\"apify_api_...\");$$FG$$\n");
    return FALSE;
  }
  if (NetUp) {
    Print("$$FG,4$$No network (is a PCnet card attached?)$$FG$$\n");
    return FALSE;
  }
  return TRUE;
}

U0 ApifyMe0()
{
  U8 *body;
  CJson *j;
  if (!ApifyReady)
    return;
  body = ApifyUsersMe(apify_token);
  if (!body) {
    Print("$$FG,4$$%s$$FG$$\n", apify_last_error);
    return;
  }
  j = JsonParse(body);
  Print("$$FG,2$$user$$FG$$: ");
  ApifyPutLine(JsonStr(JsonGet(j, "data.username")), APIFY_SHOW_COLS);
  Print("$$FG,2$$plan$$FG$$: ");
  ApifyPutLine(JsonStr(JsonGet(j, "data.plan.id")), APIFY_SHOW_COLS);
  JsonFree(j);
  Free(body);
}

U0 ApifyRun0(U8 *actor, U8 *input)
{
  U8 *body;
  F64 t0;
  if (!ApifyReady)
    return;
  Print("$$FG,6$$Running %s ...$$FG$$\n", actor);
  t0 = tS;
  body = ApifyRunSync(apify_token, actor, input);
  if (!body) {
    Print("$$FG,4$$%s$$FG$$\n", apify_last_error);
    return;
  }
  Print("$$FG,6$$done in %d s, %d bytes$$FG$$\n", ToI64(tS - t0), StrLen(body));
  ApifyShow(body);
  Free(body);
}

U0 ApifyMe()
{
  ApifyMe0;
}

// Runs an Actor and waits for it (the API gives up after 300 s), then prints the dataset items.
U0 ApifyRun(U8 *actor, U8 *input = NULL)
{
  ApifyRun0(actor, input);
}

#endif
