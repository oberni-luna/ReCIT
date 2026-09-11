Title: Revue sur appareil des astuces de tri, et le scénario end-to-end
Labels: needs-triage, chore
Type: HITL

## Parent

`docs/prd/0013-sorting-tips.md`

## What to build

La recette de cette feature est manuelle, et c'est le choix assumé : cette issue est cette recette,
faite une fois les trois astuces en place, sur un vrai appareil et dans les deux langues. La ligne
« Réafficher les astuces » de la section Debug est l'outil.

Deux choses ne se voient que là :

- **Le scénario end-to-end joue cet écran.** Une carte posée sur un identifiant `e2e.*` — le
  premier livre du carrousel, « Appliquer », la grille — ferait échouer une étape sans rapport
  avec ce qu'elle teste. Soit les astuces sont placées de façon à ne rien recouvrir, soit le
  scénario les ferme explicitement, et alors il le dit dans
  `docs/features/0012-end-to-end-scenario.md`.
- **Tout le reste tient dans l'œil** : VoiceOver, corps de texte agrandi, mode sombre, les deux
  langues, et un appareil sans Apple Intelligence.

La fiche de passage, chaque ligne rejouée après un « Réafficher les astuces » : première ouverture
avec des livres à ranger ; ouverture avec rien à ranger ; ouverture pendant la synchronisation ;
premier dépôt ; premier « Appliquer » ; première proposition ; fermeture d'une astuce sans faire le
geste, trois fois de suite ; deux comptes sur le même téléphone ; déconnexion et reconnexion.

## Acceptance criteria

- [ ] `scripts/e2e.sh` passe avec les astuces actives, sans étape masquée par une carte
- [ ] Si le scénario ferme des astuces, `docs/features/0012-end-to-end-scenario.md` le dit
- [ ] Les trois astuces sont lues en VoiceOver : annoncées à l'arrivée, croix atteignable
- [ ] Au plus grand corps de texte, aucune carte ne tronque son texte ni ne déborde de l'écran
- [ ] Les trois astuces sont vérifiées en clair et en sombre, en français et en anglais
- [ ] Sur un appareil sans Apple Intelligence, aucune astuce ne parle de la proposition
- [ ] Une astuce fermée sans le geste revient, mais pas indéfiniment — le plafond retenu est écrit
      ici
- [ ] Les captures de la passe sont jointes, ou le compte rendu dit ce qui a été vu
- [ ] Un document de feature est écrit dans `docs/features/` et le PRD 0013 est supprimé

## Blocked by

- `docs/issues/0079-sort-tip-nothing-saved-yet.md`
- `docs/issues/0080-sort-tip-let-it-propose.md`
- `docs/issues/0081-footer-gives-back-its-first-sentence.md`
