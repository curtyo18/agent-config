# UI prefs — frontend stack picks and code style

Directive frontend standards. Read this before starting any UI work. Stack picks first (what to reach for); dark mode and component-library policy next; code-level rules at the bottom (what to flag at review time). Voice throughout is imperative — an agent reading this should know what to do without further deliberation.

## Stack picks per category

- **Static content site** — When building a blog, docs site, or marketing page, use **Astro 6 with content collections and Tailwind v4**. Content collections give type-safe Markdown/MDX with schema validation; Astro ships near-zero JS by default. *Deviate when:* the site has zero interactivity, zero TypeScript, and you want a build pipeline that fits in your head — use **Eleventy 3** with Nunjucks/Markdown.

- **Mostly-static + sprinkled interactivity** — When building server-rendered HTML with a few interactive widgets, use **Astro 6 islands plus Alpine.js 3 for in-page reactivity, with Tailwind v4**. Astro hydrates only what's interactive; Alpine adds reactivity via `x-data` with no build step. *Deviate when:* the backend is Python/Ruby/Go/PHP and you want server-driven HTML fragments — use **htmx 2** over the existing template engine.

- **Small browser-side tool** — When building a single-purpose utility (regex tester, converter, scratchpad) with no backend, use **Vite 8 with vanilla TypeScript and Tailwind v4**. The `vanilla-ts` template scaffolds in one command; zero framework overhead. *Deviate when:* the tool grows past ~3 components with shared state — graduate to **Astro with a single React or Svelte island**, not a full SPA.

- **Internal tool / dashboard** — When building a forms-and-tables CRUD admin against an API, use **Vite 8 + React 19 + TanStack Router + TanStack Query + TanStack Table + shadcn/ui (Base UI primitives)**. Type-safe routing, search-param state, cache/refetch, and copy-into-repo components. *Deviate when:* you need server functions and SSR in the same project — use **TanStack Start** (still officially Release Candidate in mid-2026: API-stable and fine for personal projects, but not battle-tested — for content/SSR prefer Astro).

- **Genuine SPA** — When building a rich client-side app with deep state and complex routing, use **Vite 8 + React 19 + TanStack Router + TanStack Query + Zustand for client state + shadcn/ui**. *Deviate when:* bundle size and reactivity performance matter more than React ecosystem depth, and you want to break the React reflex — use **SvelteKit 2 with Svelte 5 runes**.

- **Chrome / browser extension** — The extension stack is owned by `commands/chrome-extension.md` — defer to it rather than duplicating (or contradicting) the decision here. (It mandates **WXT with Preact, no Tailwind**, matching the real extensions.)

## Dark mode — always dark

Every UI built under this standard is dark-only. Do not implement a light-mode toggle. Do not branch on `prefers-color-scheme`. Do not persist a theme to `localStorage`. There is no `data-theme` attribute. If a future project genuinely needs a light mode, that is a deliberate per-project decision — not the default, not assumed.

Set `color-scheme: dark` on `:root` so the browser paints native controls (scrollbars, form inputs, `<dialog>`) in dark from first paint, with no FOUC. Define the palette as CSS custom properties on `:root`. Done.

```css
:root {
  color-scheme: dark;
  --bg: #0b0b0c;
  --fg: #e7e7e9;
  --muted: #1a1a1d;
  --border: #2a2a2e;
  --accent: #6ea8fe;
}

body {
  background: var(--bg);
  color: var(--fg);
}
```

With Tailwind v4: skip `dark:` variants entirely. Configure the palette via `@theme` once in the main CSS file and use the standard utility classes — the design tokens themselves are dark.

## When to reach for a component library

**Trigger:** the build needs **three or more accessible interactive widgets** — dialog, combobox, menu, popover, tooltip, date picker, drawer — where keyboard navigation, focus management, and ARIA wiring are non-trivial. Below that bar, hand-rolled HTML + the native `<dialog>` element + Alpine for focus management is faster and lighter.

**Default pick when the trigger fires:** **shadcn/ui initialized with Base UI primitives** (`npx shadcn create` and pick Base UI). Base UI 1.0 (released Feb 2026 by the MUI team) ships components Radix lacks (Combobox, Drawer, OTPField), is actively maintained, and shadcn copies source into the repo so the components are owned, dark-themed, and Tailwind-configured in place. **Configure the generated components for dark only** — strip any theme-switcher boilerplate the CLI generates.

*Trade-off:* Base UI's pre-built block/template ecosystem is younger and thinner than Radix's. When a build leans on pasting whole pre-made sections (hero, pricing, dashboards) rather than composing primitives, initialise shadcn on **Radix** instead — still actively maintained (WorkOS), with the larger block library.

