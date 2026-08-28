# PRD 0010 — Ex-libris : dire à quoi sert l'app, avant de demander à qui on parle

## Problem Statement

L'app ouvre sur un formulaire de connexion. Quelqu'un qui vient de l'installer voit un logo, deux champs,
et une phrase qui lui apprend qu'il lui faut un compte sur un site dont il n'a jamais entendu parler.
Rien ne dit ce que l'app fait.

S'il n'a pas de compte, le seul chemin le sort de l'app vers un navigateur, où il trouve un formulaire
qui n'a ni la langue ni la typographie de l'app, et dont il doit revenir de lui-même. S'il a un compte
mais a oublié son mot de passe, il n'a aucune sortie du tout.

Il existe bien un onboarding — `Features/Onboarding/`, PRD 0007 — mais il est **après la connexion** et
il parle du scanner. Il explique un geste, pas un usage.

## Solution

Un accueil avant connexion qui énonce les trois usages de l'app en trois lignes, et deux portes : se
connecter, ou créer un compte. Puis un parcours de compte complet mené **dans l'app** — connexion,
inscription, mot de passe oublié.

L'app prend le nom **`Ex-libris`** : la marque d'appartenance collée dans un livre, *ce livre est à…*,
qui dit la possession et le retour.

Les trois usages, tels qu'ils sont énoncés à l'écran :

1. **Inventoriez** — scannez vos livres et rangez-les sur des étagères.
2. **Prêtez** — gardez la trace de ce que vous avez prêté, et à qui.
3. **Empruntez** — voyez ce que vos proches ont chez eux, et demandez-le.

Une fois la session ouverte, l'onboarding existant prend le relais sans changement : il dit comment
remplir l'app, quand elle est vide.

## User Stories

1. En tant que personne qui vient d'installer l'app, je veux savoir à quoi elle sert avant qu'on me
   demande un compte, afin de décider si elle vaut mon inscription.
2. En tant que personne qui vient d'installer l'app, je veux comprendre en trois lignes que l'app sert à
   inventorier, prêter et emprunter, afin de ne pas croire que c'est une simple liste de lecture.
3. En tant qu'utilisateur ayant déjà un compte inventaire.io, je veux atteindre « Se connecter » en un
   geste depuis le premier écran, afin de ne pas payer pour un argumentaire dont je n'ai pas besoin.
4. En tant qu'utilisateur revenant sur l'app, je veux que ma session soit restaurée sans rien retaper,
   afin de ne jamais voir l'écran de connexion sans raison.
5. En tant qu'utilisateur, je veux que mon gestionnaire de mots de passe me propose mes identifiants
   enregistrés, afin de me connecter sans les chercher ailleurs.
6. En tant que nouvel utilisateur, je veux créer mon compte sans quitter l'app, afin de ne pas perdre le
   fil dans un navigateur.
7. En tant que nouvel utilisateur, je veux savoir dès l'accueil que le compte que je crée est un compte
   inventaire.io, afin de ne pas le découvrir après coup.
8. En tant que personne qui s'inscrit, je veux apprendre que mon nom d'utilisateur est déjà pris pendant
   que je le tape, afin de ne pas le découvrir après avoir choisi un mot de passe.
9. En tant que personne qui s'inscrit, je veux la même chose pour mon adresse e-mail, pour la même raison.
10. En tant que personne qui s'inscrit, je veux que l'erreur s'affiche sous le champ fautif, afin de
    savoir lequel corriger.
11. En tant que personne qui s'inscrit, je veux que mon téléphone me propose un mot de passe fort, afin
    de ne pas en inventer un faible.
12. En tant que personne qui vient de créer son compte, je veux être connecté immédiatement, afin de ne
    pas retaper ce que je viens de choisir.
13. En tant qu'utilisateur ayant oublié son mot de passe, je veux demander une réinitialisation depuis
    l'app, afin de ne pas partir chercher la page web.
