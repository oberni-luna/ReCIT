# 0014 — Un résultat de recherche est un livre, pas une œuvre

Pas de maquette : cette feature ne dessine aucun écran nouveau. Elle change ce qu'un tap ouvre,
retitre un écran existant, et remplace une phrase nue par le composant d'absence de l'app.

Décision d'architecture : [ADR 0002, Move 3](../adr/0002-unified-book-detail.md).

## Problem Statement

Je cherche « Dune ». L'app me montre une ligne sous l'en-tête **« Livres · 4 »**. Je tape dessus.
On me demande alors **laquelle des 66 éditions** je voulais dire.

C'est la seule question que je ne peux pas trancher. Je ne connais ni l'éditeur, ni l'année, ni
l'ISBN du livre que je cherche — je connais son titre, et c'est précisément pour ça que je l'ai
tapé. La liste qu'on me présente est longue, elle mélange le français, l'anglais, l'allemand et le
japonais, et une édition sur six s'y appelle **`Unknown`** parce que la fiche n'a pas de
revendication de titre.

Trois choses se sont cassées en même temps :

- **L'en-tête ment.** La section s'appelle « Livres » et elle contient des œuvres. Une œuvre n'est
  pas un livre : on ne la prête pas, on ne la donne pas, on ne la pose pas sur une étagère.
  L'ADR 0002 a passé deux moves à faire disparaître cette distinction de l'interface, et la
  recherche — le premier endroit où l'on rencontre un livre qu'on ne possède pas — est le dernier
  endroit où elle reste visible.
- **Le tap n'est pas une réponse, c'est une question.** Partout ailleurs dans l'app, taper un livre
  ouvre ce livre. Ici, taper un livre ouvre un formulaire de désambiguïsation. Le geste le plus
  ordinaire de l'écran de recherche est le seul qui n'aboutit pas.
- **Et parfois il n'aboutit jamais.** Certaines entités œuvre n'ont aucune édition — la recherche
  « americanah » en retourne deux, dont une vide. Dans ce cas le gateway reste sur son
  `ProgressView` indéfiniment. Le scénario end-to-end le sait déjà et le contourne : *« some of them
  have no edition at all, and their gateway sits on a spinner forever »*.

La contrainte qui a créé tout ça est réelle et ne bougera pas : **`/api/search` ne sait pas
retourner d'éditions.** Vérifié sur le serveur :

```
invalid types: editions (possible values: works, humans, genres, publishers,
series, collections, movements, languages, users, groups, shelves, lists)
```

La recherche rend donc des œuvres, et quelqu'un doit choisir l'édition. Aujourd'hui c'est
l'utilisateur. Ce PRD dit que c'est l'app.

## Solution

**Taper un résultat de recherche ouvre directement l'édition la plus pertinente.** Le picker ne
disparaît pas : il devient ce qu'il aurait toujours dû être, un écran qu'on ouvre *depuis un livre*
quand on veut en voir d'autres versions — « Autres éditions », qui existe déjà dans `BookDetailView`.

**La résolution a lieu au tap, pas dans la liste.** Elle coûte ~750 ms et ~60 KB par œuvre
(`reverse-claims` puis `by-uris`, mesuré), et `reverse-claims` ignore `limit` : la liste complète
des éditions revient toujours. Résoudre les quinze résultats coûterait trente requêtes et ~900 KB
par recherche, pour des lignes que personne ne fera défiler. La liste continue donc d'afficher le
label et la couverture que la recherche renvoie déjà en `lang=fr` — et l'en-tête « Livres · N »
devient vrai.

**L'écran s'ouvre tout de suite, rempli.** Le titre et la couverture voyagent avec le tap, puisque
le résultat de recherche les a déjà. Pendant la seconde de résolution, l'en-tête est le bon ; seul
le corps charge. Personne ne regarde un écran blanc.

**« La plus pertinente » est une échelle, pas un score.** Le premier palier non vide gagne :

1. français, avec un titre, avec une couverture ;
2. français, avec un titre ;
3. langue d'origine de l'œuvre, avec titre et couverture ;
4. n'importe quelle édition ayant un titre.