**Skip when:** the project needs at most one or two interactive elements — hand-roll with the native `<dialog>` element or Alpine + ARIA attributes.

## Avoid

- **Create React App** — officially deprecated by the React team in February 2025; no security patches, no React 19 support. Use **Vite** instead.
- **Webpack as a new choice** — State of JS 2025 shows a roughly 78-point net satisfaction gap with Vite; the configuration cost no longer earns its place outside legacy maintenance. Use **Vite** instead.
- **Reflex-reaching for Next.js on content sites** — Astro leads meta-framework satisfaction by 39 points on State of JS 2025; the App Router / RSC complexity is wrong-sized for blogs, docs, and marketing. Use **Astro** for content; reach for Next.js only when SSR / RSC are genuinely required.

## Code-level rules

These are the review-time rules the `/code-review` command checks against the diff. They complement (do not replace) the stack picks above.

### What to flag

- **Mixing styling approaches in the same component** — A component that mixes Tailwind utility classes with inline `style={{ ... }}` attrs, or CSS-in-JS alongside imported stylesheets, without a clear reason. Pick one approach per component. *Severity: Minor.*
- **Long `className` strings inline** — A `className` that runs past ~6 utility classes inline in JSX. Extract to a `const buttonClasses = "..."` near the component, a `clsx`/`cn` call with named groups, or a styled component. *Severity: Minor.*
- **Non-semantic HTML for interactive elements** — A `<div onClick={...}>` where `<button>` is the right tag; a top-level `<div>` where `<main>` / `<nav>` / `<section>` would carry meaning; nested `<div>` soup where a single semantic element would do. *Severity: Important.*
- **Missing `alt` on `<img>`** — Every `<img>` needs `alt`. Decorative images get `alt=""`; meaningful images get a real description. *Severity: Important.*
- **Form inputs without label association** — An `<input>` whose label is a sibling `<div>` rather than a `<label htmlFor={...}>` or a wrapping `<label>`. Screen readers can't follow it. *Severity: Important.*
- **Custom interactive elements without keyboard / focus support** — A `<div role="button" onClick={...}>` with no `tabIndex`, no `onKeyDown` for Enter/Space, no focus styles. Either use `<button>` or wire up all three. *Severity: Important.*
- **Components doing more than one thing in one file** — Two or more independently-mounted components defined in the same file, or a component plus its own state-management hook + its own data-fetching wrapper. Split them. *Severity: Minor.*
- **Light-mode code paths** — Any `prefers-color-scheme: light` block, any `data-theme="light"` selector, any theme-toggle component or `localStorage.getItem('theme')` call, when the project did not explicitly opt in to a light mode. This standard is dark-only. *Severity: Important.*

### What NOT to flag (pragmatism guard)

- Third-party component library wrappers that bring their own styling conventions (Radix, Base UI, Headless UI primitives). Don't impose the rules above on their internals.
- A `<div>` that genuinely has no semantic meaning — layout-only wrappers are fine.
- Tiny presentational components co-located in the same file as their parent when they're only used once and never tested independently.
- Server-rendered HTML for emails / PDFs / static pages where the accessibility rules above can be relaxed to whatever the target renderer supports.

### The bar

If a screen-reader user, a keyboard-only user, or the next agent reading the JSX would be measurably worse off, it's a finding. If it's a stylistic preference with no user-facing or maintainability consequence, it's a Minor at most.

## Sources

Verified mid-2026. One URL + tag each; justification lives inline with the picks above.

- Astro 6 / 6.3 — https://astro.build/blog/astro-6/ , https://astro.build/blog/astro-630/
- State of JS 2025 (Astro +39 vs Next; Vite ≫ Webpack; Svelte 5 runes, Alpine/htmx) — https://2025.stateofjs.com/en-US/libraries/
- CRA deprecation — https://react.dev/blog/2025/02/14/sunsetting-create-react-app
- Tailwind v4 dark mode — https://tailwindcss.com/docs/dark-mode ; `color-scheme` — https://developer.mozilla.org/en-US/docs/Web/CSS/color-scheme
- WXT (extension pick) — https://wxt.dev/releases ; htmx 2 — https://htmx.org/ ; Alpine 3 — https://alpinejs.dev/
- Base UI 1.0 (`@base-ui/react`, MUI-maintained) — https://github.com/mui/base-ui/releases ; shadcn Base UI init — https://ui.shadcn.com/docs/changelog ; Radix still maintained (WorkOS) — https://github.com/radix-ui/primitives
- TanStack Router 1.170 (active) / Start still RC — https://github.com/TanStack/router/releases , https://tanstack.com/start/latest
- Vite 8 — https://vite.dev/guide/migration ; Eleventy 3 — https://www.11ty.dev/docs/versions/
