# Production check (read-only)

`check.sh` performs a bounded, read-only verification of https://avazkhoneh.com for the
audit report in the repository root: DNS, response headers, redirects, `/api/health`,
the public catalogue, robots/sitemap, the JS bundle's commit fingerprints (which
commits after the last documented deploy are live), audio caching headers, a prerendered
page, anonymous access to protected APIs, security headers and edge TLS.

It sends about twenty small requests, never logs in, never writes, and never loads the
site. Results land in `RESULT.md` next to it; raw headers and bodies in `raw/`.

Run: `bash production-check/check.sh production-check`
