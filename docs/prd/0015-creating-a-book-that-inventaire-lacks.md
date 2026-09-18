# 0015 — Créer un livre qu'inventaire.io n'a pas

Maquettes : section `Créer un livre absent` (`433:11445`) sur la page `Screens` du
[fichier Figma](https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=433-11445),
huit frames `C1` → `C8` et un panneau `Spec · Créer un livre absent` (`441:11659`). Arbitrages rendus
le 2026-09-18 : variante **A** pour l'appel à créer, `C3` et `C4` dans la v1, couverture par
`enrich=true` **et** photo.

Ce que la feature change dans la doctrine du scanner : l'état `.notFound` cesse d'être une impasse.

## Problem Statement

Je scanne une pile de livres. Un sur cinq ne donne rien : la rangée monte, affiche mon code-barres
en rouge — « Cette édition n'existe pas sur inventaire.io » — et redescend trois secondes plus tard.
Le livre est dans ma main, je sais son titre, je sais qui l'a écrit, et l'app ne me propose rien.

Ce n'est pas un bug, c'est la nature de la base : inventaire.io est une base **ouverte**, nourrie par
ses lecteurs. Les éditions françaises et récentes y manquent souvent. Le scanner sait déjà le dire —
c'est tout le propos de l'état `.notFound` — mais il s'arrête là, et la rangée est la seule de
l'application à n'avoir **aucune action** : `offersAdd` la supprime explicitement, parce qu'un « + »
désactivé inviterait à taper dessus.

Résultat, trois choses se perdent en même temps :

- **Mon livre.** Il ne rentrera pas dans mon inventaire, ce soir ni jamais, tant que quelqu'un
  d'autre ne l'aura pas créé sur le site.
- **Le travail que je viens de faire.** J'ai lu le code-barres, j'ai le livre en main, j'ai
  l'information sous les yeux — et elle part avec moi.
- **La base.** Le seul moment où une base ouverte se remplit, c'est quand quelqu'un tient l'objet.
  L'app est exactement à cet endroit-là, et elle ne demande rien.

Le site sait le faire : quand on y scanne un ISBN inconnu, il propose de créer le livre. L'app ne
sait pas.

## Solution

La rangée qui dit « je ne connais pas ce livre » gagne un bouton rond, à la place exacte du « + »
qui file un livre reconnu (variante **A** des maquettes). Il ouvre une feuille, **Nouveau livre**,
qui ne demande que ce que le code-barres ne sait pas : le **titre** et l'**auteur**. L'ISBN est là,
en lecture seule ; la langue est déduite de son préfixe ; la couverture est facultative, prise en
photo si l'on veut, sinon cherchée par le serveur à partir de l'ISBN.

Avant d'écrire quoi que ce soit, l'app demande à inventaire.io ce qu'il reconnaît déjà. S'il connaît
l'auteur, on le choisit dans une liste plutôt que d'en créer un deuxième. S'il connaît l'œuvre —
*La Main gauche de la nuit* existe, c'est cette édition-là qui manque — l'écran le dit et l'on
n'ajoute qu'une édition de plus. C'est la seule façon de contribuer sans abîmer : le doublon est le
seul dégât qu'un contributeur de bonne foi puisse faire.

Puis on publie. **On attend le serveur** — rien n'est optimiste ici : un doublon public ne se reprend
pas d'un revers, et une publication qui a échoué doit se voir pendant que le livre est encore en
main. Quand le serveur répond, le livre existe pour tout le monde, il est dans mon inventaire, et
la caméra reprend la main pour le suivant.

## User Stories

1. En tant que lecteur qui scanne une pile, je veux qu'une édition inconnue me propose d'être créée,
   pour ne pas perdre le livre que je tiens.
2. En tant que lecteur, je veux que cette proposition tienne à la place du « + » habituel, pour que
   le geste soit le même que pour un livre reconnu.
