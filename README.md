# Notely: broken on purpose

> [!CAUTION]
> **This app is DELIBERATELY INSECURE. Do not deploy it, and never put real data, real users or real API keys in it.**
> It is a practice target with 16 launch-blocking security flaws planted on purpose. Every key in this repo and its git history is fake, and the seed data uses `example.com` addresses. Run it on localhost only.

Notely is a tiny Next.js + Supabase + Stripe notes app, written the way an AI coding tool often writes one when nobody reviews it. It looks fine in the browser. Under the hood, a logged-out stranger can read everyone's notes, upgrade themselves to the paid plan, and open the admin page.

It's the sample app for the [Ship Check Kit](https://zephos.dev). Use it to try a security scanner, practice a review, or see what these bugs look like in real code before they show up in yours.

## Run it locally

You need Node 18+ and a local "Supabase". Pick one:

**Option A: Postgres + PostgREST, no Docker (what we test with)**

Supabase's Data API *is* PostgREST, so RLS, grants and the anon/service-role keys behave the same way. Install Postgres 15+ server binaries and [PostgREST](https://docs.postgrest.org/en/stable/explanations/install.html) 12+, then:

```bash
./local-stack/up.sh          # Postgres on :54322, Data API on http://127.0.0.1:54321/rest/v1, writes .env.local
npm install
npm run build && npm start   # http://127.0.0.1:3100
./local-stack/down.sh        # stop (add --reset to wipe the DB and keys)
```

`up.sh` generates a throwaway JWT secret plus anon, service-role and two test-user JWTs into `local-stack/keys.env` (git-ignored). Everything binds to 127.0.0.1.

**Option B: Supabase CLI (Docker)**

```bash
supabase init && supabase start   # applies supabase/migrations and supabase/seed.sql
cp .env.example .env.local        # fill in the URL and keys from `supabase status`
npm install && npm run build && npm start
```

## The 16 planted launch blockers

Check IDs are from the Ship Check Kit. All 16 are Tier 1 ("don't launch with this") and all 16 FAIL on this app.

| Check | What's wrong in Notely | Where |
|---|---|---|
| SC-SEC-01 | Supabase service-role key and a Stripe key committed in `.env`, then "deleted" in the next commit (still in history) | `git log -p -- .env` |
| SC-SEC-02 | Service-role key exposed to the browser via a `NEXT_PUBLIC_` env var and used in a client component | `lib/supabase.js`, `app/page.js` |
| SC-RLS-01 | `profiles` table has Row Level Security off | `supabase/migrations/` |
| SC-RLS-02 | The public anon key can read every profile and note | live Data API |
| SC-RLS-03 | `notes` select policy is `using (true)`, so user A can read user B's notes | `supabase/migrations/` |
| SC-RLS-04 | Users can write the privileged `plan` and `stripe_customer_id` columns on their own row (free to pro in one PATCH) | `supabase/migrations/` |
| SC-RLS-05 | `profile_directory` view runs without `security_invoker`, bypassing RLS | `supabase/migrations/` |
| SC-AUTH-01 | `/api/notes` never checks the session ("auth is handled on the frontend") | `app/api/notes/route.js` |
| SC-AUTH-02 | `/api/notes?user_id=` trusts whatever ID the caller sends | `app/api/notes/route.js` |
| SC-AUTH-03 | Admin role comes from a plain `session=admin` cookie anyone can set | `middleware.js` |
| SC-AUTH-04 | `/admin` is guarded only by middleware on `next@14.1.0`, bypassable with `x-middleware-subrequest` (CVE-2025-29927) | `middleware.js`, `package.json` |
| SC-ADM-01 | The admin page has no server-side role check of its own | `app/admin/page.js` |
| SC-PAY-01 | Stripe webhook never verifies the signature | `app/api/stripe/webhook/route.js` |
| SC-PAY-02 | Paid access is granted from whatever JSON the webhook receives, not verified Stripe data | `app/api/stripe/webhook/route.js` |
| SC-ENV-01 | `productionBrowserSourceMaps: true`, so your source is downloadable | `next.config.js` |
| SC-DEP-01 | Dependencies with known high/critical advisories: `next@14.1.0`, `lodash@4.17.20` | `package.json` |

Not counted above but also present (Tier 2): no Content-Security-Policy or baseline security headers, `X-Powered-By` on, no duplicate-event handling or access revocation in the webhook, and raw Postgres errors returned to clients.

## How to check your own app

A short version you can do in an afternoon. Only test apps and projects you own.

1. **Secrets in history.** `gitleaks git . --log-opts=--all`. Deleting a file doesn't remove it from history: rotate anything it finds at the provider first.
2. **Secrets in the browser.** `npm run build`, then search `.next/static` for `service_role`, `sk_live_`, `sb_secret_`. Any `NEXT_PUBLIC_` / `VITE_` var with `SECRET`, `SERVICE_ROLE` or `PRIVATE` in its name is public.
3. **The anon-key test.** With only your public anon key, `curl "$SUPABASE_URL/rest/v1/<table>?select=*" -H "apikey: $ANON_KEY"` for every table. Anything private that comes back is readable by the whole internet.
4. **The two-account test.** Sign in as user B and request user A's rows by ID, through your API and the Data API directly. Then try to PATCH your own `plan` / `role` column.
5. **Logged-out replay.** Copy a request from your browser's network tab, drop the cookies and `Authorization` header, and replay it. It should fail.
6. **Unsigned webhook.** POST a made-up `checkout.session.completed` event to your webhook with no `Stripe-Signature`. It should get a 400, not a 200.
7. **Headers, source maps, dependencies.** `curl -sI https://your.app`, look for `.js.map` files under `/_next/static`, and run `npx osv-scanner` or `npm audit` on your lockfile.

The **[Ship Check Kit](https://zephos.dev)** ($29) runs all of this and more for you: 44 checks with stable IDs, terminal recipes, and a Claude Code skill / Cursor rule that reviews your code, probes your live app and Supabase project, and writes a `SHIP-CHECK.md` report with a verdict and evidence. It's what produced the table above, and it includes the fixed version of Notely so you can see each fix.

## License

[MIT](LICENSE). Point-in-time teaching material, not a penetration test or a guarantee.
