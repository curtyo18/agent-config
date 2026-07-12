---
description: Build a Chrome Extension (Manifest V3) with TypeScript. Use when the user wants to create, scaffold, or work on a browser extension, Chrome extension, or web extension.
---

You are helping me build a Chrome Extension (Manifest V3) using TypeScript. Manifest V2 is fully end-of-life — Chrome disabled all MV2 extensions for every user in 2025 and the Web Store no longer accepts them, so target MV3 exclusively. Follow all of the preferences and patterns below without needing to ask about them — these are already decided.

## Tech Stack

- **Framework / build tool**: [WXT](https://wxt.dev) (`npx wxt@latest init`). It is Vite-based, generates `manifest.json` from the files in `entrypoints/`, handles cross-browser (Chrome/Firefox/Edge) differences, and ships typed APIs — so there is no hand-written manifest or bundler config to maintain. WXT supersedes the older `vite-plugin-web-extension`/CRXJS approaches.
- **Entry points**: Define each surface as a file in `entrypoints/` exporting `defineBackground`, `defineContentScript`, or an HTML page (e.g. `popup/`). Don't edit a manifest by hand; configure extension-wide fields in `wxt.config.ts`.
- **Popup UI**: Preact (not React — too heavy for an extension). Use JSX with `"jsxImportSource": "preact"` in tsconfig (esbuild handles it), or add `@preact/preset-vite` via the `wxt.config.ts` `vite()` hook for Fast Refresh. There is **no** official WXT Preact module — only react/vue/svelte/solid exist; do not reference `@wxt-dev/module-preact`.
- **Content script UI**: Vanilla TypeScript DOM manipulation only. Never use a framework in a content script — it risks conflicts with the host page's own framework.
- **Content script isolation**: Always inject UI into a Shadow DOM (WXT's `createShadowRootUi` helper) so styles are fully isolated from the host page.
- **Styling**: CSS imported as `?inline` into the content script and injected into the Shadow DOM as a `<style>` element.

## Manifest V3 patterns

- **Background = service worker**, never a persistent background page. Assume it terminates when idle: keep no long-lived in-memory state — persist to `chrome.storage` and re-read on wake.
- **Toolbar button**: use the `action` API (single `action` key), not the MV2 `browser_action`/`page_action` split.
- **Permissions**: split API permissions (`permissions`) from site access (`host_permissions`). Keep both minimal — request only what's used, prefer `activeTab` over broad host grants.
- **Programmatic injection**: `chrome.scripting.executeScript` (with the `scripting` permission), never the removed `chrome.tabs.executeScript`.
- **Network rules**: `chrome.declarativeNetRequest` for blocking/redirecting requests — blocking `webRequest` is gone for non-enterprise extensions.
- **No remote code**: all executable JS must ship inside the package; no loading scripts from a CDN. Inline scripts/eval are blocked by the default MV3 CSP — don't loosen it.

## TypeScript types

WXT provides Chrome API types out of the box. For a non-WXT setup, depend on `chrome-types` (Google-published, generated from Chromium source, MV3-only) rather than `@types/chrome`.

## manifest / icons conventions

- Set extension-wide fields (`name`, `permissions`, `action`, icons) in `wxt.config.ts` under `manifest`. WXT auto-wires `action.default_icon` and top-level `icons` from the generated icon set.
- **Single-source the version from `package.json`.** WXT stamps it into the generated `manifest.json` at build, so `npm version` is the only bump. Never hardcode a version literal in a manifest. If you deviate to a hand-rolled / crxjs / vite-plugin manifest, read the version from `package.json` at build time (don't duplicate it) — otherwise `npm version` updates one and the manifest ships stale.
- `run_at: "document_idle"` for content scripts (the default).
- Design icons as an SVG at `assets/icon.svg`. Render to 16/48/128 PNGs with `@resvg/resvg-js` (pure JS, no native compile — works on Windows) into `public/icons/` so WXT copies them into the build. Commit the generated PNGs so collaborators don't need to run the icon step.

## npm Scripts

```json
"icons": "node scripts/generate-icons.mjs",
"dev": "wxt",
"build": "wxt build",
"zip": "wxt zip"
```

- `npm run icons` — generate icon PNGs from the SVG source
- `npm run dev` — dev server with HMR and auto-reload
- `npm run build` — production build to `.output/`
- `npm run zip` — produces the flat, versioned zip (`manifest.json` at the archive root, version pulled from `package.json`) ready for Chrome Web Store upload. WXT cannot nest this output in a subfolder; a repo-named, folder-wrapped variant for unpacked installs is produced in CI (see Release automation).

## Release automation

Don't cut releases by hand — a manual `gh release create` is exactly where the built artifact gets forgotten (the release ends up with only GitHub's auto "Source code" archives). Scaffold `.github/workflows/release.yml` that fires on a `v*` tag push and builds → zips → publishes the GitHub release with the zip attached. The release ritual is then just bump → tag → push; the artifact attaches itself.

- Trigger on `push: { tags: ['v*'] }`; set `permissions: contents: write`; drive it with the `gh` CLI (`gh release create "$tag" *.zip --generate-notes`) — no extra marketplace actions.
- Fail the job if the tag (`vX`) doesn't equal `package.json`'s version — catches a tag pushed without a bump.
- For a non-WXT / hand-rolled build, also verify the built manifest's version equals `package.json` before publishing, so a stale `.output/`/`dist/` can't ship the wrong version.
- **Publish two artifacts: the flat `wxt zip` output (Web Store format) AND a repo-named, folder-wrapped zip for unpacked installs.** `wxt zip` archives the build with `manifest.json` at the root (what the Web Store requires) and has no option to nest it in a subfolder — so add a post-build step that copies `.output/chrome-mv3` into a folder named after the repo and zips that, so users can download → extract → "Load unpacked" the resulting `<repo>/` directory:
  ```bash
  name="${GITHUB_REPOSITORY##*/}"; ver="$(node -p "require('./package.json').version")"
  mkdir -p .output/pack && rm -rf ".output/pack/$name"
  cp -r .output/chrome-mv3 ".output/pack/$name"
  ( cd .output/pack && zip -r "$GITHUB_WORKSPACE/${name}-${ver}.zip" "$name" )   # zip is preinstalled on ubuntu-latest
  ```
  then attach both (idempotently, so re-runs `--clobber`): `gh release create "$tag" "${name}-${ver}.zip" .output/*-chrome.zip --generate-notes`. Stage under `.output/pack/` so the existing `.output/` + `*.zip` gitignore entries already cover it.

## Storage

- `chrome.storage.sync` — user configuration/watchlists. Persists across sessions, syncs across devices.
- `chrome.storage.local` — larger or device-local state.
- `chrome.storage.session` — ephemeral per-session state (also where service-worker state should live so it survives a worker restart).
- Always write typed wrappers (or use WXT's `storage` API) rather than calling `chrome.storage` directly throughout the codebase.

## Chrome Web Store Prerequisites

Before submitting, you need:

1. **Icons** — `npm run icons` generates them.
2. **Screenshot** — create `docs/screenshot-mock.html`, a self-contained file rendering a realistic 1280x800 mockup of the extension UI over a fake host page. Open it in Chrome and screenshot it. Save shots to `docs/store/screenshots/` (1280×800 or 640×400 PNGs).
3. **Privacy policy** — create `docs/privacy.html` with a plain-English policy covering what data the extension stores and what network requests it makes. Host it anywhere with a stable public URL (GitHub Pages from `main` / `/docs` is the default — the privacy page is then `https://<user>.github.io/<repo>/privacy.html`).
4. **Permissions justification** — write clear justifications for any broad permissions explaining why narrowing them isn't possible.
5. **Package** — `npm run zip` produces the flat versioned zip for the Web Store; the release workflow additionally publishes a repo-named, folder-wrapped zip for unpacked installs (see Release automation).
6. **Listing pack** — write `docs/store/listing.md` as the copy-paste source for the dashboard, ordered to match the dashboard form (see template below).

## Store listing pack (`docs/store/listing.md`)

Write this as a fill-in-order mirror of the CWS Developer Dashboard so submission is copy-paste, not a scavenger hunt. Structure it as the dashboard's two tabs. Keep the exact field names — they map 1:1 to the form.

**Store listing tab** — in this order:

- **Item name / title** (max 75 chars)
- **Summary** (short description, max 132 chars — usually the manifest `description`)
- **Description** (max 16,000 chars — the long marketing copy)
- **Category**
- **Language** (match the dashboard default, e.g. en-GB / en-US)
- **Store icon** (128×128 — point at `public/icons/128.png`)
- **Screenshots** (≥1; list each file in `docs/store/screenshots/` with a one-line caption)
- **Homepage URL** (the repo or product site)
- **Support URL** (default to `https://github.com/<user>/<repo>/issues`)

**Privacy tab** — in this order:

- **Single purpose description** (one paragraph: the *one* thing the extension does)
- **Permission justifications** — one field per entry in `permissions` **and** each `host_permissions` grant; explain why each is needed and why it can't be narrowed. Broad host access (`<all_urls>`) always needs the most care.
- **Are you using remote code?** — **No** for a compliant MV3 build (all JS bundled, no `eval`, no `<script src>` to a CDN). If Yes, a justification field is required.
- **Data usage** — the consequential part:
  - Answer each of Google's **nine** categories Yes/No with a one-line rationale: *Personally identifiable information · Health information · Financial and payment information · Authentication information · Personal communications · Location · Web history · User activity · Website content*. A table (`Category | Collected? | Rationale`) reads cleanly.
  - Certify the **three** Limited-Use statements (all normally true): (1) don't sell/transfer to third parties outside approved use cases, (2) don't use/transfer for purposes unrelated to the single purpose, (3) don't use for creditworthiness/lending.
  - **Privacy policy URL** (the hosted `privacy.html`).
- **Notes for reviewers** — lead with the facts that de-risk review (no `debugger`, no remote code, read-only vs. blocking, where sensitive data lives and that it never leaves the device).

> **Data-usage — local handling still counts; disclose it.** A common mistake is assuming "we transmit nothing off-device, so we can answer *does not collect*." Google's User Data FAQ (Q3, Q14) says the opposite: extensions must disclose data they **handle** — collect/use/store — *even when it's only processed locally or only in Chrome Storage Sync and never transmitted.* "Handle" (Q2) explicitly includes reading "the content of the HTTP requests," cookies, and the URLs the browser interacts with. So "does not collect" is only valid when the extension genuinely handles **no** user data at all. If it reads auth headers, request/response content, page content, or browsing URLs — even to render a purely local, session-only UI — declare the matching categories and certify Limited Use. Also: declaring a category while the code handles *more* than you declared is a disclosure-vs-behavior discrepancy, which CWS treats as suspendable — so map declarations to what the code actually reads, and add an explicit **Limited Use** statement to `privacy.html` (Limited Uses FAQ Q1).

End the pack with a **submission checklist** (icon ✓, ≥1 screenshot ✓, privacy policy live, both tabs filled, data-usage decision confirmed, upload the *current-version* zip only).

## .gitignore

Always include:

```
node_modules/
.output/
.wxt/
*.zip
.claude/
```

## Key Preferences

- Concise code — don't add comments, docstrings, or error handling for impossible scenarios
- Don't over-engineer — build exactly what's needed, no speculative abstractions
- Rebuild and verify after every change — always run `npm run build` and confirm it's clean before finishing
- The loaded/zipped extension is a build artifact (`.output/`), not the source. After any change — especially a version bump — rebuild and reload *that* directory in Chrome; never hand-edit the generated `manifest.json` (it's regenerated and your edit, including the version, is lost). A stale artifact loaded unpacked is the usual reason "I bumped the version but Chrome still shows the old one."

---

Begin by asking the user what the extension does, what site(s) it runs on, and what the injected UI needs to do. Then scaffold the full project structure following the conventions above.
