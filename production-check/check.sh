#!/usr/bin/env bash
# Read-only production check for https://avazkhoneh.com
# ~17 small GET/HEAD requests, one 64 KB audio range read twice, one JS bundle download.
# No logins, no writes, no load. Everything it learns goes to production-check/RESULT.md.
set -u
HOST=${HOST:-https://avazkhoneh.com}
OUT=${1:-production-check}
mkdir -p "$OUT/raw"
UA='avaz-audit-check/1.1 (read-only verification requested by the site owner)'
c() { curl -sS --max-time 30 -A "$UA" "$@"; }
R="$OUT/RESULT.md"
{
echo "# Production check (read-only) — $(date -u +%Y-%m-%dT%H:%M:%SZ) UTC"
echo
echo "Egress: $(curl -sS --max-time 8 -o /dev/null -w '%{http_code}' -A "$UA" "$HOST/api/health" 2>&1 || true)"
echo
echo "## 1. DNS (as seen from the checking host)"
echo '```'; getent ahosts avazkhoneh.com | awk '{print $1}' | sort -u; echo '```'
echo
echo "## 2. Home page — status, timing, headers"
echo '```'; c -o "$OUT/raw/home.html" -D "$OUT/raw/home.headers" -w 'http=%{http_code} time=%{time_total}s remote=%{remote_ip} size=%{size_download}\n' "$HOST/"; cat "$OUT/raw/home.headers"; echo '```'
echo
echo "## 3. Redirects"
echo '```'
printf 'http://  -> '; c -o /dev/null -w 'http=%{http_code} location=%{redirect_url}\n' "http://avazkhoneh.com/"
printf 'www     -> '; c -o /dev/null -w 'http=%{http_code} location=%{redirect_url}\n' "https://www.avazkhoneh.com/"
echo '```'
echo
echo "## 4. /api/health"
echo '```'; c -w '\nhttp=%{http_code} time=%{time_total}s\n' "$HOST/api/health"; echo '```'
echo
echo "## 5. /api/songs — catalogue served by the live API"
c -o "$OUT/raw/songs.json" -w 'http=%{http_code} time=%{time_total}s size=%{size_download}\n' "$HOST/api/songs" | sed 's/^/    /'
python3 - "$OUT/raw/songs.json" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding='utf-8'))
except Exception as e:
    print('    songs.json is not JSON:', e); sys.exit(0)
songs = d.get('songs', d) if isinstance(d, dict) else d
ids = [s.get('id') for s in songs]
print(f'    count: {len(songs)}')
print(f'    ids: {", ".join(map(str, ids))}')
print(f'    omid-baran-2 present: {"omid-baran-2" in ids}')
first = next((s for s in songs if s.get('audioUrl')), None)
open(sys.argv[1] + '.audio', 'w').write(first['audioUrl'] if first else '')
PY
echo
echo "## 6. robots.txt and sitemap.xml"
echo '```'
c -o "$OUT/raw/robots.txt" -w 'robots: http=%{http_code} size=%{size_download}\n' "$HOST/robots.txt"; grep -ci '^disallow' "$OUT/raw/robots.txt" | sed 's/^/disallow lines: /'
c -o "$OUT/raw/sitemap.xml" -w 'sitemap: http=%{http_code} size=%{size_download}\n' "$HOST/sitemap.xml"; grep -o '<loc>' "$OUT/raw/sitemap.xml" | wc -l | sed 's/^/sitemap urls: /'
echo '```'
echo
echo "## 7. JS bundle — name, compression, caching, and which commits it contains"
BUNDLE=$(grep -oE 'assets/index-[A-Za-z0-9_-]+\.js' "$OUT/raw/home.html" | head -1)
echo "bundle: \`$BUNDLE\`"; echo "$BUNDLE" > "$OUT/raw/bundle-name.txt"
echo '```'
c -I -H 'Accept-Encoding: gzip, br' "$HOST/$BUNDLE" | grep -iE '^(HTTP|content-encoding|cache-control|cf-cache-status|content-length|etag|age)'
c -o "$OUT/raw/bundle.js" -w 'download: http=%{http_code} size=%{size_download} time=%{time_total}s\n' "$HOST/$BUNDLE"
echo '```'
echo
echo "Fingerprint strings added by each commit after the last documented deploy (91acbfd), in commit order; present = that commit (or a later one that kept the string) is live:"
echo
echo '| Commit | Marker | In live bundle |'
echo '|---|---|---|'
while IFS='|' read -r commit marker; do
  if grep -q -F -e "$marker" "$OUT/raw/bundle.js"; then hit=yes; else hit=no; fi
  echo "| $commit | \`$marker\` | $hit |"
