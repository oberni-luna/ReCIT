# Créer un livre qu'inventaire.io n'a pas

Shipped on 2026-09-18. Les sept issues 0090–0096 ont été supprimées à ce commit, et le PRD 0015
avec elles ; git les garde. L'issue 0097 — la même chose depuis une recherche — reste ouverte et
n'est pas dans cette v1.

## Ce que ça fait

On scanne une pile de livres. Un sur cinq ne donnait rien : la rangée montait, affichait le
code-barres en rouge — « Cette édition n'existe pas sur inventaire.io » — et redescendait trois
secondes plus tard. Le livre était dans la main, on connaissait son titre et son auteur, et l'app
ne proposait rien. C'était la seule rangée de l'application **sans aucune action**, et à raison :
tant qu'on ne pouvait rien en faire, un « + » désactivé n'aurait fait qu'inviter à taper dessus.

Maintenant on peut. La rangée inconnue porte un bouton rond, à la place exacte du « + » qui range
un livre reconnu, et il ouvre une feuille : **Nouveau livre**. Elle ne demande que ce que le
code-barres ne sait pas — le **titre** imprimé sur cette couverture, et l'**auteur**. L'ISBN est là
en lecture seule, la langue est déduite de son préfixe, la couverture se photographie si on veut.
On publie, le serveur répond, le livre existe pour tout le monde et il est dans l'inventaire. La
caméra reprend la main pour le suivant.

## Les deux règles qui ont changé dans le scanner

La rangée `.notFound` n'avait pas de minuteur par hasard : c'était la seule façon de ne pas laisser
le flux coincé sur un livre dont on ne pouvait rien faire. Lui donner une action retourne les deux
règles d'un coup.

- **Elle ne s'efface plus toute seule.** Une offre qui disparaît au bout de trois secondes est pire
  qu'une absence d'offre. Elle tient jusqu'à ce qu'on en fasse quelque chose, comme un livre
  reconnu qui attend d'être rangé.
- **Un code-barres *différent* l'évince.** C'est la contrepartie obligatoire : viser le livre
  suivant est la façon de dire « pas celui-là ». Le **même** code, resté en vue, ne relance rien —
  la barrière anti-répétition n'a pas bougé. `.resolved` et `.adding` restent inévinçables : là un
  livre attend d'être rangé, ou est déjà parti vers le serveur.

C'est la seule exception à la règle « un seul résultat en attente à la fois », et elle est écrite
là où elle se décide, dans `BatchScanStateMachine.isReplaceable(by:)`.

## Un seul appel, et une passe à blanc avant

Tout tient dans `POST /api/entities/resolve`. Une entrée porte trois graines : l'édition, l'œuvre
dont elle est une édition, et l'auteur. Chaque graine **nomme** une entité par son uri, ou la
**décrit** par ses labels. C'est toute la mécanique : une uri est réutilisée, une description est
rapprochée puis, à défaut, créée.

Avant d'écrire, l'app appelle le même endpoint **sans `create`** — une passe qui ne touche à rien
et qui dit ce qu'inventaire connaît déjà. C'est d'elle que viennent les deux écrans de
réconciliation :

| Écran | Ce qu'il empêche |
|---|---|
| **Auteur** | Un deuxième « Ursula K. Le Guin ». Les auteurs existants d'abord, avec leur description pour trancher entre homonymes ; « créer » en dernier. La recherche est celle de l'app (`types=humans`), pas `resolve`, qui réconcilie une fiche finie et ne cherche pas au fil de la frappe. |
| **Ce livre est connu** | Une deuxième œuvre du même nom. Quand la passe reconnaît l'œuvre, on choisit : une édition de plus (par défaut), ou « non, c'est un autre livre ». |

Et sur le fil, la décision tient en une revendication :

