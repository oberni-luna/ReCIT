# Les étagères qu'un ami partage

Shipped on 2026-09-15. Les quatre issues 0090–0093 ont été supprimées à ce commit ; git les garde.

## Ce que ça fait

Le profil d'un ami montrait ses livres en une seule liste. Ses étagères — celles qu'il a bien
voulu partager — n'existaient nulle part dans l'app : ni synchronisées, ni dessinées. Or une
bibliothèque rangée dit quelque chose de plus que son contenu, et c'est exactement ce que l'app
gardait pour elle.

Entre la carte d'en-tête et « Inventaire de X », il y a maintenant une bande « Étagères de X » :
**le même carrousel que mon inventaire**, cartes à 86 % de la largeur, aimantées, la suivante qui
dépasse. On presse un livre, il grandit et l'écran recule ; on glisse, la sélection suit le doigt ;
on lève, le livre s'ouvre. On presse l'étiquette en papier, l'étagère s'ouvre en liste.

Deux différences avec la mienne, et deux seulement :

- **pas d'« Ajouter »** dans l'en-tête — on ne crée rien sur le compte d'un autre ;
- **l'étagère ouverte ne se modifie pas** : ni « Modifier » dans la barre de navigation, ni
  balayage pour retirer un livre.

Et une règle de dessin, demandée explicitement : **les étagères sont posées sur rien**. Pas la
carte plus sombre sur laquelle reposent l'en-tête au-dessus et les livres en dessous. Le carrousel
va d'un bord à l'autre de l'écran, sur le fond de l'écran. Une étagère est déjà un objet ; elle n'a
pas besoin d'une boîte.

Pas d'étagère partagée, pas de bande — en-tête compris. Et la bande obéit à la même règle que les
livres : le profil d'un inconnu n'en montre pas.

## Ce que le serveur sait faire

`GET /api/shelves?action=by-owners&owners=<id>` — le même appel que pour moi, avec l'identifiant
de quelqu'un d'autre. **C'est le serveur qui décide de ce qu'un ami partage** : il applique la
visibilité et ne rend que les étagères qu'il me laisse voir.

**Rien n'est filtré côté app**, et ce n'est pas un raccourci : `ShelfDTO` documente que
`visibility` peut être absent pour un non-propriétaire, donc un filtre local sur ce champ
masquerait des étagères pourtant partagées. La seule autorité sur ce qui se voit est celle qui a
l'information.

Le deuxième passage, `?action=by-ids&with-items=true`, reconstruit l'appartenance exactement comme
pour mes étagères : il relie les exemplaires déjà présents localement, donc les livres de l'ami —
qui sont synchronisés juste après — se rangent d'eux-mêmes sur ses étagères.

## Surface technique

**Le bug écrit avant la fonctionnalité** (issue 0090). `syncShelves` appelait
`modelContext.upsert(…, deleteMissing: true)`, et `upsert` commençait par lire **toutes** les
étagères du store, tous propriétaires confondus. Tant que le seul propriétaire synchronisé était
moi, personne ne pouvait s'en apercevoir. À la première synchronisation des étagères d'un ami, la
réponse ne contient que les siennes — et le passage de suppression aurait effacé les miennes.

`ModelContext.upsert` prend donc une portée (`scope`), qui vaut tout par défaut et **ne restreint
que la suppression**. La table de correspondance par identifiant reste globale : un document
retrouvé sous un `_id` existant doit être mis à jour sur place quelle que soit la portée, sinon
`@Attribute(.unique)` refuse le doublon. `syncShelves` passe le propriétaire qu'il synchronise.
Deux tests tiennent les deux moitiés de la règle : les étagères d'un autre survivent, celles du
propriétaire synchronisé que le serveur ne liste plus disparaissent.

**Le cycle de vie** (issue 0091). Les étagères d'un ami arrivent en trois endroits, et repartent
dans un quatrième :

- boucle des amis de `RootView.refreshUserData`, **avant** leurs livres — pour la raison qui vaut
  partout ailleurs : un exemplaire résout son appartenance contre des `Shelf` qui doivent déjà
  exister (ADR 0003). L'échec des étagères d'un ami est attrapé pour cet ami-là, et n'arrête ni la
  boucle ni la synchronisation de ses livres ;
- `UserModel.acceptRelation`, au `reconcile`, juste avant l'inventaire : un profil ouvert dans la
  foulée d'une acceptation montre les livres *et* les étagères, ou il montre une bande qui manque
  jusqu'au prochain lancement ;
