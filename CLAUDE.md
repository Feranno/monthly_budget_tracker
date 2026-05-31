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

### Key helpers (`index.html`)

- **`gm(key?)`** — "get month". Returns (and lazily creates) the month object for `currentMonth` or the given key. All reads/writes to per-month data go through this.
- **`fmt(n, short?)`** — formats a number as currency. `short=true` condenses values ≥ $1000 to `$1.2k`.
- **`spentBycat(key?)`** — returns `{ [category]: totalSpent }` for the given month.

### Sinking funds

In the Plan tab, each category has an optional "Annual / sinking" input. When a value is entered, `setSinking()` automatically overwrites the monthly budget field with `annual / 12`. This is intentional — the two columns are linked and the annual column wins.

### Trade-off modal

When `addExpense()` pushes a category over budget, `showTradeoff()` fires instead of a plain `render()`. It opens a "Roll with the punches" modal listing other categories with remaining budget, letting the user move money between categories via `doTransfer()`. Closing without acting skips the rebalance but the overspend remains.

### `auth.html` forms

Four forms share the same card, only one visible at a time: `form-signin`, `form-signup`, `form-reset`, `form-newpass`. Visibility is toggled via `display:none/block` — no framework.

The `PASSWORD_RECOVERY` flow requires `onAuthStateChange` to be registered **before** `getSession()` is called; the event fires synchronously on page load when following a reset link. The redirect guard checks `window.location.hash.includes('type=recovery')` to avoid auto-redirecting to `/` during a recovery session.

### Render cycle

`render()` is the single entry point for all UI updates. It delegates to `renderGoal()`, `renderCatSelect()`, and one of `renderTrack()` / `renderPlan()` / `renderHistory()` depending on the active tab. There is no virtual DOM or reactive framework — DOM is rebuilt via `innerHTML` on every render call.

### Design system

CSS custom properties (defined in `:root` in `index.html`) are the only theming mechanism. Key tokens: `--bg` (warm off-white), `--surface` (white), `--accent` (terracotta — used only for warnings/over-budget), `--ok` (green). Two fonts: `EB Garamond` (serif, used for headings and large numbers) and `Geist Mono` (monospace, everything else).