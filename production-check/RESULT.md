NETWORK BLOCKED from the checking environment: every request to avazkhoneh.com failed with `curl: (56) CONNECT tunnel failed, response 403` (proxy egress denied), so no result below reflects the live site.

# Production check (read-only) — 2026-09-12T20:43:57Z UTC

Egress: curl: (56) CONNECT tunnel failed, response 403
000

## 1. DNS (as seen from the checking host)
```
104.21.37.187
172.67.212.104
```

## 2. Home page — status, timing, headers
```
curl: (56) CONNECT tunnel failed, response 403
http=000 time=0.239007s remote=127.0.0.1 size=0
HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Content-Length: 72
Connection: close

```

## 3. Redirects
```
http://  -> http=403 location=
www     -> curl: (56) CONNECT tunnel failed, response 403
http=000 location=
```

## 4. /api/health
```
curl: (56) CONNECT tunnel failed, response 403

http=000 time=0.254991s
```

## 5. /api/songs — catalogue served by the live API
curl: (56) CONNECT tunnel failed, response 403
    http=000 time=0.219511s size=0
    songs.json is not JSON: [Errno 2] No such file or directory: 'production-check/raw/songs.json'

## 6. robots.txt and sitemap.xml
```
curl: (56) CONNECT tunnel failed, response 403
robots: http=000 size=0
grep: production-check/raw/robots.txt: No such file or directory
curl: (56) CONNECT tunnel failed, response 403
sitemap: http=000 size=0
grep: production-check/raw/sitemap.xml: No such file or directory
sitemap urls: 0
```

## 7. JS bundle — name, compression, caching, and which commits it contains
grep: production-check/raw/home.html: No such file or directory
bundle: ``
```
curl: (56) CONNECT tunnel failed, response 403
HTTP/1.1 403 Forbidden
Content-Length: 72
curl: (56) CONNECT tunnel failed, response 403
download: http=000 size=0 time=0.280318s
```

Fingerprint strings added by each commit after the last documented deploy (91acbfd), in commit order; present = that commit (or a later one that kept the string) is live:

| Commit | Marker | In live bundle |
|---|---|---|
grep: production-check/raw/bundle.js: No such file or directory
| e5d17da | `فایل صوتی با بیت‌ریت متغیر` | no |
grep: production-check/raw/bundle.js: No such file or directory
| 478b64e | `California, CA` | no |
grep: production-check/raw/bundle.js: No such file or directory
| 8ba30cc | `avaz-hide-nav-singing` | no |
grep: production-check/raw/bundle.js: No such file or directory
| 4d2e330 | `fixed z-[60] bg-black/70 backdrop-blur-[3px]` | no |
grep: production-check/raw/bundle.js: No such file or directory
| a111516 | `<ellipse cx=` | no |
grep: production-check/raw/bundle.js: No such file or directory
| ec63724 | `صدا را برگردان` | no |
grep: production-check/raw/bundle.js: No such file or directory
| 4e89927 | `absolute left-0 top-1/2 hidden -translate-y-1/2 sm:flex` | no |
grep: production-check/raw/bundle.js: No such file or directory
| fa3f907 | `block truncate text-[11px] text-white/45` | no |
grep: production-check/raw/bundle.js: No such file or directory
| 37d3507 | `btn-ghost inline-flex items-center gap-2 !py-2 text-sm` | no |
grep: production-check/raw/bundle.js: No such file or directory
| ab4c751 | `var(--ribbon-coming, #8B7CAE)` | no |

## 8. One audio file — headers, edge caching (same 64 KB range requested twice)
file: ``
```
request 1:
curl: (56) CONNECT tunnel failed, response 403
HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=utf-8
Content-Length: 72
http=000 time=0.235165s
request 2:
curl: (56) CONNECT tunnel failed, response 403
HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=utf-8
Content-Length: 72
http=000 time=0.253993s
```

## 9. One prerendered song page and one artist page
```
curl: (56) CONNECT tunnel failed, response 403
HTTP/1.1 403 Forbidden
http=000 time=0.236365s size=0
grep: production-check/raw/song-page.html: No such file or directory
```

## 10. Anonymous access to protected APIs (expect 401/403, never 200)
```
/api/auth/me                 curl: (56) CONNECT tunnel failed, response 403
http=000
/api/studio/overview         curl: (56) CONNECT tunnel failed, response 403
http=000
/api/analytics/summary       curl: (56) CONNECT tunnel failed, response 403
http=000
/api/dev/jobs                curl: (56) CONNECT tunnel failed, response 403
http=000
```

## 11. Security headers on the HTML origin
```
X-Content-Type-Options: nosniff
```

## 12. TLS at the edge
```
```

Requests made: 17 small GET/HEAD + 1 bundle download + 2 × 64 KB audio range. No writes, no logins.
