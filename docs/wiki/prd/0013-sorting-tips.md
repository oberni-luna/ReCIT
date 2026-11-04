# 0013 — Les astuces de « Ranger mes livres »

Maquettes : section `Astuces · TipKit` (`314:8069`) du fichier Figma — frames `SORT-1` (`314:8109`),
`SORT-2` (`314:8199`), `SORT-3` (`314:8247`) et le panneau `Spec · Astuces TipKit` (`318:8580`).
Voir [figma-library.md](../design-system/figma-library.md), passe du 2026-09-09 (2). Les trois
frames `INV-*` de la même section **ne sont pas** dans le périmètre de ce PRD.

## Problem Statement

« Ranger mes livres » est un écran dont toute la grammaire est gestuelle, et dont aucun geste ne se
voit.

- **Le glissement ne s'annonce pas.** Un livre se prend dans le carrousel du bas et se dépose sur
  une carte ; une carte rend son livre de tête au carrousel par le geste inverse. Rien à l'écran
  ne ressemble à une poignée : les couvertures ont l'air d'une liste, et une liste, on la fait
  défiler. L'app le sait si bien qu'elle a écrit l'instruction **en dur dans le pied de page** —
  `manual_sort.footer.idle` commence par « Drag & drop les livres dans les étagères pour les
  ranger. » Cette phrase est là pour toujours, y compris pour quelqu'un qui a rangé deux cents
  livres, et elle occupe la moitié de la seule ligne qui devrait dire ce que « Appliquer » va
  écrire.
- **Rien ne dit que rien n'est enregistré.** C'est la décision la plus importante de l'écran
  (PRD 0009 : la session vit en mémoire, rien ne part avant « Appliquer ») et c'est la seule qui
  ne soit écrite nulle part avant qu'un changement existe. Un utilisateur qui range trois livres
  puis ferme le modal croit avoir rangé ; un utilisateur qui hésite à déposer un livre ne sait
  pas que le geste est réversible d'un autre geste et gratuit jusqu'à l'enregistrement.
- **Le bouton de proposition est un glyphe seul.** Une baguette dans un rond, à droite d'un bouton
  large qui, lui, porte son mot. Rien ne dit que l'iPhone peut remplir les étagères tout seul à
  partir des titres et des genres, ni que sa proposition se corrige avant d'être appliquée. Sur un
  appareil sans Apple Intelligence le bouton n'est même pas dessiné, ce qui veut dire que
  l'affordance est à la fois invisible et intermittente.

Ces trois manques ont la même forme : une connaissance nécessaire, portée soit par rien, soit par
une ligne de chrome permanente qui ne s'adresse à personne en particulier.

## Solution

**Trois astuces TipKit, ordonnées, chacune invalidée par le geste qu'elle enseigne.** Une seule à
l'écran à la fois. Qui fait déjà le geste ne voit jamais l'astuce qui l'explique.

1. **SORT-1 · « Glissez pour ranger »** — pointe sur le premier livre de « Livres à ranger », à
   l'ouverture de la surface, dès qu'il y a au moins un livre à ranger. Dit le geste **et son
   inverse** : « Prenez un livre ici et déposez-le sur une étagère. Le geste inverse l'en
   retire. » Elle disparaît au premier dépôt réussi, et ne revient jamais.
2. **SORT-2 · « Rien n'est encore enregistré »** — pointe sur « Appliquer », et n'arrive **qu'une
   fois qu'il y a quelque chose à enregistrer**, donc après que SORT-1 a servi. « Vos étagères ne
   changent qu'après « Appliquer ». La phrase du bas dit ce qui sera enregistré. » Elle relie la
   décision au seul endroit où elle se lit déjà — le récapitulatif — au lieu d'ajouter une
   quatrième lecture au pied de page. Elle disparaît au premier « Appliquer » lancé.
3. **SORT-3 · « Laissez proposer un rangement »** — pointe sur le bouton de proposition, seulement
   là où Apple Intelligence tourne, et seulement une fois le glissement appris : la proposition
   est une aide au geste, pas un remplacement, et la montrer d'abord apprendrait à ne jamais
   ranger soi-même. « Votre iPhone lit les titres et les genres, et remplit les étagères. À vous
   de corriger avant d'appliquer. » Elle disparaît dès qu'une proposition est demandée.

