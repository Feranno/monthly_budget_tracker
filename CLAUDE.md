# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A no-build, no-dependency static site — two HTML files with all CSS and JS inline. Deployed on Vercel.

## Running locally

Open either HTML file directly in a browser, or use any static file server:

```bash
npx serve .
# or
python3 -m http.server 8080
```

The Vercel rewrite rules (`vercel.json`) map `/` → `index.html` and `/auth` → `auth.html`. When running locally without Vercel CLI, navigate directly to the file paths instead.

## Deployment

Push to the connected Vercel project. No build step — Vercel serves the static files directly.

## Architecture

Everything lives in two HTML files with no external JS bundles:

- **`auth.html`** — Authentication page. Three togglable forms (sign-in, sign-up, forgot-password) backed by Supabase Auth. On load, redirects to `/` if a session already exists.
- **`index.html`** — Main app. Checks for a Supabase session on init and redirects to `/auth` if none. All app logic is a single `state` object mutated in-place and persisted on every change.

### State shape (`index.html`)

```js
state = {
  goal: { name, target, saved } | null,
  categories: string[],           // ordered list; default 10 categories
  months: {
    "YYYY-MM": {
      income: number,
      budgets: { [category]: number },
      expenses: [{ id, name, cat, amt, date }],
      sinking: { [category]: number }  // annual cost; auto-divides to monthly budget
    }
  }
}
```

### Persistence

- **Supabase** (when logged in): debounced upsert (800 ms) to a `budget_data` table with columns `user_id`, `data` (jsonb), `updated_at`. Single row per user — entire `state` object stored as JSON.
- **`localStorage`** key `budget_v3`: fallback when Supabase credentials aren't present or no user is logged in.

### Supabase credentials

Both files hardcode the same `SUPABASE_URL` and `SUPABASE_ANON` key. They are public anon keys (safe to commit), but if rotating them, update both files.

### Render cycle

`render()` is the single entry point for all UI updates. It delegates to `renderGoal()`, `renderCatSelect()`, and one of `renderTrack()` / `renderPlan()` / `renderHistory()` depending on the active tab. There is no virtual DOM or reactive framework — DOM is rebuilt via `innerHTML` on every render call.

### Known issue

`deleteGoal` is defined twice in `index.html` (lines 613–614). The second definition silently overrides the first; both are identical so it's harmless, but the duplicate should be removed if editing that area.
