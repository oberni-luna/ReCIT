# C2b · Rangement indisponible — `87:2960`

Le bilan quand le téléphone ne peut pas exécuter le rangement.

| Élément | Contenu |
|---|---|
| `title` | « 24 livres ajoutés » — inchangé, l'ajout a bien eu lieu |
| `body` | « Ils ne sont sur aucune étagère. » — raccourci |
| `reason` | 32,604 329 — `Footnote/footnote200`, `foreground/secondary` : « Le rangement automatique a besoin d'Apple Intelligence, désactivé sur cet appareil. Vous pouvez ranger vos livres à la main en attendant. » |
| `cta` | `Style=Primary` — « Ouvrir les Réglages » |
| `skip` | « Continuer sans ranger » |

## Les trois cas de features/0008, transposés au bilan

| Cause | Écran |
|---|---|
| Apple Intelligence désactivée | cet écran, raison dite + route Réglages |
| Appareil inéligible | même écran, **sans CTA** — seulement « Continuer ». L'utilisateur n'y peut rien |
| Modèle en cours de téléchargement | CTA inerte, décrit comme temporaire |

Règle héritée de 0008 : jamais de substitution silencieuse. Un bilan qui ouvrirait autre chose à la place
du rangement se lirait comme le mauvais écran.

Pas de variante sombre maquettée. Les variantes « inéligible » et « téléchargement » ne sont pas maquettées
non plus — dérivées de celle-ci.