**Et le pied de page rend la moitié de sa phrase.** SORT-1 dit le glissement mieux que
`manual_sort.footer.idle` ne le disait — au bon moment, une seule fois, et en visant le livre dont
il parle. La lecture au repos du pied de page se réduit donc à son état : « Rien à appliquer pour
le moment. » L'instruction permanente s'en va avec l'astuce qui la remplace.

L'apparence est celle de la maquette, et non celle de TipKit par défaut : carte verte
(`background/tinted-inverse`), titre en `Action/action300`, texte en `Content/content300`, ombre
`Shadow/Light`, pointe de 20 × 9 vers l'élément visé.

## User Stories

1. En tant qu'utilisateur qui ouvre « Ranger mes livres » pour la première fois, je veux qu'on me
   dise comment déplacer un livre, pour ne pas croire que l'écran ne fait que montrer.
2. En tant qu'utilisateur, je veux que cette explication vise le livre dont elle parle, pour ne
   pas avoir à deviner de quoi elle parle.
3. En tant qu'utilisateur, je veux apprendre le geste **et** son inverse dans la même phrase, pour
   oser un premier dépôt sans craindre de me tromper.
4. En tant qu'utilisateur qui a déjà rangé des livres au glissement, je ne veux plus jamais voir
   l'astuce qui l'explique, pour que l'écran ne me traite pas en débutant à chaque visite.
5. En tant qu'utilisateur, je veux que l'astuce s'efface d'un geste de fermeture, pour reprendre
   mon rangement tout de suite.
6. En tant qu'utilisateur qui vient de déposer son premier livre, je veux qu'on m'apprenne que
   rien n'est enregistré, pour ne pas fermer l'écran en croyant avoir rangé.
7. En tant qu'utilisateur, je veux que cette astuce arrive **après** mon premier dépôt et pas
   avant, pour qu'elle parle d'un travail qui existe.
8. En tant qu'utilisateur, je veux qu'elle me renvoie à la phrase du bas, pour savoir où lire ce
   qui partira au serveur.
9. En tant qu'utilisateur qui a déjà appliqué une fois, je ne veux plus voir cette astuce, parce
   que j'ai appris ce qu'« Appliquer » fait en l'utilisant.
10. En tant qu'utilisateur d'un iPhone qui sait faire tourner Apple Intelligence, je veux
    apprendre que mon téléphone peut proposer un rangement, parce qu'un glyphe de baguette ne me
    le dit pas.
11. En tant qu'utilisateur, je veux qu'on me dise dans la même phrase que la proposition se
    corrige avant d'être appliquée, pour la demander sans me sentir engagé.
12. En tant qu'utilisateur d'un appareil sans Apple Intelligence, je ne veux voir aucune astuce
    à propos d'une fonction que je n'ai pas, puisque le bouton lui-même n'est pas dessiné.
13. En tant qu'utilisateur, je veux que la proposition me soit présentée **après** avoir appris à
    ranger moi-même, pour que l'écran ne me propose pas de sauter l'étape qu'il vient de
    m'apprendre.
14. En tant qu'utilisateur, je ne veux jamais deux astuces à l'écran en même temps, parce que deux
    cartes sur trois cartes d'étagère ne laissent plus rien à ranger.
15. En tant qu'utilisateur, je ne veux aucune astuce pendant que « Appliquer » écrit, pour que
    l'écran ne parle pas par-dessus son propre travail.
16. En tant qu'utilisateur dont l'inventaire est encore en cours de synchronisation, je ne veux
    pas d'astuce sur un carrousel vide, parce qu'elle désignerait un livre qui n'est pas là.
17. En tant qu'utilisateur qui a tout rangé, je ne veux pas qu'on me propose de glisser un livre
    qui n'existe plus dans le carrousel.
18. En tant qu'utilisateur qui ferme le modal en plein milieu et le rouvre, je veux retrouver
    l'astuce que je n'avais pas encore lue, et pas celles que j'ai déjà apprises.