done <<'MARKERS'
e5d17da|فایل صوتی با بیت‌ریت متغیر
478b64e|California, CA
8ba30cc|avaz-hide-nav-singing
4d2e330|fixed z-[60] bg-black/70 backdrop-blur-[3px]
a111516|<ellipse cx=
ec63724|صدا را برگردان
4e89927|absolute left-0 top-1/2 hidden -translate-y-1/2 sm:flex
fa3f907|block truncate text-[11px] text-white/45
37d3507|btn-ghost inline-flex items-center gap-2 !py-2 text-sm
ab4c751|var(--ribbon-coming, #8B7CAE)
MARKERS
rm -f "$OUT/raw/bundle.js"
echo
echo "## 8. One audio file — headers, edge caching (same 64 KB range requested twice)"
AUDIO=$(cat "$OUT/raw/songs.json.audio" 2>/dev/null); rm -f "$OUT/raw/songs.json.audio"
echo "file: \`$AUDIO\`"
echo '```'
for i in 1 2; do
  echo "request $i:"; c -o /dev/null -D - -r 0-65535 -w 'http=%{http_code} time=%{time_total}s\n' "$HOST$AUDIO" | grep -iE '^(HTTP|content-type|content-length|content-range|accept-ranges|cache-control|cf-cache-status|age|etag|last-modified|server|http=)'
done
echo '```'
echo
echo "## 9. One prerendered song page and one artist page"
echo '```'
FIRST=$(python3 -c "import json,sys; d=json.load(open('$OUT/raw/songs.json',encoding='utf-8')); s=d.get('songs',d); print(s[0]['id'] if s else '')" 2>/dev/null)
c -o "$OUT/raw/song-page.html" -D - -w 'http=%{http_code} time=%{time_total}s size=%{size_download}\n' "$HOST/song/$FIRST" | grep -iE '^(HTTP|cache-control|cf-cache-status|content-encoding|http=)'
grep -oE '<title>[^<]*</title>' "$OUT/raw/song-page.html" | head -1
echo '```'
echo
echo "## 10. Anonymous access to protected APIs (expect 401/403, never 200)"
echo '```'
for p in /api/auth/me /api/studio/overview /api/analytics/summary /api/dev/jobs; do
  printf '%-28s ' "$p"; c -o /dev/null -w 'http=%{http_code}\n' "$HOST$p"
done
echo '```'
echo
echo "## 11. Security headers on the HTML origin"
echo '```'; grep -iE '^(strict-transport|content-security|x-frame|x-content-type|referrer-policy|permissions-policy|server|cf-ray|cf-cache-status|cf-mitigated|x-powered-by)' "$OUT/raw/home.headers" || echo '(none of the expected headers found)'; echo '```'
echo
echo "## 12. TLS at the edge"
echo '```'; curl -sS --max-time 20 -A "$UA" -vI "$HOST/" 2>&1 | grep -iE 'subject:|issuer:|SSL connection|expire' | head -5; echo '```'
echo
echo "Requests made: 17 small GET/HEAD + 1 bundle download + 2 × 64 KB audio range. No writes, no logins."
} > "$R" 2>&1
rm -f "$OUT/raw/home.html" "$OUT/raw/song-page.html"
echo "wrote $R"