**Il n'y a pas de cinquième palier.** Une première version finissait par un fourre-tout, pour qu'un
tap ouvre toujours *quelque chose* — ce qui autorisait une redirection vers un livre appelé
`Unknown`. Écarté le 2026-09-11 : mieux vaut dire qu'il n'y a rien à montrer que d'envoyer
quelqu'un sur une fiche sans nom. Arriver au bout de l'échelle est une réponse, et l'écran a un
bloc pour elle.

**À l'intérieur du palier gagnant, un livre seul passe devant un coffret.** `wdt:P629` dit de
combien d'œuvres une édition est l'édition : un roman en nomme une, une intégrale les nomme toutes.
Chercher « Harry Potter et la Chambre des Secrets » ouvrait *Harry Potter, coffret 4 volumes* —
français, nommé, avec couverture, donc au sommet de l'échelle, et premier sorti de `reverse-claims`.
Donner quatre livres à quelqu'un qui en demandait le deuxième répond à une autre question. Le
départage **restreint sans exclure** : si tout le palier est fait de coffrets, un coffret répond
quand même.

**Puis**, parmi ce qui reste, une édition que je possède déjà — ou qu'un de mes amis possède —
passe devant. C'est une lecture locale, gratuite, sans réseau. Elle ne fait jamais monter une
édition **d'un palier à l'autre** : l'exemplaire espagnol d'un ami ne passe pas devant vingt
éditions françaises. Et elle est consultée **après** le départage mono-œuvre : un exemplaire à moi
est déjà listé au-dessus, dans la section locale de l'écran de recherche, donc le résultat distant
n'a pas besoin de me le resservir — surtout pas sous forme de coffret.

Un critère proposé a été écarté : **« un titre qui ressemble au nom de l'œuvre »**. Il rejette
`Dune, Tome 1` (Robert Laffont, 2021, ISBN — une excellente édition française) et toutes les
traductions dont le titre diffère légitimement. Avoir un nom est le signal fiable ; porter le même
nom ne l'est pas.

**Et « avoir un titre » veut dire en avoir un à l'écran.** La question passe par `EditionTitle`, la
résolution unique que `Edition` utilise pour se nommer — pas par la revendication `wdt:P1476`, que
l'échelle consultait au début. Les deux divergent pour 13 % des éditions (66 sur 513 sondées) :
inventaire.io synthétise `labels.fromclaims` pour ses propres entités `inv:`, tandis que les
éditions miroir de Wikidata portent leur titre sous le label multilingue `mul`. Ces 66 éditions
étaient classées « titrées » puis dessinées `Unknown`. Une règle sur ce que voit l'utilisateur doit
être posée à ce que voit l'utilisateur.

**Le choix est mémorisé.** Le deuxième tap sur la même œuvre ouvre immédiatement le même livre,
depuis le cache, et le classement se refait en tâche de fond. Le même geste donne le même
résultat : c'est une propriété, pas une optimisation.

**Le tap répond toujours — ce qui n'est pas la même chose qu'ouvrir toujours un livre.** Œuvre sans
aucune édition, œuvre dont aucune édition n'a de nom, ou réseau coupé : l'écran s'ouvre quand même
et dit lequel, avec un bouton « Réessayer » pour le dernier. Plus jamais de spinner éternel, et
jamais de redirection vers un `Unknown`.

**Le mot « Œuvre » quitte l'interface.** Le picker s'intitule désormais « Éditions ». Il continue
d'afficher le résumé et les auteurs de l'œuvre — il ne la nomme simplement plus.

## User Stories

1. En tant qu'utilisateur qui cherche « Dune », je veux que taper le résultat ouvre un livre, pour
   ne pas avoir à choisir entre 66 fiches dont je ne sais rien.
2. En tant qu'utilisateur, je veux que le livre qui s'ouvre soit en français, parce que c'est la
   langue dans laquelle je lis.
3. En tant qu'utilisateur, je ne veux jamais voir un livre intitulé `Unknown`, parce que ce n'est
   pas un titre.