3. En tant que lecteur, je veux que la rangée inconnue **reste à l'écran** jusqu'à ce que j'en fasse
   quelque chose, pour avoir le temps de décider.
4. En tant que lecteur pressé, je veux pouvoir viser le livre suivant pour chasser une rangée
   inconnue dont je ne veux rien faire, pour ne pas être bloqué par ma propre proposition.
5. En tant que contributeur, je veux qu'on me dise que ce que j'écris sera public, avant que je
   l'écrive, pour savoir où je mets mes mots.
6. En tant que contributeur, je veux que l'ISBN lu sur le code-barres soit déjà là et non modifiable,
   pour ne pas pouvoir me tromper sur la seule donnée dont l'app est sûre.
7. En tant que contributeur, je veux n'avoir que deux champs obligatoires — titre et auteur — pour
   que la contribution tienne en trente secondes.
8. En tant que contributeur francophone, je veux que la langue de l'édition soit déduite de l'ISBN,
   pour ne pas répondre à une question dont la réponse est déjà dans le code-barres.
9. En tant que contributeur, je veux voir les auteurs qu'inventaire.io connaît déjà pendant que je
   tape, pour choisir le bon plutôt que d'en créer un jumeau.
10. En tant que contributeur, je veux qu'un auteur existant se distingue par sa description et son
    nombre d'œuvres, pour trancher entre deux fiches qui portent le même nom.
11. En tant que contributeur, je veux pouvoir créer l'auteur quand aucun ne correspond, pour que
    l'absence d'une fiche ne m'arrête pas.
12. En tant que contributeur, je veux savoir quand l'œuvre existe déjà et que je n'ajoute qu'une
    édition, pour comprendre ce que je crée exactement.
13. En tant que contributeur, je veux pouvoir dire « non, c'est un autre livre » quand la
    ressemblance est trompeuse, pour ne pas rattacher mon édition à la mauvaise œuvre.
14. En tant que contributeur, je veux pouvoir photographier la couverture, parce que le livre est
    dans ma main et que c'est le seul moment où c'est facile.
15. En tant que contributeur, je veux que la photo reste facultative, pour publier même quand la
    lumière est mauvaise ou que je suis pressé.
16. En tant que contributeur, je veux que le serveur cherche lui-même une couverture à partir de
    l'ISBN, pour que le livre ne soit pas nu quand je n'ai pas pris de photo.
17. En tant que contributeur, je veux que l'échec d'une photo n'empêche pas la publication, parce
    que l'image est un ornement et le livre est l'essentiel.
18. En tant que lecteur, je veux que le livre créé arrive dans mon inventaire sans geste
    supplémentaire, parce que c'est pour ça que je le scannais.
19. En tant que lecteur, je veux que le livre créé compte dans le bilan de fin de session, pour que
    le total dise la vérité sur ce que j'ai fait.
20. En tant que contributeur, je veux voir que la publication est en cours, pour ne pas taper deux
    fois.
21. En tant que contributeur, je veux qu'une publication ratée me le dise pendant que le livre est
    encore en main, pour pouvoir réessayer tout de suite.
22. En tant que contributeur, je veux que mon brouillon survive à un échec, pour ne pas ressaisir
    ce que je viens de taper.
23. En tant que contributeur, je veux savoir que rien n'a été créé côté serveur quand ça a échoué,
    pour ne pas craindre d'avoir fait un doublon en réessayant.
24. En tant que contributeur, je veux pouvoir abandonner la création et revenir à la caméra, pour
    que la feuille ne soit pas un piège.
25. En tant que lecteur non connecté ou déconnecté en route, je veux une erreur qui dit que la
    contribution demande un compte, plutôt qu'un échec muet.
26. En tant que lecteur, je veux que la caméra ne prenne aucun nouveau code-barres pendant que la
    feuille est ouverte, pour ne pas revenir sur une rangée qui a changé sous mes doigts.
27. En tant que lecteur qui rescanne le même livre après l'avoir créé, je veux le voir reconnu
    comme n'importe quel autre, pour vérifier que ma contribution a pris.
