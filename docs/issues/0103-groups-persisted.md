Title: Les groupes persistés en SwiftData, synchronisés juste après les relations
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0019-network-graph.md`

## What to build

Mes groupes — admin, membre, invité, et les demandes envoyées depuis cet appareil — sont dans le store
SwiftData, là dès l'ouverture de l'app et hors ligne, mis à jour en place à chaque synchro.

- Un `@Model` par groupe (`_id` unique, `_rev`, nom, slug, description, image absolue, ouvert,
  cherchable, et les cinq listes de rôles en memberships `{user, invitor, timestamp}` — des ids, aucune
  relation vers `User`) avec `init(dto:)` + `update(from:)` idempotent (Q11, Q11b, ADR 0001).
- `ReaderGroup` reste le type valeur du domaine ; le modèle persisté s'y convertit. Les tests purs de
  `ReaderGroup` passent sans changement.
- `GroupModel` lit et écrit le store : la synchro (`GET /api/groups` + relectures `by-id` du registre)
  fait un upsert avec **portée de suppression** (un groupe où je n'ai plus de rôle disparaît ; un groupe
  ouvert depuis la recherche reste en mémoire, hors store). Les gestes optimistes de 0028 écrivent dans
  le store, se réconcilient ou se défont.
- « Déjà synchronisé une fois » devient un marqueur persistant de `SyncStatusStore` ; l'échec de la
  dernière synchro reste en mémoire.
- La liste Groupes lit par `@Query` ; ses sections, tri, actions et identifiants `e2e.*` ne changent pas.
- Ordre de synchro : mon utilisateur, mes étagères, **relations, groupes**, mon inventaire, listes,
  transactions, inventaires des amis (Q11c).
- La déconnexion (0025) et la suppression de compte (0017) effacent les groupes.
- Le schéma du `ModelContainer` gagne le modèle (migration légère, sans `VersionedSchema`).

## Acceptance criteria

- [ ] Au relancement, la liste Groupes montre mes groupes avant toute réponse réseau, et hors ligne.
- [ ] Une synchro met à jour un groupe en place : l'objet SwiftData garde son identité (test).
- [ ] Un groupe quitté, ou dont l'invitation a été retirée, disparaît à la synchro suivante ; un groupe de recherche n'est pas touché (test).
- [ ] Un DTO sans `picture` ou sans `description` n'efface pas la valeur locale (test).
- [ ] Accepter / refuser / quitter / inviter restent optimistes et se défont sur échec (tests de `GroupModelTests` adaptés et verts).
- [ ] Les groupes sont demandés avant mon inventaire (test sur l'ordre des appels).
- [ ] La déconnexion et la suppression de compte vident les groupes (test).
- [ ] Un store créé au schéma précédent s'ouvre au nouveau (test).
- [ ] Les 12 tests de `ReaderGroupTests` passent sans modification ; la suite complète est verte ; la build compile.

## Blocked by

None - can start immediately
