# 0084 — Créer une étagère depuis un livre

## Parent

`docs/prd/0014-create-a-list-or-shelf-from-a-book.md`

## What to build

Le même chemin, côté étagères, sur l'infrastructure posée par la tranche liste.

Le sous-menu « Étagères » de l'écran d'un livre ne disparaît plus quand l'utilisateur n'a aucune
étagère : sous les étagères existantes et séparée d'elles, une ligne « Ajouter à une nouvelle
étagère » ouvre le formulaire d'étagère habituel, dont le bouton crée l'étagère, y range
l'exemplaire, ferme la feuille et laisse un SnackBar nommant l'étagère.

Une étagère range un exemplaire, pas une édition : l'entrée reste offerte sur le seul livre que
l'utilisateur possède. C'est la seule des deux entrées qui reste conditionnelle, et cette condition
ne change pas.

Description et visibilité restent affichées dans ce mode — contrairement au mode brouillon du même
formulaire, qui les masque parce qu'il ne les écrirait pas. Ici elles sont réellement écrites.

L'enchaînement est une méthode du modèle d'étagères, par-dessus la création attendue qui existe
déjà et rend l'étagère créée, suivie du rangement optimiste. Le bouton du formulaire, aujourd'hui
synchrone parce que la création y est optimiste, devient asynchrone dans ce mode et montre sa
progression : c'est la seule perte de vivacité de la feature, et elle ne touche pas le chemin du
carrousel.

L'exemplaire peut disparaître pendant que la feuille est ouverte : sa présence en magasin est
vérifiée avant le rangement, selon le motif déjà en place ailleurs dans l'écran du livre.

## Acceptance criteria

- [ ] Avec zéro étagère, le sous-menu « Étagères » apparaît sur un livre possédé et contient la seule ligne « Ajouter à une nouvelle étagère »
- [ ] Avec des étagères existantes, elles restent en tête et la ligne de création est la dernière, séparée par un trait
- [ ] La ligne ouvre le formulaire d'étagère existant, avec nom, description et visibilité, sans son bouton de suppression
- [ ] Le bouton dit « Créer et ajouter », reste inerte sans nom, et montre sa progression pendant l'aller-retour
- [ ] Au succès : la feuille se ferme, un SnackBar nomme l'étagère, et rouvrir le sous-menu montre la nouvelle étagère avec le livre marqué comme déjà dessus
- [ ] La nouvelle étagère apparaît sur le carrousel des étagères, le livre dessus, sans rafraîchissement manuel
- [ ] Création en échec : rien n'est créé, la feuille reste ouverte avec la saisie, l'erreur passe par le SnackBar
- [ ] Création réussie et rangement en échec : l'étagère reste, l'appartenance se défait d'elle-même et l'erreur remonte par le canal d'erreurs partagé
- [ ] Le rangement poste l'identifiant serveur de l'étagère créée, jamais un identifiant optimiste
- [ ] Un exemplaire supprimé pendant que la feuille est ouverte ne fait pas planter le rangement
- [ ] Sur un livre non possédé, l'entrée « Étagères » reste absente
- [ ] Le mode création depuis le carrousel reste optimiste et instantané, et le mode brouillon de la surface de rangement est inchangé
- [ ] La nouvelle ligne porte un identifiant d'accessibilité dérivé de celui de son sous-menu
- [ ] Le scénario de bout en bout n'est pas modifié et continue de passer

## Blocked by

- `docs/issues/0083-create-a-list-from-a-book.md`
