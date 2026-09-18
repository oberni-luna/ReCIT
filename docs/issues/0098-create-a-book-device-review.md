Title: Passe sur appareil — créer un livre absent
Labels: needs-triage, device-review
Type: HITL

## Parent

`docs/features/0020-creating-a-book-that-inventaire-lacks.md`

## What to build

Rien, tant qu'on n'a pas regardé. Le parcours a été construit, compilé et couvert par des tests,
mais **jamais exercé sur un téléphone** — et deux morceaux ne peuvent pas l'être ailleurs :

- **La capture de couverture.** Le simulateur n'a pas d'appareil photo : `CoverCaptureView` n'a
  tourné que par son repli photothèque. Reste à voir le cadrage d'une couverture tenue à la main,
  la réduction à 1600 px de côté, le poids réel du JPEG envoyé, et ce que le bouton « reprendre »
  fait d'une photo déjà prise.
- **Le rythme du scan.** La rangée inconnue ne s'efface plus : il faut vérifier sur une vraie pile
  qu'elle ne gêne pas, que viser le livre suivant l'évince franchement, et que le même livre resté
  en vue ne relance rien.

À regarder aussi, une fois sur l'appareil : la feuille par-dessus la caméra (la caméra continue de
tourner derrière — coût batterie ?), la lisibilité de l'encart d'erreur sur la feuille, le retour
au scanner après publication, et le libellé VoiceOver du bouton rond, qui est la **seule** chose
qui le distingue du « + » d'ajout.

Enfin : jouer `scripts/e2e.sh` une fois, ce qui n'a pas été fait pendant l'implémentation.
Attention à la limitation de connexion d'inventaire.io.

## Acceptance criteria

- [ ] Une couverture photographiée sur l'appareil part et revient sur la fiche du livre créé
- [ ] Le poids de l'image envoyée est relevé et jugé acceptable
- [ ] Une pile de dix livres, dont trois inconnus, se scanne sans que la rangée inconnue gêne
- [ ] VoiceOver distingue « Créer ce livre » de « Ajouter à l'inventaire »
- [ ] Le scénario end-to-end a été joué une fois, et son compte-rendu lu

## Blocked by

None - can start immediately
