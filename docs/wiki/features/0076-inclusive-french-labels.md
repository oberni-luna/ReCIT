# French labels written inclusively

Shipped on 2026-11-04, on iOS and Android, in one PR (issue #28). Before this change, most labels about people used
the masculine generic (« Amis », « Ajouter des amis lecteurs », « Nom d'utilisateur », « Ouvert à tous »). The
authors' labels were already written « auteur·ice », since 0049 and later.

## What it does

Every French label that names a person no longer uses the masculine generic. Two rules apply, in this order:

1. **Épicène first.** When a neutral phrasing reads naturally, it wins.
   - « Ouvert à tous » → « Ouvert à tout le monde »
   - « Tout lecteur d'inventaire.io peut trouver le groupe. » → « Tout le monde sur inventaire.io peut trouver le groupe. »
   - « vous verrez ses livres et il verra les vôtres » → « chacun·e verra les livres de l'autre »
2. **Otherwise, the point médian.** The character is `·` (U+00B7), and the plural takes one point.
   - `ami·es`, `lecteur·ices`, `auteur·ices`, `utilisateur·ice`
   - `un·e`, `aucun·e`, `seul·e`
   - `connecté·e`, `sûr·e`, `retiré·es`

The user's first examples (`ami.e.s`, `lecteurices`) were dropped. The project already wrote `auteur·ice` in about
sixty strings, so that form was kept. Words that are not about a person stay as they were:

- books (« Tous les livres », « ceux qui voyagent », « Retiré de … »)
- the publishing house (« Éditeur »)
- impersonal `il`
- « Membre depuis » and « cette personne »

## Technical surface

- **iOS**: the `fr` values of 74 keys in `Localizable.xcstrings` (75 values, plurals included). Keys and `en` values
  are unchanged. `ListVisibilityLabelTests` now expects « Mes ami·es ».
- **Android**: 59 strings in `res/values/strings*.xml`, with the same text as iOS wherever a string exists on both.
- **End-to-end scenarios**:
  - Android's `E2EScenarioTest.kt` finds the login field and « Dans mes livres et chez mes ami·es » by their text, so
    it follows the new strings.
  - iOS finds rows by identifiers, so only its messages and step titles changed.
- **App Store fr text**: `lecteur·rices` → `lecteur·ices`.
- **Glossary**: `Ami` → `Ami·e`.

## Left open

- « Êtes-vous sûr·e ? » and « Vous n'êtes pas connecté·e. » (the error shown when adding a book with no session)
  only got the inclusive agreement. The first should name its action. The second should say what to do. Both are
  wording changes for another task.
- `:app:lintDebug` already failed before this change, on 9 `LocalContextResourcesRead` errors in Kotlin files.
- Seen on an iPhone (Debug build). Not seen on Android. The e2e scenarios were not run.
