You are Claude Code running in my terminal on my PC. This PC has the `avaz-khoneh` repository checked out, can reach the live site https://avazkhoneh.com, and can reach the DigitalOcean droplet that serves it over SSH (ask me for the SSH command or alias if it is not already configured). If this terminal is PowerShell, run the bash scripts below through Git Bash or WSL.

I am the founder and owner of Avaz Khoneh (آوازخونه), a Persian karaoke web app: Node 22 + Express + node:sqlite API, React/Vite client, nginx + certbot on a 1 vCPU / 1 GB Ubuntu droplet at /var/www/avazkhoneh (systemd unit avazkhoneh.service), Cloudflare proxying the domain, and a Python audio pipeline (Demucs, alignment, pitch) that runs only on this PC.

## What has already been done (by a previous cloud session on 2026-09-12)

1. A full system audit and capacity report was written against `am-amani/avaz-khoneh` at commit `ab4c751` (main, 2026-09-12 10:08): a code review of server and client, 108 API checks and 20 job/crash checks on an isolated instance, 59 browser captures, and a 17-run load matrix on one CPU core. That session could only push to another repository, so the report lives here:
   https://github.com/am-amani/best-of-robot-simulators/blob/claude/avaz-khoneh-system-audit-eiij5v/FULL_SYSTEM_AUDIT_AND_CAPACITY_REPORT.md
   Raw file: https://raw.githubusercontent.com/am-amani/best-of-robot-simulators/claude/avaz-khoneh-system-audit-eiij5v/FULL_SYSTEM_AUDIT_AND_CAPACITY_REPORT.md
   The same branch has `production-check/check.sh`, a read-only script that verifies the live site with about twenty small requests (no logins, no writes, no load):
   https://raw.githubusercontent.com/am-amani/best-of-robot-simulators/claude/avaz-khoneh-system-audit-eiij5v/production-check/check.sh
2. That session could NOT reach the production server or the live site (its sandbox network policy blocked the domain), so every statement about production in the report is marked "[unverified on the box]" and comes with the command that confirms it (Appendix B). The one production fact it verified from outside: avazkhoneh.com resolves to Cloudflare anycast addresses, so the zone is proxied by Cloudflare.
3. NOTHING has been fixed and NOTHING has been deployed. No code in avaz-khoneh was changed. The last commit confirmed live on the site is `91acbfd` (2026-09-11). The 16 commits on main after it (the owner's Studio, the stage control bar and settings menu, avatars, the variable-bitrate seek fix, docs) have unknown deploy status.

Key findings you must know (evidence, IDs and details are in the report; read sections 1, 3, 17 and 19 first):
- B-1 High: two editors saving the same song's lyrics silently overwrite each other; undo snapshots coalesce within 2 minutes regardless of author.
- B-2 High: `DELETE /api/dev/songs/:id/permanent` destroys audio, lyrics, comments and snapshots of a song that is NOT in the trash and leaves a zombie catalogue row.
- B-3 High: lyric edits made on the droplet exist only on its disk inside a git working tree (`server/songs`); one live song (`omid-baran-2`) exists nowhere else; database, backups and audio share one disk; there is no off-site backup.
- S-1 / B-27 High: Cloudflare is in front and `deploy/nginx.conf` has no real-IP handling, so with `trust proxy 1` the API's rate limiters key on Cloudflare edge IPs (site-wide login lockouts as traffic grows).
- B-32 High: the systemd unit runs with the default 1,024 open files; roughly 450 to 500 simultaneous audio streams start failing (measured 6.6 % errors at 600).
- C-1 High: nginx proxies `/audio` through Node instead of serving the files; the origin sends `Cache-Control: max-age=0`, so Cloudflare caches no audio.
- Medium: no JWT revocation on logout or password change (B-5); the log file name is fixed at boot so the 14-day prune never rotates it (B-6); saving Settings right after a password login wipes date of birth and phone (B-9); "NaN دقیقه پیش" timestamps in the Studio (B-10); the phone stage settings menu opens at the top of the stage because one element with one ref is rendered twice (B-4).

## What I need you to do now, in this order

Rules: read-only first; take backups before any change; never run load tests against production; never paste secrets (.env contents, tokens, keys) into chat or into files; make one change at a time, verify it, commit it; run `npm test` in server/ and client/ before any deploy; ask me before anything destructive (deleting files, resizing the droplet, firewall changes, force pushes).

### Step 1 — Put the report into this project
Download the report (raw URL above) to `docs/reports/FULL_SYSTEM_AUDIT_AND_CAPACITY_REPORT.md` and the check script to `tools/production-check.sh`. Commit both on a new branch `audit/2026-09-12`.

### Step 2 — Verify production (read-only) and correct the report
a) From this PC run `bash tools/production-check.sh production-check` and read `production-check/RESULT.md`. Its section 7 tests the live JS bundle for strings each post-`91acbfd` commit introduced; that pins down the deployed commit.
b) On the droplet over SSH run every command in Appendix B of the report: the live commit and whether the tree is dirty in /var/www/avazkhoneh, `systemctl show avazkhoneh -p LimitNOFILE`, `grep -r real_ip /etc/nginx/`, nginx worker_connections and gzip, ownership of server/data/, the backups directory and the crontab, disk, memory, log sizes, `journalctl --disk-usage`.
c) Update section 3 of the report with what you found, replacing each "[unverified on the box]" with the verified fact. Then tell me: the deployed commit, whether the tree on the box has local lyric edits, whether backups exist and how old, the file-descriptor limit, and whether nginx restores the real client IP.