- auteur choisi → `authors: [{ uri }]` ; auteur créé → `authors: [{ labels }]` ;
- œuvre reconnue → `wdt:P629` sur l'édition et **aucune** graine d'œuvre ; sinon la graine ;
- toujours `wdt:P212` (l'ISBN normalisé) et `wdt:P1476` — le titre de **cette édition**, jamais
  celui de l'œuvre : une traduction, une réédition et un coffret partagent une œuvre et n'ont pas
  la même couverture.

La passe à blanc qui échoue ne bloque rien : on publie, et le serveur dédoublonne de son côté.
Une reconnaissance vaut un écran, pas une contribution empêchée.

## Ce que le code-barres sait déjà

`GET /api/data/isbn` est **public** et rend `groupLang` : le groupe d'enregistrement d'un ISBN est
attribué par aire linguistique — `978-2` est le groupe francophone. L'appel part donc par le
service sans cookie, et ce qu'il rend fait deux choses : `wdt:P407` sur l'édition, et la langue des
labels des entités créées, à la place de celle du téléphone. L'ISBN connaît la langue du livre ; le
téléphone ne connaît que celle du lecteur.

Pas de réponse, groupe sans langue, appel qui échoue : **aucune revendication**, jamais une
devinette. Une langue fausse sur une édition publique se lit ensuite comme un fait que quelqu'un a
vérifié.

## La couverture

`enrich=true` va déjà chercher une couverture depuis l'ISBN. La photo est le secours, pour les
éditions que personne n'a jamais photographiées — et le seul moment facile est celui-ci, le livre
en main.

`APIService` n'avait aucun envoi multipart ; il en a un, et c'est son unique appelant. Le serveur
lit le **nom du champ de formulaire** comme l'identifiant de l'image et indexe sa réponse par lui,
donc l'URL revient sous le nom envoyé et part dans `image` de la graine d'édition.

Rien n'y est obligatoire : photo facultative, upload attendu mais jamais fatal. Un envoi qui ne
passe pas coûte une image, pas un livre.

C'est **la seule couture UIKit** de la fonctionnalité : SwiftUI n'a pas de vue d'appareil photo, et
la photothèque est le mauvais endroit pour un livre qu'on scanne à l'instant. Repli sur la
photothèque là où il n'y a pas d'appareil photo — le simulateur, et le scénario end-to-end avec lui.

## Rien n'est optimiste, et c'est l'échec qui est soigné

L'[ADR 0001](../adr/0001-swiftdata-reactive-optimistic.md) fait atterrir les écritures localement
d'abord. Le scanner s'en écarte déjà pour ses ajouts, parce que la confirmation *est* la
fonctionnalité. Ici la raison est plus forte : **un doublon public ne se reprend pas d'un revers**.
On attend le serveur.

Donc l'échec se dit dans la feuille, pas sur la barre partagée : le brouillon y est encore, et ce
qu'il faut savoir en premier — rien n'a été créé, donc réessayer ne fait pas de doublon — doit se
lire à côté du bouton qui va réessayer. Trois cas, distingués parce qu'ils appellent des gestes
différents : une session expirée dit que contribuer demande un compte ; une entrée refusée le dit
et **n'offre pas** de réessayer ; tout le reste est le cas pour lequel un « Réessayer » existe.

Ce qui a été tapé survit à la feuille. La session garde les brouillons par ISBN : fermer un
formulaire en échec et revenir sur le même code-barres retrouve le titre, l'auteur, la photo et la
réponse sur l'œuvre. Un brouillon devenu livre est oublié ; les autres coûtent quelques centaines
d'octets, et en perdre un est pire que le garder.

## Ce qui est testé, et ce qui ne l'est pas

Trois suites pures ou adossées à `MockURLProtocol`, aucune ne touchant le réseau réel :

- **`ResolveRequestBuilderTests`** — le corps qui part sur le fil : ISBN normalisé, titre
  d'édition, uri contre labels pour l'auteur, `wdt:P629` contre graine d'œuvre, `wdt:P407` présent
  ou absent, image offerte ou champ absent, et l'encodage qui **omet** au lieu d'envoyer `null`.
- **`EntityCreationModelTests`** — l'uri canonique rendue, une édition résolue plutôt que créée
  acceptée telle quelle, une réponse sans uri qui échoue au lieu de deviner, la langue publique, la
  reconnaissance d'œuvre, l'upload qui échoue sans rien casser.
- **`CreateBookFailureTests`** — quel code d'état donne quelle phrase, et lequel mérite un
  « Réessayer ».

Plus les nouvelles règles du scanner dans `BatchScanStateMachineTests`.

**Le scénario end-to-end n'a pas été joué** : il coûte dix minutes et déclenche la limitation de
connexion d'inventaire.io. Les identifiants `e2e.*` sont posés sur le bouton de la rangée, le
formulaire, le choix d'auteur, l'écran d'œuvre, l'erreur et la confirmation, pour qu'il puisse
l'être. Le parcours n'a pas non plus été essayé sur un appareil : la caméra n'existe pas sur le
simulateur, donc la capture de couverture n'a été exercée que par son repli photothèque.

## Ce qui reste

- **[Issue 0097](../issues/0097-the-second-door-from-search.md)** — créer un livre depuis une
  recherche qui ne trouve rien. Sans code-barres, l'ISBN devient un champ à saisir ; et il reste à
  trancher ce qu'on fait d'un livre sans ISBN, qu'inventaire.io ne peut pas accueillir comme
  édition.
- **Le glyphe `book.badge.plus`** n'existe pas dans le jeu `Icon` du fichier Figma : le bouton de
  création porte un « + », comme l'ajout, et seuls leurs libellés d'accessibilité les distinguent.
- **Les champs facultatifs** — éditeur, année, nombre de pages — sont dans la maquette et nulle
  part ailleurs.
- **`Field` sans état d'erreur ni valeur en lecture seule** dans la bibliothèque Figma : l'ISBN est
  affiché comme un texte, pas comme un champ verrouillé.

## Les maquettes

Section `Créer un livre absent` (`433:11445`) sur la page `Screens` du
[fichier Figma](https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=433-11445) :
huit frames `C1` → `C8` et un panneau `Spec · Créer un livre absent`. `C6` — l'autre porte — et les
variantes `B` et `C` de l'appel à créer y restent pour mémoire ; `A` a été retenue le 2026-09-18.
Voir [docs/design-system/figma-library.md](../design-system/figma-library.md) pour la passe.
