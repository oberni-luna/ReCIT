Title: Une ligne Debug qui réaffiche les astuces
Labels: needs-triage, chore
Type: AFK

## Parent

`docs/prd/0013-sorting-tips.md`

## What to build

L'outil de recette de cette feature, et le seul : **« Réafficher les astuces »** dans la section
Debug du profil. La ligne vide l'acquis du compte courant dans `TipsStore` et appelle
`Tips.resetDatastore()`, de sorte que la surface de tri se remette à parler sans changer de compte
ni réinstaller l'app.

Elle rejoint ses voisines dans `ProfileDebugSection` et en prend la forme : `#if DEBUG`, non
traduite, non stylée comme le reste de l'écran — elle doit ressembler à ce qu'elle est. Comme la
ligne qui oublie la réponse de l'accueil affiche ce que la règle déciderait, celle-ci dit combien
d'astuces sont actuellement acquises, faute de quoi elle a l'air cassée quand elle ne fait rien.

Sans les astuces, il n'y a rien à remettre à zéro : cette issue suit la première.

## Acceptance criteria

- [ ] La section Debug du profil porte « Réafficher les astuces »
- [ ] La presser vide l'acquis du compte courant et appelle `Tips.resetDatastore()`
- [ ] Rouvrir « Ranger mes livres » juste après montre à nouveau SORT-1
- [ ] La ligne indique combien d'astuces sont acquises pour ce compte
- [ ] L'acquis d'un autre compte n'est pas touché
- [ ] Rien de tout cela n'existe dans une configuration Release
- [ ] `xcodebuild` passe

## Blocked by

- `docs/issues/0077-sort-tip-drag-to-file.md`
