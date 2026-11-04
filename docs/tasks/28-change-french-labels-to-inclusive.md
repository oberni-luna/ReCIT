---
issue: 28
status: todo
wiki:
note: "je veux passer tous les libellés en Français en inclusif — ami → ami·e, auteur → auteur·ice, « Ajouter des amis lecteurs » → « Ajouter des ami·es lecteur·ices »"
created: 2026-11-04
---

## Context / Decisions

> je veux passer tous les libellés en Français en inclusif.
> Exemples : ami -> ami.e · auteur -> auteurice · "Ajouter des amis lecteurs" -> "Ajouter des ami.e.s lecteurices"

- **Graphie**: point médian `·` (U+00B7), plural with one point: `ami·es`, `lecteur·ices`, `auteur·ices`, `utilisateur·ices`, `un·e`, `seul·e`, `connecté·e`. This is the rule of `docs/conventions/wording.md` (Voice) and the glossary; ~60 strings already follow it. The user's `ami.e.s` / `lecteurices` examples were dropped for it.
- **Épicène first**: when a neutral phrasing reads naturally, it wins over the point (`Ouvert à tous` → `Ouvert à tout le monde`, `Tout lecteur d'inventaire.io` → `Tout le monde sur inventaire.io`, `il verra les vôtres` → `chacun·e verra les livres de l'autre`).
- **Nom d'utilisateur** → `Nom d'utilisateur·ice` everywhere; `Utilisateur` (nav title) → `Utilisateur·ice`.
- **Scope**: every French UI string on iOS (`ReCIT_iOS/Localizable.xcstrings`, `fr` values) and Android (`Recit_Android/app/src/main/res/values/strings*.xml`), one PR. App Store fr metadata: `lecteur·rices` → `lecteur·ices` only. English strings, keys, code identifiers untouched. Content from inventaire.io untouched.
- **Not gendered, left alone**: `ceux` / `il` standing for books or impersonal (`Vos livres, et ceux qui voyagent`, `dès qu'il y en aura une`), `Membre depuis`, `cette personne`.
- **Glossary**: Concepts row `Ami` → `Ami·e` (Never: `Ami`), and `Lecteur·ice` named in its Also column.
- Wording recap agreed with the user (chat, 2026-11-04):

| Avant | Après |
|---|---|
| Amis (segment, en-têtes, visibilité étagère) | Ami·es |
| Mes amis / Mes amis et mes groupes | Mes ami·es / Mes ami·es et mes groupes |
| Chez mes amis / Dans mes livres et chez mes amis | Chez mes ami·es / Dans mes livres et chez mes ami·es |
| Ajouter des amis lecteurs | Ajouter des ami·es lecteur·ices |
| Trouvez vos amis lecteurs | Trouvez vos ami·es lecteur·ices |
| Inviter des amis / Vos amis / Chercher parmi vos amis | … ami·es |
| Aucun ami à inviter / Aucun ami pour le moment | Aucun·e ami·e à inviter / Aucun·e ami·e pour le moment |
| Les invitations vont à vos amis. Ajoutez-en depuis Réseau › Amis. | Les invitations vont à vos ami·es. Ajoutez-en depuis Réseau › Ami·es. |
| Tout membre peut inviter. … Groupes de l'ami invité. | Chaque membre peut inviter. … Groupes de l'ami·e invité·e. |
| On me demande en ami | On me demande en ami·e |
| Une fois la demande acceptée, vous verrez ses livres et il verra les vôtres. … | Une fois la demande acceptée, chacun·e verra les livres de l'autre. … |
| … aucun de vous deux ne voit l'inventaire de l'autre. | … aucun·e de vous deux … |
| Chacun y inventorie ses livres … ses amis … / que chacun peut réutiliser | Chacun·e … ses ami·es … / que chacun·e peut réutiliser |
| Lecteurs / Trouver des lecteurs / Aucun lecteur de ce nom | Lecteur·ices / Trouver des lecteur·ices / Aucun·e lecteur·ice de ce nom |
| Cherchez un lecteur par son nom d'utilisateur … dès qu'il l'aura acceptée. | Cherchez un·e lecteur·ice par son nom d'utilisateur·ice … dès que la demande sera acceptée. |
| Un groupe réunit des lecteurs / … par les autres lecteurs / … aux lecteurs proches | lecteur·ices |
| Tout lecteur d'inventaire.io peut trouver le groupe. | Tout le monde sur inventaire.io peut trouver le groupe. |
| Auteur / Auteur inconnu / Chargement de l'auteur... / Choisir l'auteur | Auteur·ice / Auteur·ice inconnu·e / Chargement de l'auteur·ice… / Choisir l'auteur·ice |
| Aucun auteur de ce nom sur inventaire.io pour l'instant. | Aucun·e auteur·ice de ce nom sur inventaire.io pour l'instant. |
| Prenez l'auteur déjà présent si vous le reconnaissez : … | Prenez l'auteur·ice déjà présent·e si c'est la bonne personne : … |
| son auteur / par titre ou auteur | son auteur·ice / par titre ou auteur·ice |
| Ouvert à tous / ouvert à tous / modifiable par tous | Ouvert à tout le monde / ouvert à tout le monde / modifiable par tout le monde |
| un admin / Un admin … Tant qu'il ne l'a pas acceptée | un·e admin / Un·e admin … Tant qu'elle n'est pas acceptée |
| Vous êtes le seul admin : nommez un autre admin … | Vous êtes seul·e admin : nommez un·e autre admin … |
| Un autre admin est dans le groupe : seul l'unique admin peut le supprimer. | Le groupe compte un·e autre admin : il faut en être l'unique admin pour le supprimer. |
| Voir le membre / Son membre en sera retiré / Membre signalé : | Voir son membre / Son membre en sera retiré·e / Membre signalé·e : |
| Vous n'êtes pas connecté. / Pas d'utilisateur connecté ! | Vous n'êtes pas connecté·e. (both) |
| Êtes-vous sûr ? | Êtes-vous sûr·e ? |
| Nom d'utilisateur (login, signup, profile, search, errors, delete account) | Nom d'utilisateur·ice |
| Utilisateur (nav title) | Utilisateur·ice |

The table names the strings found on 2026-11-04; any other masculine generic found while coding follows the same two rules.

## Acceptance criteria

- `ReCIT_iOS/Localizable.xcstrings`: no French value left with a masculine generic for a person (`ami`, `amis`, `lecteur(s)`, `auteur` alone, `utilisateur`, `un admin`, `seul admin`, `tous` for people, `connecté`, `sûr`) — a grep on those words returns only épicène or point-médian forms.
- Same grep on `Recit_Android/app/src/main/res/values/strings*.xml` → same result.
- iOS Réseau tab: segment reads « Ami·es »; the empty network reads « Aucun·e ami·e pour le moment »; the add button reads « Ajouter des ami·es lecteur·ices ».
- iOS Recherche: section « Chez mes ami·es ».
- iOS login screen: field placeholder « Nom d'utilisateur·ice ».
- Android Réseau: « Ami·es », « Ajouter des ami·es lecteur·ices », « Trouvez vos ami·es lecteur·ices ».
- English localizations unchanged; string keys unchanged; iOS and Android build green (SwiftLint, Android lint).
- `metadata/app-store/localizations/fr-FR.json`: `lecteur·rices` → `lecteur·ices`.
- `docs/conventions/glossary.md`: `Ami` row reads `Ami·e`.

## Implementation

## Review

## Verification

## Feedback
