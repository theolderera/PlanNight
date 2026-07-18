# PlanNight — Improvement backlog (prioritized)

> Reviewed 2026-07-18 after a full line-by-line read of both stacks. Ordered by
> (user value × risk reduction) / effort. Effort: S < ½ day · M ≈ 1–2 days ·
> L ≈ a week. Check items off (and prune) as they land.

## P0 — security & trust (do before inviting any real users)

1. **HTTPS** (M). Credentials and JWTs currently cross the network in
   cleartext to `91.227.40.11:8080`. Free subdomain (DuckDNS) → host nginx
   `server_name` block proxying to 127.0.0.1:8080 (`deploy/nginx.conf.example`
   is ready) → certbot. Then: rebuild APK with `https://…/api`, drop the server
   IP from the cleartext allowlist, and turn off port 8080's public exposure
   (bind 127.0.0.1). *Care: nginx :80 is shared with storeos — add a server
   block, don't replace config.*
2. **Refresh-token revocation** (M). Tokens are stateless: logout/theft cannot
   be invalidated server-side for up to 30 days. Add `refresh_tokens` table
   (token-id, user, expiry, revoked) — the `/auth/refresh` service already has
   the seam (its doc comment anticipates this). Rotate on use, revoke on
   logout, "log out everywhere" becomes possible.
3. **Backend test suite + CI** (M). Zero backend tests today; every fix is
   hand-verified with curl. supertest + a disposable Postgres (compose) over:
   auth flows (409/401/timing dummy), task CRUD + ownership isolation
   (user A cannot touch user B), reschedule transaction, idempotent
   create/generate, sync deltas incl. soft-deletes, stats/streak edge days.
   GitHub Action: backend tests + `flutter analyze` + `flutter test`.
4. **Real release keystore** (S). APK signs with the debug key — any Play
   upload or update-in-place across machines will break. Generate an upload
   keystore + `key.properties` (git-ignored), wire `signingConfigs.release`.
5. **DB backups** (S). MVPS auto-backup is whole-VPS only. Nightly
   `pg_dump | gzip` cron inside the db container volume + copy off-box (even
   to the dev PC via scp). Test one restore.

## P1 — product polish (biggest daily-use wins)

6. **Evening "plan tomorrow" reminder** (S). The product's core ritual has no
   nudge. One daily local notification (configurable time, default ~21:00,
   off-switch in Settings) deep-linking to /plan. Highest value-per-line in
   the backlog.
7. **Swipe gestures on tasks** (S). `Dismissible` on TaskTile: swipe right =
   done/undone, left = skip. Check-off is the most frequent action; today it
   needs a precise icon tap.
8. **Drag-to-reorder within a day** (M). `sort_order` exists end-to-end but no
   UI sets it — `ReorderableListView` on Today/Plan, persist via the normal
   update path (works offline for free).
9. **Offline stats parity** (M). Stats screens 404 without network even though
   the cache holds every task. Compute summary/streak locally from drift
   (mirroring `stats.service.js` semantics — incl. the today-grace rule and
   rescheduled exclusion) and use the API only as refresh. Also kills the
   only "needs a connection" card in the app.
10. **First-run onboarding seed** (S). Empty Today + empty categories is a cold
    start. After register: offer 3–4 starter categories (localized names) and
    a sample template, or a dismissible 3-step intro card.
11. **Streak surfacing** (S). Streak lives only in Stats. Show a small flame +
    count on Today's app bar; celebrate crossing milestones. The discipline
    loop needs its feedback where the user acts.
12. **Sync status detail** (S). The cloud-badge shows pending count only. Add
    "last synced HH:MM / offline / error"-style subtitle in Settings, and a
    manual "sync now" (pull-to-refresh on Today).

## P2 — worthwhile, not urgent

13. **Account management** (M): change password (revoking refresh tokens — 
    depends on #2), delete account (cascade wipes all rows; required for any
    store listing).
14. **Day timeline view** (L): `durationMinutes` is collected but only shown as
    a number. An hour-axis day view with task blocks would visualize the plan
    — flagship UX work, prototype after P1 lands.
15. **Task search / backlog** (M): find past tasks by title; a dated-someday
    list for unscheduled ideas (schema change: nullable plan_date or a flag).
16. **Server log hygiene + uptime ping** (S): docker json-file log rotation
    (`max-size`), healthchecks.io cron on /health, optional Sentry in the app.
17. **flutter_timezone KGP migration** (S, timed): plugin still applies the
    Kotlin Gradle Plugin; future Flutter will refuse to build. Watch for a
    Built-in-Kotlin release and bump.
18. **iOS build** (L): code is portable (secure storage, notifications, tz all
    have iOS paths); needs a Mac + provisioning. Only if iPhone users appear.
19. **Localized backend validation prose** (S): zod messages are English; the
    client pre-validates so users rarely see them — low priority, or map
    `VALIDATION_ERROR` details client-side.
20. **Unpin drift/sqlparser** (S, timed): when upstream fixes the
    drift_dev/sqlparser break (see mobile/NOTES.md), unpin and drop the
    override.

## Deliberately NOT planned

- ORM/TypeScript rewrite (teaching codebase; raw SQL is a feature)
- CRDT/merge sync (single-user LWW is correct here)
- Push-notification infra (local notifications cover the use case without a
  server dependency)
- Web target (drift/web + wasm complexity, no current user need)