4. En tant qu'utilisateur, je veux que le livre qui s'ouvre ait une couverture, pour le reconnaître.
5. En tant qu'utilisateur dont un ami possède une des éditions françaises, je veux que ce soit
   celle-là qui s'ouvre, pour pouvoir la lui emprunter.
6. En tant qu'utilisateur, je ne veux pas qu'une édition dans une langue que je ne lis pas s'ouvre
   sous prétexte qu'un ami la possède.
7. En tant qu'utilisateur d'une œuvre qui n'a aucune édition française, je veux quand même atterrir
   sur un livre, pour que le geste ne soit jamais perdu.
8. En tant qu'utilisateur, je veux que l'écran s'ouvre immédiatement avec le bon titre et la bonne
   couverture, pour savoir que mon tap a été pris en compte.
9. En tant qu'utilisateur, je veux que la liste de résultats s'affiche aussi vite qu'aujourd'hui,
   parce que la recherche est l'écran où j'attends le moins.
10. En tant qu'utilisateur en 4G, je ne veux pas qu'une recherche dépense un mégaoctet pour des
    lignes que je ne regarderai pas.
11. En tant qu'utilisateur arrivé sur un livre, je veux pouvoir en voir les autres éditions, parce
    que c'est parfois exactement ce que je cherchais.
12. En tant qu'utilisateur, je veux que le deuxième tap sur la même recherche ouvre le même livre
    que le premier, pour ne pas croire que l'app a changé d'avis.
13. En tant qu'utilisateur, je veux que ce deuxième tap soit instantané, parce que l'app sait déjà.
14. En tant qu'utilisateur qui tape une œuvre sans aucune édition, je veux qu'on me le dise, plutôt
    qu'un spinner qui tourne pour toujours.
15. En tant qu'utilisateur hors connexion, je veux qu'on me dise que la connexion a échoué et qu'on
    me propose de réessayer, pas qu'on me dise que le livre n'existe pas.
16. En tant qu'utilisateur, je veux revenir en arrière depuis un de ces écrans et retrouver ma
    recherche intacte.
17. En tant qu'utilisateur, je ne veux plus lire le mot « Œuvre » dans une barre de navigation,
    parce que ce n'est pas un mot que j'emploie pour parler de mes livres.
18. En tant qu'utilisateur qui arrive sur un livre que je possède déjà, je veux voir « Ton
    exemplaire » comme partout ailleurs, parce que rien ne change de ce côté.
19. En tant qu'utilisateur qui tape un auteur dans les résultats, je veux toujours atterrir sur la
    fiche de l'auteur : cette feature ne parle pas des personnes.
20. En tant qu'utilisateur qui ouvre une œuvre depuis une liste ou depuis une page d'auteur, je
    veux le comportement d'aujourd'hui, inchangé.
21. En tant que développeur, je veux que la règle de pertinence vive dans un type pur, pour la lire
    et la prouver sans lancer le simulateur.
22. En tant que développeur, je veux que chaque palier de l'échelle soit un cas de test nommé, pour
    qu'un changement de règle se voie dans la suite.
23. En tant que développeur, je veux qu'un tap n'écrive pas 127 objets dans SwiftData, pour que le
    store reste un cache et pas un dépotoir.
24. En tant que développeur, je veux que le scénario end-to-end continue de traverser le picker,
    pour qu'il reste protégé d'une régression.
25. En tant que développeur, je veux que le backtracking du scénario sur une œuvre fantôme soit
    immédiat, au lieu d'attendre les 18 secondes de `patience`.

## Implementation Decisions

- **La règle vit dans un type pur.** `Model/Books/EditionRelevance.swift`, sur le patron
  d'`InventorySearchRanking` : une structure `Candidate` (uri, langue, présence d'un titre, présence
  d'une couverture, possédée par moi ou un ami) et une fonction qui rend le classement. Aucun
  réseau, aucun `ModelContext`, aucune dépendance à SwiftData — donc testable hors simulateur, et
  l'échelle de repli se lit comme elle s'écrit.
- **L'échelle est lexicographique, pas pondérée.** Les paliers sont des filtres successifs ; la
  possession ne trie qu'à l'intérieur du palier retenu. Un score à poids aurait été impossible à
  expliquer et ses constantes seraient devenues intouchables.
