// Run with: lab/tos --net mockplain tests/ApifyMock.HC
#include "B:/tests/Test"
#include "B:/src/Net/ConnTcp"
#include "B:/src/Apify/Apify"

U0 CheckErr(U8 *want, U8 *what)
{
  TestCheck(StrIMatch(want, apify_last_error) != NULL, what);
  if (!StrIMatch(want, apify_last_error))
    SerPrint("  last error: %s\n", apify_last_error);
}

U0 TestUsersMe()
{
  U8 *body = ApifyUsersMe("test-token");
  CJson *j = JsonParse(body);
  TestCheck(body && j, "users/me with the right token");
  TestCheck(!StrCmp(JsonStr(JsonGet(j, "data.username")), "mock-user"), "users/me username");
  TestCheck(!StrCmp(JsonStr(JsonGet(j, "data.plan.id")), "FREE"), "users/me plan");
  JsonFree(j);
  Free(body);

  body = ApifyUsersMe("wrong-token");
  TestCheck(!body, "users/me with a wrong token returns NULL");
  CheckErr("HTTP 401: mock: bad token", "401 error text");
  TestCheck(!ApifyUsersMe("bad token"), "token with a space refused");
  CheckErr("invalid API token", "invalid token text");
  TestCheck(!ApifyUsersMe(""), "empty token refused");
}

U0 TestRunSync()
{
  U8 *in = JsonEscape("https://example.com/\"q\"");
  U8 *input = MStrPrint("{\"startUrls\":[{\"url\":%s}]}", in);
  U8 *body = ApifyRunSync("test-token", "apify/web-scraper", input);
  CJson *j = JsonParse(body);
  TestCheck(body && j && j->type == JSON_ARR && j->n == 2, "run-sync returns a 2 item array (chunked)");
  TestCheck(!StrCmp(JsonStr(JsonGet(j, "[0].title")), "Example Domain"), "run-sync item 0");
  TestCheck(!StrCmp(JsonStr(JsonGet(j, "[1].text")), "second \xE2\x9C\x93"), "run-sync item 1 unicode");
  JsonFree(j);
  Free(body);
  Free(in);
  Free(input);

  body = ApifyRunSync("test-token", "apify~web-scraper", NULL);
  TestCheck(body != NULL, "run-sync with default input and ~ id");
  Free(body);
  TestCheck(!ApifyRunSync("wrong", "a/b", "{}"), "run-sync wrong token");
  CheckErr("HTTP 401: mock: bad token", "run-sync 401 text");
  TestCheck(!ApifyRunSync("test-token", "a b", "{}"), "bad actor id refused");
  CheckErr("invalid Actor id", "bad actor id text");
  TestCheck(!ApifyRunSync("test-token", "", "{}"), "empty actor id refused");
}

U0 TestBig()
{
  CConn *c = ConnTcpOpen("10.0.2.100", 80);
  CHttpResponse *r;
  CJson *j;
  U8 *want;
  if (!c) {
    TestCheck(FALSE, "connect for /big");
    return;
  }
  r = HttpRequest(c, "GET", "10.0.2.100", "/big", NULL, NULL, 0);
  c->close(c);
  TestCheck(r && r->status == 200, "big status");
  j = JsonParse(r->body);
  TestCheck(j && j->type == JSON_ARR && j->n == 300, "big: 300 items parsed");
  want = MStrPrint("line 299 \xC3\xA9 \"quoted\"");
  TestCheck(!StrCmp(JsonStr(JsonGet(j, "[299].text")), want), "big: last item text");
  TestCheck(JsonInt(JsonGet(j, "[150].i")) == 150, "big: middle item index");
  SerPrint("big: %d body bytes\n", r->body_len);
  Free(want);
  JsonFree(j);
  HttpResponseFree(r);
}

U0 Main()
{
  F64 t0 = tS;
  TestCheck(!NetUp(), "net up");
  ApifyUsePlain("10.0.2.100", 80);
  TestUsersMe();
  TestRunSync();
  TestBig();
  SerPrint("elapsed %.1f s\n", tS - t0);
  TestDone();
}
Main;
