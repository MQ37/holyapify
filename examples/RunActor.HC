// Run through lab/tos with TOS_SECRET_APIFY_TOKEN set. Never put a real token here.
#include "B:/Env.HC"
#include "B:/tests/Test.HC"
#include "B:/src/HolyApify"

ApifyViaAddress("10.0.2.100");
ApifyToken(APIFY_TOKEN);
apify_last_error[0] = 0;
ApifyMe;
TestCheck(apify_last_error[0] == 0, "account lookup");
if (apify_last_error[0] == 0) {
  ApifyRun("apify/website-content-crawler",
    "{\"startUrls\":[{\"url\":\"https://example.com\"}],\"maxCrawlPages\":1}");
  TestCheck(apify_last_error[0] == 0, "Actor run");
}
SerDump;
TestDone;