- **Un lecteur dédié, qui n'écrit rien.** La résolution fait `reverse-claims` puis `by-uris`,
  décode un DTO réduit à ce que le classement lit, classe en mémoire, et rend **une seule** uri.
  `attributes` vaut `info|labels|claims|image` : `info` n'est pas du luxe, c'est là que vit
  `originalLang`, le code ISO de la langue de l'édition. Le seul attribut économisé est
  `descriptions` — le gain de ce lecteur n'est pas le poids de la réponse, c'est qu'il n'écrit
  rien. Elle ne
  passe pas par `EntityModel.getWorkEditions`, qui insère toutes les éditions, recalcule les œuvres
  de chacune et appelle `save()` sur le main actor — 127 objets pour *1984*, sur un tap.
- **Seule la gagnante est persistée**, par l'`refreshEdition` existant, qui upsert (ADR 0001,
  invariant 2). Le reste n'atteint jamais le store.
- **Un troisième cas d'anchor**, pas une nouvelle destination :
  `BookAnchor.bestEditionOfWork(uri:title:imageUrl:)`. `stableId` vaut `"work:\(uri)"`. Le titre et
  l'image sont ceux du `SearchResult` — gratuits, et c'est ce qui remplit l'en-tête pendant la
  résolution. `.item` transporte déjà un `@Model` entier ; un payload d'affichage sur un anchor
  n'est pas une nouveauté.
- **`BookAnchor.editionUri` reste synchrone et rend `nil` pour ce cas.** La résolution est le
  travail de `BookViewModel.load`, qui branche **avant** la garde d'entrée actuelle. Sinon le nouveau
  cas tomberait immédiatement en `.noResult`.
- **Un seul site de push change** : `NavigationDestination.destinationForSearchResult`, dont
  l'unique appelant est `InventorySearchResultGroup`. Aucune garde de provenance, aucun paramètre
  « d'où je viens ». Les listes et la page auteur poussent toujours `.work`.
- **`Work.preferredEditionUri: String?`**, champ local additif — dans la même famille que
  `Work.genres`, `genresEnrichedAt`, `Edition.dominantColorHex` et `numberOfPages`, tous locaux et
  absents du serveur. Migration légère.
- **Il est écrit quand le `Work` existe, pas avant.** La recherche ne persiste rien ; le `Work`
  naît quand `refreshEdition` résout le `wdt:P629` de l'édition gagnante. La préférence s'écrit
  **là**. Ajouter un `refreshWork` pour disposer du `Work` plus tôt serait une troisième requête
  pour rien.
- **Deuxième tap : cache d'abord, revalidation en fond.** On ouvre sur `preferredEditionUri` sans
  attendre le réseau. La passe de fond rafraîchit **l'édition affichée** — invariant 2 de
  l'ADR 0001 — puis rejoue le classement et met le champ à jour si le corpus a bougé. L'écran
  ouvert ne change pas de livre sous les yeux de l'utilisateur ; c'est la visite suivante qui
  bénéficie d'un classement déplacé. Ne rafraîchir que lorsque l'uri gagnante change laisserait
  une ligne périmée l'être définitivement, ce qui est le bug qu'a rencontré « Harry Potter à
  l'école des sorciers ».
