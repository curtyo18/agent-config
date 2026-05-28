---
description: Build a Chrome Extension (Manifest V3) with TypeScript. Use when the user wants to create, scaffold, or work on a browser extension, Chrome extension, or web extension.
---

You are helping me build a Chrome Extension (Manifest V3) using TypeScript. Manifest V2 is fully end-of-life — Chrome disabled all MV2 extensions for every user in 2025 and the Web Store no longer accepts them, so target MV3 exclusively. Follow all of the preferences and patterns below without needing to ask about them — these are already decided.

## Tech Stack

- **Framework / build tool**: [WXT](https://wxt.dev) (`npx wxt@latest init`). It is Vite-based, generates `manifest.json` from the files in `entrypoints/`, handles cross-browser (Chrome/Firefox/Edge) differences, and ships typed APIs — so there is no hand-written manifest or bundler config to maintain. WXT supersedes the older `vite-plugin-web-extension`/CRXJS approaches.
- **Entry points**: Define each surface as a file in `entrypoints/` exporting `defineBackground`, `defineContentScript`, or an HTML page (e.g. `popup/`). Don't edit a manifest by hand; configure extension-wide fields in `wxt.config.ts`.
- **Popup UI**: Preact (not React — too heavy for an extension). Use JSX with `"jsxImportSource": "preact"` in tsconfig, or WXT's `@wxt-dev/module-preact`.
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
- `npm run zip` — produces a versioned zip (version pulled from `package.json`) ready for Chrome Web Store upload

## Storage

- `chrome.storage.sync` — user configuration/watchlists. Persists across sessions, syncs across devices.
- `chrome.storage.local` — larger or device-local state.
- `chrome.storage.session` — ephemeral per-session state (also where service-worker state should live so it survives a worker restart).
- Always write typed wrappers (or use WXT's `storage` API) rather than calling `chrome.storage` directly throughout the codebase.

## Chrome Web Store Prerequisites

Before submitting, you need:

1. **Icons** — `npm run icons` generates them.
2. **Screenshot** — create `docs/screenshot-mock.html`, a self-contained file rendering a realistic 1280x800 mockup of the extension UI over a fake host page. Open it in Chrome and screenshot it.
3. **Privacy policy** — create `docs/privacy.html` with a plain-English policy covering what data the extension stores and what network requests it makes. Host it anywhere with a stable public URL (any static host works).
4. **Permissions justification** — write clear justifications for any broad permissions explaining why narrowing them isn't possible.
5. **Package** — `npm run zip` produces the versioned zip.

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

---

Begin by asking the user what the extension does, what site(s) it runs on, and what the injected UI needs to do. Then scaffold the full project structure following the conventions above.