28. En tant que contributeur, je veux que l'édition créée porte le titre exact que j'ai tapé, pas le
    titre de l'œuvre, parce que c'est ce qui est imprimé sur ma couverture.
29. En tant que lecteur aveugle ou malvoyant, je veux que le bouton de création s'annonce autrement
    que le bouton d'ajout, pour savoir ce que je déclenche.
30. En tant que lecteur, je veux que tout cela existe en français et en anglais, comme le reste de
    l'application.

## Implementation Decisions

**Le contrat serveur, vérifié le 2026-09-18 sur `https://inventaire.io/public/api_specs.json` et sur
la source Codeberg.**

- `POST /api/entities/resolve` porte toute la création. Une entrée `{ edition, works, authors }` :
  l'édition avec `wdt:P212` (l'ISBN lu) et `wdt:P1476` (le titre saisi), l'œuvre avec son label ou
  son uri, l'auteur avec le sien. Les drapeaux `create`, `update`, `enrich`, `strict` sont des
  paramètres du corps.
- **Deux appels, pas un.** Un premier `resolve` **sans `create`** dit ce qu'inventaire reconnaît —
  c'est la matière des écrans « auteur » et « l'œuvre est déjà là ». Un second avec
  `create=true, enrich=true, strict=true` écrit.
- Une entité reconnue est désignée par son **uri** dans le seed (`authors: [{ uri }]`,
  `wdt:P629: [uri]`) ; une entité à créer est désignée par ses **labels**. C'est ce qui évite le
  doublon, et c'est le serveur qui arbitre, pas l'app.
- `GET /api/data/isbn?isbn=…` est **public** et rend `groupLang` (`fr` → `wd:Q150`) : la langue est
  déduite, jamais demandée. Échec ⇒ `wdt:P407` est omis, pas deviné.
- `POST /api/images/upload?container=entities` est un **multipart/form-data** ; la réponse indexe
  l'URL de l'image **par le nom du champ de formulaire**. L'URL rendue part dans `image` du seed
  d'édition.
- L'uri à poser dans l'item d'inventaire est la **canonique** rendue par `resolve`, jamais
  `isbn:…` — le même piège que documente déjà la vérification de possession du scanner.

**Les modules.**

- Un **constructeur de payload** pur : il prend un brouillon (ISBN, titre, nom ou uri d'auteur, uri
  d'œuvre éventuelle, langue, URL d'image) et rend la requête `resolve`. Aucune dépendance au réseau,
  à SwiftData ni à SwiftUI — c'est le module profond de cette feature, et celui qui porte les règles
  (uri contre label, P407 présent ou absent, ISBN normalisé sans tirets).
- Un **lecteur de réponse** pur : il dit, d'une réponse `resolve`, quelles entités ont été reconnues
  et quelle uri canonique porte l'édition.
- Un **modèle de création** (`@Observable @MainActor`, dans la couche service, à côté des autres
  modèles de domaine) : il enchaîne langue → photo → upload → resolve à blanc → resolve créateur, et
  n'expose que des méthodes `throws` qui ne rendent rien à afficher. Injecté comme tous les autres
  modèles partagés, aux **deux** endroits habituels.
- **La machine à états du scanner** change de règle, pas de forme : `.notFound` devient un état
  actionnable et persistant (plus de minuteur de notice), et un **code différent peut l'évincer**,
  ce que rien ne pouvait faire jusqu'ici. `.resolved` et `.adding` restent inévictables. Un
  événement neuf porte la fin de la création et incrémente le compteur de session, pour que le
  bilan reste vrai.
- **Le service réseau** gagne un envoi multipart. Il n'en avait aucun ; c'est la seule extension de
  sa surface.
- **La recherche d'auteurs réutilise la recherche existante** (`types=humans`), avec son score et sa
  description. `resolve` réconcilie, il ne cherche pas au fil de la frappe.
