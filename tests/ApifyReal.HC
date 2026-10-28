// Full stack against the real API, no token needed: a bad token must give a clean 401.
// Run: lab/tos --net apify tests/ApifyReal.HC
#include "B:/tests/Test.HC"
#include "B:/src/Net/NetUp"
#include "B:/src/Tls/Tls13"
#include "B:/src/Apify/Apify"

TestCheck(NetUp == 0, "NetUp");
apify_ip = "10.0.2.100";
U8 *r = ApifyUsersMe("apify_api_invalid_token_for_test");
TestCheck(r == NULL, "bad token gives NULL");
SerPrint("error: %s\n", apify_last_error);
TestCheck(StrFind("HTTP 401", apify_last_error) != NULL, "401 surfaced");
r = ApifyRunSync("apify_api_invalid_token_for_test", "apify/hello-world", "{}");
TestCheck(r == NULL, "run-sync bad token gives NULL");
SerPrint("error: %s\n", apify_last_error);
TestDone;