14. En tant que personne dont l'adresse n'est peut-être pas la bonne, je veux une confirmation qui ne me
    dise pas si le compte existe, afin que personne ne puisse tester des adresses sur mon dos.
15. En tant qu'utilisateur qui se trompe de mot de passe, je veux un message en français qui le dise,
    afin de comprendre sans lire de l'anglais technique.
16. En tant qu'utilisateur hors ligne, je veux un message distinct d'un refus d'identifiants, afin de
    savoir que le problème n'est pas mon mot de passe.
17. En tant qu'utilisateur arrivé sur la connexion sans compte, je veux basculer vers l'inscription sans
    revenir en arrière, afin de ne pas naviguer à reculons.
18. En tant qu'utilisateur, je veux que la pile de navigation ne dépasse jamais un cran, afin de ne pas
    m'y perdre.
19. En tant qu'utilisateur qui grossit les caractères, je veux que l'accueil défile, afin de lire les
    trois usages en entier.
20. En tant qu'utilisateur qui grossit les caractères, je veux que les boutons restent atteignables,
    afin que l'action que je viens chercher ne sorte pas de l'écran.
21. En tant qu'utilisateur d'un petit iPhone, je veux la même chose, pour la même raison.
22. En tant qu'utilisateur en thème sombre, je veux que tous ces écrans le respectent, afin de ne pas
    être ébloui.
23. En tant qu'utilisateur qui grossit les caractères, je veux que l'onboarding post-connexion défile
    aussi, afin de ne pas perdre son bouton.
24. En tant que nouvel utilisateur, je veux qu'après mon inscription l'app m'explique comment la remplir,
    afin de ne pas rester devant une bibliothèque vide.
25. En tant qu'utilisateur existant qui se reconnecte, je veux ne pas revoir cet onboarding de mise en
    route, afin qu'on ne me propose pas de scanner des livres que j'ai déjà.
26. En tant qu'utilisateur, je veux que la déconnexion n'efface que ma session, afin qu'elle ne casse
    rien d'autre dans l'app.
27. En tant qu'utilisateur, je veux retrouver le nom de l'app à l'écran d'accueil et dans ses messages,
    afin de savoir de quelle app on me parle.
28. En tant qu'utilisateur existant, je veux que le renommage ne me déconnecte pas, afin de ne pas subir
    une régression déguisée en nouveauté.
29. En tant qu'anglophone, je veux ces écrans dans ma langue, afin de ne pas lire du français par défaut.
30. En tant que développeur du projet, je veux que la règle « aucun message serveur anglais à l'écran »
    soit tenue par un test, afin qu'elle ne se perde pas à la prochaine modification.
31. En tant que développeur du projet, je veux que la branche « inscription réussie sans cookie » soit
    testée, afin qu'un changement de comportement du serveur ne casse pas l'inscription en silence.
32. En tant que développeur du projet, je veux que les modèles partagés respectent la convention
    `@Observable`, afin de ne pas ajouter à une dette que le projet a décidé de solder.

## Implementation Decisions

### Le placement de l'accueil

L'accueil **est la racine non authentifiée** : la vue racine le rend à la place de l'écran de connexion.
Il est donc vu à chaque fois qu'on est déconnecté, et **rien n'est persisté**.

C'est une décision, pas un oubli. Le magasin d'onboarding existant est indexé **par identifiant
d'utilisateur**, et sa documentation défend ce choix — un premier lancement est une propriété d'un
compte, pas d'un téléphone. Avant connexion il n'y a pas d'identifiant : « montrer le pitch une seule
fois » exigerait un drapeau d'appareil, exactement ce que ce magasin a refusé d'introduire. Et être
déconnecté *est* l'état qui a besoin du pitch.

Prix assumé : celui qui se reconnecte souvent retraverse l'accueil. La déconnexion est rare — les
cookies sont persistés au trousseau et restaurés au lancement.

### La navigation

Une pile de navigation dédiée à la branche non authentifiée, avec son propre type de destinations.
**Pas** celui du navigateur d'entités : celui-là porte des payloads SwiftData et décrit le côté
authentifié.