### Step 3 — Secure the production-only data BEFORE deploying anything
- Copy from the droplet to this PC with rsync or scp: `server/data/` (database, WAL and backups), `server/songs/`, `server/dev-data/pitch-drafts/`, `server/public/audio/`. Keep the copy outside the repository and tell me its path and size.
- If `git status` on the droplet shows modified or untracked files under server/songs or server/dev-data, bring them into the repository (commit them on the audit branch) so `omid-baran-2` and any on-box lyric edits no longer exist only on the droplet.

### Step 4 — Deploy main (`ab4c751` or newer) following docs/DEPLOY.md
Only after Step 3 is complete. `git pull`, `npm ci`, build, restart, then check `/api/health`, one song page and the Studio in a browser. The build's prerender opens the production database, so run the build as the service user, not root, and check `ls -l server/data/` afterwards: a root-owned WAL file breaks the service (report B-26).

### Step 5 — Apply the "Now" fixes from section 19 of the report
Infrastructure (on the droplet, mirrored in the files under deploy/):
1. `LimitNOFILE=65536` in the systemd unit (deploy/avazkhoneh.service and /etc/systemd/system), then daemon-reload and restart.
2. nginx: serve `/audio/` directly (`alias` to server/public/audio, `sendfile on`, `Cache-Control: public, max-age=86400`); raise `worker_connections`; add Cloudflare real-IP handling (`set_real_ip_from` for Cloudflare's published IPv4 and IPv6 ranges plus `real_ip_header CF-Connecting-IP`); keep `trust proxy 1` in the API. Verify: `curl -sI https://avazkhoneh.com/audio/<file>.mp3 | grep -i cf-cache-status` should be HIT on the second request, and the API request log should show visitor IPs rather than Cloudflare's.
3. Nightly off-site backup: the database via `VACUUM INTO`, plus songs, drafts and audio, to DigitalOcean Spaces or any S3-compatible bucket using rclone or s3cmd, cron at 03:00, 30-day retention. Then do ONE test restore into a scratch directory and prove the restored database opens. Add a backup-age check to the health endpoint or the Studio.
4. An external uptime monitor (free tier) on `/api/health`, plus a disk-space alert and a CPU alert. If Cloudflare's Bot Fight Mode blocks the monitor, add a WAF skip rule for it.
Code (in avaz-khoneh, one commit each, with tests):
5. B-2: permanent delete only for songs already in the trash, owner-only, and remove the catalogue row in the same transaction as the files.
6. B-1: optimistic concurrency on lyric saves (the client sends the version or updated_at it loaded; the server answers 409 on mismatch and the editor shows a reload prompt); never coalesce snapshots across different users.
7. B-5: a `token_version` on the user, bumped on password change, password reset and logout; reject older JWTs.
8. `/api/health` returns the deployed commit hash, read once at boot from `git rev-parse` or from a file written by the build.
9. The small fixes B-4, B-9, B-10 and B-6 exactly as described in section 17.

### Step 6 — Report back
Update `docs/reports/FULL_SYSTEM_AUDIT_AND_CAPACITY_REPORT.md` section 17 with a status column (fixed, deployed, or open) and give me a short summary: the deployed commit before and after, what was backed up and where, which fixes are live, what remains open, and anything you found on the box that the report got wrong.