19. En tant qu'utilisateur, je veux que ce que j'ai appris soit attaché à **mon compte** et pas au
    téléphone, pour qu'une autre personne sur le même appareil ait droit aux mêmes astuces.
20. En tant qu'utilisateur qui se déconnecte et se reconnecte, je ne veux pas revoir les astuces :
    me reconnecter n'est pas une première fois.
21. En tant qu'utilisateur, je veux lire les astuces dans ma langue, comme le reste de l'écran.
22. En tant qu'utilisateur en corps de texte agrandi, je veux que la carte grandisse avec le texte
    plutôt que de le tronquer.
23. En tant qu'utilisateur en mode sombre, je veux une carte qui reste lisible, sans que personne
    ait eu à la redessiner.
24. En tant qu'utilisateur de VoiceOver, je veux que l'astuce soit annoncée quand elle arrive et
    qu'elle soit fermable au clavier comme au doigt.
25. En tant qu'utilisateur, je ne veux plus lire une instruction de glissement permanente sous les
    boutons, puisque l'astuce me l'a dite au bon moment.
26. En tant que développeur, je veux pouvoir remettre les astuces à zéro depuis la section Debug du
    profil, pour tester l'écran sans créer un compte à chaque essai.
27. En tant que développeur, je veux que la règle « quelle astuce est due, et quand » vive dans un
    type pur, pour la lire et la raisonner sans lancer l'app.
28. En tant que développeur, je veux que ce type ait la forme d'`OnboardingGate`, pour que les deux
    décisions de première fois de l'app se lisent de la même façon.
29. En tant qu'utilisateur, je veux qu'une astuce fermée sans avoir fait le geste revienne une
    prochaine fois — mais pas indéfiniment — pour ne pas perdre l'information sur une fermeture
    accidentelle.
30. En tant qu'utilisateur, je veux que le scénario end-to-end continue de passer : les astuces ne
    doivent pas masquer les éléments que le scénario touche.

## Implementation Decisions

- **Un type pur décide, TipKit ne fait qu'afficher.** `Model/Tips/SortTipGate` (ou nom voisin) est
  une fonction de l'état vers « quelle astuce est due » : nombre de livres à ranger, existence
  d'un changement en attente, disponibilité du modèle, écriture en cours, et ce qui a déjà été
  appris. Aucune dépendance à TipKit, aucune dépendance à SwiftData, aucun accès au disque — la
  même forme qu'`OnboardingGate`, y compris dans l'esprit : la vue ne décide rien, elle pose la
  question.
- **Les `Tip` TipKit sont muettes.** Chaque astuce est un `Tip` sans `#Rule` de fond : un unique
  `@Parameter` booléen, piloté par le gate. L'ordre est porté par un `TipGroup(.ordered)` sur la
  surface de tri, ce qui garantit l'unicité à l'écran ; l'éligibilité reste dans le type pur, où
  elle se lit. Les règles natives auraient éparpillé l'ordre et l'éligibilité dans trois fichiers
  et les auraient rendues inobservables.
- **La mémoire est par utilisateur.** `AppModels/Tips/TipsStore` (forme d'`OnboardingStore` :
  ensemble observé, miroir `UserDefaults`, injecté) enregistre les astuces acquises par
  `userId`. La déconnexion n'efface rien. Les `datastoreLocation` de TipKit restent par
  application ; ce qui fait foi pour « cette personne a appris ce geste », c'est le store, et le
  paramètre booléen des `Tip` en découle.
- **Trois invalidations, aux trois endroits où le geste se produit**, et nulle part ailleurs :
  le premier `moveBook` accepté depuis le carrousel vers une étagère, le premier `apply` lancé,
  la première `proposeArrangement` demandée. Ce sont des faits de `SortSessionModel`, pas des
  faits de vue : un dépôt refusé n'apprend rien.
- **L'éligibilité lit la session, pas le store SwiftData.** `SortSessionModel` expose déjà
  `phase`, `hasPendingChanges`, `isApplying`, `isProposing` et la projection d'où sortent les
  livres à ranger. Le gate prend ces valeurs en entrée ; il ne va rien chercher lui-même.