« Créer un compte » existe sur l'accueil **et** sur la connexion. Depuis la connexion il **remplace** la
pile au lieu de s'y empiler, pour qu'elle ne dépasse jamais un cran.

### Le contrat serveur

Vérifié contre la spec OpenAPI **vivante** publiée par inventaire.io, et non contre le miroir GitHub
archivé.

| Méthode | Chemin | Corps |
|---|---|---|
| POST | `/auth/signup` | `username`, `email`, `password` — les trois obligatoires |
| POST | `/auth/login` | `username`, `password` |
| POST | `/auth/logout` | — |
| GET | `/auth/username-availability` | `?username=` |
| GET | `/auth/email-availability` | `?email=` |
| POST | `/auth/reset-password` | `email` |

Les chemins actuels du code utilisent la forme `?action=`, **dépréciée côté serveur**. Deux appels de
production l'ont confirmé sur un compte de test fourni par l'owner : le chemin documenté répond `200` et
renvoie les trois cookies attendus, dont les deux cookies de session.

Les erreurs reviennent en `{ status, message }`, où `message` est **de la prose anglaise écrite par le
serveur**.

### Les modules

Trois modules profonds sont extraits, chacun testable sans réseau ni interface :

- **Le traducteur d'erreurs d'authentification** — prend un statut HTTP et le message du serveur, rend un
  cas d'erreur de l'app. Interface minuscule, aucune dépendance réseau. C'est lui qui garantit qu'aucune
  prose anglaise n'atteint l'écran, et cette garantie devient une propriété testable au lieu d'une
  discipline.
- **La règle de session après inscription** — décide, à partir de la présence de cookies de session dans
  la réponse, s'il faut enchaîner une connexion. Elle isole la branche que la production ne produit
  jamais à la demande.
- **L'état de disponibilité d'un champ** — modélise ce qu'un champ de nom d'utilisateur ou d'e-mail peut
  valoir pendant la frappe : vide, en cours de vérification, libre, pris, invalide. La vue rend un état,
  elle n'en dérive aucun.

Ils suivent le patron déjà établi dans le projet par la porte d'onboarding et la machine à états du
scanner par lot : pas de SwiftUI, pas de SwiftData, pas de préférences.

Le service d'authentification, lui, reste un module de bordure : il parle réseau, cookies et trousseau.
Il gagne l'inscription, la réinitialisation et les deux vérifications de disponibilité.

### La validation de l'inscription

**En direct, par champ.** Le nom d'utilisateur et l'e-mail interrogent leur endpoint de disponibilité
pendant la frappe. « Ce nom est déjà pris » est de loin l'échec le plus probable, et le découvrir après
avoir choisi un mot de passe est la pire place pour l'apprendre.

Ces endpoints valident *aussi* la forme — leur description dit « valid **and** available » — donc ils
portent gratuitement les règles de nommage du serveur, qu'on n'aura jamais à recopier ni à maintenir
côté client.

Conséquence d'interface : l'erreur d'inscription est **sous le champ concerné**. La note unique reste
pour la connexion, dont l'échec ne s'attribue à aucun des deux champs.

### L'inscription ne fait jamais retaper

L'inscription est traitée comme la connexion : même capture de cookies, même persistance au trousseau.
Si aucun cookie de session ne revient, une connexion est enchaînée avec les identifiants qu'on vient
d'utiliser, avant de rendre la main.

### La réinitialisation ne dit jamais si le compte existe

La confirmation lit « si un compte existe pour cette adresse, un e-mail est parti ». Distinguer les deux
cas ferait de l'écran un oracle répondant « ce compte existe » à qui teste une liste d'adresses. Le
serveur ne devrait pas les distinguer non plus, mais on n'en dépend pas : la formulation prudente est
écrite côté client quoi qu'il réponde.

### Le remplissage automatique

