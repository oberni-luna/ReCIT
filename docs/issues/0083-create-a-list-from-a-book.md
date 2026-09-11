# 0083 — Créer une liste depuis un livre

## Parent

`docs/prd/0014-create-a-list-or-shelf-from-a-book.md`

## What to build

Le chemin complet, de la ligne de menu jusqu'au serveur, côté listes.

Le sous-menu « Listes » de l'écran d'un livre ne disparaît plus quand l'utilisateur n'a aucune
liste. Sous les listes existantes, séparée d'elles par un trait, une dernière ligne dit « Ajouter à
une nouvelle liste ». La toucher ouvre le formulaire de création de liste habituel, dont le bouton
dit « Créer et ajouter » : il crée la liste, y range l'œuvre du livre, ferme la feuille et laisse un
SnackBar nommant la liste.

Cette tranche pose au passage l'infrastructure que la tranche étagère réutilisera : le type pur qui
décrit une demande de création-puis-rangement, le modifier qui monte la bonne feuille depuis l'écran
(un `.sheet` posé dans le contenu d'un `Menu` ne se présente pas de façon fiable), et la ligne de
création dans le composant de menu d'appartenance partagé — c'est là que vit la règle « jamais de
sous-menu vide », écrite une seule fois pour les deux porteurs.

L'enchaînement lui-même est une méthode du modèle de listes, pas du formulaire : création attendue
— le rangement a besoin de l'identifiant serveur et ne peut pas partir vers un identifiant
optimiste — puis rangement optimiste. La méthode de création de liste existante doit retourner la
liste qu'elle insère.

Le sélecteur de type est masqué et la valeur forcée à l'œuvre : le livre impose la réponse. La règle
d'affichage existante ne bouge pas — l'entrée n'est offerte que pour une édition qui ne tient qu'une
seule œuvre.

## Acceptance criteria

- [ ] Avec zéro liste, le sous-menu « Listes » apparaît sur l'écran d'un livre et contient la seule ligne « Ajouter à une nouvelle liste »
- [ ] Avec des listes existantes, elles restent en tête du sous-menu, dans leur ordre actuel, et la ligne de création est la dernière, séparée par un trait
- [ ] La ligne ouvre le formulaire de création de liste existant, sans son bouton de suppression
- [ ] Le sélecteur de type de liste est absent en mode création-depuis-un-livre, et la liste créée est bien une liste d'œuvres
- [ ] Le bouton du formulaire dit « Créer et ajouter » et reste inerte tant qu'aucun nom n'est saisi
- [ ] Le bouton montre sa progression pendant l'aller-retour de création
- [ ] Au succès : la feuille se ferme, un SnackBar nomme la liste, et rouvrir le sous-menu montre la nouvelle liste avec le livre marqué comme déjà dedans
- [ ] La nouvelle liste apparaît dans l'écran des listes sans rafraîchissement manuel
- [ ] Création en échec : rien n'est créé, la feuille reste ouverte avec la saisie, l'erreur passe par le SnackBar
- [ ] Création réussie et rangement en échec : la liste reste, l'appartenance se défait d'elle-même et l'erreur remonte par le canal d'erreurs partagé
- [ ] Le rangement poste l'identifiant serveur de la liste créée, jamais un identifiant optimiste
- [ ] Fermer la feuille sans valider ne crée rien
- [ ] Une édition à zéro ou plusieurs œuvres n'affiche toujours pas l'entrée « Listes »
- [ ] Les trois chaînes nouvelles sont des clés localisées
- [ ] La nouvelle ligne porte un identifiant d'accessibilité dérivé de celui de son sous-menu
- [ ] Le mode création-simple du formulaire, appelé depuis l'écran des listes, est inchangé
- [ ] Le scénario de bout en bout n'est pas modifié et continue de passer

## Blocked by

None - can start immediately
