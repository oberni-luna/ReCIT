# Wiki — Index

Living knowledge base for Ex-libris. Pages link to each other and to tasks with relative links (GitHub) or `[[wikilink]]` (Obsidian). Keep it current via `/wa-wiki`.

## Pages

- [glossary](../conventions/glossary.md) — one word per thing: concepts, screens, parts, flows
- [architecture](architecture.md) — layers, data flow, sessions, navigation, and the ADRs behind them
- [shelves](shelves.md) — Inventaire et étagères
- [scanning-and-sorting](scanning-and-sorting.md) — Scanner et « Ranger mes livres »
- [book-and-editions](book-and-editions.md) — fiche livre, œuvres, éditions, création et modification
- [search](search.md) — Recherche
- [lists](lists.md) — Listes
- [network](network.md) — Réseau, amis, groupes, échanges
- [account-and-profile](account-and-profile.md) — accueil, compte, Profil
- [platform-and-design](platform-and-design.md) — iOS 18, iPhone Duo, dark mode, design system
- [android](android.md) — the Android port
- [testing](testing.md) — test suites and the end-to-end scenario

## Folders

- `adr/` — architecture decisions, numbered
- `features/` — one write-up per shipped feature: what it turned out to be. The index with one line each is in `CLAUDE.md` → "Shipped features".
- `prd/` — what a feature is meant to be before it ships, deleted once its feature doc exists ([README](prd/README.md))
- `design-system/` — the Figma library and its divergences from code ([figma-library.md](design-system/figma-library.md))
- `integrations/` — Apple app-site-association, Google Play
- `grill-me/` — decisions and design extraction of the Réseau graph grilling (2026-10-13); the graph was removed in [0048](features/0048-network-graph-removed.md)

## How to read

- A page describes a domain, decision, or subsystem — the *why* and the *shape*, not a copy of the code.
- Tasks reference wiki pages in their `wiki:` frontmatter; wiki pages can link back to tasks.
- The code is the structural truth; the wiki is the human narrative on top — it explains what reading the source can't tell you.
