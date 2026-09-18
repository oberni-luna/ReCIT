Title: Photographier la couverture, pendant que le livre est en main
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0015-creating-a-book-that-inventaire-lacks.md` — frame `C2`, emplacement de couverture.

## What to build

`enrich=true` va déjà chercher une couverture depuis l'ISBN. La photo est le secours, pour les
éditions que personne n'a jamais photographiées — et le seul moment où c'est facile est celui-ci.

- Un emplacement pointillé dans la feuille ouvre l'appareil photo. C'est la **seule couture UIKit**
  de la feature : une vue représentable dédiée, avec repli sur la photothèque quand l'appareil photo
  n'est pas disponible (simulateur).
- `APIService` gagne un envoi **multipart/form-data** — il n'en avait aucun. L'upload part vers
  `POST /api/images/upload?container=entities` ; la réponse **indexe l'URL par le nom du champ de
  formulaire** envoyé (source Codeberg, vérifiée le 2026-09-18).
- L'URL rendue part dans `image` du seed d'édition.
- **Un upload en échec n'empêche jamais de publier** : on publie sans image et on le dit en une
  ligne. L'ordre est photo (facultative) → upload → resolve.
- L'image est réduite avant envoi ; rien n'est envoyé si l'utilisateur n'a pas pris de photo.

## Acceptance criteria

- [ ] L'emplacement ouvre l'appareil photo, et la photothèque là où l'appareil photo n'existe pas
- [ ] La photo prise s'affiche dans l'emplacement, et peut être reprise
- [ ] La requête d'upload est un `multipart/form-data` authentifié vers le bon conteneur
- [ ] L'URL rendue se retrouve dans `image` du seed d'édition
- [ ] Un upload en erreur laisse la publication aboutir, sans image, avec un mot à l'écran
- [ ] Aucune requête d'upload quand aucune photo n'a été prise
- [ ] L'envoi multipart est couvert par un test adossé à `MockURLProtocol`
- [ ] Textes en français et en anglais

## Blocked by

- `docs/issues/0091-publish-a-minimal-edition.md`
