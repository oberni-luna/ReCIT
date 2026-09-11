# 0014 — Créer une liste ou une étagère depuis un livre

## Problem Statement

Je viens d'ajouter mon premier livre. J'ouvre son écran, je touche « … », et le menu ne me propose
ni liste ni étagère — les deux entrées ont purement disparu. Rien ne me dit qu'elles existent, rien
ne me dit où aller les chercher. Pour ranger ce livre, il faut que je devine qu'il existe ailleurs
dans l'application un endroit où créer une étagère, que j'y aille, que je la crée, que je revienne
sur le livre, et que je rouvre le menu.

Le même mur se dresse plus tard, en plus petit : j'ai trois listes, aucune ne convient à ce livre-là,
et le menu ne sait m'offrir que les trois. Créer la quatrième demande de quitter le livre que j'ai
sous les yeux — et de le retrouver après.

Le menu se tait exactement au moment où il aurait le plus à dire : quand je n'ai encore rien.

## Solution

Les entrées « Listes » et « Étagères » ne disparaissent plus faute de contenu. Chacune porte, sous
ses conteneurs existants et séparée d'eux, une dernière ligne : « Ajouter à une nouvelle liste », 
« Ajouter à une nouvelle étagère ». Avec zéro liste, cette ligne est la seule — et le sous-menu
existe quand même.

La toucher ouvre le formulaire de création habituel, celui-là même qui sert depuis l'écran des
listes et depuis le carrousel d'étagères. Son bouton dit « Créer et ajouter », parce que c'est ce
qu'il fait : la liste est créée, le livre y entre, la feuille se ferme, et un SnackBar nomme
l'endroit où le livre vient d'atterrir.

Une étagère range un exemplaire, pas une édition : l'entrée « Étagères » ne s'affiche donc toujours
que sur un livre que je possède. C'est la seule des deux entrées qui reste conditionnelle.

## User Stories