- **L'interface** : la feuille de création est posée sur la vue caméra, pas poussée dans la pile de
  navigation du flux — la pile appartient au chemin de la fiche livre. Les écrans réutilisent les
  composants du design system tels qu'ils sont ; aucun composant nouveau n'est nécessaire côté
  Figma, et côté Swift seuls le choix d'auteur et le rattachement d'œuvre sont des vues neuves.
- **La capture de couverture** est la seule couture UIKit de la feature, isolée dans une vue
  représentable dédiée, avec repli sur la photothèque quand l'appareil photo n'existe pas.
- **Rien n'est optimiste.** L'écriture attend le serveur, comme l'ajout du scanner le fait déjà et
  pour une raison plus forte encore : on écrit dans une base publique.

## Testing Decisions

Un bon test ici décrit un **comportement observable** : la requête qui part sur le fil, l'état où
la machine atterrit, la décision prise à partir d'une réponse. Jamais la forme interne d'un type.
Prior art dans le dépôt : les suites Swift Testing pures du scanner, et les suites adossées à
`MockURLProtocol` pour les modèles.

Trois suites, aucune ne touchant le réseau réel :

- **Le constructeur de payload.** Un auteur choisi part en uri et non en label ; un auteur créé part
  en labels ; une œuvre reconnue devient une revendication `wdt:P629` ; la langue absente n'ajoute
  aucune revendication ; l'ISBN part normalisé ; l'image n'est là que quand il y en a une.
- **La machine à états.** `.notFound` ne s'efface plus toute seule ; un code **différent** l'évince ;
  le **même** code ne la rejoue pas ; `.resolved` et `.adding` restent inévictables ; la fin de
  création pose `.added` et incrémente la tally une seule fois.
- **Le modèle de création**, sur `MockURLProtocol` : la séquence d'appels attendue, un upload en
  échec qui ne fait pas échouer la publication, un `resolve` en erreur qui remonte sans rien laisser
  derrière.

Le scénario end-to-end **n'est pas joué** dans ce travail — il coûte dix minutes et déclenche la
limitation de connexion d'inventaire.io. Les identifiants `e2e.*` sont posés sur les nouveaux
éléments pour qu'il puisse l'être plus tard.

## Out of Scope

- **La deuxième porte** — créer un livre depuis une recherche qui ne trouve rien (frame `C6`). Elle
  demande une saisie manuelle de l'ISBN et s'adosse à l'absence de l'issue 0086. Elle fera l'objet
  d'une issue à part.
- **Modifier une fiche existante** : corriger un titre, ajouter une couverture à une édition déjà
  là, fusionner deux auteurs. Tout cela se fait sur inventaire.io.
- **Les champs facultatifs** — éditeur, année, nombre de pages. La ligne existe dans la maquette,
  elle ne mène nulle part en v1.
- **Créer une œuvre sans édition**, ou un auteur seul, hors du parcours de scan.
- **Le mode hors ligne** : aucune file d'attente, aucune reprise différée. Un échec est un échec,
  le brouillon reste à l'écran.
- **Le glyphe `book.badge.plus`** dans la bibliothèque Figma : le bouton porte un « + » tant qu'il
  n'existe pas.

## Further Notes

Le panneau `Spec · Créer un livre absent` du fichier Figma porte trois manques du design system
relevés pendant la maquette, et aucun n'est bloquant : pas de glyphe `book.badge.plus`, pas de
chrome de feuille modale (la barre de navigation « Inline + Back + Text action » en tient lieu), et
un composant `Field` sans état d'erreur ni valeur en lecture seule.

La limitation de débit d'inventaire.io s'applique aussi ici : l'upload d'image accepte 50 requêtes
avec une seconde minimum entre deux. Rien dans ce parcours ne peut en émettre plus d'une à la fois,
mais une reprise agressive après échec le pourrait — d'où le fait que réessayer soit un geste de
l'utilisateur, jamais une boucle.
