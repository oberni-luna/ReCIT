Title: Les recherches envoyées reviennent au focus du champ, gardées sur l'appareil
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0012-unified-inventory-search.md`

## What to build

Le premier temps de la recherche : **au focus du champ, mes trois dernières recherches**, avant
même d'avoir tapé quoi que ce soit. Un tap sur l'une d'elles relance la recherche, « Effacer »
vide l'historique.

Module nouveau **`RecentSearchStore`** (`AppModels/Search/`), `@MainActor @Observable`, construit
exactement comme `OnboardingStore` : une propriété observée miroitée dans un `UserDefaults`
**injectable**, avec une clé **par `_id` d'utilisateur**. Par utilisateur et non par app, pour la
même raison que l'accueil : un téléphone partagé doit deux historiques séparés, et se déconnecter
n'effface rien — l'historique appartient au compte qui l'a écrit.

Sa surface :

- l'historique ordonné d'un utilisateur, et la tranche de trois que l'écran affiche ;
- `record(query:userId:)` — normalise (trim, espaces réduits), **dédoublonne sans tenir compte de
  la casse ni des accents**, et remonte une entrée existante en tête au lieu d'en créer une
  jumelle ;
- `clear(userId:)`.

**Aucun plafond sur ce qui est stocké** : tout est gardé, le plafond de trois est un fait
d'affichage. La suppression unitaire n'est pas de cette tranche (ni de ce PRD).

`record` est appelé **à l'envoi seulement** — touche « rechercher » ou tap sur une suggestion, les
deux gestes de l'issue 0071. Une requête tapée puis abandonnée ne laisse rien : c'est ce qui fait
que la liste des récentes est une liste de choses réellement cherchées.

À l'écran : une section « Recherches récentes » dont l'en-tête porte l'action « Effacer », et trois
rangées à glyphe horloge — **la vue de rangée de l'issue 0071**, avec un autre glyphe et un libellé
nu. Un tap sur une récente relance la recherche comme une suggestion : `SearchPhase` passe en
`results`, et la requête remonte en tête de l'historique.

Le store est construit dans `RootView` avec les autres modèles d'app et injecté dans
l'environnement — aux **deux** endroits, comme le veut la règle du projet.

## Acceptance criteria

- [ ] Focaliser le champ sans rien taper affiche les trois dernières recherches
- [ ] Un tap sur une récente relance la recherche et remonte l'entrée en tête
- [ ] « Effacer » dans l'en-tête vide tout l'historique de l'utilisateur courant
- [ ] Une requête seulement tapée, jamais envoyée, n'entre pas dans l'historique
- [ ] Chercher deux fois la même chose ne crée pas deux entrées
- [ ] « Monte Cristo » et « monte cristo » sont la même entrée
- [ ] L'historique survit à la fermeture de l'app
- [ ] Deux comptes sur le même appareil ont deux historiques distincts, et se déconnecter n'en
      efface aucun
- [ ] Tout est stocké, rien n'est plafonné côté stockage ; seul l'affichage se limite à trois
- [ ] `RecentSearchStore` est construit dans `RootView` et injecté dans l'environnement
- [ ] Suite `RecentSearchStore`, sur le modèle de `OnboardingStoreTests` : vide au départ ; une
      recherche enregistrée revient ; deux utilisateurs restent séparés ; l'historique survit à un
      store neuf sur les mêmes defaults ; une répétition remonte au lieu de dupliquer ; casse et
      accents se replient ; `clear` vide un utilisateur sans toucher l'autre
- [ ] Chaque cas de test utilise son propre domaine `UserDefaults`, jamais `.standard`
- [ ] Les nouvelles chaînes sont dans `Localizable.xcstrings`, au vouvoiement
- [ ] L'écran se lit en clair et en sombre
- [ ] `xcodebuild` passe, la suite `ReCIT_iOSTests` passe

## Blocked by

- `docs/issues/0071-inventaire-io-suggestions-and-results.md`