Les champs déclarent leur nature — nom d'utilisateur, mot de passe, nouveau mot de passe, adresse
e-mail — et l'e-mail obtient son clavier. Le code n'en pose aucune aujourd'hui, dans tout le projet.

Les **domaines associés**, qui feraient remonter dans l'app le mot de passe enregistré depuis le site,
sont hors périmètre : ils exigent un fichier hébergé par inventaire.io, un serveur tiers. Le fichier et
sa notice sont prêts dans le dépôt, à transmettre à l'association.

### Ce qu'on corrige au passage

Le service d'authentification doit être ouvert pour recevoir l'inscription. Quatre défauts y sont
corrigés dans le même geste, trois d'entre eux sur des lignes qu'on modifie de toute façon :

1. **Chemins dépréciés** — voir le contrat ci-dessus.
2. **La purge de cookies à la déconnexion efface *tous* les cookies du processus**, pas seulement ceux
   d'inventaire : une déconnexion casse la session de tout autre hôte que l'app a contacté. La
   persistance, elle, filtre correctement — l'asymétrie est le bug. Ajouter un troisième point d'entrée
   à l'authentification en laissant ça en place, c'est signer la panne.
3. **Le codage sécurisé est désactivé** à l'archivage et au désarchivage des cookies, alors que le type
   archivé le supporte.
4. **Les messages d'erreur du service sont du français en dur**, hors catalogue — le défaut déjà relevé
   ailleurs dans le projet, dans le fichier le plus visible du parcours.

### Le modèle d'authentification passe en `@Observable`

Avant tout le reste, et dans son propre lot. La convention du projet interdit les nouveaux
`ObservableObject`, et cette feature s'apprête à doubler la surface d'API de ce type. Dix points d'appel
dans six fichiers : c'est le moment le moins cher que ce fichier connaîtra.

Le piège à surveiller, et c'est le seul : une injection d'environnement manquante à l'ancienne mode
plante au lancement avec un message clair ; à la nouvelle, elle rend `nil` et se comporte faussement, en
silence. Les deux sites convertis doivent être exercés à l'exécution, pas seulement compilés.

### Le renommage

**De vitrine uniquement** : nom affiché, deux chaînes du catalogue, icône. Deux choses ne bougent pas, et
c'est une contrainte dure :

- **La clé de trousseau** — les cookies de session y sont rangés. La changer déconnecte silencieusement
  tous les utilisateurs existants, qui retomberaient sur l'accueil qu'on construit : la feature passerait
  pour la régression.
- **L'identifiant de paquet** — le changer crée une nouvelle app sur l'App Store et abandonne les
  installations existantes.

Le type racine, les dossiers, les cibles et les schémas gardent leur nom.

### Les chaînes

Les clés existantes du formulaire de connexion ne sont pas renommées : sept clés déjà traduites
bougeraient pour un gain nul côté utilisateur, et chaque clé déplacée est une occasion de perdre une
traduction. La cohabitation des espaces de noms est une dette assumée, à solder à part.

La langue source du catalogue est **l'anglais** : chaque chaîne neuve reçoit sa valeur anglaise comme
source et sa traduction française — l'inverse de ce que des lots précédents ont laissé s'installer.

Une chaîne devient fausse et disparaît : celle qui dit qu'il faut aller créer un compte sur le site.

## Testing Decisions

Un bon test ici décrit un **comportement observable de l'extérieur** du module : une entrée, une sortie,
et rien sur la façon dont le module s'y prend. Aucun test ne doit connaître la forme interne d'un type,
l'ordre de ses appels, ni le nom de ses propriétés privées — sinon le test se casse au premier
refactoring qui ne change rien pour l'utilisateur.

**Modules testés :**

- **Le traducteur d'erreurs.** Chaque statut et chaque forme de message serveur connue rend le cas
  attendu ; et surtout, aucune entrée ne fait ressortir le message du serveur. C'est la règle décidée en
  conception, transformée en propriété.
- **La règle de session après inscription.** Cookies présents → rien à faire ; cookies absents → une
  connexion doit suivre.
