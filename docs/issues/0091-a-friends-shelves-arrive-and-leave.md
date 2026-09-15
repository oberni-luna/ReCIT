Title: Les étagères d'un ami arrivent avec ses livres, et repartent avec lui
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/` — les étagères partagées d'un ami.

## What to build

Aujourd'hui `syncShelves` n'est appelé que pour `myUser`. Les étagères d'un ami n'existent nulle
part côté app, ce qui est la raison pour laquelle l'écran ne peut rien en montrer. Cette issue ne
dessine rien : elle fait entrer les données, et les fait ressortir.

**`GET /api/shelves?action=by-owners&owners=<id>` suffit.** Le serveur applique la visibilité :
ce qu'il rend pour un ami est exactement ce que cet ami partage avec moi. **Aucun filtrage côté
app** — `ShelfDTO` documente que `visibility` peut être absent pour un non-propriétaire, donc
filtrer localement reviendrait à masquer des étagères pourtant partagées.

**Trois points de couture :**

1. `RootView+RefreshUserData`, boucle des amis : `syncShelves` **avant** `syncInventory`, pour la
   même raison que pour moi — un item résout son appartenance contre des `Shelf` qui doivent déjà
   exister. Un échec sur les étagères d'un ami ne doit pas emporter la synchro de ses livres.
2. `UserModel.acceptRelation` : le `reconcile` tire déjà l'inventaire du nouvel ami sur-le-champ,
   pour qu'un profil ouvert dans la foulée ne dise pas « c'est vide ici ». Ses étagères suivent le
   même chemin, et dans le même ordre. `UserModel` reçoit `shelfModel` par `start(…)`, comme il
   reçoit déjà `inventoryModel`.
3. `UserModel.unfriend` : le `reconcile` supprime les copies de l'ex-ami après l'accord du
   serveur. Ses étagères partent avec elles. Sans cela le store garde des étagères d'un lecteur qui
   n'est plus dans mon réseau, et la prochaine `syncShelves` ne peut plus les nettoyer — on ne
   synchronise plus quelqu'un qui n'est plus un ami.

Le portillon d'appartenance (`ShelfModel.isMembershipWriteInFlight`) est global à l'app et reste
tel quel : il protège une écriture optimiste sur **mes** étagères, et une synchro des étagères d'un
ami est un lecteur de plus qui a raison de se tenir tranquille pendant ce temps.

## Acceptance criteria

- [ ] `syncShelves` est appelé pour chaque ami, avant `syncInventory`, dans la boucle de
      `refreshUserData`
- [ ] Un échec de la synchro des étagères d'un ami n'interrompt ni la boucle ni la synchro de ses
      livres
- [ ] Accepter une invitation fait arriver les étagères du nouvel ami en même temps que ses livres
- [ ] Retirer un ami supprime ses étagères comme ses copies, après l'accord du serveur
- [ ] Aucun filtrage de `visibility` côté app
- [ ] Mes étagères sont intactes après une synchro d'un ami (garanti par l'issue 0090)
- [ ] `xcodebuild -scheme ReCIT_iOSTests` passe

## Blocked by

- `docs/issues/0090-shelf-sync-delete-pass-scoped-to-one-owner.md`