- **La disponibilité d'Apple Intelligence entre par `AutoSortModel.availability`**, comme pour le
  bouton lui-même, de sorte que l'astuce et le bouton ne puissent pas être en désaccord — et,
  comme ce modèle est observable, quelqu'un qui active Apple Intelligence et revient trouve les
  deux ensemble, sans relancer.
- **Aucune astuce pendant que l'écran travaille** : `isApplying` ou `isProposing` suffit à rendre
  le gate muet, ce qui règle par construction le cas de l'astuce posée sur des cartes qui
  respirent.
- **Le composant d'affichage est à nous.** Un `TipViewStyle` reprend la carte de la maquette
  (tokens du design system, pas de valeurs littérales) et la pointe reste hors de la carte, comme
  dans le fichier Figma, pour viser le premier livre ou un bouton sans déformer la carte.
- **`manual_sort.footer.idle` perd sa première phrase.** La chaîne se réduit à son état
  (« Rien à appliquer pour le moment. » / « Nothing to apply for now. ») en français et en
  anglais. C'est la contrepartie de SORT-1 : l'instruction est dite une fois, au bon moment,
  plutôt qu'en permanence à tout le monde.
- **Une ligne dans la section Debug du profil** — `ProfileDebugSection`, qui existe déjà et qui
  porte déjà les entrées de première fois : « Réafficher les astuces » vide le store pour
  l'utilisateur courant et appelle `Tips.resetDatastore()`. `#if DEBUG`, non traduite, non
  stylée, comme ses voisines.
- **Le scénario end-to-end**, qui joue cet écran, doit continuer de passer : les astuces sont
  posées de façon à ne pas recouvrir les identifiants `e2e.*` qu'il vise, ou le scénario les ferme
  explicitement.

## Testing Decisions

Pas de suite automatisée pour cette feature : la recette est manuelle, et c'est le choix assumé du
propriétaire. Ce qui la rend possible :

- **« Réafficher les astuces »** dans la section Debug du profil remet l'état à zéro sans changer
  de compte ni réinstaller. C'est l'outil de test, et il fait partie du périmètre.
- Les états à repasser à la main : première ouverture avec des livres à ranger, ouverture avec
  rien à ranger, premier dépôt, premier « Appliquer », appareil avec et sans Apple Intelligence,
  français et anglais, clair et sombre, corps de texte agrandi, VoiceOver.
- Les suites existantes de la surface de tri (plan d'écriture, atterrissage, registre) doivent
  rester vertes : ce PRD n'a pas le droit de déplacer le modèle.

## Out of Scope

- **Les trois astuces de l'écran Inventaire** (`INV-1`, `INV-2`, `INV-3` dans la même section
  Figma). Elles sont dessinées, elles ne sont pas ici.
- Toute astuce ailleurs dans l'app : recherche, listes, fiche livre, scanner.
- Un centre d'aide, un tutoriel rejouable, une visite guidée.
- Le modèle de la surface de tri : snapshot gelé, pile de changements, `SortWritePlan`, registre
  reprenable. Rien n'y touche.
- La proposition elle-même (ce que le modèle range et comment) : l'astuce la présente, elle ne la
  change pas.
- Les maquettes en mode sombre : la carte est bâtie sur des tokens, le sombre suit sans redessin.

## Further Notes

- **Pourquoi cet écran d'abord.** C'est celui dont la grammaire est la moins visible, et le seul où
  l'ignorance coûte du travail perdu — fermer le modal sans appliquer efface un rangement fait à la
  main. L'inventaire, lui, ne fait perdre qu'un geste.
- **La pointe hors de la carte** est une contrainte constatée dans Figma (un nœud d'instance ne se
  déplace pas) qui se trouve être la bonne structure côté code aussi : la carte ne sait pas qui
  elle vise.
- **Le nombre d'astuces est un plafond, pas un objectif.** Trois pour tout l'écran ; toute
  quatrième idée d'astuce sur cette surface doit d'abord en retirer une.
- TipKit demande iOS 17 ; la cible est iOS 26, donc rien à arbitrer de ce côté.
