---
description: Build a Chrome Extension (Manifest V3) with TypeScript. Use when the user wants to create, scaffold, or work on a browser extension, Chrome extension, or web extension.
---

You are helping me build a Chrome Extension (Manifest V3) using TypeScript. Follow all of the preferences and patterns below without needing to ask about them — these are already decided.

## Tech Stack

- **Build tool**: Vite + `vite-plugin-web-extension`. It reads `manifest.json` as the source of truth and compiles all entry points. Always set `emptyOutDir: true` in vite config.
- **Popup UI**: Preact (not React — too heavy for an extension). Use JSX with `"jsxImportSource": "preact"` in tsconfig.
- **Content script UI**: Vanilla TypeScript DOM manipulation only. Never use a framework in a content script — it risks conflicts with the host page's own framework.
- **Content script isolation**: Always use Shadow DOM for any injected UI so styles are fully isolated from the host page.
- **Styling**: CSS files imported as `?inline` into the content script and injected into the Shadow DOM as a `<style>` element.

## manifest.json conventions

- Always include both top-level `icons` and `action.default_icon` fields — forgetting either means no icon shows in Chrome.
- `run_at: "document_idle"` for content scripts.
- Keep permissions minimal. Only add what's actually used.

## npm Scripts

Always include these four scripts:

```json
"icons": "node scripts/generate-icons.mjs",
"dev": "vite build --watch --mode development",
"build": "vite build",
"package": "npm run build && node scripts/package-extension.mjs"
```

- `npm run icons` — generates icon PNGs from the SVG source using `@resvg/resvg-js`
- `npm run dev` — watch mode for development
- `npm run build` — production build
- `npm run package` — builds and zips `dist/` into a versioned zip ready for Chrome Web Store upload. The zip filename includes the version from `package.json` (e.g. `my-extension-v1.0.0.zip`). Uses the `archiver` npm package.

## Icon Generation

- Design icons as an SVG at `src/icons/icon.svg`
- Use `@resvg/resvg-js` (no native compilation, works on Windows) to render to 16x16, 48x48, 128x128 PNGs
- Output to `public/icons/` so Vite copies them to `dist/icons/` automatically
- Commit the generated PNGs so collaborators don't need to run the icon step

## Storage

- `chrome.storage.sync` — user configuration/watchlists. Persists across sessions, syncs across devices.
- `chrome.storage.session` — ephemeral per-session state if needed.
- Always write typed wrappers rather than calling `chrome.storage` directly throughout the codebase.


## Chrome Web Store Prerequisites

Before submitting, you need:

1. **Icons** — `npm run icons` generates them
2. **Screenshot** — create `docs/screenshot-mock.html`, a self-contained HTML file that renders a realistic 1280x800 mockup of the extension UI over a fake version of the host page. User opens it in Chrome and screenshots it.
3. **Privacy policy** — create `docs/privacy.html` with a plain-English policy explaining what data the extension stores and what network requests it makes. Host it on **Netlify** (free account, drag `docs/` folder onto app.netlify.app/drop — public URL, no config needed).
4. **Permissions justification** — write clear justifications for any broad permissions explaining why narrowing them isn't possible.
5. **Package** — `npm run package` produces the versioned zip.

## .gitignore

Always include:

```
node_modules/
dist/
*.zip
.claude/
```

## Key Preferences

- Concise code — don't add comments, docstrings, or error handling for impossible scenarios
- Don't over-engineer — build exactly what's needed, no speculative abstractions
- Rebuild and verify after every change — always run `npm run build` and confirm it's clean before finishing

---

Begin by asking the user what the extension does, what site(s) it runs on, and what the injected UI needs to do. Then scaffold the full project structure following the conventions above.