1. En tant qu'utilisateur venant d'ajouter mon premier livre, je veux voir l'entrée « Étagères » dans le menu « … » de ce livre, pour savoir que ranger mes livres est possible.
2. En tant qu'utilisateur sans aucune liste, je veux voir l'entrée « Listes » dans le menu « … » d'un livre, pour découvrir la fonctionnalité au moment où elle me servirait.
3. En tant qu'utilisateur sans aucune étagère, je veux pouvoir créer ma première étagère sans quitter l'écran du livre, pour ne pas avoir à retrouver ce livre ensuite.
4. En tant qu'utilisateur sans aucune liste, je veux pouvoir créer ma première liste depuis le livre, pour la même raison.
5. En tant qu'utilisateur ayant déjà des étagères, je veux les voir listées comme aujourd'hui, en haut du sous-menu, pour garder ma mémoire des positions.
6. En tant qu'utilisateur ayant déjà des étagères, je veux que la ligne de création soit la dernière, séparée des étagères par un trait, pour ne pas la confondre avec une étagère existante.
7. En tant qu'utilisateur dont aucune liste ne convient au livre que je regarde, je veux en créer une nouvelle depuis ce livre, pour ne pas perdre le fil.
8. En tant qu'utilisateur, je veux que la ligne de création dise « Ajouter à une nouvelle liste » plutôt que « Nouvelle liste », pour comprendre que le livre y entrera.
9. En tant qu'utilisateur, je veux que le formulaire qui s'ouvre soit celui que je connais déjà, pour ne pas avoir à réapprendre des champs.
10. En tant qu'utilisateur créant une étagère depuis un livre, je veux pouvoir renseigner son nom, sa description et sa visibilité, pour ne pas devoir la rouvrir ensuite pour la compléter.
11. En tant qu'utilisateur créant une liste depuis un livre, je veux pouvoir renseigner son nom et sa description, pour la même raison.
12. En tant qu'utilisateur créant une liste depuis un livre, je ne veux pas avoir à choisir un type de liste, parce que le livre impose la réponse et qu'un choix trahi ensuite est pire qu'un choix absent.
13. En tant qu'utilisateur, je veux que le bouton du formulaire dise « Créer et ajouter », pour ne pas croire qu'il me restera un geste à faire après.
14. En tant qu'utilisateur, je veux que la feuille se ferme d'elle-même une fois l'objet créé et le livre rangé, pour revenir au livre sans geste supplémentaire.
15. En tant qu'utilisateur, je veux un SnackBar nommant la liste ou l'étagère où le livre vient d'entrer, parce que rien d'autre à l'écran ne me le confirmerait.
16. En tant qu'utilisateur, je veux que la nouvelle liste apparaisse dans le sous-menu « Listes » si je le rouvre aussitôt, avec le livre marqué comme déjà dedans.
17. En tant qu'utilisateur, je veux retrouver la nouvelle étagère sur le carrousel des étagères, avec le livre dessus, sans avoir à rafraîchir quoi que ce soit.
18. En tant qu'utilisateur dont la connexion lâche pendant la création, je veux que le formulaire reste ouvert avec mon texte et qu'une erreur me le dise, pour pouvoir réessayer sans tout retaper.
19. En tant qu'utilisateur dont la création réussit mais dont le rangement échoue, je veux garder la liste ou l'étagère que j'ai vue naître, parce que la détruire derrière mon dos serait pire que l'oubli du livre.
20. En tant qu'utilisateur dans ce cas, je veux qu'une erreur me signale que le livre n'y est pas entré, pour pouvoir l'y remettre d'une seconde tentative.
21. En tant qu'utilisateur sur un livre que je ne possède pas, je ne veux pas voir « Étagères », parce qu'une étagère range un exemplaire et que je n'en ai pas.
22. En tant qu'utilisateur sur un livre que je ne possède pas, je veux quand même voir « Listes », parce qu'une liste range une œuvre et que je peux vouloir la noter sans la posséder.
23. En tant qu'utilisateur sur l'écran d'une œuvre, je veux la même ligne « Ajouter à une nouvelle liste », pour que la règle ne dépende pas de l'écran d'où je viens.
24. En tant qu'utilisateur, je veux que le formulaire ouvert depuis un livre ne propose pas de supprimer quoi que ce soit, puisqu'il n'y a rien à supprimer avant la création.
25. En tant qu'utilisateur, je veux que le bouton reste inerte tant que je n'ai pas saisi de nom, pour ne pas créer un conteneur sans titre.
26. En tant qu'utilisateur, je veux pouvoir fermer la feuille sans rien créer, et retrouver le livre exactement comme je l'avais laissé.
27. En tant qu'utilisateur créant une étagère depuis un livre, je veux voir que ça travaille pendant l'aller-retour serveur, pour ne pas toucher le bouton deux fois.
28. En tant qu'utilisateur ayant supprimé mon exemplaire pendant que la feuille était ouverte, je ne veux pas que l'application plante en essayant de le ranger.
29. En tant que développeur, je veux que la règle « jamais de sous-menu vide » soit écrite une seule fois, pour qu'elle ne diverge pas entre les listes et les étagères.
30. En tant que développeur, je veux que l'enchaînement création-puis-rangement vive dans les modèles, pour que les formulaires n'aient pas à connaître l'ordre des appels serveur.
31. En tant que développeur, je veux que le rangement s'appuie sur l'identifiant serveur du conteneur créé et jamais sur un identifiant optimiste, pour ne pas poster une appartenance vers un document inexistant.
32. En tant que testeur du scénario de bout en bout, je veux un identifiant d'accessibilité sur chacune des nouvelles lignes, pour pouvoir couvrir ce chemin plus tard sans retoucher l'interface.

## Implementation Decisions

**Une requête de création, portée par l'écran.** Un `.sheet` posé dans le contenu d'un `Menu` ne se
présente pas de façon fiable : la feuille doit être montée par l'écran, pas par le sous-menu. Un
type pur décrit la demande — ranger une œuvre dans une liste à créer, ranger un exemplaire sur une
étagère à créer — et les menus ne font que l'écrire dans un binding. Un modifier unique, posé sur
chaque écran porteur, lit ce binding et monte le bon formulaire. Deux écrans, une ligne chacun, et
une seule définition de la feuille.

