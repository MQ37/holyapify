# Validation status

## README replication checks

The linked HolyNet lab image built successfully, and a fresh TempleOS ISO download matched its documented SHA-256. Tests ran from fresh local clones with the pending changes applied, inside stock TempleOS VMs. The shell launchers ran inside a separate container controlling rootless Podman; that harness omitted the remote client's unsupported `--group-add keep-groups` flag. The shipped local launcher retains it.

The client suite passed all three entries: 23 plain API mock checks, 3 TLS frontend checks and 4 real-API checks using an invalid token. The included `examples/RunActor.HC` passed 2 checks over TLS with a runtime mock token and printed account details and dataset items. The real API returned HTTP 401 for both account lookup and Actor submission.

The same example passed both checks with a real token supplied at runtime: authenticated account lookup, then a one-page `apify/website-content-crawler` run against `https://example.com`. It returned one dataset item with title `Example Domain`. All client requests and TLS ran in HolyC inside the guest; the host relay copied TCP bytes. No token, account identifier, real-run screenshot or raw log was committed.

Actor calls now allow 310 seconds without response bytes instead of inheriting the transport's 60-second limit. A regression with a 100 ms transport timeout and a 500 ms delayed mock response passes with the fix and fails without it. The README documents the separate VM timeout and provides a complete runtime-token command.

Gitleaks 8.30.1 found no secrets in either repository's reachable committed history or working tree. A separate content scan found no owner names, personal paths or private infrastructure details; repository URLs intentionally contain the account handle. Logo PNGs contain no text or EXIF metadata. Git author/committer identity was inspected and deliberately retained at the owner's request.

## Repository split: current checks

All execution below took place in rootless Podman. HolyC checks ran in fresh stock TempleOS V5.03 VMs inside the container. The official ISO was downloaded in a container to RAM and matched the README's expected SHA-256.

| Check | Result |
|---|---|
| HolyNet TLS mock | 12 checks, TOS-DONE fail=0 |
| TLS handshake negative cases | 17 checks, TOS-DONE fail=0 |
| HolyApify plain API mock using the separate dependency | 22 checks, TOS-DONE fail=0 |
| HolyApify frontend using the separate dependency | 3 checks, TOS-DONE fail=0 |
| Frontend with deliberately unavailable TLS fixture | 3 failed checks and exit 1, as expected |
| Shared runner with a stub failing entry | Old runner exited 0; fixed runner exits 1 |
| Shared runner with all stub entries passing after a failure | Exit 0; stale failure markers cleared |
| Both container-control wrappers | Entry/mode arguments and readonly application mount verified with a stub |
| Shell and Python syntax | Passed |
| Repository content and preview | Local Markdown links, owner-name scan, absence of project license, embedded image and dedication checked |

The full VM suite has not been repeated after the split. The checks above exercise the modified staging path, the new full-library loader, and client integration. No authenticated production Actor run was made.

## Previous implementation session

The original combined project reported all 17 entries passing, including crypto vectors, HTTP/JSON, TLS, TCP/DNS and unauthenticated real-API requests. That is recorded session history, not a new full-suite result.

Real API tests returned expected HTTP 401 responses. A successful authenticated Actor run remains unverified. Some RFC vector values were transcribed through a summarizing fetch tool and have not all been checked byte-for-byte against the original publications. The TLS review was a source review, not an independent cryptographic audit.
