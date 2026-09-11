Title: La première astuce de « Ranger mes livres » : glissez pour ranger
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0013-sorting-tips.md`

## What to build

La balle traçante des astuces : **toute la colonne vertébrale, pour une seule astuce**. À
l'ouverture de la surface de tri, dès qu'il y a au moins un livre à ranger, une carte verte pointe
le premier livre du carrousel « Livres à ranger » et dit le geste **et son inverse**. Elle ne
revient jamais une fois qu'un livre a été déposé.

Quatre pièces, dont trois sont réutilisées par les issues suivantes :

- **`SortTipGate`** (`Model/Tips/`) — type pur, sans TipKit, sans SwiftData, sans disque. Répond
  « quelle astuce est due » à partir de valeurs simples : nombre de livres à ranger, changement en
  attente, disponibilité du modèle, écriture ou proposition en cours, et ce qui a déjà été appris.
  Cette issue n'en câble que la clause de SORT-1 ; les deux autres cas existent dans le type et
  renvoient « rien » tant que 0079 et 0080 ne les ont pas remplis. Même forme
  qu'`OnboardingGate` : la vue pose la question, elle ne décide pas.
- **`TipsStore`** (`AppModels/Tips/`) — la forme d'`OnboardingStore` : ensemble observé, miroir
  `UserDefaults`, injecté, **par utilisateur**. Une astuce apprise appartient au compte, pas au
  téléphone ; la déconnexion n'efface rien. Ajouté en `@State` dans `RootView` et injecté dans
  l'environnement, comme les autres modèles partagés.
- **Le style de carte** — un `TipViewStyle` qui rend la maquette : fond `background/tinted-inverse`,
  titre `Action/action300`, texte `Content/content300`, rayon `radius/rounded`, ombre
  `Shadow/Light`, pointe de 20 × 9 vers l'élément visé, la pointe hors de la carte. Tokens du
  design system, aucune valeur littérale.
- **L'astuce elle-même** — un `Tip` muet : un unique `@Parameter` booléen piloté par le gate,
  posé dans un `TipGroup(.ordered)` sur la surface de tri, ce qui garantit qu'il n'y en a jamais
  deux à l'écran. `Tips.configure` est appelé au démarrage, à côté de `DesignSystem.start()`.

L'invalidation est un fait de `SortSessionModel`, pas de vue : **le premier `moveBook` accepté**
depuis le carrousel vers une étagère. Un dépôt refusé n'apprend rien.

Maquette : frame `SORT-1 · Glisser pour ranger` (`314:8109`) de la section `Astuces · TipKit`.

## Acceptance criteria

- [ ] À la première ouverture de la surface avec au moins un livre à ranger, la carte apparaît et
      pointe le premier livre du carrousel
- [ ] Elle dit le geste et son inverse, au vouvoiement, en français et en anglais
- [ ] Elle se ferme par sa croix, et la fermeture seule ne compte pas comme apprise
- [ ] Après un premier dépôt réussi, elle ne revient plus, y compris après relance de l'app
- [ ] Aucune astuce tant que la surface est en `syncing`, ni quand le carrousel est vide
- [ ] Aucune astuce pendant une écriture ou une proposition en cours
- [ ] `SortTipGate` est un type valeur pur : ni TipKit, ni SwiftUI, ni SwiftData, ni `UserDefaults`
- [ ] `TipsStore` retient l'acquis par `userId` ; deux comptes sur le même téléphone ont chacun
      leurs astuces ; se déconnecter et se reconnecter n'en redonne aucune
- [ ] La carte suit les tokens : lisible en clair et en sombre sans redessin, et grandit avec le
      corps de texte au lieu de le tronquer
- [ ] VoiceOver annonce la carte à son arrivée et sa croix est atteignable
- [ ] La carte ne recouvre pas les identifiants `e2e.*` que le scénario end-to-end touche sur cet
      écran
- [ ] `xcodebuild` passe, la suite `ReCIT_iOSTests` passe inchangée

## Blocked by

None - can start immediately