- `UserModel.unfriend`, au `reconcile` : elles partent avec les exemplaires. **C'est ici ou nulle
  part** — `syncShelves` est ce qui élague les étagères d'un propriétaire, et il n'est plus jamais
  appelé pour quelqu'un qui a quitté mon réseau. Laissées derrière, elles resteraient en base pour
  toujours, et réapparaîtraient entières le jour où la relation se referait, avant qu'aucune
  synchronisation n'ait eu son mot à dire.

`UserModel.start` reçoit donc `shelfModel` à côté d'`inventoryModel`, pour cette seule raison.
Deux tests : retirer un ami supprime ses étagères et pas les miennes, et un serveur qui refuse le
retrait les garde — la suppression étant au `reconcile`, elle n'est jamais atteinte, exactement
comme pour ses livres.

Le portillon d'appartenance (`ShelfModel.isMembershipWriteInFlight`) n'a pas bougé : il est global
à l'app, et une synchronisation des étagères d'un ami est un lecteur de plus qui a raison de se
tenir tranquille pendant qu'une écriture optimiste sur les miennes attend sa réponse.

**La bande** (issue 0092) — `Features/Community/UserShelvesSection.swift`, une `Section` dont le
corps est le carrousel. `ShelfRowView` est repris **tel quel**, et c'est tout l'argument pour le
mettre là : la carte ne porte aucune affordance d'édition. Tout ce qui écrit est ailleurs — dans
l'« Ajouter » de l'en-tête, que cette section n'a pas, et dans la barre de navigation de
`ShelfDetailView`, qui se retire.

Deux détails de mise en page valent d'être dits :

- **posée sur rien** : `listRowBackground(Color.clear)`, `listRowSeparator(.hidden)` et
  `listRowInsets(EdgeInsets())` — la transparence pour le fond, les encarts remis à zéro pour que
  le carrousel aille d'un bord à l'autre au lieu d'être rentré dans les marges de la `List` ;
- **la largeur se mesure** : `ShelfRowView` prend une largeur explicite parce qu'une carte qui se
  mesure elle-même dans une `List` déclenche la boucle de `UICollectionView` d'ADR 0003, et un
  `GeometryReader` dans une rangée de liste n'a pas de hauteur intrinsèque à donner. C'est donc le
  `ScrollView` horizontal — qui remplit la rangée de toute façon — qui publie sa propre largeur
  par `onGeometryChange`, et les cartes ne sont dessinées qu'une fois cette largeur connue.

La liste du profil et le carrousel se figent tous les deux pendant qu'un livre est choisi
(`focus.isArmed`), sinon le glissement ferait défiler la page au lieu de déplacer la sélection. Le
`ShelfFocusModel` est injecté au niveau de `MainTabView`, donc la copie du livre pressé se dessine
au-dessus de toute l'app depuis cet écran comme depuis l'inventaire (ADR 0006).

**La lecture seule** (issue 0093) — `ShelfDetailView` compare `shelf.ownerId` à
`userModel.myUser?._id`. **Dérivée, pas transmise** : un paramètre `isReadOnly` peut être passé à
faux par un appelant ajouté plus tard, une étagère ne peut pas mentir sur son propriétaire. La
propriété absorbe au passage la garde que la barre d'outils avait déjà — une étagère qui ne se
résout pas (supprimée, pas encore synchronisée) n'est pas la mienne non plus.

Les deux gestes **disparaissent** au lieu d'être grisés. Un bouton éteint pose une question à
laquelle l'écran n'a pas de réponse à donner : ce n'est pas mon étagère, et le titre comme le
chemin qui y mène l'ont déjà dit.

## Ce qui n'est pas fait

- **Emprunter depuis l'étagère d'un ami.** La liste de ses livres, sur son profil, porte un menu
  contextuel « Emprunter à X » ; l'étagère ouverte ne le porte pas. La fiche du livre, elle, le
  porte — c'est une surface de moins à tenir en phase avec les règles de transaction, et le geste
  reste à un tap.
- **Rien n'est dit quand un ami ne partage aucune étagère.** La bande est simplement absente,
  plutôt qu'une carte vide : les deux états vides que l'inventaire sait montrer font une course
  qui m'appartient (scanner mes livres, les ranger), et ni l'un ni l'autre n'est quelque chose à
  demander de la bibliothèque d'un autre.
- **Une passe sur appareil.** La bande n'a été vue ni en sombre, ni en VoiceOver, ni au plus grand
  corps de texte, ni dans les deux langues. En particulier, le geste de pression sur un livre
  n'a pas été essayé au doigt à l'intérieur d'une `List` — c'est le seul endroit de l'app où il
  vit dans une liste plutôt que dans un `ScrollView`.
- **Le scénario end-to-end ne joue pas ce parcours** : il ne se connecte qu'à un compte, et une
  étagère partagée demande deux comptes amis.
