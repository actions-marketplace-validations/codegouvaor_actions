# Contributing to ADS React (`@codegouvaor/react-ads`)

Hello friends 👋 — thank you for considering contributing to the official React
implementation of the **Astoria Design System**.

Everything here is developed in the open, for the digital services of the Republic of
Astoria. Before anything else:

-   Read [AUDIT.md](AUDIT.md) — the state of the codebase and what is still inherited from the
    upstream French `react-dsfr` project. **Do not reintroduce French-government branding or
    dependencies** unless it is part of a documented migration step.
-   Read [GOVERNANCE.md](GOVERNANCE.md) and [CODE_OF_CONDUCT-ish expectations](GOVERNANCE.md#code-of-conduct).
-   Check [the open issues](https://github.com/codegouvaor/react-ads/issues) and say what you
    are working on before opening a PR.

## Setting up the development environment

Requirements: Node ≥ 18, `pnpm` (the repository is managed with pnpm — see
`pnpm-lock.yaml`).

```bash
git clone https://github.com/codegouvaor/react-ads.git
cd react-ads
pnpm install
```

Useful commands:

| Command                                 | Purpose                                                     |
| --------------------------------------- | ----------------------------------------------------------- |
| `pnpm build`                            | Generates the CSS-derived types/assets and compiles `dist/` |
| `pnpm storybook`                        | Interactive documentation (dev server, port 6006)           |
| `pnpm test`                             | Unit tests (vitest, `test/runtime/**`)                      |
| `pnpm lint:check` / `pnpm format:check` | ESLint / Prettier verification                              |
| `pnpm format`                           | Auto-format the codebase                                    |

> Storybook and the integration demo apps (`test/integration/*`) run against `dist/`, so run
> `pnpm build` first (or keep `npx tsc -w -p src` running) when you change `src/`.

## Where things live

| Path                                            | Content                                                                                                       |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `src/<Component>.tsx`                           | One module per component (subpath import: `@codegouvaor/react-ads/<Component>`)                               |
| `src/ads/`                                      | ADS foundations: design token contracts (colors, typography, spacing, radius, elevation, motion, breakpoints) |
| `src/fr/`                                       | Legacy token helpers + CSS-derived types (to be renamed with the ADS CSS layer — see MIGRATION.md)            |
| `src/next-app-router/`, `src/next-pagesdir.tsx` | Next.js integration helpers                                                                                   |
| `src/mui/`                                      | Optional MUI adaptation layer                                                                                 |
| `src/bin/`                                      | CLI tools (`react-ads optimize-css`, `copy-static-assets`, …)                                                 |
| `stories/<Component>.stories.tsx`               | Component documentation (Storybook)                                                                           |
| `test/runtime/`                                 | Unit tests (vitest)                                                                                           |
| `test/integration/`                             | Demo apps: CRA, Vite, Next.js Pages/App Router (dev only)                                                     |

## Contribution guidelines

-   📣 **Say what you're doing**: open (or comment on) an issue and reference it from your PR.
-   🧩 **Prefer small PRs.** One logical change per PR is much easier to review and release.
-   🔗 **Use the link abstraction**: components that render links must use the component
    returned by `getLink()` instead of `<a />`, so the library plays nice with all routing
    libraries (see `src/Header` for an example).
-   🕹️ **Controlled _and_ uncontrolled**: when relevant, components should support being used
    either controlled or uncontrolled (see `<Tabs />`).
-   🌎 **No hard-coded text in JSX**: use the i18n mechanism (`src/i18n.ts`) for built-in
    strings, and register translations for the languages you add.
-   ♿ **Accessibility is first class** (target WCAG 2.2 AA): keyboard navigation, visible
    focus, ARIA, labels. Document the a11y properties of the component in its story.
-   🎨 **Never hard-code visual values in components**: colors, spacing, radii etc. must come
    from the token system (CSS custom properties / `src/ads`). If a value is missing, extend
    the tokens — don't inline a color or a pixel value.
-   🧹 Keep the code consistent with the existing style: 4-space indentation, Prettier
    (`pnpm format`), ESLint clean.
-   ✅ Add tests when you add behavior (`test/runtime/`), and run `pnpm test` before pushing.

## Component conventions

Components live one-per-module in `src/`, exporting both a named export and a default
export of the same name (`export const Alert = …; export default Alert;`). Re-export new
generic components from `src/index.ts` (the root import) **unless** they require an optional
dependency (MUI, charts, Next.js…).

Storybook: each component has a story file (`stories/<Component>.stories.tsx`) covering
variants, states and examples — keep the import instructions shown in stories up to date.

## Linking your local copy into your own project

To develop against your own app with a local build of the library:

```bash
pnpm build
node scripts/link-in-external-project.js YOUR-PROJECT-ABSOLUTE-PATH
# keep the compiler watching while you edit:
npx tsc -w -p src
```

(For the integration demo apps under `test/integration/`, use `pnpm start-*` scripts, which
build, link and launch each app.)

## Working on the legacy stylesheet layer

The CSS layer is still generated from `@gouvfr/dsfr` at build time (`scripts/build/`,
`src/bin/`, `patches/`). If you need to change it, see [MIGRATION.md](MIGRATION.md) — the
long-term direction is to replace it with ADS-generated stylesheets, not to patch DSFR
further.

## Reporting issues

-   Bugs, feature requests, component gaps: [issues](https://github.com/codegouvaor/react-ads/issues)
    (use the templates).
-   Security vulnerabilities: **do not** open a public issue — see [SECURITY.md](SECURITY.md).

Thank you very much ❤️