**La ligne de création vit dans le composant de menu partagé.** `MembershipMenu` gagne un titre de
création et une action optionnelle ; quand l'action est fournie, le garde qui masque le sous-menu
vide ne s'applique plus. Les deux porteurs — listes et étagères — héritent donc du même séparateur,
du même ordre (conteneurs existants d'abord, création en dernier) et de la même règle. La ligne
n'entre pas dans le type pur qui décrit une entrée d'appartenance : cette entrée porte un
identifiant de conteneur et une action de bascule, dont la création n'a ni l'un ni l'autre.

**Un troisième mode dans les deux formulaires existants.** Ni nouvelle vue, ni duplication : les
formulaires de liste et d'étagère prennent chacun un paramètre optionnel unique qui bascule leur
bouton vers « créer puis ranger ». La forme est celle du mode brouillon déjà en place dans le
formulaire d'étagère — un optionnel plutôt qu'une paire de drapeaux, pour que les modes ne puissent
pas être à moitié activés. Le mode création-simple existant, appelé depuis le carrousel et depuis
l'écran des listes, n'est pas touché.

**Le type de liste est imposé.** Une liste créée depuis un livre reçoit des œuvres ; son sélecteur
de type est masqué et la valeur forcée. Même raisonnement que le mode brouillon du formulaire
d'étagère, qui masque description et visibilité parce qu'il ne les écrirait pas. Ici description et
visibilité, elles, sont réellement écrites : elles restent affichées.

**Création attendue, rangement optimiste.** Le rangement a besoin de l'identifiant serveur du
conteneur : l'appartenance ne peut pas partir vers un identifiant optimiste. Le bouton attend donc
la création — un seul aller-retour, derrière un bouton asynchrone qui montre sa progression — puis
range en optimiste et ferme. Le côté étagère dispose déjà d'une création attendue rendant l'objet
créé ; le côté liste crée déjà en attendant, mais ne rend rien : sa méthode de création doit
retourner la liste qu'elle insère.

**L'enchaînement est un module de modèle, pas de vue.** Chaque modèle — listes, étagères — expose
une méthode unique « créer puis ranger » : le formulaire l'appelle et ne connaît ni l'ordre des
appels, ni la différence d'optimisme entre les deux étapes, ni la règle d'échec. C'est le seul
endroit à relire quand cet ordre changera.

**Règle d'échec, asymétrique et délibérée.** Création en échec : rien n'est créé, la feuille reste
ouverte avec sa saisie, l'erreur passe par le SnackBar — le comportement actuel du formulaire de
liste. Création réussie et rangement en échec : le conteneur reste. Le rangement étant optimiste,
son revers se défait de lui-même et l'erreur remonte par le canal d'erreurs partagé. On ne détruit
jamais un objet que l'utilisateur a vu naître pour compenser une seconde requête.

**L'exemplaire est vérifié avant d'être rangé.** Il peut disparaître pendant que la feuille est
ouverte — c'est le motif connu des lectures sur un objet supprimé, déjà traité ailleurs par un test
de présence en magasin. Le même test garde l'entrée de la nouvelle étagère.

**Portée des écrans.** Le comportement vit dans le composant, donc l'écran d'une œuvre le gagne en
même temps que l'écran d'un livre. L'entrée « Listes » reste soumise à la règle existante — elle
n'est offerte que pour une édition qui ne tient qu'une seule œuvre ; une édition à zéro ou plusieurs
œuvres n'affiche toujours pas de liste, parce qu'un sous-menu qui rangerait plusieurs œuvres d'un
coup ne dirait pas ce qu'il fait. L'entrée « Étagères » reste offerte sur le seul exemplaire que je
possède.

**Libellés et localisation.** Trois chaînes nouvelles — la ligne liste, la ligne étagère, le bouton
« Créer et ajouter » — en clés localisées, du côté de la moitié du code qui en utilise déjà. Le
formulaire d'étagère, qui écrit son français en dur, n'est pas converti au passage : hors périmètre,
mais aucune dette nouvelle n'y est ajoutée.

**Accessibilité.** Chaque nouvelle ligne porte un identifiant dérivé de celui de son sous-menu, sur
le modèle des lignes d'appartenance. Le scénario de bout en bout n'est pas modifié : les
identifiants sont posés pour que le chemin soit couvrable plus tard sans retoucher l'interface.

## Out of Scope

- **Afficher les étagères et les listes d'un livre sur son écran.** Rien n'y montre aujourd'hui ses
  appartenances, ce qui est la raison du SnackBar. Une rangée d'appartenance réactive serait un
  meilleur retour — et une autre feature.
- **Un SnackBar sur la bascule d'appartenance existante.** Ranger un livre sur une étagère déjà
  créée ne dit toujours rien. Ce silence-là reste tel quel.
- **L'entrée « Étagères » sur un livre que je ne possède pas**, et le raccourci qui l'ajouterait à
  l'inventaire au passage. Écarté délibérément : un geste ne doit pas en cacher deux.
- **Les éditions à plusieurs œuvres.** Elles n'affichent toujours pas « Listes ».
- **Convertir le formulaire d'étagère aux chaînes localisées.**
- **Une étape de scénario de bout en bout** pour ce chemin. Les identifiants sont posés, l'étape ne
  l'est pas.
- **Tout test nouveau**, unitaire ou d'interface.

## Further Notes

Le formulaire d'étagère créait jusqu'ici en optimiste et fermait immédiatement : dans le nouveau
mode, son bouton attend le serveur et montre sa progression. C'est la seule régression de vivacité
de la feature, et elle est confinée à ce mode — le chemin du carrousel reste instantané.

La ligne de création placée en dernier plutôt qu'en premier est un choix de mémoire musculaire : les
conteneurs existants gardent leur rang, et la création est la sortie de secours qu'on cherche quand
aucun rang ne convient. Avec zéro conteneur, la question ne se pose pas — elle est seule.