- **L'état de disponibilité d'un champ.** Les transitions pendant la frappe, y compris le retour d'une
  vérification devenue obsolète parce que l'utilisateur a continué à taper.
- **Le service d'authentification**, contre le protocole d'URL simulé déjà présent dans la suite : une
  inscription qui réussit avec cookies, une inscription qui réussit **sans** cookie — la branche de
  repli, que la production ne produit jamais à la demande et qui serait cassée pour tout le monde le jour
  où le serveur change —, un refus, et une panne réseau. Plus la déconnexion, qui ne doit effacer que les
  cookies de session configurés.

**Non testé :** les vues. Le projet n'a pas de tests d'interface au-delà de la cible XCUITest existante,
et en ajouter pour quatre écrans de formulaire coûterait plus qu'il ne protège.

**Prior art :** la porte d'onboarding et son magasin, la machine à états du scanner par lot et les types
de tri sont les modèles de tests purs. Pour le service, le protocole d'URL simulé et le double d'API du
dossier de support de la suite. Deux précautions que la forme du service impose : son initialiseur lit le
trousseau, donc les tests doivent lui passer une clé unique et nettoyer derrière eux ; et le stockage de
cookies est partagé par le processus, donc les tests doivent injecter le leur.

**Interdit :** ajouter quoi que ce soit à la suite d'intégration, qui parle au serveur de production.

## Out of Scope

- **Les domaines associés** — dépendent d'un fichier hébergé par un tiers. Le fichier et sa notice sont
  prêts ; l'habilitation suivra quand l'association l'aura déposé.
- **Le contrat de récupération de données de l'API.** La synchronisation d'inventaire peut sortir sans
  écrire son horodatage quand la réponse ne se décode pas, ce qui laisserait un compte neuf sur un
  indicateur de chargement perpétuel. La vérification montre que l'endpoint répond un objet décodable
  pour un inventaire vide : le trou est réel et théorique. Le combler veut dire changer le contrat d'une
  méthode qui a une trentaine d'appelants ; documenté, pas corrigé ici.
- **Le renommage du code** — type racine, dossiers, cibles, schémas, identifiant de paquet, clé de
  trousseau. Voir les deux contraintes dures.
- **La refonte des espaces de noms de chaînes**, et la dette des littéraux français entrés comme clés.
- **La connexion par un tiers** (OAuth Wikidata, présent dans l'API) — l'app ne l'utilise pas aujourd'hui.
- **La confirmation d'adresse e-mail** après inscription — l'endpoint existe, le parcours ne l'appelle pas.

## Further Notes

**Vérification manuelle exigée avant livraison.** Le changement des chemins touche le seul mécanisme qui
laisse entrer les utilisateurs existants. La connexion a été vérifiée à la main contre la production ; la
**déconnexion ne l'a pas été** et doit l'être sur appareil. Aucun repli sur 404 n'est prévu : deux
chemins d'authentification qui coexistent, c'est deux chemins à déboguer plus tard.

**Le raccordement avec l'onboarding existant ne demande aucun changement.** La porte exige déjà inventaire
synchronisé, zéro livre, jamais répondu. Un compte neuf coche les trois après sa première synchro —
vérifié de bout en bout contre la production. Les deux séquences se suivent sans se connaître : l'accueil
dit à quoi sert l'app, l'onboarding dit comment la remplir. Un nouvel arrivant traverse donc accueil →
création → mise en route. C'est accepté.

**Le nom.** « Étagère » a été écarté, et pas pour des raisons de goût : le mot est déjà un nom commun du
produit — l'utilisateur *crée des étagères*. Nommer l'app pareil rend ambiguë chaque phrase de
l'interface, de la documentation et du support. S'y ajoutent l'accent, qui pèse sur la recherche et les
claviers non français, et le fait que le mot ne dit rien de deux tiers de la promesse.

**Maquettes** : section `Accueil & compte` de la bibliothèque Figma du projet, documentée dans
`docs/design-system/figma-library.md`.
