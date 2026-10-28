// The friendly commands against the TLS mock. Run: lab/tos --net mock tests/FrontMock.HC
#include "B:/tests/Test.HC"
#include "B:/src/HolyApify"

ApifyViaAddress("10.0.2.100");
ApifyToken("test-token");
apify_last_error[0] = 0;
ApifyMe;
TestCheck(apify_last_error[0] == 0, "account command succeeds");
apify_last_error[0] = 0;
ApifyRun("apify/hello-world", "{\"x\":1}");
TestCheck(apify_last_error[0] == 0, "Actor command succeeds");
ApifyToken("wrong");
ApifyMe;
TestCheck(StrFind("HTTP 401", apify_last_error) != NULL, "bad token reports 401");
TestDone;
