<div align="center">

<img src="assets/holyapify.png" width="260" alt="An illuminated Christian cross with a gold halo and pixel circuit traces">

<h1>HolyApify</h1>

<p><strong>Web scraping. In HolyC. On stock TempleOS.</strong><br>
In memory of Terry A. Davis, God's chosen programmer.</p>

<p><code>HolyC only</code> · <code>TempleOS V5.03</code> · <code>powered by HolyNet</code></p>

<p><em>The Lord is my shepherd. Apify is my scraper.</em></p>

</div>

---

Run an Apify Actor from TempleOS. Send JSON. Get its dataset back in the terminal. All guest-side code is HolyC; the TCP/IP stack and TLS come from [**HolyNet**](https://github.com/MQ37/holynet), in the sibling `holynet` repository.

```c
#include "B:/src/HolyApify"

ApifyToken("YOUR_DISPOSABLE_APIFY_TOKEN");
ApifyMe;
ApifyRun("apify/hello-world", "{}");
```

**Yes, the guest does the TLS.** The lab's forwarder only copies TCP bytes. No Linux process makes the HTTPS request on TempleOS's behalf.

> God intended TempleOS to stay offline. We connected it to a web scraper. Forgive us.

**Experimental, unauthenticated TLS.** HolyNet does not validate server certificates or CertificateVerify signatures, and its random generator is experimental. Use disposable credentials and non-sensitive data only. [Read the security model before using a token.](SECURITY.md)

## Quick start

Clone the two repositories next to each other:

```sh
git clone https://github.com/MQ37/holynet.git
git clone https://github.com/MQ37/holyapify.git
```

First follow [HolyNet's lab setup](https://github.com/MQ37/holynet#boot-the-lab) to build the `localhost/tos-lab:1` image and download and verify the stock TempleOS ISO in RAM. If you already cloned it above, start at `cd holynet` in those instructions. You need Linux, rootless Podman and access to `/dev/kvm`.

After the lab setup, switch from `holynet` to the sibling client:

```sh
cd ../holyapify
lab/tos --net mock tests/FrontMock.HC
```

That boots a fresh TempleOS VM inside Podman, loads HolyNet and HolyApify on its RAM drive and exercises the friendly commands against a local TLS mock. No Apify account or paid Actor run is required. A passing test ends with `TOS-DONE fail=0`.

Set `HOLYNET_DIR` if the dependency lives somewhere else. Both repositories are mounted read-only. The host-side launcher only orchestrates containers; QEMU, HolyC compilation and execution happen inside the lab.

## Three commands. An unreasonable amount of networking.

| Command | What it does |
|---|---|
| `ApifyToken("...");` | Keeps the API token in guest RAM for subsequent commands |
| `ApifyMe;` | Prints the authenticated account's username and plan |
| `ApifyRun("owner/actor", "{...}");` | Runs an Actor and prints the returned dataset items |
| `ApifyRun("owner/actor");` | Runs with the default input `{}` |

A one-page crawl looks like this:

```c
ApifyRun("apify/website-content-crawler",
  "{\"startUrls\":[{\"url\":\"https://example.com\"}],\"maxCrawlPages\":1}");
```

Results appear as numbered items with coloured field names. Errors come back as readable messages. TempleOS cannot draw UTF-8, so the friendly terminal display substitutes `?` for non-ASCII characters; the JSON parser retains the underlying text.

Actor runs use your Apify account and may incur charges. This client uses the [synchronous run-and-return-dataset endpoint](https://docs.apify.com/api/v2/actor-run-sync-get-dataset-items-post), with the API's 300-second ceiling and HolyNet's 8 MiB response limit. Actor calls allow 310 seconds without response bytes; the lab's separate VM timeout must also be raised for long calls, as shown below. Long jobs, streaming output and the full official SDK are outside its scope.

## For HolyC programs

```c
U8 *body = ApifyRunSync(token, "apify/hello-world", "{}");
if (body) {
  CJson *items = JsonParse(body);
  // Work with the dataset here.
  JsonFree(items);
  Free(body);
} else
  Print("%s\n", apify_last_error);
```

`ApifyUsersMe(token)` uses the same ownership convention: successful calls return an allocated JSON string; failures return `NULL` and set `apify_last_error`.

The library includes HolyNet through `B:/src/HolyNet`. The lab stages both repositories at that fixed guest path. [Architecture and API contracts →](docs/ARCHITECTURE.md)

## Real API, restricted guest

The lab's `--net apify` mode only forwards guest TCP traffic to `api.apify.com` on ports 80 and 443. There is no guest DNS in that mode. Set the relay address while keeping the real hostname for TLS SNI:

```c
ApifyViaAddress("10.0.2.100");
```

Use `--net mock` for the local fake API or `--net open` for general guest internet access. The default mode has no external service forwarding. `TOS_ISO` overrides the ISO location and `TOS_OUT` selects a separate RAM-backed output directory.

Keep real tokens out of source files and command history. The lab accepts runtime values through environment variables prefixed with `TOS_SECRET_`; they become named HolyC globals in `B:/Env.HC`.

The lab is headless: it runs an entry file, captures the terminal, and closes the VM. The snippets above are HolyC source, not Linux shell commands. Use the included [runnable example](examples/RunActor.HC) to look up your account and crawl one page. It sets the forwarding address, loads the runtime token, prints the results to the captured terminal and serial output, and reports failures to the launcher.

From the `holyapify` directory, in Bash:

```sh
read -rsp 'Disposable Apify token: ' TOS_SECRET_APIFY_TOKEN
printf '\n'
export TOS_SECRET_APIFY_TOKEN
lab/tos --net apify --timeout 420 examples/RunActor.HC
unset TOS_SECRET_APIFY_TOKEN
```

This makes a real, billable call to [Website Content Crawler](https://apify.com/apify/website-content-crawler/input-schema) with `https://example.com` and `maxCrawlPages: 1`. Edit the example to choose another Actor and input. The screenshot is `/dev/shm/templeos-net/out/last.png` unless you set `TOS_OUT`. Revoke the disposable token afterward. Server authentication is still absent.

To try the same example without an account or charges:

```sh
TOS_SECRET_APIFY_TOKEN=test-token lab/tos --net mock examples/RunActor.HC
```

## Tests

```sh
lab/tos --net mockplain tests/ApifyMock.HC
lab/tos --net mock tests/FrontMock.HC
lab/tos --net apify tests/ApifyReal.HC
lab/test-all
```

The client suite covers local API responses and the friendly command layer, plus real unauthenticated API errors. HolyNet maintains the separate crypto, TLS, HTTP, JSON and networking suite.

**Status:** all three client test entries pass. The included Actor example passes against the TLS mock and the real API: an authenticated one-page crawl returned one dataset item. Invalid-token requests also returned the expected HTTP 401 responses. [Current validation notes →](docs/STATUS.md)

## Credits

**Terry A. Davis** created TempleOS and HolyC. HolyApify is dedicated to his memory.

HolyNet supplies the network stack, cryptography, TLS, HTTP and JSON. Its network code derives from [Shrine](https://github.com/minexew/Shrine). [Dependency and third-party notices →](THIRD_PARTY_NOTICES.md)

No license is granted for original project code. Dependencies retain their existing terms. HolyApify is an independent, unofficial client, not endorsed by Apify or the TempleOS project.