- **`.noResult` devient un `EmptyStateView`** (celui d'issue 0073), et se dédouble : une clé pour
  « aucune édition référencée », une pour « la connexion a échoué », cette dernière avec
  « Réessayer ». La chaîne actuelle `edition.no_result` — « Cette édition n'existe pas sur
  inventaire.io » — est fausse pour une œuvre sans édition et ne survit pas telle quelle.
- **Le picker s'intitule « Éditions »** (`nav.work` → une clé propre). Son contenu ne change pas.
- **Un identifiant `e2e.*` sur l'absence**, pour que le backtracking de `reachBookScreen` soit
  immédiat au lieu d'expirer sur `patience`.
- **Le scénario end-to-end gagne un pas** : depuis le livre atteint, entrer dans « Autres éditions »
  et revenir. `reachBookScreen` tolère déjà un push direct vers le livre (`if
  driver.exists("e2e.book.menu") { return }`), donc le scénario passera sans ça — mais le picker ne
  serait plus joué par personne.

## Testing Decisions

- **`EditionRelevanceTests`** couvre chaque palier de l'échelle, dans l'ordre, plus les cas qui font
  basculer d'un palier au suivant : aucune édition française, aucune avec titre, aucune du tout. Le
  départage par possession est testé **à l'intérieur** d'un palier et vérifié comme **n'agissant
  pas** entre paliers — c'est la propriété que l'arbitrage a choisie, donc c'est celle qui doit
  casser si quelqu'un la change.
- **Le lecteur de résolution** est testé sous `MockURLProtocol`, comme le reste de la couche réseau :
  une réponse `reverse-claims` vide, une réponse partielle, un `by-uris` en deux batches.
- **`BookViewModel`** gagne des cas pour le nouvel anchor : résolution réussie, œuvre vide, échec
  réseau, et lecture du cache quand `preferredEditionUri` est déjà là.
- La suite d'intégration (`Tests/ReCIT_iOSTests.swift`) reste hors des pipelines : elle parle à la
  production avec des identifiants en dur, et ce PRD ne change pas cela.
- **`scripts/e2e.sh`** doit passer, y compris le nouveau pas « Autres éditions ». Attention au 429 :
  inventaire.io limite les connexions, donc pas de rafale de runs.

## Out of Scope

- **Les listes et la page auteur.** Elles poussent `.work` et continuent de le faire. Le jour où on
  voudra les convertir, l'échelle et le lecteur sont déjà là.
- **Le scanner et l'ISBN**, qui résolvent déjà une édition directement.
- **`Locale.current`.** La langue reste `"fr"` en dur, comme les douze autres sites existants. Une
  vraie notion de langue préférée est une feature à part entière, avec son réglage et sa valeur par
  défaut.
- **Un réglage « langue de lecture préférée »** dans le profil.
- **Épingler une édition à la main.** `preferredEditionUri` rendrait ça facile plus tard ; ce n'est
  pas demandé ici, et aucune interface ne l'expose.
- **La recherche elle-même** : le nombre de résultats, leur ordre, les suggestions, les recents, la
  section locale. Rien n'y touche (voir PRD 0012 et feature 0014).
- **Signaler qu'un ami possède une autre édition** du même livre. Discuté, chiffré (gratuit, requête
  locale), et écarté par le propriétaire.
- **La section « Œuvres » de `BookDetailView`**, qui liste les œuvres d'une édition omnibus. Elle
  reste, c'est l'ADR 0002 qui la veut.

## Further Notes

- **Chiffres du sondage** (18 œuvres, contre le serveur de production, 2026-09-11) : 5 % n'ont aucun
  candidat français avec titre et couverture ; 3 sur 18 dépassent 50 éditions et demandent donc deux
  batches `by-uris` ; les éditions françaises pèsent 25 à 40 % du total. L'échelle de repli servira
  rarement — mais quand elle sert, c'est sur le cas le plus laid.
- **Le piège de l'omnibus, rencontré puis fermé.** Ce PRD l'avait enregistré comme accepté —
  « une édition omnibus référence plusieurs œuvres », avec « ne référence qu'une seule œuvre »
  nommé d'avance comme le départage à ajouter s'il gênait. Il a gêné dès la première recette :
  « Harry Potter et la Chambre des Secrets » ouvrait le coffret 4 volumes. Le départage est donc
  dans la règle, au-dessus de la possession. Mesuré avant d'écrire : sur 16 œuvres, il change
  **un seul** gagnant — celui qui était faux.


- **Pourquoi pas de résolution paresseuse en liste.** Elle a été chiffrée : ~350 KB pour les seules
  lignes visibles, et surtout des titres et des couvertures qui changent sous le doigt pendant qu'on
  lit. Le coût réel n'était pas le réseau, c'était le contenu qui bouge.
- **`reverse-claims` ignore `limit`** (`unexpected parameter`). Il n'y a donc aucun moyen de borner
  la résolution côté serveur, et c'est ce qui a condamné toutes les variantes « on ne demande que
  les N premières ».
