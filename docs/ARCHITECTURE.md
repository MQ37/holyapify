# HolyApify architecture

HolyNet supplies the complete network/crypto/TLS/HTTP/JSON stack. Keep it beside this repository, or set HOLYNET_DIR. The local launcher sets TOS_APP_DIR and invokes the dependency's lab; both trees are staged to the same guest RAM drive without changing library includes.

| Path | Responsibility |
|---|---|
| src/Apify/Apify.HC | API requests, auth header, Actor identifier validation and errors |
| src/HolyApify.HC | Single application loader and friendly terminal commands |
| tests/ | Plain mock, TLS frontend and real unauthenticated API checks |
| examples/ | Runnable Actor example using a runtime token |
| lab/ | Container-control wrappers for the shared HolyNet lab |

## API

- `ApifyToken(token)` copies the token into guest RAM.
- `ApifyMe()` prints account username and plan.
- `ApifyRun(actor, input=NULL)` prints a synchronous run's dataset; NULL input means `{}`.
- `ApifyUsersMe(token)` returns allocated JSON or NULL.
- `ApifyRunSync(token, actor, input)` returns allocated dataset JSON or NULL.
- `apify_last_error` holds the last error. Callers Free successful JSON strings.
- `ApifyViaAddress(ip)` sets the lab's forwarding address without changing the API hostname sent in SNI.
- `ApifyUsePlain(host, port)` selects plain TCP for local mock tests only.

The client calls GET /v2/users/me and POST /v2/acts/{actor}/run-sync-get-dataset-items with an Authorization bearer header. JSON error messages include the HTTP status. HolyNet caps response bodies at 8 MiB; the synchronous endpoint has a 300-second ceiling. Actor calls raise the socket read timeout to 310 seconds; callers must also raise the lab's VM timeout when needed.

## Security

TLS is encrypted but does not authenticate certificates. The included Actor example has completed an authenticated one-page crawl against the real API; this is a functional check, not a cryptographic audit.
