# Bibliothèque Figma — design system RECITs

Miroir Figma du design system iOS. **Le code Swift est la source de vérité** ; Figma en est le reflet.

- **Proposition du 2026-10-28 — `Edition de profil`** (`800:3908`, page `Profil`, à droite de `Profil`, clair
  seul) : tout ce que `PUT /api/user` d'inventaire.io laisse modifier au compte. Rangée 1 « Profil public » :
  `A1 · Profil` (`807:712`, « Modifier le profil » sous l'en-tête, section « Réglages »), `A2 · Modifier le profil`
  (`807:1168` — photo, nom d'utilisateur, bio, position, « Enregistrer » épinglé), `A3 · Photo` (`809:881`, menu
  appareil / Photos / Gravatar / Retirer), `A4 · Nom pris, bio trop longue` (`809:1013`), `A5 · Position`
  (`810:1094`). Rangée 2 « Compte et notifications », sans bouton, chaque réglage écrit seul : `A6 · Compte et
  connexion` (`810:1522`), `A7 · Mot de passe` (`810:1954`), `A8 · Adresse e-mail` (`810:2325`),
  `A9 · Notifications par e-mail` (`810:2690`). Panneau `Spec · Édition de profil` (`811:1380`) : l'attribut serveur
  de chaque champ, et cinq points à trancher. **Trois composants nouveaux** sur `Screens · Components` :
  `Form / Avatar Picker` (`803:616`), `Form / Text Area` (`803:637`, Tone ∈ {Default, Error}) et
  `Form / Map Preview` (`803:638`, dessin de remplacement de MapKit, contraintes SCALE / CENTER pour s'agrandir).
  Les écrans sont des clones de la coque d'`E3` (`758:3589`) ; leurs cartes sont des `list group` encartés sur
  `background/form-cell`, pas des `Form / Group`, parce que `Row / Toggle` fait 361 et déborde d'un slot de 329.
  Pièges : dans une instance, l'opacité **d'un paint** bindé se perd — la poser sur le calque ; le libellé du bouton
  d'`Action Bar / Attached` se règle par `children[0].children[0]` (`findOne` ne l'a pas trouvé après un
  `setProperties` sur la barre de navigation). **Implémentée le même jour**
  ([feature 0055](../features/0055-profile-editing.md)), avec des écarts listés là.
- **Passe du 2026-10-27 — le fond des formulaires** : deux variables nouvelles dans `Color`,
  `background/form` (`background/secondary` en clair, `background/default` en sombre) et `background/form-cell`
  (l'inverse : `background/default` / `background/secondary`). En sombre, un formulaire passe d'un fond `gray/800`
  sous des cartes noires à un fond noir sous des cartes `gray/800`, comme les listes groupées d'iOS ; en clair rien ne
  bouge. `Form / Group` (`702:520`) et le `contenu` de `Form / Swipe Row` (`757:608`) sont sur `background/form-cell` ;
  la `feuille` de 40 écrans de formulaire est sur `background/form`. Passés au code le même jour :
  `DesignSystem.Form` et `DesignSystem.FormList` (D-FF1, résolue). Détail en fin de fichier.
- **Proposition du 2026-10-29 — `Éditions · Filtre par langue`** (`831:7654`, page `Inventaire`, en bas de la page,
  clair seul) : l'en-tête « Éditions de … » porte à droite la langue affichée, un toucher ouvre un menu qui la change,
  la langue du téléphone par défaut. `L1 · Éditions · En français` (`831:7657`, clone de `C1` `770:4774`, toute la
  longueur, sans le bandeau), `L2 · Éditions · Choix de la langue` (`831:7849`, défilée, menu ouvert sous le
  libellé) et `Spec · Éditions · Filtre par langue` (`831:9045`, quatre points à trancher). Données réelles de
  *L'Appel de la forêt* lues dans le store du simulateur : 7 742 éditions, dont **5 613 sans langue**. **Un composant
  nouveau**, `Chrome / Menu Row · Choice` (`830:23605`, `Screens · Components`) — coche, libellé, compte —,
  `Section Header` (`28:164`) étendu, `Icon` à 36 variantes. **Implémentée le même jour**
  ([feature 0058](../features/0058-editions-language-filter.md)), avec le menu d'iOS au lieu du composant. Détail en fin
  de fichier.
- **fileKey** : `S7IvC6GvlcUFe5IgbtvQq6`
- **Lien** : https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits
- **Passe du 2026-10-27 — le fond des formulaires** : deux variables nouvelles dans `Color`,
  `background/form` (`background/secondary` en clair, `background/default` en sombre) et `background/form-cell`
  (l'inverse : `background/default` / `background/secondary`). En sombre, un formulaire passe d'un fond `gray/800`
  sous des cartes noires à un fond noir sous des cartes `gray/800`, comme les listes groupées d'iOS ; en clair rien ne
  bouge. `Form / Group` (`702:520`) et le `contenu` de `Form / Swipe Row` (`757:608`) sont sur `background/form-cell` ;
  la `feuille` de 40 écrans de formulaire est sur `background/form`. Passés au code le même jour :
  `DesignSystem.Form` et `DesignSystem.FormList` (D-FF1, résolue). Détail en fin de fichier.
- **Rangement du 2026-10-25 — plus de page `Screens`** : ses écrans sont répartis sur une page par fonctionnalité —
  `Inventaire`, `Liste`, `Réseau`, `Profil`, `Search`, `Scan et ajout`, et `Accueil & compte`, que la liste demandée
  n'avait pas — pour ce qui est dans l'app, et sur `Archive` pour les essais, les pistes non retenues, les « Tel
  quel » remplacés et les réplications périmées. Ids et contenu de la page dans la [carte des
  pages](#carte-des-pages-mise-à-jour). Chaque section porte en tête une note Inter 24 (`note · rangement`) qui dit
  sa feature et ce qui est parti en archive. **Les node ids des frames ne changent pas** : « page `Screens` » dans
  les entrées ci-dessous est historique. Sections renommées : `Onboarding` → `Mise en route` (`73:2829`),
  `Astuces · TipKit` → `Astuces · Ranger mes livres` (`314:8069`), `Synchronisation · Progression` →
  `Synchronisation · Inventaire` (`495:13490`), `Empty states` → `États vides · 2026-08-28` (`199:5924`, archive),
  `Profil` (`400:10440`) → `Profil · avant 0028 et 0034` (archive). `Scan · Repère` (`313:7880`), vide, est supprimée ;
  les sections coupées en deux ont gagné une section sœur (ids `734:*` à `737:*`). Trois légendes de colonne des États
  vides (« Tel quel », « Proposé », « Spécification ») sont supprimées, devenues fausses à la remise en page. La page
  `Screens iPad` n'est pas touchée.
- **Proposition du 2026-10-28 — `Modifier l'édition, l'œuvre et l'auteur·ice · V2`** (`814:5090`, page
  `Inventaire`, en bas de la page) : un double de `750:2508` où `E5` est remplacé par deux écrans complets.
  « Modifier l'œuvre » (`W1`) montre **tout ce qu'inventaire.io accepte sur une œuvre** ; « Modifier l'auteur·ice »
  (`A1`), nouveau, tout ce qu'il accepte sur une personne. Reliés en prototype à `E1`. Aucun composant nouveau.
  **Implémentée le même jour** ([feature 0057](../features/0057-edit-works-and-authors.md)). Détail en fin de
  fichier.
- **Proposition du 2026-10-25 — `Modifier l'édition · Toutes les données`** (`750:2508`, page `Inventaire`, sous
  `Fiche livre · Données bibliographiques`) : le formulaire « Modifier l'édition » avec **tout ce qu'inventaire.io
  permet de dire d'une édition**, et le même écran pour l'ajout depuis le scanner. « Édition de » liste les œuvres :
  on en ajoute, on en détache une d'un glissement, et en toucher une ouvre « Modifier l'œuvre », la forme de `V5`.
  « Enregistrer » est épinglé en bas. Six frames — `E1` toute la hauteur, clair (`750:2509`) et sombre (`752:2856`),
  `E2` depuis le scanner (`752:2917`), `E3` à l'ouverture (`758:3589`), `E4` détacher (`758:3657`), `E5` modifier
  l'œuvre (`758:3803`) — et `Spec · Modifier l'édition · Toutes les données` (`754:3472`). **Un composant nouveau**,
  `Form / Swipe Row` (`757:607`) ; `Action Bar / Attached` réutilisée ; `Form / Labeled Value`, `Form / Group` et
  `Form / Cover ISBN` étendus, éteints par défaut. **Implémentée le même jour**
  ([feature 0050](../features/0050-every-bibliographic-datum.md)), avec des écarts. Détail en fin de fichier.
- **Proposition du 2026-10-25 — `Fiche livre · Données bibliographiques`** (`744:2382`, page `Inventaire`, sous
  `Œuvre & édition`, clair seul) : la fiche d'une édition gagne tout en bas une section « Données bibliographiques »
  d'une seule rangée, « Modifier », qui ouvre le formulaire de l'édition (la forme de `V3 · Nouvelle édition`,
  pré-remplie). Deux frames — `Édition · Je possède · Complète` (`744:2383`, toute la longueur, 393 × 1 506) et
  `Édition · Je possède · Défilée jusqu'en bas` (`744:2482`, 393 × 852) — et `Spec · Fiche livre · Données
  bibliographiques` (`744:24535`). **Aucun composant nouveau** : `Section Header` et `Row / Link` Tinted, le reste
  cloné de `Œuvre & édition`. **Implémentée le même jour** ([feature 0049](../features/0049-edit-an-edition.md)) ;
  le formulaire n'est pas maquetté, et le code y ajoute un sous-titre que `V3` n'a pas.
  **Retouchée à la main le même jour** dans `744:2383` : le bas de la fiche est une seule rangée `Row / Link`
  Tinted « Données bibliographiques », sans en-tête de section, suivie d'une note `Footnote/footnote200` « Enrichir
  les données bibliographiques permet d'enrichir la base de données open data de inventaire.io ». `744:2482` n'est
  plus dans la section. Le code la suit depuis la [feature 0050](../features/0050-every-bibliographic-datum.md).
- **Proposition du 2026-10-25 — `Nouveau livre v2`** (`712:21292`, page `Screens`, sous `Nouveau livre · Tel que
  livré`, clair seul) : quand un scan ne trouve pas l'édition, chercher d'abord l'**œuvre** ; trouvée, il ne reste
  que l'édition à décrire, introuvable, on la crée avec l'édition. Six frames `V1` → `V6` et
  `Spec · Nouveau livre v2` (`713:21515`). Une seconde rangée, `Couverture d'une nouvelle œuvre` : `V7` → `V13` et
  `Spec · Couverture d'une nouvelle œuvre, et l'encart des données` (`718:21971`). L'encart « Données
  bibliographiques » et le « ? » de barre qui le rouvre en feuille sont posés sur toute la section. **Quatre
  composants nouveaux** (`Form / Work Row` `711:21157`, `Form / Image Preview` `716:615`, `Form / Notice` `722:595`,
  `Chrome / Menu Panel · Section` `722:756`), quatre glyphes de plus dans `Icon`, une quatrième ligne dans
  `Chrome / Menu Panel` et un bouton de queue dans `Chrome / Sheet Nav Bar`. **Rien n'est implémenté.** Détail en fin
  de fichier.
- **Passe du 2026-10-25 — `Nouveau livre · Tel que livré`** (`704:20545`, page `Screens`, sous `Créer un livre
  absent`, clair seul) : le formulaire de création d'un livre inconnu **tel que le code le montre**
  (feature 0020), et non plus la proposition d'avant le code. Huit frames `L1` → `L8`, la feuille et ses écrans
  poussés, plus `Spec · Nouveau livre (livré)` (`706:21066`). **Onze composants nouveaux** sur `Screens · Components` —
  la famille `Form / *`, une carte de section à slots et ses rangs, plus `Chrome / Sheet Nav Bar` et
  `Chrome / Sheet Backdrop` — et quatre glyphes de plus dans `Icon`. Détail, constats sur le code et divergences en
  fin de fichier.
- **Passe du 2026-10-03 — `Profil · À propos & version`** (`528:16519`, page `Screens`, mode clair seul) :
  `V1 · Profil · À propos & version` (`528:16520`, clone de `A0 · Profil · Sans Réseau` `499:14070`) — une entrée
  `Row / Link` Tinted « À propos d'inventaire.io » entre les transactions et « Se déconnecter », et un pied de page
  `Note` Footnote/Secondary centré « Ex-libris · Version 1.3.0 (10) » ; « Supprimer son compte » repassé en
  Destructive, comme dans le code (A0 le montrait en Tinted). `V2 · À propos d'inventaire.io` (`528:16634`) — écran
  poussé : `Onboarding / Brand`, quatre `Onboarding / Value Row`, une section « Aller plus loin » de quatre
  `Row / Link` Tinted, une `Note` d'indépendance. Panneau `Spec · À propos & version` (`528:16850`).
  **Aucun composant ni token nouveau.** Proposition, non implémentée. Section renommée
  `Profil · À propos, version & don` au second temps, qui ajoute `V3 · Profil · Soutenir Ex-libris` (`530:16697`,
  clone de V1 avec une étiquette papier fermable « Soutenir Ex-libris » tout en haut — clone de l'étiquette
  inventaire.io, +1°, `Action / Pill` Prominent « Faire un don ») et `V4 · Paywall · Soutenir Ex-libris`
  (`530:16834`, feuille : `Sync / Progress Bar` à 50 % pour le partage, trois `Onboarding / Value Row`, trois
  `Search / Scope Card` pour 3 / 5 / 10 € — composant parqué, ressorti ici —, `Button / Large` Primary). Toujours
  aucun composant ni token nouveau.
- **Passe du 2026-10-04 — `Soutenir Ex-libris · Cartes`** (`534:16797`, page `Screens`) : quatre cartes pour remplacer
  l'étiquette de V3, jugée laide. `A · Étagère` (`534:16799`, `shelf/parchment`, illustration à gauche) ;
  `B · Ex-libris` (`534:16814`, vignette d'ex-libris sur `shelf/label/paper`, double filet `foreground/tinted`,
  inclinée −1°) ; `C · Vert nuit` (`534:16830`, `background/tinted-inverse`, illustration qui déborde à droite,
  pastille « 50 % pour inventaire.io » avec le logo) ; `D · Deux bibliothèques` (`534:16848`, lavis `ShelfWash` sur
  `shelf/parchment`, illustration + logo inventaire.io, `Sync / Progress Bar` à 50 %). Chacune posée dans un clone de
  V1 (`534:16870`, `534:16948`, `534:17027`, `534:17108`). **Trois images importées** (frame
  `Assets · images importées`, `534:16798`) : `BooksOnShelf` — l'illustration de l'icône d'app
  (`Resources/AppIcon.icon/Assets/BooksOnShelf.png`, réduite à 700 px) —, `ShelfWash` (`wash.png`, 700 px) et
  `InventaireIo`. Leurs `imageHash` se réutilisent sans réimport. Cartes en nœuds bruts (propositions, pas
  composants) ; l'opacité de la pastille de C se perd au `clone()` et doit être reposée.
- **Passe du 2026-10-04 (2) — `Soutenir Ex-libris · Cartes (2)`** (`538:17203`) : six pistes de plus, chacune seule
  puis posée dans un clone de V1. `E · Étiquette verte` (`538:17204`) — la C en étiquette de bagage : vecteur à coins
  gauches coupés, `background/tinted-inverse` + lavis à 18 %, œillet couleur du fond, ficelle `shelf/label/ink`,
  −1,5° ; `F · Marque-page` (`538:17222`) — ruban `background/tinted-inverse` à queue d'aronde sur carte blanche,
  « Plus tard » textuel au lieu de la croix ; `G · Fiche de prêt` (`539:17214`) — fiche réglée sur
  `shelf/label/paper`, « Et vous ? », tampon `foreground/error` « 50 % INVENTAIRE.IO » à 12° ; `H · Timbre`
  (`540:17276`) — timbre dentelé (perforations = ellipses `background/default`), oblitération en pointillés ;
  `I · Étagère` (`540:17337`) — instance de `Shelf Card` Illustrative, l'étiquette du rayon *est* le bouton
  « Soutenir Ex-libris », haut rogné par un cadre `shelf crop` ; `J · Ticket` (`540:17368`) — billet
  `background/tinted` avec talon « 50 / 50 · ADMET UN DON », encoches couleur du fond et perforation en tirets.
  Les vecteurs `vectorPaths` refusent les commandes `T` (et `S`) : tout écrire en `C` / `Q`.
- **Passe du 2026-10-06 — `NavigationSplitView · iPad mini`** (`552:2`, **nouvelle page `Screens iPad`**
  `548:17852`, mode clair seul) : les onglets principaux en NavigationSplitView, pour une app redimensionnable
  (iPad, iPhone Duo). La TabView reste la racine — capsule flottante en haut en largeur régulière — et chaque onglet
  héberge un split view ; en largeur compacte on retombe sur les écrans iPhone. `S1 · Inventaire · 3 colonnes`
  (`552:3`, Bibliothèque & étagères 280 | livres 360 avec `Shelf Card` en tête | fiche) ; `S2 · Listes · 3 colonnes`
  (`552:440`) ; `S3 · Réseau · 2 colonnes` (`552:18694`, sidebar 360 clonée d'A1, détail dans une colonne lisible de
  700 — deux `Shelf Card` côte à côte) ; `S4 · Profil · 2 colonnes` (`552:18902`, Transactions sélectionné) ;
  `S5 · Inventaire · Portrait` (`552:19108`, 744 × 1133, sidebar repliée). Panneau `Spec · NavigationSplitView iPad`
  (`553:1015`) avec huit points à trancher. Frames 1133 × 744, mode `Light` épinglé. **Trois composants nouveaux** sur
  `Screens · Components` : `Chrome / Status Bar · iPad` (`551:506`, Theme, 24 pt, icônes en MAX),
  `Chrome / Tab Bar · iPad` (`551:543`, Active ∈ {Inventaire, Listes, Réseau, Profil}, `background/default` +
  `Shadow/Light` à la place du Liquid Glass), `Sidebar / Row` (`551:558`, State ∈ {Default, Selected}, props
  `Label`, `Count`, `Show count`, `Glyph`, `Show glyph` — Selected = `background/tinted` + `foreground/tinted`).
  `Icon` (`21:60`) passe à **27 variantes** avec `sidebar.left` (`550:17914`). **Chrome rendu responsive** :
  contraintes de `Chrome / Nav Bar` (titre STRETCH, action MAX), `Chrome / Search Field` (champ STRETCH, Annuler MAX),
  `Chrome / Status Bar` (icônes MAX) et `Chrome / Home Indicator` (grabber CENTER) — rien ne bouge à 393, mais
  une instance s'étire enfin à la largeur d'une colonne. La sélection d'une cellule (`Cell / Book`, `Cell / Entity`,
  `Cell / User`) est un override de fill `background/tinted`, pas une variante. `Shelf Card` (layout absolu) ne se
  réduit pas : la garder à 338 et dimensionner la colonne autour. **Aucun token nouveau.** Proposition, non implémentée.
- **Passe du 2026-10-06 (2) — `NavigationSplitView natif · premier niveau · iPad mini`** (`556:1015`, page
  `Screens iPad`, sous la précédente) : ce que donne le **seul changement de code**, sans design ajouté — en largeur
  `.regular`, la TabView est remplacée par un NavigationSplitView à deux colonnes dont la sidebar est une
  `List(selection:)` des quatre onglets, et le détail l'écran racine iPhone tel quel, étiré. `P1 · Inventaire`
  (`556:1016`), `P2 · Listes` (`557:1226`), `P3 · Réseau` (`557:1498`, badge en texte secondaire), `P4 · Profil`
  (`557:1804`), `P5 · Inventaire › Fiche livre` (`557:19789`, poussée dans le détail), `P6 · Portrait · sidebar
  masquée` (`557:20058`), `P7 · Portrait · sidebar en surimpression` (`557:20263`, voile `background/inverse` à
  `opacity/surface/backdrop`). Panneau `Spec · NavigationSplitView natif` (`558:2087`) avec le code Swift et ce que
  la maquette révèle. **Deux composants nouveaux** sur `Screens · Components` : `Chrome / Sidebar Row · System`
  (`555:498`, State ∈ {Default, Selected}, props `Glyph` (INSTANCE_SWAP sur `Icon`), `Label`, `Badge`, `Show badge` —
  le rang natif, police système, Selected = `background/tinted-inverse` + `foreground/inverse`) et
  `Chrome / Glass Button` (`555:499`, 44 pt, prop `Glyph`). **SF Pro et les SF Symbols ne se rendent pas via le
  connecteur Figma** : `listAvailableFontsAsync` les liste, mais `hasMissingFont === true` et largeur 0 —
  `getSfSymbolCharacter` ne sert donc à rien ici. Inter et `Icon` en tiennent lieu, comme pour le reste du chrome.
- **Passe du 2026-10-13 — `Profil`** (`588:17841`, page `Screens`, à droite des trois sections qu'elle fusionne, mode
  clair seul) : la synthèse de `Profil · À propos, version & don` et de `Soutenir Ex-libris · Cartes`.
  `P1 · Profil · Soutenir & À propos` (`588:17842`, clone de `Profil · Carte C · Vert nuit` `534:17027` — carte C
  fermable en tête, « À propos d'inventaire.io », pied de page de version ; pastille de C reposée à 14 %).
  `P2 · À propos d'inventaire.io · Fond blanc` (`588:17876`, V2 repassée sur `background/default`, nav et tab bar
  comprises) : une étagère dessinée en tête — `ShelfWash`, `ShelfPlank`, dos peints aux couleurs de l'icône en
  `GRADIENT_LINEAR` avec filets dorés, un ocre penché, une pile couchée — et l'étiquette papier « inventaire.io »
  avec le logo sous la planche ; `Onboarding / Brand` réécrit « La bibliothèque derrière Ex-libris » ; glyphes des
  valeurs dans une pastille `background/tinted` ; « Aller plus loin » cerclé de `border/default` ; pied centré avec
  l'icône d'app. Trois paywalls sur fond blanc : `PA · L'étagère` (`588:17950`, illustration de l'icône sur lavis,
  carte 50 / 50 à deux moitiés égales, trois pastilles de montant), `PB · Trois formats` (`588:17994`, le montant se
  choisit sur une étagère — poche 3 €, grand format 5 €, beau livre 10 € en couvertures de face, étiquette de prix
  sous chacune, « Offrir un grand format · 5 € »), `PC · Le mot de l'auteur` (`588:18038`, lettre signée sur papier
  + lavis `shelf/parchment` à 22 %, cachet de l'icône en pointillés sur le coin, montants en liste à bouton radio).
  Panneau `Spec · Profil` (`591:18178`). **Aucun composant ni token nouveau** ; nœuds bruts, illustrations en
  couleurs littérales. La signature de PC est en Alegreya Medium Italic 30, hors échelle. Proposition, non
  implémentée. Deux pièges du connecteur : les `id` de styles finissent par une virgule (`S:…,`) — sans elle,
  `setTextStyleIdAsync` ne fait rien et le texte reste en Inter ; et `setBoundVariableForPaint` remet l'`opacity`
  de la peinture à 1, à reposer après coup.
- **Passes du 2026-10-13 — `Réseau · Graphe`** (`512:15486`, page `Screens`) : la section proposée plus tôt (R1–R6,
  six composants `Graph / …` locaux, panneau `Spec · Réseau en graphe` `515:16039`) **complétée** après le grilling
  du même jour, puis **validée**. Composants locaux, à ne pas publier : `Graph / Friend` gagne `Requested` (anneau
  pointillé `[4,4]`) ; `Graph / Friend · Dot` passe à Default / Requested, sans initiales (photo ou disque teinté) ;
  `Graph / Group` gagne la propriété `Show pending` (le point rouge de 0033 après le nom) et **un seul aspect
  sélectionné** quel que soit le rôle (`512:16050`), au lieu des Member / Invited · Highlighted ; `Graph / Me` a son
  repli en initiales ; `Graph / Zoom Controls` (`521:15969`) refait en `Chrome / Glass Button` ; `Graph / Status
  Pill` (compteur, « Synchronisation… », « Réessayer ») ; `Avatar · Repli`, Kind (lecteur, groupe) × Size (44 pt en
  `Action/action300`, 32 pt en `Action/action200`). Frames : `R1′` (`603:20944`, contrôles et compteur posés),
  `R1′b`, `R3′` (`603:21890`, « 42 amis · 6 groupes » au lieu de 7, arêtes des isolés gardées au dézoom), `R2′`
  (feuille groupe native couvrant la tab bar), `R2b`, `R2c`, `R2d`, `E1`–`E3` (dont l'état vide `E1`,
  `602:18269`), `R5′` et `R6′`, `R1′ · Sombre` et `R3′ · Sombre` (mode de variables `Dark`), la bande
  `Feuille groupe · variantes de texte` (0, 1, 4, « et N autres ») et le panneau `Décisions · grilling 2026-10-13`,
  qui fait foi sur le `Spec` d'origine. Entre elles, ce que la liste « À dessiner » du grilling demandait : le menu
  « + » de Tout, les feuilles invitation de groupe, demandeur et ami, la pilule « Synchronisation… » / « Réessayer »,
  les replis d'avatar dans les rangées d'Amis et de Groupes. `R4`
  (zoomé, minicarte) est **hors v1**. Une passe de corrections a suivi la relecture. **Aucun token nouveau** ; les
  tailles hors échelle (72, 44, 24, 52, 32 pt, rayon de feuille 32, paddings de pilule) restent littérales. Défauts
  du fichier sans conséquence sur le code : `Icon` n'a ni `minus`, ni `scope`, ni `person.badge.plus`, ni
  `arrow.clockwise`, ni `checkmark`, ni `xmark` (substituts en place) ; `Chrome / Tab Bar · Réseau` sans variante
  sombre (override dans les écrans sombres). **Implémentée le même jour, en `DEBUG` seulement**
  ([feature 0035](../features/0035-network-graph.md)). Écarts, le code faisant foi : `Picker` natif dans un bandeau
  fixe pour `Chrome / Segmented Control · 3` ; `.sheet` native à un detent mesuré, poignée système, graphe actif
  derrière, au lieu du panneau dessiné ; Liquid Glass (`.buttonStyle(.glass)` dans un `GlassEffectContainer`,
  `.glassEffect` pour la pilule) au lieu des capsules, boutons désactivés et non masqués aux bornes ; `Menu` natif
  pour le « + » ; tuile compacte au rayon `radius/medium` (8) au lieu de 14 ; SF Symbols `minus`, `scope`,
  `person.badge.plus`, `arrow.clockwise` ; entre ×0,6 et ×1, les nœuds pleins rétrécissent avec le réseau (non
  dessiné) ; ni R4, ni les comptes de livres de R5 / R6. Détail dans la feature.
  **Retirée du code le 2026-10-25** ([feature 0048](../features/0048-network-graph-removed.md)) : « Tout », le
  graphe et leurs composants sont supprimés, le contrôle segmenté redevient Amis | Groupes en première ligne de
  liste. La section Figma reste, comme point de départ si le graphe revient.
- **Essais du 2026-10-23 — `Réseau · Graphe · Livres (essais)`** (`683:19881`, page `Screens`, sous `Réseau ·
  Graphe`) : quatre pistes pour mettre les livres des inventaires dans le graphe, **rien de tranché**. `L-A · Piles
  par lecteur` (`683:19901`, une pile de couvertures contre chaque avatar, le nombre sous le nom), `L-B · Livres en
  commun` (`683:19946`, les livres possédés par deux lecteurs au moins, reliés en pointillé à chacun), `L-C · Lecteur
  touché, ses livres en orbite` (`683:19991`, depuis R2d : ses dix derniers livres autour de lui, la feuille ouvre sa
  bibliothèque) et `L-D · Livres à emprunter` (`683:20044`, les exemplaires prêtés, donnés ou vendus, étiquetés), plus
  le panneau `Pistes · Livres dans le graphe` (`687:20545`) et ses questions. Composants locaux, à ne pas publier :
  `Graph / Book` (`683:19883`, 24 × 36, `radius/book`, `Shadow/Painted Book`, propriété `Show band` pour un dos
  peint), `Graph / Book · Pile` (`683:19885`), `Graph / Book · Tag` (`683:19898`, Kind ∈ {Prêt, Don, Vente}) et
  `Graph / Book · More` (`683:19899`, « + N »). **Aucun token nouveau** ; Don et Vente empruntent `color/yellow/300`
  et `background/secondary`. Couvertures de maquette : les trois images déjà dans le fichier et des dos peints. Chrome
  hérité de R1′ (onglet Profil), en retard sur l'app.
- **Implémentation du 2026-09-27 — `Réseau · Onglet & Groupes`** (`499:14069`) : l'onglet Réseau et la
  gestion des groupes sont implémentés ([feature 0028](../features/0028-network-tab-and-groups.md)). Écarts, le code
  faisant foi : création et réglages en feuilles et non en écrans poussés ; pas de pilule « Rejoindre » dans la
  recherche (le résultat ne dit pas si le groupe est ouvert) ; ni livres du groupe, ni photo, ni lieu, ni invitation
  par e-mail, ni signalement ; « Quitter » dans le « … » de la fiche, pas dans les réglages ; tags de `Group Header`
  avec glyphe. Détail dans la feature.
- **Passe du 2026-09-27 (2) — `Synchronisation · Progression`** : les premières synchronisations avec une
  progression **déterminée** (progrès = éléments d'inventaire reçus / total annoncé), mode clair seul. Section
  `Synchronisation · Progression` (`495:13490`) sur la page `Screens` : `I-A · Inventaire · Encart`
  (`495:13591`, clone de `R1 · Repos · Light` `334:8625`, encart sous la recherche) ; `I-B · Inventaire · Barre
  compacte` (`495:13745`, barre fine + légende sous la recherche) ; `P · Profil · Amis en synchronisation`
  (`495:13895`, clone de `492:13108` — Camille 40 %, Rémi déjà synchronisé, Inès 80 %, Paul « En attente ») ;
  `F-A · Ami · Encart` (`495:14066`) et `F-B · Ami · Barre sous l'en-tête` (`495:14198`), clones de `N10`
  (`411:11215`) sans menu ; panneau `Spec · Synchronisation` (`495:14280`). **Trois composants locaux** :
  `Sync / Progress Bar` (`495:13535`, Progress ∈ {0…100} par pas de 5, remplissage en contrainte `SCALE` — un
  enfant d'instance ne se redimensionne pas par l'API), `Sync / Banner` (`495:13584`, props `Title`, `Percent`,
  `Detail`), `Cell / User · Syncing` (`495:13577`, clone de `Cell / User` avec barre). **Aucun token nouveau.**
  **A retenue et implémentée** le 2026-09-27 ([feature 0027](../features/0027-first-sync-progress.md)) ;
  B reste une proposition ; divergences listées dans la feature.
- **Passe du 2026-09-27 — `Profil · inventaire.io`** : une étiquette papier **fermable** (croix en haut à droite)
  qui dit que l'app est branchée sur inventaire.io et que chaque livre ajouté enrichit ses données ouvertes
  (data.inventaire.io). Section `Profil · inventaire.io` (`492:13079`) sur la page `Screens`, mode clair seul, quatre
  clones de `Profil · Light` (`400:10441`) : `0 · Tel quel` (`492:13080`) ; `A · Étiquette sous l'en-tête`
  (`492:13108`) — pleine largeur, inclinée −1°, glyphe `feather`, deux paragraphes (commun libre / données ouvertes)
  et deux liens texte « Découvrir inventaire.io » / « Explorer les données ouvertes » ; `B · Étiquette qui compte`
  (`492:13136`) — compacte, **au-dessus** de l'en-tête, inclinée +1°, « Vos 128 livres, en commun », un
  `Action / Pill` Tinted « Explorer les données » et un lien « inventaire.io » ; `C · Étiquette accrochée au compte`
  (`492:13164`) — l'étiquette chevauche le bas de `User Header` (conteneur `header + étiquette`, espacement −20),
  inclinée +2°, « Un compte inventaire.io » : le compte de l'app *est* un compte inventaire.io. La croix est une
  instance `Icon` `xmark.circle` en position absolue. **Aucun composant ni token nouveau** (`Icon`, `Action / Pill`,
  `shelf/label/*`, `Shadow/Light`, `Content/*`, `Action/action300`, `foreground/tinted`). Étiquettes pinées en
  `Light`. Chrome hérité du clone (4 onglets). **A retenue** — retouchée par l'utilisateur : croix dans la ligne de
  titre, un lien souligné sous chaque paragraphe — **et implémentée** le 2026-09-27
  ([feature 0026](../features/0026-profile-says-it-is-inventaire.md)) ; divergences listées dans la feature.
- **Passe du 2026-09-26 — `Listes · Propositions`** : cinq pistes pour l'onglet Listes **peuplé**, mode clair seul.
  Section `Listes · Propositions` (`464:12392`) sur la page `Screens`, six clones de `Listes · Light` (`40:309`) :
  `0 · Tel quel` (`464:12393`) ; deux pistes sobres — `A · Encart enrichi` (`464:12460`, trois couvertures en
  éventail, nom, explication, « 12 œuvres ») et `B · Rangées par type` (`464:12527`, sections Œuvres / Auteur·ices,
  compteur en pastille `background/tinted`) ; trois pistes dans le langage des étagères — `C · Pochettes papier`
  (`464:12594`, grille de pochettes `shelf/label/paper` d'où dépassent les couvertures), `D · Rayonnages de couvertures`
  (`464:12661`, une planche par liste, couvertures **de face** — une étagère montre des dos, une liste des
  couvertures — et l'étiquette papier sous la planche) et `E · Tiroir à fiches` (`464:12728`, fiches de bibliothèque
  empilées, la dernière ouverte). **Cinq composants locaux** posés sous les écrans, faits d'instances existantes
  (`Thumbnail`, `Icon`, `Separator`, `Section Header`) : `Proposition A / List Row` (`466:12852`, Type ∈ {Work, Author}),
  `Proposition B / List Row` (`466:13000`), `Proposition C / Pocket` (`467:12852`), `Proposition D / Display Shelf`
  (`467:12967`), `Proposition E / Index Card` (`468:13036`, Tab ∈ {Left, Center, Right}) — à ne pas publier.
  **A retenue et implémentée** le 2026-09-26 ([feature 0024](../features/0024-list-rows-show-their-covers.md)) ;
  divergences listées dans la feature. **Aucun token nouveau.** Couvertures : les trois images déjà dans le fichier, posées
  en fill de `Thumbnail` (le `Livre` imbriqué masqué). Chrome hérité du clone (4 onglets), en retard sur l'app.
- **Passe du 2026-09-26 — `Listes vides · Étiquette`** : l'onglet Listes sans aucune liste (D54), dans le langage
  de l'étagère vide. Section `Listes vides · Étiquette` (`462:12178`) sur la page `Screens`, mode sombre seul, trois
  clones de `E · Aucune liste · Tel quel · Dark` (`212:6773`) : `0 · Aucune liste · Tel quel` (`462:12179`),
  `A · Une étiquette qui explique` (`462:12186`) — consigne « Pas encore de liste », une étiquette papier « Liste ou
  étagère ? » (une étagère range les livres qu'on a ; une liste garde en mémoire ceux qu'on n'a pas — à acheter, à
  lire, conseillés), puis une étiquette « Créer une liste » ; `B · Deux étiquettes côte à côte` (`462:12365`) — la
  même différence dite par deux étiquettes « Étagère » / « Liste », puis « Créer une liste ». Pas de planche : une
  liste n'est pas un meuble. **Aucun composant ni token nouveau** (clones de l'étiquette `461:11989`, `Icon`, styles
  existants). Étiquettes pinées en `Light`. Chrome hérité du clone (4 onglets). **A retenue et implémentée** le
  2026-09-26 ([feature 0022](../features/0022-empty-lists-tab-explains-a-list.md)) ; divergences listées dans la feature.
- **Passe du 2026-09-22 — `Inventaire vide · Première étape`** : trois propositions pour la note de l'étagère
  vide quand l'inventaire est vide (`ShelfEmptyStateErrand.scan`). Section `Inventaire vide · Première étape`
  (`460:11692`) sur la page `Screens`, mode sombre seul, quatre clones de `A · Collection vide · Tel quel · Dark`
  (`209:6110`) : `0 · Tel quel` (`460:11693`), `A · Note étendue sur l'étagère` (`460:11703`) — l'étiquette papier
  devient une note (titre, phrase, deux `Action / Pill` Tinted) posée sur la planche ; `B · Étiquette + consigne
  sous la planche` (`460:11713`) — l'étiquette garde sa forme (« Première étape / Ajouter vos livres »), la phrase et
  les deux pastilles passent sous la planche ; `C · Deux étiquettes, deux gestes` (`460:11723`) — la phrase au-dessus,
  et deux étiquettes papier « Scanner » / « Rechercher » posées sur la planche, chacune une action. **Aucun composant
  ni token nouveau** : `Action / Pill`, `Icon`, `shelf/label/*`, `Shadow/Light`, styles `Content/*` et `Footnote/*`.
  Notes papier épinglées en `Light` (îlot clair, comme les champs de `Se connecter · Vert`). L'étiquette d'origine est
  masquée par override (`name row` invisible), pas détachée. Chrome hérité du clone : tab bar à 4 onglets et une seule
  action de barre, en retard sur l'app. **C et D retenues et implémentées** le 2026-09-22 ([feature 0021](../features/0021-empty-shelf-first-steps.md)) ; divergences — inclinaison ±1° dérivée du texte, glyphe `books.vertical.fill` pour Ranger — listées dans la feature. Seconde rangée, même
  langage que C pour l'autre errand (`ShelfEmptyStateErrand.sort`, des livres mais aucune étagère) :
  `0 · Livres sans étagère · Tel quel` (`461:11937`, clone de `210:6374`) et `D · Livres sans étagère · Une étiquette`
  (`461:11950`) — phrase « Étape suivante : ranger vos livres » au-dessus, une seule étiquette papier « Ranger mes
  livres · à la main, ou avec un peu d'aide » posée sur la planche, glyphe `Icon/book` (faute de
  `books.vertical.fill`, comme pour les astuces TipKit).
- **Passe du 2026-09-18 — `Créer un livre absent`** : ce qu'il advient d'un scan qui ne trouve rien. Section
  `Créer un livre absent` (`433:11445`) sur la page `Screens` : 8 frames — `C1` scan sans résultat, `C2` formulaire,
  `C3` auteur, `C4` l'œuvre existe déjà, `C5` publié, `C6` la même absence vue de la recherche, `C7` l'échec,
  `C8` trois variantes de l'appel à créer — plus `Spec · Créer un livre absent` (`441:11659`). **Aucun composant ni
  token nouveau** : tout est instancié depuis `Field`, `Note`, `Cell / Entity`, `Empty State`, `Onboarding / Value
  Row`, `Search / Query Row`, `Section Header`, `Row / Link`, `Button / Large`, `Button / Circular Icon`, `Icon` et
  le chrome. `C1` et `C5` sont des clones de `S0 · Existant · Livre reconnu`, tab bar retirée (le scanner est un
  `fullScreenCover`). Ce qui manque au système est listé dans le panneau : pas de glyphe `book.badge.plus`, pas de
  chrome de feuille modale, `Field` sans état erreur ni lecture seule. **Rien n'est implémenté** — c'est une
  proposition, et l'arbitrage A/B/C reste à rendre. *Mis à jour le 2026-10-25 :* A a été retenue et la fonctionnalité
  livrée le jour même ([feature 0020](../features/0020-creating-a-book-that-inventaire-lacks.md)), avec des écarts
  — feuille et non plein écran, boutons qui défilent, pas de « Revoir mes informations » en C4. L'état livré est
  maquetté dans `Nouveau livre · Tel que livré` (`704:20545`) ; cette section reste pour mémoire.
- **Passe du 2026-09-12 — `Réseau · Ajouter des amis lecteurs`** : le parcours d'ajout d'un ami lecteur, dans les
  deux sens. Section `Réseau · Ajouter des amis lecteurs` (`407:10422`) sur la page `Screens` : 11 frames en clair
  seul, deux composants nouveaux (`Cell / Relation`, `Cell / Invitation`) et un panneau `Spec · Réseau`
  (`412:11330`). **Implémentée le jour même** ([feature 0018](../features/0018-reader-network.md)), aux cinq écarts
  listés en fin de fichier près. Détail en fin de fichier.
- **Passe du 2026-09-11 (2) — `Édition · Actions mises en avant`** : quatre **propositions** pour sortir du menu
  « … » les trois actions d'entrée de la fiche livre — ajouter à l'inventaire, emprunter à un ami, ajouter à une
  liste. Section `Édition · Actions mises en avant` (`362:9924`), clair seul. Rien de tout cela n'existe en Swift :
  c'est une exploration, pas une réplication. Arbitrage à rendre, détail en fin de fichier.
- **Passe du 2026-09-11 — `Œuvre & édition`** : le détail d'une œuvre et celui d'une édition, tels que
  l'[ADR 0002](../adr/0002-unified-book-detail.md) les a refaits. Section `Œuvre & édition` (`351:9412`) sur la page
  `Screens` : 5 frames en **clair seul** et un panneau de spécification. Quatre composants nouveaux, `Row / Summary`
  étendu, trois glyphes de plus dans `Icon`. Les frames `Fiche livre` (`42:1125` / `42:1219`) sont **conservées telles
  quelles** : elles datent de l'ancien `EditionDetailView`. Détail en fin de fichier.
- **Dernière passe** : 2026-09-05 — `B3 · Accueil · Plein écran illustré` (`265:7532`) est la **maquette retenue**
  et est implémentée ([feature 0013](../features/0013-welcome-cover-wall.md)). Divergences code ↔ Figma constatées à
  l'implémentation, le code faisant foi :

  | Point | Figma `B3` | Code |
  |---|---|---|
  | Couvertures | 28 tuiles fixes de 88 × 132, gouttière 8 | 4 colonnes dérivantes, largeur dérivée de l'écran (88,25 sur 393), ratio 2:3, gouttière 8 |
  | Voile | 5 arrêts de `green/900` (0,92 · 0,6 · 0,74 · 0,96 · 1) | **identique** — le voile avait été densifié au milieu tant que le texte était centré ; le texte passé en bas, la densité est revenue au mur |
  | Mouvement | aucun (maquette statique) | 10,5 à 15 pt/s, impaires vers le bas, paires vers le haut |
  | Sol des gouttières | néant (le fond de la frame) | `green/900` plein, pour que l'inter-couverture lise comme une ombre |
  | Bouton primaire | rectangle papier dessiné à la main | `background/tinted-inverse` en mode sombre, soit `green/200` — le token donne la maquette |
  | Écart bouton ↔ lien | 17 pt (hors échelle) | `spacing/zero` + le padding du style secondaire, soit 16 pt et une cible tactile de 55 |
  | Retrait latéral de la phrase | 10 pt (hors échelle) | `spacing/small` (8) |
  | Bas du bloc | 832 pt, soit 14 pt dans la zone du home indicator | le bas de la zone sûre |
  | Mention | texte de l'ancienne note | réécrite (provenance des couvertures + hébergement du compte), fr et en |

  Alignement et écarts repris tels quels de la révision du 2026-09-05 : bloc **aligné en bas**,
  construit du bas vers le haut, `spacing/large` entre les trois groupes, `spacing/medium` entre
  l'accroche et la phrase, `spacing/x-small` entre le nom et l'accroche, `spacing/medium` de marge
  latérale, `spacing/s-medium` de padding vertical sur la mention. Les trois `Onboarding / Value
  Row` de l'ancienne maquette ne sont plus instanciées : une phrase les remplace.

  Les frames `A1`-`A3` et `B1`-`B2` de la section `Propositions · Chaleur` ne sont pas retenues ; `A3` reste la
  référence pour l'état « inventaire vide », qui n'est pas implémenté.
- **Passe du 2026-09-09 (2)** — les astuces TipKit, section `Astuces · TipKit` (`314:8069`) sur la page `Screens` :
  six écrans et un `Spec · Astuces TipKit` (`318:8580`) qui porte le scénario — quoi, où, dans quel ordre, et ce qui
  invalide chaque astuce. Un composant nouveau, `Astuce / TipKit` (`316:8597`) sur la page `Components` : carte
  `background/tinted-inverse`, titre `Action/action300`, texte `Content/content300`, rayon `radius/rounded`, ombre
  `Shadow/Light`. **La pointe n'est pas dans le composant** — un nœud d'instance ne peut pas être déplacé, et une
  pointe fixée au centre ne viserait ni un bouton de barre ni le premier livre d'un carrousel ; c'est un triangle de
  20 × 9 posé dans l'écran, à côté de l'instance.

  | Frame | Astuce | Visée |
  |---|---|---|
  | `314:8070` | INV-1 · Choisir un livre | les tranches de la première étagère |
  | `314:8083` | INV-2 · Ranger mes livres | le bouton `Ranger` de la barre |
  | `314:8096` | INV-3 · Ajouter des livres | le bouton `Scanner` |
  | `314:8109` | SORT-1 · Glissez pour ranger | le premier livre de « Livres à ranger » |
  | `314:8199` | SORT-2 · Rien n'est encore enregistré | « Appliquer » |
  | `314:8247` | SORT-3 · Laissez proposer un rangement | le bouton de proposition |

  Trois divergences assumées, le code faisant foi : les frames `Étagères` du fichier datent d'avant PRD 0008, donc
  les deux actions `Ranger` et `Scanner` ont été **posées à la main** dans la barre (le composant `Chrome / Nav Bar`
  n'en porte qu'une) ; le glyphe de `Ranger` est `Icon/book`, faute d'un `books.vertical.fill` dans le jeu ; et la
  section est en `Light` seulement — la carte est bâtie sur des tokens, le mode sombre suit sans redessin.
  **Rien de tout cela n'est implémenté** : aucune astuce TipKit n'existe dans le code à ce jour.
- **Passe du 2026-09-11** — la recherche unifiée, section `Recherche unifiée` (`334:8624`) sur la page `Screens`.
  Quatre écrans en clair et sombre (`R1 · Repos` → `R4 · Résultats`) qui fondent le champ de l'inventaire et
  l'onglet Recherche en une recherche à trois temps, à la manière de Mail sur iOS, plus le panneau
  `Spec · Recherche unifiée` (`340:9412`). Deux composants nouveaux (`Search / Query Row` `331:255`,
  `Search / Scope Card` `333:274`, ce dernier parqué), trois étendus (`Icon` → 22 variantes avec `feather` et
  `xmark.circle`, `Chrome / Search Field` → 6 avec `State=Typed`, `Cell / Book` → propriété `Show tag`).
  Révisée deux fois le même jour : le carrousel de portées sort de R2, l'écran des récentes vides (`R2b`) arrive,
  et les huit arbitrages sont rendus — il ne reste que la tab bar à 3 onglets. **Rien n'est implémenté** : c'est
  une proposition. Détail complet en fin de fichier.

- **Passe du 2026-09-09** — le repère du scanner, section `Scan · Repère` (`313:7880`) sur la page `Screens`.
  Trois frames, mode `Dark` épinglé, toutes clonées de `Batch Add` (`57:2401`) — même photo de caméra, même voile,
  même chrome :

  | Frame | id | Ce qu'elle montre |
  |---|---|---|
  | `S0 · Existant · Livre reconnu` | `313:7881` | Le clone non modifié — l'état `.resolved`, pour comparer |
  | `S1 · Repère · Texte sur voile` | `313:7897` | `.idle` : glyphe `barcode.viewfinder` + une phrase centrée, sur le voile nu |
  | `S2 · Repère · Encart teinté` | `313:7913` | `.idle` : la même phrase dans un encart `background/tinted` + `radius/medium`, glyphe à gauche |

  Le point de la maquette : **le repère prend la place exacte de la rangée** — il est le seul enfant de
  `Frame Highlighted Book`, à la même origine (`y = 678`), donc l'arrivée d'un livre remplace un bloc par un autre
  sans que rien ne se déplace. Copie : « Approchez le code-barres d'un livre de l'appareil photo », `Content/content300`,
  `foreground/default` ; le glyphe en `foreground/tinted`.

  Arbitrage à rendre : S1 est plus léger et laisse voir la scène, mais son contraste dépend de ce que filme
  l'appareil — le voile de `ScanOverlayPalette.scrim` est faible à cette hauteur. S2 se lit sur n'importe quelle
  image et pèse plus. **S1 est retenue et implémentée** le 2026-09-10 (`Features/Scanner/ScanHintView.swift`,
  clé `scanner.hint`) ; S2 reste une proposition. Les trois frames portent du texte hors instance — c'était une
  exploration, pas une passe de réplication — donc elles sont exclues de l'audit de factorisation.

- **Passe du 2026-09-05 (2)** — connexion et création de compte sur le vert de l'accueil, section `Accueil &
  compte` (`222:7167`), troisième rangée : `Se connecter · Vert` (`278:2`) et `Créer un compte · Vert` (`278:12`).
  Les six frames `Light` / `Dark` / `Erreur` existantes sont conservées telles quelles. Aucun token, style ni
  composant nouveau — la maquette est faite de modes épinglés :

  | Élément | Traitement |
  |---|---|
  | Frame | collection `Color` épinglée sur `Dark`, fond `background/tinted` — soit `green/900`, le vert du voile de `B3` |
  | `nav`, `status bar`, `home indicator` | variantes `Theme=Dark` ; le fill du `nav` repassé sur `background/tinted` pour qu'il se fonde dans le vert au lieu du `#1C1C1E` littéral de la variante |
  | `box` des champs | collection `Color` **ré-épinglée sur `Light`** — le seul îlot clair de l'écran. Le `Value` étant enfant de `box`, il hérite du mode et reste en `foreground/default` encre sombre. `background/secondary` en clair, donc `gray/50` : les champs restent blancs, sans binder de primitive |
  | Libellés des champs, `note/lead` | montés de `foreground/secondary` à `foreground/default` (`Tone=Default` pour la note) : sur `green/900`, `foreground/secondary` ne donne que 4,1:1 — 4,5:1 depuis que le token est passé au voile blanc 60 % le 2026-09-06, toujours sous le seuil AA du petit texte. La décision tient |
  | Boutons | inchangés — en mode sombre `background/tinted-inverse` vaut `green/200` et `foreground/tinted-inverse` `green/900`, soit exactement le bouton de `B3` ; le secondaire reste en `foreground/tinted`, `green/200` |

  Reste à trancher : la mention de bas d'écran garde `foreground/secondary` (4,5:1 depuis le 2026-09-06), au même niveau de discrétion
  que la mention de `B3`. **Ces deux frames sont implémentées** — `LoginView`, `CreateAccountView`,
  `AuthField(isOnTinted:)` et le pin d'apparence d'`AuthFlowView`. Le code suit la maquette, à trois choses près,
  et le code fait foi :

  | Point | Figma | Code |
  |---|---|---|
  | Épinglage des modes | par nœud (`Dark` sur la frame, `Light` sur chaque `box`) | `preferredColorScheme(.dark)` sur la pile pour ces destinations, `environment(\.colorScheme, .light)` sur la seule boîte du champ — même mécanique, mêmes tokens |
  | Barre de navigation | fill `background/tinted` opaque | `toolbarBackground(...backgroundTinted..., .visible)` — le matériau par défaut d'iOS poserait une vitre grise en haut |
  | Bouton primaire désactivé | non dessiné | `background/disable` — **réglé le 2026-09-06** : le token est passé de `gray/400` (une dalle grise plus forte que l'état actif crème) à un voile blanc 10 %, qui s'efface sur le vert au lieu de crier |
  | Bord haut de la barre d'actions | arête franche | dégradé `background/tinted` de 0 % à 100 %, `xLarge` de haut, démarré `small` au-dessus de la barre (`AuthActionsBackground`) — sinon le formulaire disparaît derrière une ligne |
  | Fond sous le clavier | hors maquette | le vert est peint derrière **toutes** les safe areas, celle du clavier comprise : un clavier translucide laissait voir le noir de la fenêtre |
  | `action/secondary` « Créer un compte » sur `Se connecter · Vert` | présent | **supprimé** — les deux portes sont sur l'accueil, une seule reste sur cet écran. La frame Figma n'a pas été mise à jour |

- **Passe du 2026-09-06** — deux échelles d'alpha, et cinq tokens qui deviennent des voiles. D'abord 18 primitives
  dans `Primitives` : `color/white-01`…`color/white-09` et `color/black-01`…`color/black-09`, de 10 % à 90 %. Puis
  cinq sémantiques rebasées dessus — `foreground/disable` (sombre), `foreground/secondary`,
  `foreground/placeholder`, `background/disable` (sombre) et `border/default`, ce dernier **fermant D49**. Le code a
  suivi : `Color.swift` écrit ces cinq cas en `.black.opacity(x)` / `.white.opacity(x)`, `color/gray/600` n'est plus
  consommé par personne. Sens de la passe **inhabituel — Figma vers le code** : c'est une décision de design, prise
  dans le fichier puis répercutée, et non une divergence à trancher en faveur du code.
- **Passe du 2026-09-04** — section `Propositions · Chaleur` (`265:7465`) sur la page `Screens` : trois
  propositions plus illustrées pour « Inventaire vide » et trois pour « Accueil », à côté d'un clone de l'écran
  actuel. Aucun token, style ni composant nouveau — les couvertures réutilisent les quatre `imageHash` déjà présents
  dans le fichier (`ShelfPlank` + trois couvertures), les dos sont peints avec les primitives `color/*`.
- **Passe du 2026-08-20** (issue 0036) — les cinq états jamais dessinés de la surface de tri : 9 frames dans
  `Ranger mes livres`, 2 variantes d'`Icon` (`circle`, `exclamationmark.circle`), la propriété `Mark glyph#133:0` sur
  `AutoSort / Shelf Header`.
- **Passes précédentes** : 2026-08-20 — onboarding, « Ranger mes livres · Résultat », puis le tri manuel.
  2026-08-19 — le label papier de l'étagère (issue 0012) : style d'effet `Shadow/Light`, variables `shadow/light`,
  `shelf/label/paper`, `shelf/label/ink`, appliquées aux deux variantes de `Shelf Card`.
  2026-08-18 — tokens, styles de texte, styles d'ombre, page `Tokens`, puis les 26 composants et les 16 frames
  d'écran.
- **Éditeur** : fichier `/design/` (les nœuds de design sont autorisés).

## Règle de source de vérité

Toute divergence code ↔ Figma se tranche **en faveur du code**, et se **documente** — dans la description du token
concerné, et dans la table [Divergences](#divergences-relevées-dans-le-code) ci-dessous. On ne corrige jamais le code
en douce depuis Figma.

Corollaire : les valeurs « bizarres » de ce fichier sont volontaires. Avant de « réparer » un token, lire sa
description : elle dit pourquoi.

## Conventions du fichier

| Convention | Détail |
|---|---|
| Nommage des couleurs primitives | Le **chemin exact de l'asset catalog** : `color/gray/900`, y compris les noms à espace et `%` (`color/gray/700 75%`). Greppable depuis le Swift. |
| Nommage des sémantiques | `famille/rôle` : `foreground/default`, `background/tinted-inverse`, `border/error`. |
| Portées | **Explicites partout**, jamais `ALL_SCOPES`. Primitives = `[]` (invisibles dans les pickers). |
| Code syntax | **iOS uniquement**, et c'est le **vrai symbole Swift** (`DesignSystem.Color.foregroundDefault`). Pas de WEB ni d'ANDROID : il n'y a pas de codebase web ni Android dans ce dépôt. |
| Alias | Les sémantiques sont des **alias** vers les primitives. Jamais de valeur recopiée. |
| Alpha | Un token qui porte une alpha (`shadow/*`, `clear`) **ne peut pas** être un alias : valeur brute par mode. |
| Opacités | **Stockées en pourcentage** (`92`, pas `0.92`). Figma lit une variable bindée à `opacity` comme un %. Stocker `0.92` donnerait 0,92 % — invisible, et le bug ne se voit qu'à la capture. |
| Ombres | Couleur **bindée** à une variable mode-aware, jamais littérale. |
| Modes épinglés | Les planches de couleurs et d'ombres épinglent leur mode via `setExplicitVariableModeForCollection`, pour que clair et sombre se lisent côte à côte. |
| Chrome de documentation | Les libellés des planches sont en **Inter** avec un fill littéral, pour ne pas se confondre avec les spécimens de l'app. Ce sont les seuls fills non bindés du fichier, et ils sont hors composant, donc invisibles pour l'audit. |

### Polices — pas de substitution

Contrairement au cas courant, **les deux familles réelles se résolvent dans Figma** : `Alegreya`
(Regular / Medium / Bold) et `Open Sans` (Regular / SemiBold / ExtraBold). Sondées avant construction :
`hasMissingFont === false` et `width > 0` pour chacune. Aucun substitut (Inter, Nunito, Lora) n'a été nécessaire.

La famille est malgré tout **pilotée par une variable** (`font/family/serif`, `font/family/sans`) : un changement de
famille reste une seule édition.

Attention à `Open Sans` : Figma accepte **`SemiBold`** *et* `Semi Bold`, `ExtraBold` *et* `Extra Bold`. Le fichier
utilise la forme sans espace, pour coller aux noms de fichiers `.ttf` du dépôt.

## Carte des pages

| Page | id |
|---|---|
| `Tokens` | `0:1` |

### Sections de `Tokens`

| Section | id | Planches (id) |
|---|---|---|
| `1 · Couleurs` | `10:2` | `Sémantiques — Clair` `11:2` · `Sémantiques — Sombre` `11:141` · `Primitives` `12:2` |
| `2 · Typographie` | `10:3` | `Échelle typographique` `13:2` |
| `3 · Espacements` | `10:4` | `Échelle d'espacement` `14:2` |
| `4 · Rayons` | `10:5` | `Rayons de coin` `15:2` |
| `5 · Ombres` | `10:6` | `Ombres — Clair` `16:2` · `Ombres — Sombre` `16:36` |
| `6 · Opacités` | `10:7` | `Opacités` `17:2` |

Les sections sont empilées verticalement, sans chevauchement, chacune ajustée à ses planches (marge 48, gap 160).
**Les coordonnées d'un enfant de `SECTION` sont relatives à la section** — un `enfant.y = section.y + marge` sort du
cadre sans qu'aucun contrôle ne le voie.

## Collections de variables

| Collection | id | Modes (id) | Variables |
|---|---|---|---|
| `Primitives` | `VariableCollectionId:4:2` | `Value` (`4:0`) | 48 |
| `Color` | `VariableCollectionId:4:3` | `Light` (`4:1`), `Dark` (`4:2`) | 32 |
| `Spacing` | `VariableCollectionId:4:4` | `Value` (`4:3`) | 11 |
| `Radius` | `VariableCollectionId:4:5` | `Value` (`4:4`) | 8 |
| `Sizing` | `VariableCollectionId:4:6` | `Value` (`4:5`) | 4 |
| `Typography` | `VariableCollectionId:4:7` | `Value` (`4:6`) | 10 |
| `Opacity` | `VariableCollectionId:4:8` | `Value` (`4:7`) | 2 |

**Total : 95 variables, 10 styles de texte, 7 styles d'effet.**

Les trois dernières variables (`shadow/light`, `shelf/label/paper`, `shelf/label/ink`) et le septième style d'effet
(`Shadow/Light`) datent de la passe du 2026-08-19 ; les résultats d'audit datés du 2026-08-18 plus bas comptent donc
92 et 6, et n'ont pas été rejoués.

Les modes clair/sombre ne vivent **pas** dans l'asset catalog : chaque `.colorset` porte une seule valeur, et la
paire light/dark est assemblée en Swift par `Color(light:dark:)` dans `DesignSystem/Tokens/Color.swift`. C'est là
qu'il faut lire les deux modes.

## Tables de tokens

### Primitives — `color/*` (source : `Assets.xcassets/color/`)

| Token | Hex | α | Consommé par |
|---|---|---|---|
| `color/gray/0` | `#FFFFFF` | 1 | `background/default` L · `shelf/label/paper` **L et D** |
| `color/gray/50` | `#F1F1F1` | 1 | `foreground/inverse` L · `foreground/default` D · `background/secondary` L · `background/grouped` L · `background/grouped-elevated` L |
| `color/gray/200` | `#E8ECE6` | 1 | `background/inverse` D · `background/disable` L · `background/tinted-inverse` D |
| `color/gray/400` | `#AFAFAF` | 1 | `foreground/disable` L — a perdu `foreground/secondary` D et `foreground/placeholder` L le 2026-09-06 |
| `color/gray/500` | `#959A92` | 1 | — inutilisé |
| `color/gray/600` | `#7E837C` | 1 | — **inutilisé depuis le 2026-09-06** : ses trois rôles sont passés aux voiles |
| `color/gray/700` | `#2D2D2D` | 1 | `background/error` D |
| `color/gray/700 75%` | `#2D2D2D` | **0.50** | — inutilisé · **le nom ment** (voir D1) |
| `color/gray/800` | `#2A2A2A` | 1 | `background/secondary` D |
| `color/gray/900` | `#191919` | 1 | `foreground/default` L · `foreground/inverse` D · `background/inverse` L · `background/grouped-elevated` D · `shelf/label/ink` **L et D** |
| `color/gray/1000` | `#000000` | 1 | `background/default` D · `background/grouped` D |
| `color/gray/1000 10%` | `#000000` | 0.10 | — inutilisé |
| `color/green/100` | `#F2FAE9` | 1 | `foreground/tinted-inverse` L · `background/tinted` L |
| `color/green/200` | `#E7FFCE` | 1 | `foreground/tinted` D · `border/tinted` D · `background/tinted-inverse` D |
| `color/green/300` | `#D8FFB1` | 1 | — inutilisé |
| `color/green/400` | `#B6DA9F` | 1 | — inutilisé |
| `color/green/500` | `#90CF8E` | 1 | — inutilisé |
| `color/green/600` | `#579F66` | 1 | — inutilisé |
| `color/green/700` | `#558154` | 1 | `foreground/tinted` L · `border/tinted` L — le vert de marque |
| `color/green/800` | `#3A5A40` | 1 | `background/tinted-inverse` L — le fond du bouton primaire |
| `color/green/900` | `#344E41` | 1 | `foreground/tinted-inverse` D · `background/tinted` D |
| `color/red/100` | `#F1E4DB` | 1 | `background/error` L |
| `color/red/400` | `#E14D4D` | 1 | `foreground/error` D · `border/error` D |
| `color/red/800` | `#821F1F` | 1 | `foreground/error` L · `border/error` L |
| `color/yellow/300` | `#FDF1A8` | 1 | — inutilisé |
| `color/yellow/400` | `#F5D36E` | 1 | — inutilisé |

`color/gray/200` est **légèrement vert**, pas neutre — c'est volontaire, il porte la teinte de marque dans les gris.
`color/red/100` est le seul `.colorset` stocké en composantes hexadécimales et non en flottants.

### Primitives — `color/white-0x` et `color/black-0x` (nées dans Figma)

Deux échelles d'alpha, de 10 % à 90 % par pas de 10, sur du blanc pur et du noir pur. **Elles n'ont aucune
contrepartie dans `Assets.xcassets`** : ce sont les premières primitives du fichier qui ne miroitent pas le
catalogue. Elles existent pour les voiles — un bord, une ombre portée, un scrim — que le code rend en
`Color.white.opacity(x)` / `Color.black.opacity(x)` et qu'aucune couleur opaque ne peut donner (voir D49).

| Tokens | Base | Alphas |
|---|---|---|
| `color/white-01` … `color/white-09` | `#FFFFFF` | 0.10 · 0.20 · 0.30 · 0.40 · 0.50 · 0.60 · 0.70 · 0.80 · 0.90 |
| `color/black-01` … `color/black-09` | `#000000` | 0.10 · 0.20 · 0.30 · 0.40 · 0.50 · 0.60 · 0.70 · 0.80 · 0.90 |

Portées `[]` et aucune `codeSyntax`, comme toute primitive — et parce qu'aucun symbole Swift ne leur correspond.

Six sont consommées depuis le 2026-09-06 : `white-01` (`background/disable` D, `border/default` D), `white-03`
(`foreground/placeholder` D), `white-05` (`foreground/disable` D), `white-06` (`foreground/secondary` D),
`black-01` (`border/default` L), `black-04` (`foreground/placeholder` L, `background/shade` D depuis le 2026-10-27), `black-05` (`foreground/secondary` L).
Les douze autres restent un stock.

`color/black-01` fait doublon de valeur avec `color/gray/1000 10%`, qui vient du catalogue et reste la primitive
de référence tant qu'un asset la porte. Le doublon est assumé : l'échelle vaut par sa continuité.

### Primitives — `shelf/*` (source : `Features/Shelves/ShelfPalette.swift`)

Teintes **hors thème** : elles dépeignent un objet physique (papier, encre), pas du chrome d'interface. Même valeur
en clair et en sombre, **volontairement**.

| Token | Hex | Symbole Swift |
|---|---|---|
| `shelf/parchment` | `#E4DAC4` | `ShelfPalette.parchment` |
| `shelf/ink-dark` | `#3A2E24` | `ShelfPalette.ink(onHex:)` — luminance > 0.58 |
| `shelf/ink-cream` | `#F4EEE1` | `ShelfPalette.ink(onHex:)` — luminance ≤ 0.58 |
| `shelf/ink-fallback` | `#4A3B2C` | `ShelfPalette.ink(onHex:)` — aucun hex de couverture |

`ShelfPalette` porte aussi le papier et l'encre du label (`labelPaper`, `labelInk`) : eux ne sont pas des primitives —
ils aliasent des gris existants — et vivent donc dans la table des sémantiques, plus bas.

La couleur du dos peint elle-même n'est **pas** un token : `ShelfPalette.spineColor(_:)` la calcule depuis l'hex
persisté de la couverture (saturation ×1.45 plafonnée à 0.92, luminosité bornée à [0.42, 0.82]). Elle n'a pas de
valeur fixe, donc pas de variable.

### Sémantiques — `Color` (source : `DesignSystem/Tokens/Color.swift`)

| Token | Light | Dark | Symbole Swift |
|---|---|---|---|
| `foreground/default` | `gray/900` | `gray/50` | `DesignSystem.Color.foregroundDefault` |
| `foreground/inverse` | `gray/50` | `gray/900` | `.foregroundInverse` |
| `foreground/disable` | `gray/400` | **`white-05`** | `.foregroundDisable` |
| `foreground/secondary` | **`black-05`** | **`white-06`** | `.foregroundSecondary` |
| `foreground/tinted` | `green/700` | `green/200` | `.foregroundTinted` |
| `foreground/tinted-inverse` | `green/100` | `green/900` | `.foregroundTintedInverse` |
| `foreground/error` | `red/800` | `red/400` | `.foregroundError` |
| `foreground/placeholder` | **`black-04`** | **`white-03`** | `.foregroundPlaceholder` |
| `background/default` | `gray/0` | `gray/1000` | `.backgroundDefault` |
| `background/inverse` | `gray/900` | `gray/200` | `.backgroundInverse` |
| `background/disable` | `gray/200` | **`white-01`** | `.backgroundDisable` |
| `background/secondary` | `gray/50` | `gray/800` | `.backgroundSecondary` |
| `background/grouped` | `gray/50` | `gray/1000` | `.backgroundGrouped` — **code seul**, voir D-R8 |
| `background/grouped-elevated` | `gray/50` | `gray/900` | `.backgroundGroupedElevated` — **code seul**, voir D-R8 |
| `background/form` | → `background/secondary` | → `background/secondary` | `.backgroundForm` — voir D-FF1, D-FF2 |
| `background/form-cell` | → `background/default` | → `background/shade` | `.backgroundFormCell` — voir D-FF1, D-FF2 |
| `background/shade` | `#000000` @ 0 % | → **`black-04`** | `.backgroundShade` — voir D-FF2, D-FF3 |
| `background/tinted` | `green/100` | `green/900` | `.backgroundTinted` |
| `background/tinted-inverse` | `green/800` | `green/200` | `.backgroundTintedInverse` |
| `background/error` | `red/100` | **`gray/700`** | `.backgroundError` — voir D7 |
| `border/default` | **`black-01`** | **`white-01`** | `.borderDefault` — voir D49, close |
| `border/tinted` | `green/700` | `green/200` | `.borderTinted` |
| `border/error` | `red/800` | `red/400` | `.borderError` |
| `clear` | transparent | transparent | `.clear` |

`borderTinted` partage **le même `case` Swift** que `foregroundTinted`, et `borderError` celui de `foregroundError` :
les deux paires sont égales par construction, pas par coïncidence. Si l'une doit bouger, il faut d'abord scinder le
`case` dans `Color.swift`.

**Six tokens sont des voiles**, pas des couleurs : `foreground/disable` (sombre), `foreground/secondary`,
`foreground/placeholder`, `background/disable` (sombre), `border/default` et, depuis le 2026-10-27,
`background/shade` aliasent les primitives d'alpha `color/white-0x` / `color/black-0x`. `background/form-cell` en
sombre en est un par alias : la carte d'un formulaire assombrit le fond qu'elle couvre au lieu d'avoir son propre
gris. Ils prennent donc la teinte de ce qui est derrière eux, au lieu de ne bien se
lire que sur un seul fond — c'est le raisonnement de D49, étendu le 2026-09-06 aux quatre autres. Côté Swift ils
s'écrivent `.black.opacity(x)` / `.white.opacity(x)` : aucun `.colorset` ne les porte.

Conséquence à surveiller : un voile n'a pas de contraste fixe. `foreground/secondary` en sombre (blanc 60 %) donne
4,5:1 sur `green/900` — tout juste sous le seuil AA du petit texte, ce qui est pourquoi l'écran de connexion monte
ses libellés à `foreground/default` (voir la passe du 2026-09-05 (2)).

`foreground/placeholder` **n'est plus identique** à `foreground/disable` : il est d'un cran plus léger dans les deux
modes (40 % contre 50 % en clair, 30 % contre 50 % en sombre). Le rôle distinct porte enfin une valeur distincte.

### Sémantiques — `shadow/*` et `shelf/*`

| Token | Valeur (les deux modes) | Symbole Swift |
|---|---|---|
| `shadow/soft` | noir 10 % | `Color.black.opacity(0.1)` |
| `shadow/book` | noir 16 % | `Color.black.opacity(0.16)` |
| `shadow/light` | noir 18 % | `DesignSystem.Shadow.light` |
| `shadow/lying-book` | noir 22 % | `Color.black.opacity(0.22)` |
| `shadow/spine` | noir 45 % | `Color.black.opacity(0.45)` |
| `shelf/parchment` | → `shelf/parchment` | `ShelfPalette.parchment` |
| `shelf/ink/dark` | → `shelf/ink-dark` | `ShelfPalette.ink(onHex:)` |
| `shelf/ink/cream` | → `shelf/ink-cream` | `ShelfPalette.ink(onHex:)` |
| `shelf/ink/fallback` | → `shelf/ink-fallback` | `ShelfPalette.ink(onHex:)` |
| `shelf/label/paper` | → `color/gray/0` | `ShelfPalette.labelPaper` |
| `shelf/label/ink` | → `color/gray/900` | `ShelfPalette.labelInk` |

`shadow/light` est la **seule** ombre à porter un vrai symbole Swift : `DesignSystem.Shadow.light`, consommée par le
modificateur `View.shadow(_:)` (`DesignSystem/Tokens/Shadow.swift`). Les cinq autres restent des littéraux
`Color.black.opacity(…)` écrits dans le code des features ; leur reprise dans l'enum est suivie par l'**issue 0014**.
Tant qu'elle n'est pas faite, la colonne « Symbole Swift » de ce tableau est la valeur littérale, pas un token.

Comme les autres `shadow/*`, `shadow/light` porte sa propre alpha et **n'est donc pas un alias** : valeur brute,
identique en clair et en sombre.

`shelf/label/paper` et `shelf/label/ink` aliasent des primitives de gris (`color/gray/0`, `color/gray/900`) — mais
elles **ne suivent pas** `background/default` / `foreground/default`, et c'est **volontaire, pas un oubli**. Ces deux
rôles s'inversent en sombre, alors que l'illustration de l'étagère (`ShelfWash`, `ShelfPlank`) est un asset unique et
universel, sans variante sombre : un label qui s'inverserait collerait du papier quasi noir sur un lavis crème. Les
deux variables portent donc la **même valeur dans les deux modes**, dans une collection qui, elle, est mode-aware —
c'est ce qu'il faut lire avant de « réparer » leur binding. Même raisonnement que `shadow/spine`, maintenu à 45 % au
lieu d'être normalisé vers `shadow/soft`. Côté Swift, la règle est portée par `ShelfPalette`, pas par
`DesignSystem.Color`, exactement pour la même raison : ces teintes dépeignent un objet physique, pas du chrome.

`shadow/soft` consolide **trois** littéraux `0.1` séparés (`ScaleButtonStyle`, `CellThumbnail`, `EntityImageView`) —
une valeur en dur qui revient trois fois est un token qui manque.

Les alphas d'ombre vivent ici, dans des variables **couleur**, et non dans la collection `Opacity` : une couleur
bindée porte son alpha elle-même, et `setBoundVariableForEffect(effect, 'color', v)` ne binde que la couleur.

### `Spacing` (source : `DesignSystem/Tokens/Spacing.swift`)

| Token | pt | Symbole Swift |
|---|---|---|
| `spacing/zero` | 0 | `DesignSystem.Spacing.zero` |
| `spacing/xx-small` | 2 | `.xxSmall` |
| `spacing/x-small` | 4 | `.xSmall` |
| `spacing/small` | 8 | `.small` |
| `spacing/s-medium` | 12 | `.sMedium` |
| `spacing/medium` | 16 | `.medium` |
| `spacing/large` | 24 | `.large` |
| `spacing/x-large` | 32 | `.xLarge` |
| `spacing/xx-large` | 64 | `.xxLarge` |
| `line-height/small` | 0.7 | `DesignSystem.LineHeight.small` — **code mort** (D5) |
| `line-height/medium` | 0.86 | `DesignSystem.LineHeight.medium` — **code mort** (D5) |

L'échelle saute de 32 à 64 : il n'y a rien entre les deux.

### `Radius` (source : `DesignSystem/Tokens/CornerRadius.swift`)

| Token | pt | Symbole Swift |
|---|---|---|
| `radius/none` | 0 | `DesignSystem.CornerRadius.none` |
| `radius/minimal` | 4 | `.minimal` |
| `radius/medium` | 8 | `.medium` |
| `radius/rounded` | 12 | `.rounded` |
| `radius/rounded-large` | 24 | `.roundedLarge` |
| `radius/full` | 360 | `.full` |
| `radius/hairline` | 1 | **hors échelle** — `.rect(cornerRadius: 1)`, `PaintedBookView.swift:56` |
| `radius/book` | 2 | **hors échelle** — `.rect(cornerRadius: 2)`, `ShelfBooksView.swift:100` et `:109` |

`radius/full` vaut 360 et non une demi-hauteur calculée, pour saturer sur n'importe quelle taille de contrôle.

### `Sizing`

| Token | pt | Symbole Swift | Note |
|---|---|---|---|
| `sizing/icon/tag` | 16 | `TagLabelStyle.iconSize` | `@ScaledMetric(relativeTo: .body)` — **grandit** avec Dynamic Type, ce n'est pas un plafond |
| `sizing/icon/circular-button` | 24 | `CircularIconButtonStyle` | boîte du glyphe ; + `spacing/medium` de padding → bouton de 56 pt, au-dessus des 44 pt minimum |
| `sizing/shelf/horizontal-margin` | 24 | `ShelfCardMetrics.horizontalMargin` | ADR 0006 |
| `sizing/border/hairline` | 1 | `Constant.borderWidth` | **code mort** (D5) |

Les proportions de l'étagère ne sont **pas** des tokens : `plankHeight = width × 129/820`, `zoneHeight = width × 9/16`,
`topRoom = zoneHeight × 0.25` sont dérivées de la largeur de carte que décide le carrousel (`ShelfCardMetrics`).
Un ratio n'a pas de valeur absolue à mettre dans une variable.

### `Typography` (source : `DesignSystem/Tokens/TextStyle.swift`)

| Token | Valeur | Note |
|---|---|---|
| `font/family/serif` | `Alegreya` | face de lecture — corps, notes de bas de page |
| `font/family/sans` | `Open Sans` | face d'interface — titres, actions, légendes |
| `font/size/title-200` | 32 | `.largeTitle` |
| `font/size/content-400` | 19 | `.body` |
| `font/size/title-50` | 18 | `.title2` |
| `font/size/content-300` | 17 | `.body` |
| `font/size/action-300` | 17 | `.body` |
| `font/size/footnote-200` | 12 | `.footnote` |
| `font/size/action-200` | 12 | `.body` |
| `font/size/caption-200` | 12 | `.caption1` |

Trois tailles valent 12 pt mais s'ancrent sur **trois courbes Dynamic Type différentes** (`.footnote`, `.body`,
`.caption1`) : elles divergent dès que l'utilisateur change la taille du texte. C'est pour ça qu'elles restent trois
tokens et non un seul.

**Figma ne sait pas exprimer Dynamic Type.** Toutes les tailles du fichier sont les valeurs **non mises à l'échelle**.

### `Opacity` — en pourcentage

| Token | % | Source |
|---|---|---|
| `opacity/surface/plank` | 92 | `ShelfRowView.swift:97`, `ShelfEmptyStateView.swift:68` |
| `opacity/surface/backdrop` | 20 | `EntityImageView.swift:32` — voir D2 |

## Styles de texte — 10

Nommés `Famille/symboleSwift`, pour que la feuille Figma et le `case` Swift se retrouvent d'un coup d'œil. Taille et
famille **bindées** aux variables `Typography`.

| Style | Police | pt | Ancre Dynamic Type | Symbole Swift |
|---|---|---|---|---|
| `Title/title200` | OpenSans ExtraBold | 32 | `.largeTitle` | `DesignSystem.TextStyle.title200` |
| `Title/title50` | OpenSans ExtraBold | 18 | `.title2` | `.title50` |
| `Content/content400Bold` | Alegreya Bold | 19 | `.body` | `.content400Bold` |
| `Content/content400` | Alegreya Medium | 19 | `.body` | `.content400` |
| `Content/content300` | Alegreya Medium | 17 | `.body` | `.content300` |
| `Footnote/footnote200Bold` | Alegreya Bold | 12 | `.footnote` | `.footnote200Bold` |
| `Footnote/footnote200` | Alegreya Regular | 12 | `.footnote` | `.footnote200` |
| `Action/action300` | OpenSans SemiBold | 17 | `.body` | `.action300` |
| `Action/action200` | OpenSans SemiBold | 12 | `.body` | `.action200` |
| `Caption/caption200` | OpenSans Regular | 12 | `.caption1` | `.caption200` |

`title200` sert aussi de `largeTitleTextAttributes` et `title50` de `titleTextAttributes` sur `UINavigationBar`
(`DesignSystem.swift`). Les modifier change la barre de navigation.

## Styles d'effet — 7 ombres

Couleur **bindée** à `shadow/*`, donc mode-aware. Le rayon SwiftUI est repris **tel quel** comme flou Figma.

| Style | x, y | Flou | Couleur | Source |
|---|---|---|---|---|
| `Shadow/Pressed` | 0, 2 | 8 | `shadow/soft` | `ScaleButtonStyle.swift:20` — **uniquement pendant l'appui** ; au repos rayon et offset valent 0 |
| `Shadow/Thumbnail` | 0, 0 | 2 | `shadow/soft` | `CellThumbnail.swift:49` |
| `Shadow/Entity Glow` | 0, 0 | 10 | `shadow/soft` | `EntityImageView.swift:22` |
| `Shadow/Painted Book` | 0, 1.5 | 1.5 | `shadow/book` | `PaintedBookView.swift:57` |
| `Shadow/Book Spine` | 0, 0.5 | 1 | `shadow/spine` | `ShelfSpineView.swift:24`, `ShelfBooksView.swift:80` |
| `Shadow/Lying Book` | 1, 2 | 3 | `shadow/lying-book` | `ShelfBooksView.swift:110` |
| `Shadow/Light` | 0, 2 | 3 | `shadow/light` | `.shadow(.light)` — `ShelfLabelView.swift:52`, `ShelfFocusBookCell.swift:66` |

`Shadow/Light` est arrivée avec le label papier (issue 0012), et c'est la seule dont la source ne soit pas un
littéral : les deux points d'appel passent par `DesignSystem.Shadow.light`, donc la valeur ne peut plus diverger entre
le label et la couverture de la cellule de focus.

**Le design a bougé, pas le code.** La feuille Figma portait jusque-là une ombre **brute** en (0, 1), flou 4, sur le
label ; le code partage (0, 2), flou 3. Le code faisant foi, le style a été créé aux valeurs du code puis appliqué aux
deux variantes de `Shelf Card` en remplacement de l'ombre littérale. Sa couleur est bindée à `shadow/light`, comme
celle des six autres.

`Shadow/Light` hérite de D9 — noir pur dans les deux modes, donc invisible sur un fond sombre. Acceptable ici et
seulement ici : elle ne tombe jamais que sur l'illustration de l'étagère, claire dans les deux modes.

`Shadow/Book Spine` est à 45 % — bien plus lourd que toute ombre d'interface, parce qu'il lit comme un **contact**
et non comme une élévation. Ne pas le normaliser vers `shadow/soft`.

`Shadow/Lying Book` est la seule ombre du système avec un décalage en `x` non nul : c'est ce qui vend la lumière
latérale sur une pile.

## Inventaire des composants

**Aucun.** Cette passe n'a produit que des fondations (variables + styles + page `Tokens`).

Ce qui est prêt à devenir un composant, avec sa source :

| Candidat | Source Swift | Variantes attendues |
|---|---|---|
| `Button / Large` | `DesignSystem/ButtonStyles/LargeButtonStyle.swift` | `primary`, `secondary`, `destructive` × `enabled`, `disabled`, `pressed` |
| `Button / Circular Icon` | `DesignSystem/ButtonStyles/CircularIconButtonStyle.swift` | `enabled`, `disabled`, `pressed` + `INSTANCE_SWAP` pour le glyphe |
| `Tag` | `DesignSystem/LabelStyles/TagLabelStyle.swift` | `tinted`, `secondary` |
| `TagView` | `DesignSystem/TagView.swift` | aucune — mais voir D8 avant de le répliquer |

Pour les créer, charger `figma-generate-library` et suivre sa phase 3 (une page par composant).

## Ce qui n'existe pas, et quoi faire à la place

| Absent | Pourquoi | À la place |
|---|---|---|
| Dynamic Type | Figma n'a pas de notion d'échelle de texte système | Les tailles du fichier sont les valeurs de base. Pour vérifier un cas accessibilité, tester dans le simulateur, pas dans Figma |
| Une variable pour la couleur d'un dos de livre | `ShelfPalette.spineColor(_:)` la **calcule** depuis l'hex de la couverture | Utiliser `shelf/parchment` comme état de repli, et accepter que la couleur réelle soit dynamique |
| Des tokens pour les ratios de l'étagère | Ce sont des proportions dérivées de la largeur de carte, pas des longueurs | Lire `ShelfCardMetrics` ; documenté dans ADR 0006 |
| Code syntax WEB / ANDROID | Il n'y a ni codebase web ni Android dans ce dépôt | iOS seulement. Ne pas ajouter de `var(--…)` fantaisiste |
| Une bibliothèque Figma souscrite | `get_libraries` ne renvoie que des UI kits communautaires (Material 3, iOS 26/27, SDS) | Tout est construit depuis le code. Ne pas importer un kit « pour aller plus vite » : son modèle de tokens ne correspond pas |
| Styles de peinture (`PaintStyle`) | Les variables couvrent le besoin et portent les modes | Utiliser les variables `Color`, pas des styles de couleur |

## Snippet de préambule

À coller en tête de tout `use_figma` qui crée des nœuds dans ce fichier. Encode les pièges déjà payés.

```js
const colls = await figma.variables.getLocalVariableCollectionsAsync();
const COLOR_COLL = colls.find(c => c.name === 'Color');
const MODES = {
  Light: COLOR_COLL.modes.find(m => m.name === 'Light').modeId,
  Dark: COLOR_COLL.modes.find(m => m.name === 'Dark').modeId,
};

const allVars = await figma.variables.getLocalVariablesAsync();
const V = {}, byId = {};
for (const v of allVars) { byId[v.id] = v; V[v.name] = v; }
const TS = {}; for (const s of await figma.getLocalTextStylesAsync()) TS[s.name] = s;
const ES = {}; for (const e of await figma.getLocalEffectStylesAsync()) ES[e.name] = e;

// Les faces réelles se résolvent : pas de substitut. Charger avant tout write de texte.
for (const [family, style] of [
  ['Inter', 'Regular'], ['Inter', 'Semi Bold'], ['Inter', 'Bold'],
  ['Alegreya', 'Regular'], ['Alegreya', 'Medium'], ['Alegreya', 'Bold'],
  ['Open Sans', 'Regular'], ['Open Sans', 'SemiBold'], ['Open Sans', 'ExtraBold'],
]) await figma.loadFontAsync({ family, style });

// Résout un alias jusqu'à sa valeur concrète, pour un mode donné.
function resolve(v, modeId) {
  let val = v.valuesByMode[modeId], guard = 0;
  while (val && val.type === 'VARIABLE_ALIAS' && guard++ < 8) {
    const next = byId[val.id], keys = Object.keys(next.valuesByMode);
    val = next.valuesByMode[next.valuesByMode[modeId] !== undefined ? modeId : keys[0]];
  }
  return val;
}

// Peinture bindée dont la couleur de BASE porte la valeur résolue : sur une instance,
// le littéral gagne sur la variable, donc une base noire s'affiche NOIRE.
function paint(tokenName, modeId, opacity) {
  const v = V[tokenName];
  const b = resolve(v, modeId);
  const p = figma.variables.setBoundVariableForPaint(
    { type: 'SOLID', color: { r: b.r, g: b.g, b: b.b } }, 'color', v);
  return opacity === undefined ? p : { ...p, opacity };
}

// Conteneur de structure : jamais de fond blanc, toujours hug vertical.
function AL(dir, props) { const f = figma.createAutoLayout(dir, props); f.fills = []; return f; }

// Largeur fixe + hauteur qui hugge, dans le bon ordre (resize fige les DEUX axes).
function fixWidth(node, w) {
  node.resize(w, node.height);
  node.layoutSizingHorizontal = 'FIXED';
  node.layoutSizingVertical = 'HUG';
}
```

Rappels d'API qui ont chacun coûté un aller-retour :

- `use_figma` est **atomique** : un script qui échoue ne modifie rien. Retenter après correction est sûr.
- Le contexte de page retombe sur la **première page** à chaque appel ; `setCurrentPageAsync` **une fois par script**.
- Une opacité sur une peinture bindée demande une **passe séparée** (`node.fills = node.fills.map(p => ({...p, opacity}))`),
  et `clone()` / `createComponentFromNode()` la perdent.
- `INSTANCE_SWAP` veut un **node id**, pas une `key`.
- `query()` n'accepte pas de `/` : utiliser `findOne(n => n.name === 'Icon / xmark')`.
- Les coordonnées d'un enfant de `SECTION` sont **relatives** à la section.

## Checklist d'audit

Avant de livrer une passe :

- [ ] Zéro fill / stroke en dur dans un composant
- [ ] Zéro texte sans style dans un composant
- [ ] Zéro variable en `ALL_SCOPES`
- [ ] Zéro variable sans code syntax iOS ni description
- [ ] Chaque style de texte a `fontFamily` **et** `fontSize` bindés
- [ ] Chaque style d'effet a sa couleur bindée
- [ ] Aucun enfant ne déborde de sa section, aucune section n'en chevauche une autre
- [ ] **Capturer et regarder** chaque section — un script qui retourne `success` peut avoir produit une planche vide

Le script : `~/.claude/skills/extract-design-system/scripts/audit.js`. Il ne contrôle les fills et les textes
**qu'à l'intérieur des composants** — tant qu'il n'y a pas de composant dans ce fichier, ces deux compteurs restent
vides par construction, ce n'est pas une preuve de propreté. Les contrôles étendus (code syntax, descriptions,
bindings de styles) ont été ajoutés en ligne lors de la passe du 2026-08-18 ; les reprendre.

Dernier résultat (2026-08-18) : tout à zéro. 1 page, 92 variables, 10 styles de texte, 6 styles d'effet, 0 composant.

## Divergences relevées dans le code

Produites par la réplication. **Statut « ouverte » = rien n'a été changé côté code.**

| # | Où | Constat | Statut |
|---|---|---|---|
| D1 | `Assets.xcassets/color/gray/700 75%.colorset` | Le nom annonce 75 %, l'alpha vaut **0.50** | ouverte — valeur répliquée fidèlement, nom conservé |
| D2 | `Features/EntityBrowser/EntityImageView.swift:32` | `.opacity(colorScheme == .dark ? 0.2 : 0.2)` — ternaire mort, les deux branches sont identiques | ouverte |
| D3 | `DesignSystem/Tokens/Color.swift:76-86` | `uiColor` **ignore `self`** : il renvoie noir/blanc pour *tous* les tokens sauf `.clear`. C'est un bouchon qui se présente comme une correspondance | ouverte |
| D4 | `DesignSystem/Tokens/TextStyle.swift:56` | `weight` contredit `customFont` : `title200` / `title50` déclarent `.black` alors que la police est OpenSans **ExtraBold**. Visible seulement si la police custom ne charge pas — ce que D6 rend probable | ouverte |
| D5 | `Spacing.swift` (`LineHeight` 0.7 / 0.86), `TagView.swift` (`Constant.borderWidth`) | Déclarés, référencés nulle part | ouverte — répliqués et marqués « code mort » |
| D6 | `DesignSystem/Tokens/TextStyle.swift`, `DesignSystem/DesignSystem.swift` | **Bug réel, plus large que décrit ici.** Les trois faces OpenSans retombaient sur la police système, pour trois raisons distinctes : `UIFont(name:)` résout un nom **PostScript**, qui n'est pas le nom de fichier. Les faces livrées s'appellent `OpenSans-Extrabold` et `OpenSans-Semibold` (b minuscule), et la régulière s'appelle simplement `OpenSans` — le code demandait `OpenSans-ExtraBold`, `OpenSans-SemiBold` et `OpenSans-Regular`. Donc `title200`, `title50`, `action200`, `action300` et `caption200` étaient en San Francisco **partout dans l'app**. S'y ajoutait la casse du fichier `OpenSans-Semibold.ttf`, que `Bundle.url(forResource:)` ne trouvait pas, et le `break` de `setupFonts` — au lieu de `continue` — qui faisait avorter la boucle et privait d'enregistrement toutes les faces déclarées après elle | **résolue** — les trois noms PostScript corrigés, `break` → `continue`. Verrouillée par `Tests/DesignSystemFontTests.swift` : chaque face doit se résoudre, et aucun style de texte ne doit retomber sur la police système. C'est la seule façon d'attraper ce bug — le compilateur ne le voit pas, et à l'écran il ressemble à un choix de design |
| D7 | `Color.swift` — `backgroundError` | En sombre, la valeur est un **gris** (`gray/700`), là où tous les autres tokens d'erreur restent rouges dans les deux modes | ouverte — probable oubli |
| D8 | `DesignSystem/TagView.swift:26` | `RoundedRectangle(cornerRadius: .medium)` sans `.fill` → se peint dans la couleur de premier plan héritée | ouverte |
| D9 | Les six ombres | Toutes en noir pur dans les deux modes. En mode sombre, sur `background/default` (noir pur), elles sont **invisibles** — visible sur la planche `Ombres — Sombre` (`16:36`) | ouverte — la variable `shadow/*` est mode-aware, il suffit d'y mettre une teinte claire en sombre |
| D10 | `CLAUDE.md` (racine) | Affirmait que `ReCIT_iOS/CLAUDE.md` en était un « **duplicate** », alors que c'était un fichier différent — un guide Swift/SwiftUI pour agents | **résolue** le 2026-08-29 — le fichier interne est supprimé (ses règles étaient déjà toutes dans la racine, seuls les exemples avant/après sont perdus, voir l'historique git) et la mention est retirée |

D6 mérite une correction indépendamment de ce travail Figma : deux polices ne se chargent pas sur l'appareil.

## Le réflexe de reprise

Au démarrage de toute session qui touche au fichier Figma :

```bash
find . -name "figma-library.md" -o -name "*figma*.md" | head
```

Lire ce fichier **avant** d'appeler le moindre outil Figma. Il donne le `fileKey`, les conventions et les node ids —
donc de quoi continuer au lieu de recommencer. Ne demander le lien Figma que s'il n'y a pas de doc.

Si le fichier Figma a changé sans cette doc (variables ou composants ajoutés à la main), **réconcilier** :
inventorier Figma, mettre la doc à jour, signaler les écarts. Une doc en retard est pire qu'une absence de doc :
elle est crue.

Toute passe qui ajoute un composant, une variable ou un écran met cette doc à jour **dans la même session** —
en particulier les compteurs, les node ids, et le statut des divergences.

---

# Écrans (passe du 2026-08-18, `extract-screens`)

Huit écrans, chacun en clair et en sombre : **16 frames de 393 × 852**, safe areas 59 / 34. Mode épinglé sur chaque
frame via `setExplicitVariableModeForCollection`, ce qui est ce qui fait basculer les 27 tokens sémantiques sans
retoucher un seul nœud.

## Carte des pages (mise à jour)

| Page | id | Contenu |
|---|---|---|
| `Tokens` | `0:1` | 6 sections, 9 planches de tokens |
| `Components` | `20:2` | Les 3 composants qui **miroitent le package** design system |
| `Screens · Components` | `20:3` | Les 23 composites de feature et de chrome |
| `Inventaire` | `737:22197` | `Étagères` (`734:22155`), `Étagère vide · Première étape` (`734:22157`), `Ranger mes livres` (`97:3755`), `Astuces · Ranger mes livres` (`314:8069`), `Synchronisation · Inventaire` (`495:13490`), `Œuvre & édition` (`351:9412`), `Fiche livre · Données bibliographiques` (`744:2382`, proposition), `Modifier l'édition · Toutes les données` (`750:2508`, proposition), `Doublons · ISBN et signalement` (`767:4172`), `Modifier l'édition, l'œuvre et l'auteur·ice · V2` (`814:5090`, proposition), `Éditions · Filtre par langue` (`831:7654`, proposition) |
| `Liste` | `737:22198` | `Listes` (`735:22155`), `Listes · Aucune liste` (`735:22157`), `Liste ouverte, vide` (`735:22159`) |
| `Réseau` | `737:22199` | `Réseau · Onglet & Groupes` (`499:14069`), `Réseau · Ajouter des amis lecteurs` (`407:10422`), `Synchronisation · Amis` (`735:22163`), `Réseau · Graphe` (`512:15486`) |
| `Profil` | `737:22200` | `Profil` (`588:17841`), `Transactions` (`735:22166`) |
| `Search` | `737:22201` | `Recherche unifiée` (`334:8624`), `Recherche · Aucun résultat` (`736:22156`) |
| `Scan et ajout` | `737:22202` | `Scanner` (`327:8637`), `Mise en route` (`73:2829`), `Nouveau livre · Tel que livré` (`704:20545`), `Nouveau livre v2` (`712:21292`, en cours, rien d'implémenté) |
| `Accueil & compte` | `737:22203` | `Accueil` (`736:22162`), `Accueil & compte` (`222:7167`) |
| `Archive` | `737:22204` | 27 sections en colonnes par fonctionnalité, chacune sous un titre Inter Bold 96 : les pistes non retenues, les « Tel quel » remplacés, les réplications périmées |
| `Screens (vide — à supprimer)` | `20:4` | Vidée le 2026-10-25 ; le connecteur refuse de supprimer une page (`Removing this node is not allowed`) |

La séparation entre `Components` et `Screens · Components` est intentionnelle : `Components` ne contient que ce qui
existe dans `DesignSystem/` côté Swift (les deux `ButtonStyle`, le `LabelStyle` de tag). Tout le reste — le chrome iOS
et les vues de feature — vit sur `Screens · Components` et le dit dans sa description. La bibliothèque du design
system reste le miroir du package ; les composites ne s'y invitent pas.

## Composants — `Components` (miroir du package)

| Composant | node id | Variantes | Propriétés | Source Swift |
|---|---|---|---|---|
| `Button / Large` | `22:14` | Style ∈ {Primary, Secondary, Destructive} × State ∈ {Default, Disabled} | `Label#22:1` | `ButtonStyles/LargeButtonStyle.swift` |
| `Button / Circular Icon` | `23:10` | State ∈ {Default, Disabled} | `Glyph#23:1` (INSTANCE_SWAP) | `ButtonStyles/CircularIconButtonStyle.swift` |
| `Tag` | `23:23` | Color ∈ {Tinted, Secondary} | `Label#23:5`, `Glyph#23:6`, `Show glyph#23:7` | `LabelStyles/TagLabelStyle.swift` |

**Aucun des deux boutons n'a de variante `Pressed`** : l'état pressé est un `scaleEffect(0.9)` avec un `easeOut(0.2)`,
c'est-à-dire une transformation, pas une apparence. En faire une variante inventerait un état visuel qui n'existe pas.

## Composants — `Screens · Components`

### Chrome système

Couleurs **littérales** et axe `Theme` explicite, sauf mention contraire : une barre de statut ne se recolore pas avec
la palette de l'app, elle se recolore avec l'OS.

| Composant | node id | Variantes | Propriétés | Note |
|---|---|---|---|---|
| `Chrome / Status Bar` | `24:30` | Theme | — | 393 × 59, sans fond |
| `Chrome / Home Indicator` | `24:35` | Theme | — | 393 × 34, grabber 140 × 5 |
| `Chrome / Tab Bar` | `25:234` | Active ∈ {Inventaire, Listes, Réglages, Recherche} × Theme | — | 393 × 83. Teinte active **bindée** à `foreground/tinted` (`ReCIT.swift:31`) |
| `Chrome / Nav Bar` | `26:162` | Style ∈ {Large, Inline, Inline + Back} × Theme | `Title#26:18`, `Action glyph#26:19`, `Show action#26:20` | Large 96, Inline 44. Titres **bindés** — l'app configure `UINavigationBarAppearance` |
| `Chrome / Search Field` | `27:172` | State ∈ {Idle, Active} × Theme | `Placeholder#27:4` | 393 × 52. `Active` signifie aussi que le carrousel d'étagères a disparu |
| `Icon` | `21:60` | Glyph ∈ 18 valeurs | — | À consommer par `INSTANCE_SWAP`, jamais une variante par icône |

### Composites de feature

| Composant | node id | Variantes | Propriétés | Source Swift |
|---|---|---|---|---|
| `Thumbnail` | `28:163` | Size ∈ {Small 36, Medium 48, Large 64} × Shape ∈ {Minimal 4, Medium 8, Round} | — | `Components/CellThumbnail.swift` |
| `Section Header` | `28:164` | — | `Label#28:0` | `Shelves/ShelfSectionHeader.swift` depuis l'issue 0010 ; ailleurs, des en-têtes de `Section` littéraux identiques. **Aucune variante avec action** — voir D35 |
| `Separator` | `47:193` | — | — | Le filet entre rangs d'un groupe encarté |
| `Cell / Book` | `29:154` | — | `Title#29:0`, `Subtitle#29:1`, `Show subtitle#29:2`, `Authors#29:3`, `Owner#29:4`, `Show owner#29:5`, `Show divider#29:6` | `Inventory/InventoryCell.swift` |
| `Cell / Entity` | `31:188` | Type ∈ {Work, Author, Item} | `Title#31:15`, `Subtitle#31:16`, `Show subtitle#31:17`, `Owner#31:18`, `Show owner#31:19` | `Search/SearchResultCell.swift` **et** `Book/OtherEditionsCell.swift` |
| `Cell / Transaction` | `30:162` | — | `Title#30:0`, `Description#30:1`, `Unread#30:2` | `Transactions/TransactionCellView.swift` |
| `Cell / User` | `30:179` | — | `Username#30:3`, `Item count#30:4` | `Community/UserCellView.swift` |
| `Cell / List` | `38:193` | — | `Name#38:0`, `Explanation#38:1` | `Lists/EntityListView.swift` |
| `Row / Link` | `38:200` | Tone ∈ {Tinted, Destructive} | `Label` (fusionnée) | `Profile/ProfileView.swift` |
| `Row / Summary` | `38:201` | — | `Body#38:5` | `EntityBrowser/EntitySummaryView.swift` + `WithLabel.swift` |
| `User Header` | `32:170` | — | `Username#32:0`, `Item count#32:1`, `Show avatar#32:2` | `Community/UserHeaderView.swift` |
| `Entity Header` | `32:179` | — | `Title#32:4`, `Subtitle#32:5`, `Show subtitle#32:6` | `EntityBrowser/EntityHeaderView.swift` + `EntityImageView.swift` |
| `Syncing Placeholder` | `32:174` | — | `Message#32:3` | `Components/SyncingPlaceholderView.swift` |
| `Shelf Card` | `34:210` | Paint ∈ {Placeholder, Illustrative} | `Name#34:2` | `Shelves/ShelfRowView.swift` — la ligne de nom porte `shelf/label/paper` + `shelf/label/ink` et le style `Shadow/Light` depuis l'issue 0012, sur les **deux** variantes. `Paint=Placeholder` reste périmée par ailleurs : voir D34 |
| `Shelf Create Card` | `34:211` | — | `Name#34:3` | `Shelves/ShelfEmptyStateView.swift` — le composant Figma porte encore l'ancien nom (renommage Swift à l'issue 0011). Vérifier aussi son glyphe « + » : le code l'a perdu à la même issue |
| `Transaction Actions Bar` | `37:178` | — | `Show overflow#37:0` | `Transactions/TransactionActionsBar.swift` |
| `Transaction Message` | `37:213` | Type ∈ {Action, User} | `Body`, `Timestamp`, `Author` (par variante) | `TransactionDetailView.messageView` |

⚠️ **Les clés de propriété sont réattribuées par `combineAsVariants`.** Ne jamais réutiliser la clé renvoyée à la
création d'un composant avant sa combinaison — elle change. Le préambule ci-dessous contient un `setByName` qui
résout la clé par son nom au moment de s'en servir : c'est la seule façon robuste.

## Table des écrans

| Écran | Clair | Sombre | Panneau | Source Swift |
|---|---|---|---|---|
| **Étagères** | `39:2` | `39:179` | `45:1678` | `Shelves/ShelvesView.swift` + `ShelvesContent.swift` |
| **Listes** | `40:309` | `40:404` | `45:1690` | `Lists/EntityListView.swift` |
| **Détail étagère** | `40:499` | `40:646` | `45:1702` | `Shelves/ShelfDetailView.swift` |
| **Recherche** | `41:723` | `41:841` | `45:1714` | `Search/MainSearchView.swift` → `SearchView.swift` |
| **Profil** | `41:959` | `41:1094` | `45:1726` | `Profile/ProfileView.swift` |
| **Fiche livre** | `42:1125` | `42:1219` | `45:1738` | `Book/BookDetailView.swift` |
| **Toutes les transactions** | `42:1313` | `42:1435` | `45:1750` | `Transactions/AllTransactionsView.swift` |
| **Détail transaction** | `42:1557` | `42:1688` | `45:1762` | `Transactions/TransactionDetailView.swift` |

Chaque frame ne contient que des **instances** et des conteneurs de layout nommés (`list group`). Audit de
factorisation : **0 dessin brut** sur les 16 frames.

## Recettes de composition

- **Un onglet racine** = Status Bar + Nav Bar (Large) + [Search Field] + contenu + Tab Bar + Home Indicator. Le chrome
  s'ajoute **en dernier** pour qu'il peigne par-dessus le contenu qui défile.
- **Un écran poussé** = Status Bar + Nav Bar (Inline + Back) + contenu + Tab Bar + Home Indicator. La barre d'onglets
  reste : une destination poussée vit dans sa pile, donc dans son onglet.
- **Une List encartée** = un conteneur `list group` (auto-layout vertical, `background/default`, `radius/medium`,
  clip) contenant des instances de cellule séparées par des instances de `Separator`.
- **Une List `.plain`** = les cellules directement sur `background/default`, `Show divider` allumé sur `Cell / Book`.

## Ce qui n'existe pas dans ce fichier, et pourquoi

| Absent | Raison | À la place |
|---|---|---|
| Les couvertures de livres | Le plugin API ne peut pas récupérer une image distante | `Thumbnail` reste sur `background/disable`, qui est l'état réel avant chargement |
| `ShelfWash` | 1 Mo, trop lourd pour le payload du plugin | Une ellipse floutée à la teinte dominante `#F5E4C1`. `ShelfPlank` **est** le vrai PNG (réduit) |
| Les dos de livres peints | `SpineStripLoader` les peint depuis un ruban de la couverture | `Paint=Placeholder` (fidèle : parchemin) ou `Paint=Illustrative` (teintes inventées, à ne pas prendre pour des données) |
| Les SF Symbols | Non redistribuables dans un fichier Figma | 15 approximations vectorielles à la même taille optique |
| La tab bar Liquid Glass d'iOS 26 | Non reproductible sans le UI kit Apple | La barre classique, état actif par la couleur seule |
| Les variantes `.fill` des symboles actifs | Même raison | La couleur suffit à marquer l'onglet actif |
| Les spinners et états transitoires | `ProgressView` est un contrôle vivant | Non maquettés, listés dans chaque panneau |
| L'appui maintenu sur une étagère | Hors périmètre de cette passe | ADR 0006 décrit le geste ; rien dans Figma |
| Les feuilles et formulaires | Hors périmètre de cette passe | Les 4 coques restent à faire |

## Préambule pour toute passe sur les écrans

À coller en tête de tout `use_figma` qui compose un écran. Complète le préambule des tokens.

```js
// La page de la fonctionnalité (`Inventaire`, `Liste`, `Réseau`, `Profil`, `Search`, `Scan et ajout`,
// `Accueil & compte`) — il n'y a plus de page `Screens` depuis le 2026-10-25.
const page = figma.root.children.find(p => p.name === 'Inventaire');
await figma.setCurrentPageAsync(page);
// Charger TOUTES les faces avant d'instancier : un style de texte bindé les résout à la pose.
for (const [family, style] of [
  ['Inter', 'Regular'], ['Inter', 'Medium'], ['Inter', 'Semi Bold'], ['Inter', 'Bold'],
  ['Alegreya', 'Regular'], ['Alegreya', 'Medium'], ['Alegreya', 'Bold'],
  ['Open Sans', 'Regular'], ['Open Sans', 'SemiBold'], ['Open Sans', 'ExtraBold'],
]) await figma.loadFontAsync({ family, style });

const COLOR_COLL = (await figma.variables.getLocalVariableCollectionsAsync()).find(c => c.name === 'Color');
const MODE = {
  Light: COLOR_COLL.modes.find(m => m.name === 'Light').modeId,
  Dark: COLOR_COLL.modes.find(m => m.name === 'Dark').modeId,
};

/** Résout une propriété par son NOM : `combineAsVariants` réattribue les clés. */
function setByName(inst, name, value) {
  const key = Object.keys(inst.componentProperties || {}).find(k => k.split('#')[0] === name);
  if (!key) throw new Error('no property "' + name + '" on ' + inst.name);
  inst.setProperties({ [key]: value });
}

/** Le gras markdown que `Text(.init(...))` rend, appliqué à la main sur l'instance. */
function applyBold(textNode) {
  const chars = textNode.characters;
  const ranges = []; let out = '', i = 0;
  while (i < chars.length) {
    if (chars[i] === '*' && chars[i + 1] === '*') {
      const end = chars.indexOf('**', i + 2);
      if (end > -1) {
        const inner = chars.slice(i + 2, end);
        ranges.push([out.length, out.length + inner.length]);
        out += inner; i = end + 2; continue;
      }
    }
    out += chars[i]; i++;
  }
  if (!ranges.length) return false;
  textNode.characters = out;
  for (const [a, b] of ranges) textNode.setRangeFontName(a, b, { family: 'Alegreya', style: 'Bold' });
  return true;
}

/** Un frame d'écran, mode épinglé. Le chrome s'ajoute EN DERNIER. */
function screenShell(name, theme, groundPaint) {
  const f = figma.createFrame();
  f.name = name; f.resize(393, 852); f.clipsContent = true;
  f.fills = [groundPaint];
  page.appendChild(f);
  f.setExplicitVariableModeForCollection(COLOR_COLL, MODE[theme]);
  return f;
}
```

Pièges spécifiques aux écrans, en plus des sept de l'API :

- **`resize()` refige les deux axes.** Sur un composant censé huguer en hauteur, il faut remettre
  `layoutSizingVertical = 'HUG'` **après** le `resize`. Symptôme : un composant de 393 × 10.
- **`combineAsVariants` réattribue les clés de propriété.** Utiliser `setByName`.
- **Une instance d'icône ne se redimensionne que si le glyphe a des contraintes `SCALE`.** Les 15 variantes d'`Icon`
  les portent ; un nouveau glyphe doit les recevoir aussi.
- **La rotation Figma est antihoraire positive.** Le livre penché de l'étagère est à `+10`, pas à `-10` : il doit
  tomber **sur** la pile, pas s'en écarter.
- **Le texte enrichi n'est pas une propriété.** Poser le gras à la main sur l'instance, après avoir posé le texte.

## Checklist d'audit — écrans

- [ ] Chaque frame ne contient que des instances et des conteneurs de layout **nommés**
- [ ] Zéro `VECTOR` / `RECTANGLE` / `ELLIPSE` / `TEXT` hors instance dans un frame d'écran
- [ ] Chaque composant porte une description avec son type Swift, ses métriques et ses pièges
- [ ] Chaque paire clair / sombre a son mode épinglé sur le frame
- [ ] Les panneaux de spécification sont exclus de l'audit de factorisation (ils sont de la doc, pas des écrans)
- [ ] **Capturer et regarder** chaque frame

Dernier résultat (2026-08-18) : 0 dessin brut, 0 fill en dur, 0 texte sans style, 0 nom dupliqué, 0 composant sans
description, 0 variable en `ALL_SCOPES`. 4 pages, 92 variables, 10 styles de texte, 6 styles d'effet,
**26 composants**, **16 frames d'écran**, 8 panneaux.

Mise à jour du 2026-08-20 (passes « Résultat » puis « Tri manuel ») : **29 composants** sur `Screens · Components`
(+`Bottom Action Bar`, et `Icon` passe à 16 variantes avec `line.3.horizontal`). Avant le tri manuel : **28 composants**
(+3 : `AutoSort / Shelf Header`, `AutoSort / Book Row`, `AutoSort / Note` ; `Chrome / Nav Bar` gagne une variante,
pas un composant), 3 sur `Components`. Écrans : les 16 frames répliqués, plus les frames d'exploration de la section
`Onboarding` et les 2 frames de la section `Ranger mes livres`. La passe onboarding du même jour n'avait pas rejoué
les compteurs.

Mise à jour du 2026-08-20 (soir, issue 0036) : toujours **29 composants** — aucun composant nouveau, mais `Icon`
(`21:60`) passe à **18 variantes** (`circle`, `exclamationmark.circle`) et `AutoSort / Shelf Header` (`100:228`)
gagne la propriété `Mark glyph#133:0`. Écrans : **9 frames** de plus dans `Ranger mes livres`.

## Écrans morts relevés dans le code

Aucune transition n'y mène ; seule leur propre `#Preview` les référence. **Candidats à la suppression.**

| Écran | Constat |
|---|---|
| `Features/Inventory/MyInventoryView.swift` | Remplacé par `ShelvesView` (ADR 0003), jamais supprimé |
| `Features/Works/WorkListView.swift` | Zéro référence |
| `Features/EntityBrowser/EntityBrowserView.swift` | Zéro référence |

Deux onglets sont par ailleurs déclarés mais **jamais rendus** (`TabConfig.isHidden == true`) : `community`
(`CommunityView`) et `transactions`, ce dernier n'étant qu'un `Text("nav.transactions_placeholder")`.

## Divergences relevées dans le code — passe écrans

Suite de la table des tokens. **Statut « ouverte » = rien n'a été changé côté code.**

| # | Où | Constat | Statut |
|---|---|---|---|
| D11 | `MainTabView.swift:85` | `selectedTab` vaut `.community` par défaut — un onglet dont `isHidden == true`, donc absent du `TabView`. L'app démarre sur une sélection qui n'existe pas | ouverte |
| D12 | `MainTabView.swift:130-140` | `.navigationTitle` / `.navigationBarTitleDisplayMode` appliqués à `ProfileView`, `EntityListView` et `AddInventoryItemSearchView`, qui possèdent **chacune leur propre `NavigationStack`**. Les modificateurs sont hors pile : morts. Trois occurrences | ouverte |
| D13 | `tab.profile` vs `nav.profile` | L'onglet s'appelle « Réglages », son titre de navigation « Profil ». Deux noms pour un écran | ouverte |
| D14 | `Search/MainSearchView.swift` | Le fichier porte un nom (`MainSearchView`) qu'aucun type n'utilise — il contient `AddInventoryItemSearchView` — et son en-tête annonce un troisième nom (`AddInventoryItemView.swift`) | ouverte |
| D15 | `Book/BookDetailView.swift:8`, `Book/BookViewModel.swift:16` | Les deux renvoient à `EditionDetailView`, qui n'existe plus | ouverte |
| D16 | `Lists/EntityListView.swift:2`, `Works/WorkListView.swift:2` | En-têtes annonçant `MyInventoryView.swift` ; `#Preview` au corps commenté | ouverte |
| D17 | `EntityListView.swift:27`, `WorkListView.swift:22`, `CommunityView.swift:23` | `range(of:options:.caseInsensitive)` sur du texte saisi, là où `CLAUDE.md` impose `localizedStandardContains()`. `InventoryListContent` le fait correctement — trois points d'entrée, deux méthodes | ouverte — **deux** depuis le 2026-09-26 : `EntityListView` corrigé (feature 0024) |
| D18 | ~~`SearchView.swift:41` et `:118`~~, `EntityListView.swift:50`, `InventoryListContent.swift:81`, `SyncingPlaceholderView.swift:26`, `SyncingInlineRow.swift:25` | `.red` / `.secondary` **système** là où `.foregroundError` / `.foregroundSecondary` existent. Six occurrences | ouverte — **quatre** depuis le 2026-09-11 : les deux de `SearchView` sont parties avec le fichier (issue 0074) ; **trois** depuis le 2026-09-26 : le `.secondary` d'`EntityListView` est parti avec `ListRowView` (feature 0024) |
| D19 | ~~`SearchView.swift:71`~~ | `"loading more results..."` en dur, non localisé, dans une app entièrement en `Localizable.xcstrings` — et un `HStack(spacing: 12)` littéral | **résolue** le 2026-09-11 (issue 0074) — la chaîne est partie avec `SearchView`, et `grep` ne trouve plus aucun `HStack(spacing: 12)` dans l'app : fermée franchement, pas déplacée |
| D20 | `Localizable.xcstrings` | 9 littéraux français de la feature Étagères sont entrés dans le catalogue **comme clés**, sans traduction `fr` : « Cette étagère est vide », « Créer », « Description (optionnel) », « Enregistrer », « Fermer », « Modifier l'étagère », « Nom de l'étagère », « Nouvelle étagère », « Visibilité ». La langue source étant l'anglais, un utilisateur anglophone voit du français. Une clé vide `""` traîne aussi | ouverte |
| D21 | ~~`search.friends_inventory`~~ | « Dans l'inventaire de **tes** amis » — le SEUL tutoiement du catalogue. Les 21 autres chaînes à la deuxième personne vouvoient | **résolue** le 2026-09-11 (issue 0074) — la clé est supprimée du catalogue avec `SearchView`. La section locale de la recherche unifiée dit « Dans mes livres et chez mes amis » |
| D22 | `SearchResultCell.workCell` vs `OtherEditionsCell` | Même layout, dupliqué. Les deux écrivent `HStack(spacing: 12)` et `VStack(spacing: 4)` en **littéraux** alors que les nombres valent exactement `.sMedium` / `.xSmall`. Le commentaire d'`OtherEditionsCell` dit qu'il « mirrors the book-list cover cell » — il le miroite par copie | ouverte |
| D23 | `CellThumbnail` — points d'appel | La même couverture reçoit un rayon et une taille différents selon l'entrée : `.minimal` / 48 dans `InventoryCell` et `TransactionCellView`, les **défauts** `.medium` / 36 dans `SearchResultCell` et `OtherEditionsCell` | ouverte |
| D24 | `TransactionCellView.swift:47-51` | `TransactionStateLabel` est enveloppé dans `.textStyle(.content300).foregroundStyle(.foregroundSecondary)` : les deux sont morts, `TagLabelStyle` repose son propre style et ses fills en aval. Le `HStack(spacing: .xSmall)` qui l'entoure n'a qu'un enfant | ouverte |
| D25 | `TransactionCellView.isRead` | La propriété s'appelle `isRead` mais renvoie `true` quand la transaction n'a **pas** été lue (elle nie `readStatus`). La pastille non-lu s'affiche donc quand `isRead` est vrai | ouverte |
| D26 | `TransactionDetailView.messageView` | Les messages entrants et sortants rendent **à l'identique** : `getUIMessages` distingue soigneusement `.incoming` de `.outgoing`, mais la branche `default:` les traite d'un seul layout — ni côté, ni couleur, ni alignement | ouverte |
| D27 | `TransactionDetailView` — horodatage | `.formatted(date: .abbreviated, time: .standard)` : `.standard` inclut les **secondes**, dans un fil de discussion | ouverte |
| D28 | `UserCellView` vs `UserHeaderView` | `UserCellView` ne pose **aucun** `foregroundStyle` et hérite de la couleur de label de la `List` ; `UserHeaderView` pose `foreground/default` explicitement sur les deux mêmes lignes | ouverte |
| D29 | `ShelfEmptyStateView` (ex-`ShelfCreateCardView`) | Redéclarait `plankHeight`, `zoneHeight` et `topRoom` en propriétés calculées privées au lieu d'utiliser `ShelfCardMetrics` | résolue — issue 0011, la vue utilise `ShelfCardMetrics` |
| D30 | `EntitySummaryView` | `.onTapGesture` là où un `Button` est requis par la convention du projet : il n'a besoin ni de la position ni du nombre de taps. Conséquence réelle : pas d'état pressé, pas d'action d'accessibilité. (`ShelfCreateCardView` avait le même défaut ; corrigé par l'issue 0011) | ouverte |
| D31 | `Features/Shelves/ShelfSectionHeader.swift` (ex-`ShelvesContent.sectionTitle`) | Le constat tient toujours, à l'adresse près : l'issue 0010 a remplacé la fonction par un type de vue, sans toucher aux deux points relevés. Le titre utilise `foregroundDefault` là où les autres en-têtes de section retombent sur le secondaire du système, et ses libellés restent des littéraux français passés en `String` — donc **non localisés** : `"Étagères"`, `"Tous les livres · N"` et `"Ajouter"`, ce dernier alors qu'une clé `action.add` traduite (« Add » / « Ajouter ») existe déjà au catalogue | ouverte — reformulée pour l'issue 0010 |
| D32 | `ReCIT_iOS.xcodeproj` | `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor` alors qu'**aucun asset `AccentColor` n'existe**. Le `.tint(.foregroundTinted)` de `ReCIT.swift:31` sauve le rendu, mais le réglage pointe dans le vide | ouverte |
| D33 | `AllTransactionsView` | Ne fixe pas `navigationBarTitleDisplayMode`, donc iOS lui donne un grand titre. « Toutes les transactions » en `title200` (32 pt ExtraBold) passe à la ligne dans une barre de 96 pt | ouverte |
| D34 | `Shelf Card`, variante `Paint=Placeholder` (`34:210`) | **Divergence côté Figma.** La passe 0012 n'a corrigé que ce qu'elle touchait : la variante reste périmée face au code livré. Sa `name row` n'a **aucun fill**, donc la pastille de papier ne s'y dessine pas, et elle affiche encore un **crayon** là où le code n'a plus qu'un chevron — le crayon a quitté la carte pour la barre de navigation du détail (issue 0008) | ouverte — demande une passe de design, pas une correction de code |
| D35 | `Section Header` (`28:164`) vs `ShelfSectionHeader.swift` | Le composant Figma n'a ni action de fin de ligne ni variante pour en porter une, alors que l'en-tête « Étagères » a gagné un bouton **Ajouter** teinté (issue 0010). Le composant décrit donc un en-tête que l'écran Étagères n'utilise plus tel quel | ouverte — passe de design |
| D36 | `Features/Shelves/ShelfLabelView.swift:43` | Le chevron du label est peint en `.foregroundSecondary` — un rôle qui **s'inverse** en sombre — et dimensionné par `.font(.footnote)` système, sur un papier délibérément mode-indépendant (`shelf/label/ink` / `shelf/label/paper`). En sombre, le chevron passe donc de `gray/600` à `gray/400` sur un papier resté blanc : le contraste baisse au lieu d'être stable, et c'est le seul élément du label à ne pas suivre la règle du reste | ouverte — relevée en documentant l'issue 0013 |
| D37 | `Features/AutoSort/*` | Toute la feature était en **littéraux français** : « Ranger mes livres », « Créer ces étagères », « Terminer », « Relancer le rangement »… entraient dans `Localizable.xcstrings` comme **clés**, sans aucune localisation — la langue source étant l'anglais, un anglophone lisait du français. Même défaut que D20 pour Étagères | **en grande partie résolue par suppression** — l'issue 0043 a supprimé `AutoSortPlanView`, `AutoSortApplyReport` et `AutoSortShelfMark`, qui portaient la quasi-totalité de ces littéraux, et déplacé `AutoSortBookRow` en `Features/Sorting/SortBookRow.swift` (il n'en portait aucun). **Reste ouverte pour le seul survivant**, `AutoSortUnavailableView`, dont les trois messages d'indisponibilité sont toujours des littéraux ; `action.open_settings` y est la seule vraie clé traduite. La surface de tri qui remplace l'écran écrit tout au catalogue |
| D38 | `Features/AutoSort/AutoSortApplyReport.swift` | Les pluriels étaient concaténés dans l'interpolation (`"étagère\(n > 1 ? "s ont" : " a")"`). Ces phrases ne pouvaient pas entrer au catalogue du tout, et la règle de pluriel devenait du code au lieu d'être une donnée de traduction | **résolue par suppression** — le fichier a été supprimé par l'issue 0043. Son remplaçant, `Features/Sorting/ManualSortApplyReport.swift`, pluralise par substitution au catalogue (`manual_sort.report.*`) et documente explicitement qu'il ne reproduit pas ce défaut |
| D39 | `C3 · Rangement proposé` (`80:2708`) | **Divergence côté Figma.** Le frame d'onboarding était déjà périmé face au code livré : résumé « 5 étagères pour 24 livres » que le code n'avait pas, CTA « Créer les 5 étagères » là où le code disait « Créer ces étagères », aucun bouton **Annuler**, rangs `Cell / List` au lieu des livres de chaque étagère | **aggravée** — l'issue 0043 a supprimé `AutoSortPlanView` : le frame ne décrit plus un écran périmé, il décrit un écran qui n'existe pas. Le CTA de C2 mène désormais à la surface de tri (`ManualSortView`), maquettée plus bas sous « Tri manuel ». Frame **conservé**, à remaquetter lors d'une passe de design — ne pas le supprimer |
| D40 | `Icon` (`21:60`), variante `Glyph=line.3.horizontal` | **Divergence côté Figma.** La variante avait été posée à (0, 0), superposée à `Glyph=book` : les deux se chevauchaient dans le jeu, invisible tant qu'on n'ouvre pas le composant | résolue — passe 0036, la variante a reçu sa case (0, 192) et le jeu a été redimensionné |
| D41 | `Features/AutoSort/AutoSortApplyReport.swift` — branche `.allLanded` | Le registre déclarait explicitement qu'un registre **vide** vaut `.allLanded` (« there was nothing to create and nothing failed, which is a finished run »), mais le rapport rendait alors « **0 étagère a été créée et remplie.** » | **résolue par suppression** — le fichier a été supprimé par l'issue 0043. Le cas qu'elle anticipait — appliquer une pile qui se coalesce à rien — est un cas normal sur la surface de tri, et `ManualSortApplyReport` le traite : `landedCount == 0` rend `manual_sort.report.nothing_to_save`. Le registre lui-même a été déplacé et renommé `SortApplyLedger` (`Model/Sorting/`) |
| D42 | `AutoSort / Book Row` (`100:229`) vs `Features/Sorting/SortBookRow.swift` | **Divergence assumée côté code.** Le composant porte une ligne de genre sous l'auteur, et le code la rendait (`primaryGenre`). La donnée réelle vient des claims Wikidata `wdt:P136`, qui remontent des libellés comme « **Figure d'autorité** » : une ligne qui ne dit rien du livre et se lit comme un bug. Ligne supprimée du rang ; le pipeline continue d'utiliser le genre pour *décider* où va un livre | ouverte côté Figma — le composant décrit un rang que l'écran ne dessine plus. À trancher en passe de design : soit retirer la ligne du composant, soit attendre une source de genre digne de confiance |
| D43 | `AutoSort / Book Row`, propriété `Show handle` | **Divergence assumée côté code.** La poignée du composant n'est plus dessinée par l'app : la liste est tenue en mode édition et c'est **la poignée système** qui la remplace, avec son lever, son animation et sa zone de saisie. Une poignée maison à côté aurait fait deux prises pour un seul geste | ouverte côté Figma — la propriété décrit un élément que l'app ne dessine plus, mais le rendu à l'écran est équivalent |
| D44 | `Tri manuel · Glissement` (`135:3934` / `136:4110`), `Tri manuel · Dépôt sur étagère vide` (`137:4286`) | **Frames périmés, conservés.** Ils maquettaient le drag maison — rang soulevé en `Shadow/Pressed`, emplacement libéré en `background/disable`, bande teintée en cible. Ce drag ne prenait pas sur appareil et a été remplacé par le reorder natif de `List` : le lever, le trou et la surbrillance sont ceux du système et ne sont pas stylables. Le point ouvert sur `background/disable` = `gray/600` en sombre tombe avec eux | périmés — renommés `Superseded (PRD 0009) · …` dans le fichier, **à ne pas supprimer** : ils documentent une intention. Le geste est redevenu un drag applicatif (`draggable` / `dropDestination`, PRD 0009), mais le lever, l'aperçu et le dépôt restent ceux du système et ne sont pas stylables — donc toujours pas à remaquetter tel quel |
| D45 | `Ranger mes livres · Light` (`160:6659`) vs `SortGridMetrics` | **Divergence assumée côté code.** La maquette pose les cartes d'étagère à 112,33 avec une gouttière de **12** ; le code applique la formule de l'owner — `3W + 4 × 16 = largeur`, soit **109,67 et une gouttière de 16**. Les cartes livre, elles, suivent la maquette : 100,33, gouttière 12, plus un peek de 40 qui annonce le défilement du carrousel | ouverte côté Figma — arbitrée en faveur du code par l'owner (PRD 0009). À reprendre en passe de design : soit la maquette passe à 16, soit le code revient à 12 |
| D46 | `Ranger mes livres · Light`, `+` de la barre de navigation | **Divergence assumée côté code.** La maquette met la création d'étagère dans la nav bar ; le code l'a déplacée en **dernière tuile de la grille** — à l'endroit où le geste s'utilise, et elle sert en même temps d'état vide et de cible de dépôt (déposer un livre dessus crée l'étagère et le range). Une action, un contrôle | ouverte côté Figma — les frames ajoutés en 0045 montrent la tuile ; le frame nominal garde le `+` |
| D47 | `Ranger mes livres · Light`, titre de carte vs `TextStyle` | **Diagnostic erroné, refermé.** J'avais écrit qu'aucun token serif n'existait à la taille du titre de carte : `Footnote/footnote200Bold` **est** une Alegreya Bold 12, et c'est exactement ce que la maquette applique. Aucun écart. Le titre des cartes « livre à ranger », lui, est `Content/content300` (Alegreya Medium 17) sur deux lignes, et le code le rendait en 12 — corrigé côté code | résolue — rien à changer côté Figma |
| D48 | `Ranger mes livres`, frames d'états | **Écart de production, résolu.** Les 12 frames d'états manquants ont été générés depuis les décisions du PRD 0009 en clonant le frame nominal, donc à partir des mêmes composants et des mêmes variables. Les pastilles instancient bien `Tag` sans glyphe (`Show glyph = false`), comme le code | résolue — frames à relire par l'owner ; le détail d'étagère (`Détail étagère · Light`) est le seul écran de la feature qui n'avait aucune maquette |
| D49 | `border/default` (variable Figma) vs `DesignSystem.Color.borderDefault` | **Divergence assumée côté code.** La variable Figma résout `gray/200` en clair et `gray/700` en sombre — deux gris opaques. Le code rend désormais **noir à 10 %** et **blanc à 10 %**, donc un voile et non une couleur. La raison : un gris opaque ne se lit comme un bord que sur un seul fond. `gray/200` est légèrement vert (il porte la teinte de marque dans les gris, cf. la note sous les primitives), et sur le lavis d'une étagère ou sur le blanc semi-opaque du panneau de tri il se lisait comme un **trait dessiné** au lieu d'une arête. C'est ce qui avait poussé le filet du panneau de tri à être écrit en `Color.black.opacity(0.2)` en dur, hors token — un contournement maintenant supprimé, le token faisant le travail. Conséquence : `border/default` n'a pas de hex fixe — il aliase désormais `color/black-01` / `color/white-01`, primitives d'alpha nées dans Figma et sans `.colorset` | **close le 2026-09-06** — les primitives manquantes ont été créées (`color/black-01`, `color/white-01`, dans les deux échelles d'alpha) et `border/default` les aliase. Figma et le code disent enfin la même chose, et le raisonnement du voile a été étendu à quatre autres tokens (`foreground/disable` D, `foreground/secondary`, `foreground/placeholder`, `background/disable` D) |

Rappel historique de la passe tokens : **D6 était la priorité** — `OpenSans-SemiBold` et `OpenSans-Regular` ne s'enregistraient
pas au lancement, donc `action200`, `action300` et `caption200` retombent sur la police système sur l'appareil.

---

# Onboarding — propositions (passe du 2026-08-20)

Section `Onboarding` (`73:2829`) sur la page `Screens`. Trois propositions pour la mise en route « inventaire vide →
scanner par lot → rangement automatique ». **Exploration, pas une passe de réplication** : ces frames ne miroitent
aucun écran Swift existant, sauf l'écran de rangement, qui approximait `Features/AutoSort/AutoSortPlanView.swift`
— supprimé depuis (issue 0043), ce qui périme `C3` sans le rendre inutile : voir D39.

**La proposition C est retenue** (2026-08-20). A et B restent dans la section, marquées « écartée », comme trace des
arbitrages — ne pas les supprimer sans supprimer aussi les panneaux qui les expliquent.

## C · Deux plein-écrans — retenue

| Frame | id | Rôle |
|---|---|---|
| `C1 · Bienvenue` | `80:2852` | Premier lancement, inventaire vide. CTA « Scanner mes livres », échappatoire « Plus tard » |
| `C1 · Bienvenue · Sombre` | `87:3011` | Mode épinglé `Dark`, chrome en `Theme=Dark` |
| `C1b · Après « Plus tard »` | `87:2880` | Où l'invitation retombe : le mot sur la planche, une seule ligne à cocher |
| `C2 · Bilan du scan` | `80:2895` | À la fermeture du scanner. Titre = compte de la session, CTA « Ranger mes livres » |
| `C2 · Bilan du scan · Sombre` | `87:3064` | idem, mode `Dark` |
| `C2b · Rangement indisponible` | `87:2960` | Apple Intelligence désactivée : la raison est dite, CTA vers les Réglages |
| `C3 · Rangement proposé` | `80:2708` | **Périmé (2026-08-21, issue 0043)** : miroitait `AutoSortPlanView`, écran supprimé. La cible du CTA de C2 est désormais la surface de tri (`ManualSortView`), maquettée sous « Tri manuel ». Frame conservé — voir D39 |
| `Commun · Scanner par lot (existant)` | `81:2847` | Clone de `57:2401`, non modifié |
| `Spec · C` | `81:2891` | Déclencheurs, flags, cas d'indisponibilité, ce qui reste à trancher |

`C1b` et `C2b` n'ont pas de variante sombre : ce sont des états dérivés, à décliner au moment de l'implémentation.

Les panneaux des propositions écartées : A `81:2863`, B `81:2877`. Frames de A `76:2241` `76:2253` `80:2596`,
frames de B `76:2265` `76:2277` `80:2690`.

## Ce que la construction a appris

- **On ne peut pas déplacer un enfant d'instance** : `set_y` sur un sous-nœud d'instance renvoie
  `This property cannot be overridden in an instance: relative-transform`. Le mot papier de `Shelf Empty Card` est
  donc **masqué** (`visible = false`, override autorisé) et la liste à cocher est redessinée dans la frame, tokens
  bindés (`shelf/label/paper`, `shelf/label/ink`, style `Shadow/Light`).
- Les frames d'écran de ce fichier n'ont **pas d'auto-layout** : leurs enfants sont posés en absolu. Insérer un
  encart veut dire décaler à la main tout ce qui est sous lui, chrome exclu.
- `Shelf Card` (`Paint=Illustrative`) sert d'illustration d'accueil, **label masqué** : sans ça elle annonce
  « Classiques français » sur un écran de bienvenue.
- Une variante sombre s'obtient en clonant, en épinglant le mode `Dark` sur la frame, puis en passant les instances
  de chrome en `Theme=Dark`. Tout le reste suit, parce que tout est bindé.
- Le glyphe `xmark` n'existe pas dans `Icon` (`21:60`). Sans objet pour C, mais c'est ce qui a privé le bandeau de B
  d'une croix de fermeture.


---

# Ranger mes livres — résultat (passe du 2026-08-20, `extract-screens`)

Section `Ranger mes livres` (`97:3755`) sur la page `Screens`. **Une réplication**, pas une exploration : ces deux
frames miroitent `Features/AutoSort/AutoSortPlanView.swift` dans sa phase `.applied`, résultat `allLanded` — la même
liste que la revue, marques cochées, rapport au pied. Le code n'a pas d'écran de progression séparé : c'est ce qui
fait qu'un échec partiel s'explique tout seul.

> **Frames périmés depuis le 2026-08-21 (issue 0043) — conservés, pas supprimés.** L'écran qu'ils miroitent a été
> retiré : la revue, son application et son registre ont disparu, et le rangement se fait désormais sur la surface de
> tri (`Features/Sorting/ManualSortView.swift`, PRD 0008), seul écran de l'app à créer des étagères et à les remplir.
> Ce qui suit décrit donc un écran mort. Il reste ici pour deux raisons : c'est la trace d'une passe de réplication
> conforme au code de son jour, et la surface de tri lui **reprend** l'essentiel — la marque par étagère, le rang de
> livre et le rapport de fin, tous trois maquettés à partir d'ici. La section « Tri manuel » plus bas décrit l'écran
> vivant ; c'est elle qui fait foi. Ne pas remaquetter ces deux frames à l'identique.

## Table des écrans

| Écran | Clair | Sombre | Panneau | Source Swift |
|---|---|---|---|---|
| **Ranger mes livres · Résultat** — **périmé, écran supprimé** | `103:3008` | `105:3107` | `108:3181` | à l'époque `AutoSort/AutoSortPlanView.swift` + `AutoSortBookRow.swift` + `AutoSortShelfMark.swift` + `AutoSortApplyReport.swift` ; **plus aucune source Swift** depuis l'issue 0043. Équivalents vivants : `Sorting/ManualSortListView.swift` + `SortBookRow.swift` + `ManualSortShelfMark.swift` + `ManualSortApplyReport.swift` |

Audit de factorisation : **0 dessin brut**, 0 texte sans style, 25 instances par frame, mode épinglé sur chacun.
Les quatre `▢` de tête sont des conteneurs assumés (`list group / …`), un par `Section` encartée.

## Composants ajoutés — `Screens · Components`

| Composant | node id | Variantes | Propriétés | Source Swift |
|---|---|---|---|---|
| `AutoSort / Shelf Header` | `100:228` | — | `Name#100:0`, `Count#100:1` | à l'époque le `header:` du `Section` par étagère de `AutoSortPlanView.planList` ; désormais `Sorting/ManualSortSectionHeader.swift` — le composant survit à l'écran, c'est le tri manuel qui le porte |
| `AutoSort / Book Row` | `100:235` | — | `Title#100:2`, `Authors#100:3`, `Show authors#100:4`, `Genre#100:5`, `Show genre#100:6` | `Sorting/SortBookRow.swift` (ex-`AutoSort/AutoSortBookRow.swift`, déplacé par l'issue 0043 : la surface de tri en est le seul lecteur) |
| `AutoSort / Note` | `101:236` | Style ∈ {Content, Footnote} × Tone ∈ {Default, Secondary} | `Body#101:0` | les `Section { Text }` isolées : rapport, reste sans étagère, propositions écartées |

`AutoSort / Book Row` est délibérément **distinct de `Cell / Book`** : rien n'est encore rangé, donc ni état de
transaction, ni disponibilité, ni navigation. Le genre y est en `foreground/tinted` parce qu'il est la **raison** du
classement — c'est ce qui permet de dire si c'est le genre ou la correspondance qui a fauté.

`AutoSort / Shelf Header` ne portait à cette passe **que la marque `landed`** : `applying` est un spinner (non
maquetté, convention du fichier) et `pending` / `failed` demandaient deux glyphes absents d'`Icon` (`21:60`). La
passe 0036 les a ajoutés et a ouvert la marque par une propriété `Mark glyph#133:0` (`INSTANCE_SWAP`) plutôt que par
un axe de variantes — voir plus bas. Les trois marques approximent les symboles `.fill` du code par leur version au
trait, seule forme que le jeu porte.

## Variante ajoutée à un composant existant

`Chrome / Nav Bar` (`26:162`) gagne **`Style = Inline + Back + Text action`** (`102:224` clair, `102:235` sombre) et
la propriété **`Action label#102:6`**. C'est la forme d'un `ToolbarItem(placement: .primaryAction) { Button("Terminer") }` :
une action de fin de ligne en **texte** teinté, pas un glyphe. Le titre y est réduit à 197 pt (x = 98, centré sur le
frame) pour ne pas passer sous le libellé. Les trois anciens `Style` et leurs clés de propriété sont inchangés — les
instances déjà posées sur les 16 frames n'ont pas bougé.

## Recette de composition

Fond `background/secondary` (`.applyListBackground()`), puis, en absolu : en-tête d'étagère (31) · `list group` de 361
à `radius/medium` contenant les `AutoSort / Book Row` (87) séparés par `Separator` · gap de 12 entre l'encart et
l'en-tête suivant, de 20 entre deux encarts · notes encartées (47 sur une ligne, 70 sur deux) · chrome posé **en
dernier**. Barre d'onglets sur `Inventaire` — l'entrée par la carte d'étagère vide ; l'écran est aussi atteignable
depuis Réglages.

Une `Section` de List encartée est un **encart** : la note du rapport est donc dans un `list group`, pas posée nue.
Un `footer:` de section, lui, se dessine nu — c'est le cas du « Rien n'a encore été créé… » de l'état proposition.

## Ce qui n'est pas maquetté

| Absent | Pourquoi |
|---|---|
| `.applying` | Spinners et états transitoires, non maquettés par convention du fichier |
| Le rapport partiel (`stopped`) | Demande les marques `pending` et `failed`, donc deux glyphes à ajouter à `Icon` d'abord |
| `.failed` (« Le rangement n'a pas pu être proposé ») et le mur d'indisponibilité | Hors du périmètre demandé ; `AutoSortUnavailableView` a trois messages, un par raison. **Le mur n'existe plus** (issue 0043) : l'indisponibilité est devenue une phrase à côté du bouton de proposition du tri manuel, `ManualSortProposalButton` |
| La section « propositions écartées » | N'apparaît que si le validateur a rejeté une correspondance |
| L'état `plan.isEmpty` | Une seule phrase, portée par `AutoSort / Note` Content/Secondary — à poser le jour où il est utile |

Les couvertures des huit vignettes sont **la même image** que les écrans voisins, posée en override d'instance : un
seul visuel pour tous les livres, ce n'est pas une donnée.

## Ce que la construction a appris

- **Les glyphes d'`Icon` sont dessinés au trait, pas au remplissage.** Leurs vecteurs portent un `stroke` bindé à
  `foreground/default` et **aucun fill**. Teinter une icône veut donc dire remplacer le `stroke` ; poser un `fill`
  bouche le cercle et fait disparaître la coche — ce qui ne se voit qu'à la capture.
- **`clone()` d'une variante perd ses `componentPropertyReferences`** en entrant dans le `COMPONENT_SET`. La
  propriété existait, l'instance la portait à la bonne valeur, et le texte affichait quand même l'ancien libellé. Il
  faut réattribuer `{ characters: 'Title#26:18' }` à la main après le `appendChild`.
- En revanche, `set.addComponentProperty` **ne renomme pas** les clés existantes : ajouter une variante et une
  propriété à un composant déjà consommé par 16 frames est sûr. C'est `combineAsVariants` qui réattribue, pas
  `appendChild`.
- Une peinture bindée **suit bien le mode épinglé à travers une instance**, y compris sur un `stroke` d'icône : le
  clone sombre a résolu `foreground/tinted` en `green/200` sans retouche. Le piège 4 ne concerne que les overrides
  posés avec une base littérale incohérente.


## Tri manuel — proposition (2026-08-20)

Dérivé de l'écran de résultat, dans la même section. **Rien de tout ceci n'existe dans le code** : c'est une
proposition de design, pas une réplication. La liste cesse d'être une revue et devient une surface de travail —
on range à la main, sans modèle.

| Frame | id |
|---|---|
| `Tri manuel · Light` | `115:3276` |
| `Tri manuel · Dark` | `120:3636` |
| `Tri manuel · Appliqué · Light` | `126:3672` |
| `Spec · Tri manuel` | `117:3526` |

Neuf frames de plus ont rejoint la section le soir même — le glissement, la cible de dépôt, la synchronisation
d'ouverture, « À ranger » vide et l'échec partiel : voir [Les cinq états jamais dessinés](#passe-du-2026-08-20-issue-0036--les-cinq-états-jamais-dessinés).

**Spec fonctionnelle : [docs/features/0010-grid-shelf-sorting.md](../features/0010-grid-shelf-sorting.md)**
(et, pour la surface qu'elle remplace, [0009](../features/0009-manual-shelf-sorting.md)) — le modèle de
diff, les états et les cas limites vivent là, pas ici. Le PRD d'origine
(`docs/prd/0008-manual-shelf-sorting.md`) est supprimé depuis le 2026-08-29 ; il reste dans l'historique git.

Ce que la proposition ajoute à l'écran de résultat :

- une section **« À ranger »** qui se comporte comme une étagère mais n'en est pas une — en dernier, sans marque,
  et le tas se vide vers le haut au fil du rangement ;
- une **poignée de déplacement** à droite de chaque rang, « À ranger » compris : le glissement est symétrique, on
  sort un livre d'une étagère aussi bien qu'on l'y met ;
- un **« + »** dans la barre de navigation pour créer une étagère à la volée ;
- **« Terminer »** en **barre épinglée** au bas de l'écran, à la place qu'il occupait dans la barre de navigation.

Le genre est masqué dans « À ranger » : ces livres sont sans étagère faute de genre connu, l'afficher vide dirait
deux fois la même chose.

### Ajouts au système

| Ajout | node id | Défaut | Pourquoi ce défaut |
|---|---|---|---|
| Glyphe `line.3.horizontal` dans `Icon` | `112:232` | — | La poignée de déplacement. 16e variante du jeu |
| `Show handle` sur `AutoSort / Book Row` | `Show handle#113:0` | **false** | Les frames de résultat miroitaient le code livré, qui n'avait pas de glisser-déposer. Le défaut reste ce qu'il est, les frames de résultat étant conservés — mais le seul écran vivant qui pose ce composant, le tri manuel, le met à `true` partout |
| `Show mark` sur `AutoSort / Shelf Header` | `Show mark#113:1` | **true** | L'écran de résultat portait la marque ; le tri manuel l'éteint partout |
| `Bottom Action Bar` | `114:231` | — | Barre d'action épinglée : `background/default`, filet `border/default` en haut, `Button / Large` Primary en pleine largeur. 393 × 83, se pose à y = 686 |

Les deux booléens sont **défaut-neutres par construction** : ajoutés avec le défaut qui laisse les six instances
déjà posées sur `Résultat · Light` / `· Dark` exactement comme elles étaient. Vérifié à la capture, pas seulement au
raisonnement.

### Décisions de design, et leur revers

- **« Terminer » quitte la List.** `AutoSortPlanView` gardait délibérément son action *dans* la liste pour que les
  marques restent le récit principal (écran supprimé depuis, issue 0043 — l'argument, lui, tient toujours, et c'est
  celui que le code du tri manuel a finalement retenu : voir `ManualSortListView`). Ici il n'y a plus de marques, la liste se réordonne à chaque geste, et une
  action posée au pied s'éloigne à mesure qu'on travaille. D'où la barre épinglée — et le revers assumé : deux
  barres empilées au bas de l'écran, 166 pt de chrome.
- **Le « + » prend la place de « Terminer »** dans la barre de navigation. Les deux ne coexistent jamais : c'est ce
  qui rend le déplacement nécessaire plutôt que cosmétique.
- **Le contenu défile sous la barre d'action, jamais sous la barre de navigation.** Le composant de nav est
  translucide : la première composition faisait passer une carte dessous et le rang fantômait derrière le titre.

### À trancher avant de coder

- **`onMove` ne traverse pas les sections d'une `List`.** Un glisser-déposer d'une étagère à une autre impose
  `.draggable` / `.dropDestination` avec un transfert typé, pas un mode édition. C'est la contrainte qui décide de
  la faisabilité, et elle n'est pas visible dans la maquette.
- Même écran que le résultat d'auto-sort une fois le rangement appliqué (les marques s'éteignent, les poignées
  s'allument), ou écran distinct atteignable sans avoir rien lancé ? Et dans le premier cas, que devient le rapport
  « 2 étagères ont été créées et remplies » ?
- Une écriture par dépôt, ou une seule à « Terminer » ? La première suit l'optimisme de l'ADR 0001 ; la seconde fait
  de « Terminer » une vraie validation, et impose de savoir ce qu'un abandon annule.

### Non maquetté

*(état à la passe du 2026-08-20 matin ; cinq de ces états ont été dessinés le soir même — voir « Les cinq états
jamais dessinés » plus bas. Reste non maquetté : la feuille de création derrière le « + », la proposition en cours de
génération, et l'état `.applying` d'une étagère.)*

Le rang en cours de glissement (soulevé, ombre, emplacement d'accueil) · la section survolée comme cible de dépôt ·
la feuille de création derrière le « + » · « À ranger » vide, où la section devrait disparaître · l'inventaire
entièrement rangé.


### Passe du 2026-08-20 (soir) — étagères existantes et indicateur d'état

Deux changements de fond après relecture, dont un venu de l'utilisateur directement dans le fichier.

**Ce que l'utilisateur a changé dans la maquette** — repris tel quel, c'est son arbitrage :

- le frame devient un **canevas de défilement** de 393 × 1540 (et non un viewport de 852) : tout le contenu est
  visible d'un coup, la tab bar est calée en bas du canevas ;
- le contenu passe dans un conteneur **auto-layout vertical, gap 14, enfants centrés** — d'où les encarts à 361 sans
  `x` explicite. Une section s'insère maintenant par `insertChild`, sans recalculer un seul `y` ;
- `Bottom Action Bar` (`114:231`) porte **deux** `Button / Large` — Primary « Créer ces étagères » puis Secondary
  « Annuler » — et redescend **dans le flux** de la liste, au pied. La barre épinglée est abandonnée.

**Ce que cette passe ajoute :**

| Ajout | id / clé | Défaut |
|---|---|---|
| `Show tag` sur `AutoSort / Shelf Header` | `Show tag#119:0` | **false** |

La pastille est une instance du `Tag` du design system (`23:23`), pas un badge nouveau. Trois états, posés en
override sur l'instance :

| État | Pastille |
|---|---|
| Étagère déjà sur le serveur, intacte | *aucune* |
| Étagère à créer | « Nouvelle », `Color=Tinted` |
| Étagère existante dont le contenu a bougé | « Modifiée », `Color=Secondary` |

**C'est l'absence qui porte l'état normal** : le diff se lit sans rien compter. Les deux pastilles sont dérivées du
diff au rendu — jamais stockées — donc une pastille ne peut pas mentir sur ce que fera le bouton, et sortir un livre
puis le remettre l'éteint.

La maquette montre désormais cinq sections : deux étagères `Nouvelle` issues d'un auto-sort, une existante marquée
`Modifiée`, une existante sans pastille, puis « À ranger ». La note encartée n'est plus le rapport d'un rangement
passé mais le **récapitulatif du diff à enregistrer**, en toutes lettres, juste au-dessus des boutons.

Le frame sombre a été **reconstruit** depuis le clair (l'ancien `116:3430` est supprimé) : il avait divergé pendant
les retouches. Reconstruire un jumeau sombre coûte un clone, un mode épinglé et quatre `Theme=Dark` — moins cher que
de rejouer les modifications des deux côtés.


### Passe du 2026-08-20 (fin) — trois boutons et l'état « appliqué »

Après une session de grilling, l'écran change de nature : il n'y a plus un écran de revue et un écran de tri, mais
**un seul écran** dont l'entrée est « état initial + changements IA optionnels » et dont l'état de travail est une
**pile de changements**. L'IA devient un générateur de changements comme le doigt de l'utilisateur. L'architecture
complète est dans [docs/features/0010-grid-shelf-sorting.md](../features/0010-grid-shelf-sorting.md) ; seules ses
conséquences visuelles sont ici.

`Bottom Action Bar` (`114:231`) porte maintenant **trois** `Button / Large` :

| Bouton | Style | Rôle |
|---|---|---|
| « Proposer un rangement » | Secondary | Empile les changements de l'IA. **N'écrit rien** |
| « Appliquer le rangement » | Primary | Exécute la pile — **« Enregistrer » dans le code depuis le 2026-10-02** ([feature 0032](../features/0032-sorting-save-and-leave.md)) ; le frame n'est pas mis à jour |
| « Annuler » / « Terminer » | Secondary | Voir la règle ci-dessous |

**Le libellé du troisième bouton est dérivé de `changes.isEmpty`**, pas d'un drapeau collant :

- pile non vide → primaire actif, troisième bouton **« Annuler »** (jette la pile) ;
- pile vide → primaire **désactivé**, troisième bouton **« Terminer »** (ferme l'écran).

Un apply réussi vide la pile, donc « Terminer » apparaît tout seul — et si l'utilisateur reprend le tri, il redevient
« Annuler », ce qui est vrai. C'est ce que montre `Tri manuel · Appliqué · Light` (`126:3672`) : plus aucune pastille
(rien n'est en attente), la note encartée passe du récapitulatif au rapport, le primaire est en `State=Disabled`, le
troisième dit « Terminer ».

Le mur d'indisponibilité d'Apple Intelligence disparaît de la maquette : il n'y a plus qu'un bouton, qui peut être
absent ou inerte. Sur un appareil qui ne peut pas faire tourner le modèle, l'écran reste entièrement utilisable.


### Passe du 2026-08-20 (issue 0036) — les cinq états jamais dessinés

Cinq états de la surface de tri n'existaient dans aucune maquette, dont deux qui **sont** la sensation de la
fonctionnalité : le rang pendant qu'on le glisse, et la section sous le doigt. Ils sont dessinés à côté des trois
frames existants, dans la même section `Ranger mes livres` (`97:3755`).

**Rien de tout ceci n'existe dans le code** — comme le reste du tri manuel, c'est une proposition de design. La spec
fonctionnelle reste [docs/features/0010-grid-shelf-sorting.md](../features/0010-grid-shelf-sorting.md).

#### Les frames

| Frame | id | Mode | Ce qu'il tranche |
|---|---|---|---|
| `Tri manuel · Synchronisation · Light` | `134:3832` | Clair | L'aller-retour serveur d'ouverture **bloque tout l'écran**. Viewport 393 × 852 (et non un canevas : il n'y a rien à faire défiler), `Syncing Placeholder` sur toute la zone de contenu, et **le « + » de la barre de navigation est absent** tant que l'instantané n'existe pas |
| `Tri manuel · Synchronisation · Dark` | `134:3899` | Sombre | idem |
| `Tri manuel · Glissement · Light` | `135:3934` | Clair | Le rang soulevé, le trou qu'il laisse, et la section remplie survolée comme cible |
| `Tri manuel · Glissement · Dark` | `136:4110` | Sombre | idem |
| `Tri manuel · Dépôt sur étagère vide · Light` | `137:4286` | Clair | Le même geste au-dessus d'une étagère créée à la volée, **encore vide** : son encart porte une note, donc une hauteur à viser |
| `Tri manuel · Tout rangé · Light` | `139:4469` | Clair | « À ranger » vide : **la section reste**, une note à la place des rangs, compte à « 0 livre » |
| `Tri manuel · Tout rangé · Dark` | `140:4652` | Sombre | idem |
| `Tri manuel · Échec partiel · Light` | `142:4835` | Clair | Le rapport en **trois** parties, plus une marque par étagère : posée, échec, en attente, rien |
| `Tri manuel · Échec partiel · Dark` | `143:5022` | Sombre | idem |

`Dépôt sur étagère vide` n'a **pas** de jumeau sombre, et c'est délibéré : la teinte de survol et l'ombre du rang
soulevé sont déjà prouvées par le couple `Glissement`, ce frame n'ajoute qu'une variante de cible. Même raisonnement
que `C1b` / `C2b` de la passe onboarding.

Le panneau `Spec · Tri manuel` (`117:3526`) est étendu de six blocs — les cinq états, la décision sur « À ranger »
vide, le vocabulaire des marques, les trois parties du rapport, et trois points à trancher. Sa liste « états non
maquettés » a été réécrite au lieu d'être laissée périmée.

#### Le rang soulevé, et le trou

Le rang quitte le flux de la liste et se pose **en absolu sur le frame**, entre le contenu et le chrome : il prend
`background/default`, `radius/medium`, l'ombre `Shadow/Pressed`, et se décale de 10 pt vers la droite. Sa place
devient un conteneur nommé `emplacement libéré / <titre>`, à la hauteur exacte du rang, rempli en
`background/disable`.

**Le compte de l'en-tête ne bouge pas.** Rien n'est déposé tant que le doigt n'a pas lâché ; un compte qui changerait
en vol mentirait sur ce qui est acquis.

L'ombre **réutilise `Shadow/Pressed`** (0, 2, flou 8) faute d'ombre de lévitation dans le système. Le raccourci se
défend — un glissement commence par un appui — et surtout : aucun symbole Swift ne porte d'élévation de ce genre, donc
inventer un style d'effet ici aurait été inventer un token que le code ne réclame pas. À revoir le jour où il le
réclamera.

#### La cible de dépôt

La section survolée passe **entière** en `background/tinted`, filets haut et bas en `border/tinted`, en-tête compris :
c'est la **section** qui reçoit, pas une ligne. Le dépôt entre dans une étagère, jamais entre deux rangs — l'ordre à
l'intérieur d'une étagère n'existe pas dans le modèle, donc un emplacement d'insertion inter-rangs promettrait quelque
chose que l'écriture ne sait pas tenir.

Sur une **étagère vide**, l'encart n'est jamais réduit à rien : il porte une note « Cette étagère est encore vide.
Déposez un livre ici pour la remplir. » Sans elle, une étagère neuve serait une cible de dépôt de 0 pt de haut.

#### « À ranger » vide — la décision

La PRD laissait le choix ouvert. **La section reste**, avec une note à la place des rangs et un compte à « 0 livre ».
Trois raisons :

1. c'est la seule cible qui **sort** un livre d'une étagère — la faire disparaître supprimerait la moitié de la
   symétrie que la poignée promet sur tous les rangs ;
2. le dernier dépôt ferait s'évanouir une section entière sous le doigt, exactement le saut que le retour de survol
   existe pour éviter ;
3. un compte à zéro est la seule **preuve** que le travail est fini ; une section absente ne prouve rien, elle
   ressemble à un bug.

Le prix, assumé : une section qui ne contient rien reste à l'écran.

Détail du même frame : les livres rangés à la main gardent leur **genre masqué** une fois sur l'étagère. Ils étaient
sans étagère faute de genre connu, et c'est le doigt qui les a classés — la colonne de genres se lit donc comme la
trace de ce que le modèle a su faire.

#### Le rapport d'échec partiel

Trois parties, jamais deux, exactement comme `SortApplyLedger.Result.stopped` (ex-`AutoSortApplyProgress`,
déplacé en `Model/Sorting/` par l'issue 0043) :

| Sortie | Copie de la maquette |
|---|---|
| Créée **et remplie** | « Créée et remplie : Romans classiques. » |
| Créée **sans ses livres** | « Échec sur Science-fiction et fantasy : l'étagère a été créée, mais ses livres n'y sont pas encore. » |
| **Jamais créée** | « Non traitée : Bandes dessinées. » |

La deuxième ne se replie pas sur « non créée » : rien n'est annulé, donc l'étagère est peut-être là, vide, et
l'utilisateur irait la chercher. Le sens venait de `AutoSortApplyReport.swift`, supprimé depuis (issue 0043) ;
**la forme, non** — les phrases sont
écrites pour se lire au singulier comme au pluriel, la règle de pluriel devant venir du catalogue et non d'une
ternaire dans l'interpolation (D38, délibérément non reproduite).

Après l'arrêt, **les pastilles redisent la vérité toutes seules**, sans cas particulier : `Romans classiques` a atterri
→ plus de pastille ; `Science-fiction et fantasy` existe désormais mais son contenu diffère encore → `Modifiée` ;
`Bandes dessinées` n'a pas été touchée → `Modifiée`. La pile n'est pas vide, donc le primaire reste actif et le
troisième bouton dit toujours « Annuler ». Rien à ajouter au règlement des boutons.

#### Ajouts au système

| Ajout | id / clé | Défaut | Pourquoi ce défaut |
|---|---|---|---|
| Glyphe `circle` dans `Icon` | `132:235` | — | La marque `pending`. Le cercle de `checkmark.circle`, sans la coche : géométrie et bindings identiques par construction |
| Glyphe `exclamationmark.circle` dans `Icon` | `132:239` | — | La marque `failed`. Le même cercle + barre et point importés en SVG, `stroke` bindé à `foreground/default` comme les 17 autres |
| `Mark glyph` sur `AutoSort / Shelf Header` | `Mark glyph#133:0` (`INSTANCE_SWAP`) | **`21:55` = `checkmark.circle`** | Le défaut est la marque que l'écran de résultat porte déjà : les six instances posées sur `Résultat · Light` / `· Dark` n'ont pas bougé |

`Icon` (`21:60`) passe donc à **18 variantes**, et le nombre de composants reste à **29** — aucun composant nouveau,
seulement deux variantes et une propriété.

**Pourquoi une propriété `INSTANCE_SWAP` et pas un axe de variantes `Mark`.** Passer `AutoSort / Shelf Header` en
`COMPONENT_SET` demande `combineAsVariants`, qui **réattribue les clés de propriété** — et le composant est déjà
consommé par une dizaine d'instances sur quatre frames livrés. `addComponentProperty`, lui, ne renomme rien. La
teinte de la marque se pose ensuite en override sur le `stroke` du vecteur (`foreground/tinted`, `foreground/disable`,
`foreground/error`) : les glyphes du jeu sont dessinés **au trait**, poser un `fill` boucherait le cercle.

Une étagère sur laquelle il n'y a **rien** à faire ne porte aucune marque — c'est `Poésie` sur le frame d'échec.
Une coche veut dire que la création **et** l'écriture d'appartenance ont abouti : créée sans ses livres est un échec,
pas un demi-succès.

#### Audit de factorisation — les 9 frames

**0 dessin brut** (aucun `VECTOR` / `RECTANGLE` / `ELLIPSE` / `LINE` / `TEXT` hors instance) · **0 fill ou stroke en
dur** (toutes les peintures sont bindées, y compris les overrides) · **0 texte sans style** · **0 conteneur au nom par
défaut** · **mode épinglé sur 9 frames sur 9**.

| Frame | Instances | Conteneurs nommés |
|---|---|---|
| `Synchronisation · Light` / `· Dark` | 5 | 0 |
| `Glissement · Light` / `· Dark` | 24 | 10 |
| `Dépôt sur étagère vide · Light` | 26 | 11 |
| `Tout rangé · Light` / `· Dark` | 26 | 9 |
| `Échec partiel · Light` / `· Dark` | 28 | 8 |

Les conteneurs `Frame 1` / `Frame 2` hérités du clone ont été renommés `contenu défilant` et `pied de liste` sur les
neuf frames — un conteneur au nom par défaut n'est pas un conteneur nommé. Les frames sources (`115:3276`,
`120:3636`, `126:3672`) portent encore les anciens noms ; ils n'ont pas été touchés, cette passe ajoute **à côté**.

La section `Ranger mes livres` passe à 8754 × 3247 pour les contenir. Aucun chevauchement avec `Onboarding`
(`73:2829`) ni avec les frames de premier niveau de la page.

#### Ce que la construction a appris

- **`setProperties` sur une propriété `INSTANCE_SWAP` renomme le nœud échangé.** Le `mark` devient `Icon`, et un
  `findOne(n => n.name === 'mark')` posé juste après renvoie `null`. Retrouver le sous-nœud par sa **position**
  (`header.children[0]`), pas par son nom, puis le renommer si on tient au nom.
- **Un frame cloné ne se réajuste pas.** Ajouter une section à un conteneur en auto-layout allonge le contenu mais
  pas le canevas : la barre d'onglets se retrouve **au milieu** de la liste. Recalculer `tab.y`, `home.y` et la
  hauteur du frame après chaque insertion.
- **Un rang soulevé doit sortir du flux**, donc quitter le conteneur en auto-layout pour se poser en absolu sur le
  frame — mais **avant** le chrome dans l'ordre des enfants, sinon il passe par-dessus la barre de navigation
  translucide.
- Une variante ajoutée à `Icon` atterrit à (0, 0) si on ne lui donne pas sa case ; `line.3.horizontal` y était depuis
  la passe précédente, superposée à `book` (D40).

---

# États vides (passe du 2026-08-28, `extract-screens`)

Cinq états vides de l'onglet **Inventaire** et de la feature **Listes**, chacun en « tel quel » (ce que l'app rend
aujourd'hui) et en « proposé », clair et sombre : **18 frames** dans la section `Empty states` (`199:5924`) de la page
`Screens`, plus 5 panneaux de spécification.

La section existait déjà, vide, avant cette passe.

## Table des écrans

| État | Tel quel · Clair | Tel quel · Sombre | Proposé · Clair | Proposé · Sombre | Panneau | Source Swift |
|---|---|---|---|---|---|---|
| **A · Collection vide** | `209:5967` | `209:6110` | `209:6301` | `209:6438` | `215:7151` | `Shelves/ShelvesContent.swift:79` |
| **B · Livres sans étagère** | `210:6233` | `210:6374` | — | — | `215:7163` | `Shelves/ShelvesContent.swift:79` |
| **C · Recherche sans résultat** | `211:6475` | `211:6538` | `211:6605` | `211:6686` | `215:7171` | `Inventory/InventorySearchRemoteSection.swift` — **proposition implémentée le 2026-09-11 (issue 0076)** : les frames `211:6605` / `211:6686` sont adoptées dans la recherche unifiée, via `EmptyStateView` (`Empty State` `204:263`, `Layout=Centered`), là où l'état se produit réellement — une réponse vide d'inventaire.io. `InventoryListContent:65`, contre lequel la maquette avait été dessinée, garde son `Text` centré : c'est l'inventaire filtré, pas une requête sans résultat. **D55 reste ouverte** |
| **E · Aucune liste** | `212:6707` | `212:6773` | `212:6839` | `212:6921` | `215:7181` | `Lists/EntityListView.swift:41` |
| **H · Liste ouverte, vide** | `213:6935` | `213:7015` | `213:7095` | `213:7168` | `215:7191` | `Lists/EntityListDetail.swift:88` / `:173` |

**B n'a pas de frame « Proposé », volontairement** : c'est le seul des cinq où le code n'a rien à corriger. La carte
remplace le carrousel, sa note dit l'action suivante, la liste dessous est pleine. Dessiner un doublon n'aurait rien
documenté ; le panneau le dit à la place.

Audit de factorisation : **18 frames, 0 dessin brut**. Un seul `▢` en tête de frame — le `list group` de H, conteneur
de layout assumé (le groupe encarté qu'une `List` dessine).

## Composant ajouté — `Screens · Components`

| Composant | node id | Variantes | Propriétés |
|---|---|---|---|
| `Empty State` | `204:263` | Layout ∈ {Centered, Row} × Tone ∈ {Default, Secondary} | `Title#205:0`, `Body#205:5`, `Show body#205:10`, `Glyph#205:15` (INSTANCE_SWAP), `Show glyph#205:20`, `Show action#205:25` |

- **Layout=Row** reproduit ce que le code dessine : une ligne alignée à gauche, posée comme un rang de `List`.
- **Layout=Centered** porte les propositions : glyphe, titre, phrase, et une instance de `Button / Large`.
- Les variantes `Row` **n'ont pas** les nœuds glyphe / body / action. `Show glyph`, `Show body` et `Show action` y
  sont donc sans effet — c'est voulu : un rang n'a rien à cacher.
- Le **libellé du bouton n'est pas une propriété** du composant : c'est le `Label#22:1` de l'instance
  `Button / Large` imbriquée, à surcharger sur l'instance (`findOne(name === 'Action')`).
- `Tone` porte **deux choses à la fois** — le style de texte *et* la couleur. C'est un axe impur, assumé : il
  reproduit l'écart réel entre les deux points d'entrée du code plutôt que de le lisser. Voir D50.

## Composants corrigés

| Composant | node id | Ce qui a changé |
|---|---|---|
| `Section Header` | `28:164` | Gagne `Action label#206:0` et `Show action#206:1` (défaut **false**, pour ne pas modifier les frames existants). L'action est un `Label(…, systemImage: "plus")` tinté en `action200`, padding vertical 8. **Referme D35.** |
| `Shelf Empty Card` | `34:211` | Perd sa ligne de nom **sous la planche**, héritée de `ShelfCreateCardView` : le code ne dessine qu'une note **sur** l'étagère. La propriété `Name#34:3` est renommée **`Note#34:3`** et rebranchée sur cette note. |

⚠️ Le renommage `Name` → `Note` change le sens de la propriété sur les instances existantes du fichier. Les frames
nominaux `Étagères · Light` / `Dark` portent encore la valeur « Nouvelle étagère », qui n'existe plus dans le code —
à reprendre en passe de design.

## Corrections à apporter à ce document (constats de cette passe)

La doc était en retard sur trois points, vérifiés dans le fichier :

| Écrit plus haut | Réalité au 2026-08-28 |
|---|---|
| `Shelf Create Card` — « le composant Figma porte encore l'ancien nom » | Il s'appelle **`Shelf Empty Card`** depuis une passe antérieure. Le « + » avait bien déjà disparu. |
| `Icon` (`21:60`) — 18 variantes | **20** : `magic` et `undo` se sont ajoutées sans être documentées. |
| `Chrome / Nav Bar` (`26:162`) — 3 styles | **4** : `Inline + Back + Text action`, plus la propriété `Action label#102:6`. |

Compte à jour : **30 composants** sur `Screens · Components` (+`Empty State`), 3 sur `Components`.

## Ce qui n'est pas maquetté

| Absent | Raison |
|---|---|
| **D · Sync en cours** (inventaire) et **G · Sync en cours** (listes) | `Syncing Placeholder` (`32:174`) existe déjà ; seuls les frames manquent. Écartés à la sélection. |
| **F · Recherche de liste sans résultat** | Rend exactement le frame « E · Tel quel » : le même écran blanc. |
| **I · Liste introuvable** (`ContentUnavailableView`) et **J · type `publisher`** | Hors sélection. Les deux réutilisent la clé `list.empty` — voir D53. |
| **Détail étagère vide** (`ShelfDetailView:53`) | Adjacent, hors périmètre demandé. Son libellé « Cette étagère est vide » est un littéral français non localisé (D20). |

## Divergences relevées dans le code — passe états vides

| # | Où | Constat | Statut |
|---|---|---|---|
| D50 | `InventoryListContent.swift:79` vs `EntityListDetail.swift:89` | Deux états vides de la même app rendus autrement : l'un en `action200` + `.secondary`, l'autre en `content300` + couleur de label héritée. Ni la graisse, ni la couleur, ni l'alignement ne se répondent | ouverte — l'axe `Tone` d'`Empty State` reproduit l'écart au lieu de le masquer |
| D51 | `ShelfEmptyStateErrand.noteText` | Le code imprime une case **« ☐ »** en tête de seconde ligne (`"Todo\n☐ Scanner mes livres"`). La maquette ne la rend pas : Alegreya n'a pas U+2610, et un tofu dans une note manuscrite se verrait plus que son absence | ouverte côté Figma — écart assumé. Côté code, vérifier ce que l'appareil rend réellement |
| D52 | `ShelvesView.swift:41-48` | Le commentaire annonce que le bouton de tri n'apparaît qu'« une fois l'inventaire synchronisé, car trier une bibliothèque vide ne trie rien » — mais la garde ne teste que `lastInventorySync != nil`, jamais le **nombre** de livres. Avec zéro livre le bouton s'affiche quand même, et ouvre une surface qui n'a rien à ranger. Le commentaire décrit une intention que le code n'applique pas | ouverte |
| D53 | `Lists/EntityListDetail.swift:37`, `:56`, `:89`, `:173` | La clé **`list.empty`** (« Cette liste est vide ») sert **trois sens différents** : la liste est vide, la liste est **introuvable** (`ContentUnavailableView` ligne 54), et le type `publisher` n'est **pas implémenté** (ligne 37, qui rend ce texte quel que soit le contenu). Une liste d'éditeurs pleine affiche donc « Cette liste est vide » | ouverte |
| D54 | `Lists/EntityListView.swift:41` | L'onglet Listes n'a **aucun état vide** : sans liste, la `List` ne rend aucun rang et rien ne la remplace — un écran gris, sans phrase et sans issue, à l'endroit exact où l'utilisateur arrive la première fois. Le « + » de la barre de navigation est la seule sortie, et rien ne l'indique. Même écran pour une recherche sans résultat | **fermée pour « aucune liste »** le 2026-09-26 (feature 0022, frame `462:12186`) · ouverte pour la recherche sans résultat |
| D55 | `Inventory/InventoryListContent.swift:65-83` | Deux défauts dans la même branche. **(a)** Le message « Oh, c'est vide ici » décrit un inventaire vide, alors que la branche sert aussi — et surtout — la **recherche sans résultat** : un utilisateur qui a 300 livres et cherche « Vercors » lit qu'il n'a rien. **(b)** `emptyView` est un `VStack` sans `frame(maxWidth:maxHeight:)` : le texte se pose en haut à gauche du premier rang de la `List`, pas au centre de l'écran — donc il se lit comme un résultat plutôt que comme une absence | ouverte |
| D56 | `Localizable.xcstrings`, clé `inventory.empty` | La valeur `fr` finit par une **espace** : `"Oh, c'est vide ici "`. (`search.remote.empty` a le même défaut : `"Pas de résultat "`) | ouverte |
| D35 | `Section Header` (`28:164`) | Le composant n'avait ni action ni variante pour en porter une, alors que l'en-tête « Étagères » a gagné un bouton **Ajouter** tinté à l'issue 0010 | **résolue** — `Action label` + `Show action` ajoutés, métriques et cible de ~31pt documentées dans la description |

## Nœuds à trier sur la page `Screens` (hors section)

Repérés en inventoriant la page, laissés en place — **à trancher par l'owner** :

| Nœud | id | Constat |
|---|---|---|
| `Étagères · Empty` | `70:2460` | Brouillon de l'état B, hors section. C'est lui qui a servi de source aux clones de cette passe. Doublonne maintenant `210:6233`. |
| `Étagères · Light` | `52:1983`, `70:2635` | Deux copies du frame nominal `39:2`, hors section, à `y = -74`. |
| `image 2` | `170:7722` | `RECTANGLE` nu de 392 × 852 posé sur la page, sur la rangée « Recherche ». |

## Ce que la construction a appris

- **`resetOverrides()` efface aussi le nom du nœud.** Une instance créée puis renommée puis « nettoyée » repart sous
  le nom de sa variante (`Glyph=list.bullet`), et le câblage des propriétés par nom échoue en silence — la propriété
  se crée, la référence ne se pose pas. Renommer **après** le reset.
- **Une propriété de texte n'a qu'un défaut, et il écrase les variantes.** Les deux variantes `Row` avaient reçu
  chacune leur libellé avant la combinaison ; l'ajout de `Title` les a toutes ramenées au même. C'est le rappel
  déjà écrit dans `factorisation.md`, constaté ici à la capture.
- **`findAncestor` n'existe pas sur les nœuds de cet environnement.** L'audit de factorisation publié plus haut
  l'utilise (`n.parent.findAncestor?.(…)`) et ne lève rien grâce à l'optional chaining — il compte donc **tous** les
  nœuds de dessin, instances comprises, et ne peut pas rendre 0. Remonter les parents à la main :

  ```js
  function insideInstance(n, stop) {
    let p = n.parent;
    while (p && p.id !== stop.id) { if (p.type === 'INSTANCE') return true; p = p.parent; }
    return false;
  }
  ```

- **Le canal `use_figma` casse au-delà d'environ 19 ko de réponse**, et l'erreur remonte comme un JSON tronqué
  (`Invalid JSON: EOF while parsing a string`), pas comme un dépassement. Lire un composant lourd — `Shelf Empty
  Card` et ses images — demande de ne renvoyer que des identifiants et des noms, jamais `characters`.
- **Un état vide « fidèle au code » est un livrable en soi.** Le frame `212:6707` est un écran gris et c'est tout
  son intérêt : mis à côté de sa proposition, il rend une absence discutable. Sans lui, D54 resterait une phrase.

---

# Accueil & compte — proposition (passe du 2026-08-28)

Section `Accueil & compte` (`222:7167`) sur la page `Screens`. **Exploration, pas une réplication** : aucun de ces
écrans n'existe en Swift, sauf `Se connecter` qui remaquette `Authentication/View/LoginView.swift` au design system.

Le besoin : dire à quoi sert l'app avant la connexion — inventorier et ranger, garder trace des prêts, emprunter à ses
connaissances — et offrir connexion **et** inscription, sachant que beaucoup d'utilisateurs ont déjà un compte
inventaire.io.

## Le nom

Les maquettes portent **« Ex-libris »**, retenu le 2026-08-28 parmi Ex-libris · Passe-livre · Rayon · Étagère.

« Étagère » a été écarté pour une raison qui n'est pas esthétique : **le mot est déjà un nom commun du produit**.
L'utilisateur crée des étagères ; nommer l'app pareil rend ambiguë chaque phrase de l'interface, de la doc et du
support. S'y ajoutent l'accent (recherche App Store, claviers non français) et le fait que le mot ne dit rien des deux
tiers de la promesse — prêter et emprunter.

Le nom est une **propriété de texte** sur `Onboarding / Brand`, précisément parce qu'il n'est pas arrêté : le changer
est une édition, pas une reprise.

## Table des écrans

| Écran | Clair | Sombre | Autre état | Source Swift |
|---|---|---|---|---|
| **Accueil** | `222:7168` | `222:7226` | — | *aucune* — l'écran n'existe pas |
| **Se connecter** | `224:7232` | `224:7275` | Erreur : `224:7318` | `Authentication/View/LoginView.swift` |
| **Créer un compte** | `224:7363` | `224:7408` | — | *aucune* — l'inscription part vers le web |
| **Mot de passe oublié** | `234:7382` | `234:7417` | Confirmation : `234:7452` / `234:7493` | `Authentication/View/ForgotPasswordView.swift` + `PasswordResetSentView.swift` |
| **Spec** | `226:7383` | | | |

La confirmation de réinitialisation lit « **si** un compte existe pour cette adresse, un e-mail vient de
partir ». Jamais « e-mail envoyé », jamais « adresse inconnue » : distinguer les deux cas ferait de
l'écran un oracle répondant « ce compte existe » à qui teste une liste d'adresses. Le serveur ne devrait
pas les distinguer non plus, mais la maquette n'en dépend pas — la formulation prudente est écrite côté
client quoi qu'il réponde.

Audit de factorisation : **7 frames, 0 dessin brut**, aucun `▢` — que des instances.

## Composants ajoutés — `Screens · Components`

| Composant | node id | Variantes | Propriétés |
|---|---|---|---|
| `Onboarding / Brand` | `222:258` | — | `Name#222:0`, `Tagline#222:1` |
| `Onboarding / Value Row` | `221:260` | — | `Glyph#221:0` (INSTANCE_SWAP), `Title#221:1`, `Body#221:2` |
| `Field` | `221:271` | Type ∈ {Text, Secure} | `Label#221:3`, `Value#221:6` |

`Field` reproduit `LoginView`'s `.withLabel(label:)` sur `background/secondary`, rayon 12. `Type=Secure` ne diffère
que par la valeur affichée : c'est un axe de **contenu**, gardé en variante parce que le code emploie deux types de vue
distincts (`TextField` / `SecureField`).

## Composant renommé et étendu

| Avant | Après | Pourquoi |
|---|---|---|
| `AutoSort / Note` | **`Note`** (`101:236`) | Les écrans de compte le consomment aussi. Un composant que deux features importent ne peut pas garder le nom de l'une d'elles — le même raisonnement que `ShelfSectionHeader` sortant de `Features/Shelves/`. |

`Note` gagne **`Tone=Error`** (2 variantes de plus, 6 au total) : `LoginView.swift:43-49` affiche un message d'échec
en `foregroundError` et rien dans le fichier ne le portait.

Compte à jour : **34 composants** sur `Screens · Components`, 3 sur `Components`.

## Décisions, et leur revers

- **« Se connecter » est primaire, « Créer un compte » secondaire.** Parce que la plupart des utilisateurs ont déjà un
  compte inventaire.io. Le revers est réel : le nouvel arrivant — celui qui vient d'installer l'app — trouve son
  action en second, et le bouton secondaire de ce design system se lit comme un lien.
- **Un seul écran plutôt que trois slides.** Les trois usages sont une seule idée, et trois balayages avant un
  formulaire de connexion se paient pour rien. Le revers : moins de place pour illustrer chaque usage.
- **Pas d'illustration sur l'accueil.** Les trois glyphes en tiennent lieu. La planche est réservée à la séquence
  post-connexion, qui la remplit avec les vrais livres de l'utilisateur — la promesse tenue plutôt qu'annoncée.
- **La mention inventaire.io est répétée sur les trois écrans.** Le compte n'appartient pas à cette app ; le découvrir
  après coup serait pire que le lire trois fois.

## À trancher avant de coder

1. **L'inscription native n'existe pas.** `LoginView.swift:108` envoie vers `inventaire.io/signup` par `openURL`. Le
   frame « Créer un compte » suppose un formulaire **dans** l'app : à valider contre l'API avant implémentation.
   Repli si l'endpoint ne convient pas : garder le renvoi web, et l'écran devient une explication plus un bouton
   sortant. Ne pas partir du frame comme d'un acquis.
2. ~~**Mot de passe oublié** : aucun écran, renvoi web assumé.~~ **Faux, corrigé le 2026-08-28** :
   `POST /auth/reset-password { email }` est public et documenté. Deux frames ajoutés, plus leur
   confirmation. Le renvoi web n'avait aucune justification.
3. **Le renommage touche le catalogue**, pas seulement l'icône : « RECITs » est en dur dans `onboarding.tally.body`.
4. **Trois écrans d'affilée pour un nouvel arrivant** — accueil → création de compte → `C1 · Bienvenue`. À arbitrer :
   fondre C1 dans l'accueil, ou ne garder C1 que pour un inventaire vide constaté après connexion. En l'état les deux
   séquences se suivent sans se connaître.
5. **La langue source du catalogue est l'anglais.** Ces copies veulent leur version EN avant d'entrer au catalogue,
   sinon elles reproduisent D20 et D37.

## Ce que la construction a appris

- **`clone()` d'une variante perd `componentPropertyReferences`.** Les deux variantes `Tone=Error` clonées depuis
  `Tone=Default` ont gardé leur texte littéral et perdu le lien vers `Body#101:0` : la propriété existait, l'instance
  l'affichait bien dans son panneau, et le texte ne bougeait pas. Le symptôme est un écran d'erreur qui annonce
  « 2 étagères ont été créées et remplies ». **Reposer la référence après tout `clone()` de variante**, et vérifier
  au rendu — le panneau de propriétés ne montre pas l'absence de lien.
- Corollaire du piège déjà connu sur `resetOverrides()` : les deux effacements silencieux de cette famille
  (le **nom** du nœud pour `resetOverrides`, la **référence de propriété** pour `clone`) ne lèvent aucune erreur et ne
  se voient qu'à la capture.

## Divergences relevées en implémentant le PRD 0010 (2026-08-28)

Suite des tables précédentes. Toutes trouvées en écrivant le code ou en le faisant tourner, pas en
relisant.

| # | Où | Constat | Statut |
|---|---|---|---|
| D57 | `AppModels/Shelf/ShelfModel.swift` | La forme `?action=` **dépréciée côté serveur** survit à huit points d'appel (`create`, `by-owners`, `by-ids`, `add-items`…). L'authentification en est sortie (issue 0056) ; l'API des étagères non. Le critère « plus aucun `?action=` dans le code » de l'issue 0056 n'était donc pas tenable, et a été restreint à l'authentification | ouverte — même travail à refaire pour les étagères |
| D58 | `Components/WithLabel.swift` vs la maquette | `withLabel(label:)` dessine son libellé en **`caption200`** ; la maquette des champs de compte demande **`footnote200`**. `AuthField` écrit donc son propre libellé plutôt que de restyler les six autres formulaires qui consomment ce modificateur | ouverte — à trancher : aligner la maquette sur `caption200`, ou faire porter le style au modificateur |
| D59 | `inventaire.io` — `cookie-session` global | **Le plus grave de la passe.** `GET /auth/username-availability` répond `200` **et** `Set-Cookie: inventaire:session` — une session **anonyme**, sous les deux noms exacts qu'`AuthService` lit pour décider si quelqu'un est connecté. Constaté sur appareil : taper trois lettres dans le champ nom d'utilisateur, relancer, et l'app ouvrait sur les onglets d'un compte inexistant. La cause est côté serveur — `server/middlewares/middlewares.ts` applique `cookie-session` globalement — donc **tout appel public d'authentification doit poser `httpShouldHandleCookies = false` et ne pas appeler `absorbCookies`** ; seuls `login` et `signUp` absorbent | contournée côté app, tenue par deux tests · **ouverte côté serveur**, à signaler à inventaire.io |
| D60 | `inventaire.io` — `reset_password.ts` | Le serveur **est un oracle** : un compte introuvable donne `400 "email not found"`, avec l'adresse recopiée dans le corps. N'importe qui peut donc tester une liste d'adresses. L'app le neutralise en écrasant toutes les réponses sauf l'échec de transport sur une seule confirmation (`PasswordResetOutcome`) — cette collapse porte seule la protection | contournée côté app · **ouverte côté serveur**, à signaler |
| D61 | `Model/SearchResult/SearchResult.swift` | `Hashable` était **synthétisé** au-dessus d'un `@Model` SwiftData, dont la conformité n'est visible depuis un autre fichier que si les deux tombent dans le même lot d'une compilation en batch mode. Ajouter n'importe quel fichier ailleurs dans la cible repartitionnait les lots et cassait le build dans un fichier que personne n'avait touché | résolue — les deux témoins sont écrits à la main, sémantique de synthèse préservée |
| D62 | `DesignSystem/Tokens/TextStyle.swift` | La `UIFont` est construite via `UIFontMetrics` **à la construction**, donc le texte en police personnalisée ne se remet pas à l'échelle sur un changement **vif** de taille de contenu : il ne prend la nouvelle taille qu'au relancement. Concerne toutes les vues de l'app à égalité | ouverte — antérieure à cette passe, relevée en vérifiant les tailles d'accessibilité |
| D63 | `Localizable.xcstrings`, `Assets.xcassets` | Orphelins après la réécriture de l'écran de connexion : la clé `login.title` et les jeux d'images `mainLogo` et `inventaireIo` ne sont référencés par aucun fichier Swift | ouverte — suppression à faire dans la passe de nettoyage des chaînes |

Rappel : D51 (la case « ☐ » de la note d'étagère) et D52 (le bouton de tri au-dessus d'une bibliothèque
vide) restent ouvertes côté code, sans rapport avec cette feature.

---

# Recherche unifiée — proposition (passe du 2026-09-11)

Une seule recherche, dans l'onglet Inventaire, en trois temps — le modèle de **Mail sur iOS**. Elle remplace le champ
de l'inventaire (`ShelvesView.searchable`) **et** l'onglet Recherche (`MainSearchView` → `SearchView`), qui disparaît.

Section `Recherche unifiée` (`334:8624`) sur la page `Screens`, à droite de `Astuces · TipKit`. **10 frames** de
393 × 852 (cinq écrans × clair / sombre, mode épinglé) + 1 panneau.

## Table des écrans

| Écran | Clair | Sombre | Ce qu'il montre |
|---|---|---|---|
| **R1 · Repos** | `334:8625` | `334:8773` | L'inventaire tel quel, champ `State=Idle`. Cloné des frames `Étagères`, **onglet Recherche caché** |
| **R2 · Focus** | `336:8840` | `336:8956` | Temps 1 : le champ monte en haut (la grande nav se replie), les 3 dernières recherches. Rien d'autre |
| **R2b · Aucune récente** | `365:10364` | `365:10450` | Premier lancement, ou après « Effacer » : `Empty State` centré entre le champ et le clavier |
| **R3 · Trois caractères** | `338:9018` | `338:9182` | Temps 2 : local (mes livres + ceux de mes amis) plafonné à 3, puis 3 suggestions inventaire.io |
| **R4 · Résultats** | `339:9250` | `339:9361` | Temps 3 : après envoi, les résultats complets groupés par type |
| Panneau | `340:9412` | — | `Spec · Recherche unifiée`, au format des sept autres |

## Composants ajoutés — `Screens · Components`

| Composant | node id | Variantes | Propriétés |
|---|---|---|---|
| `Search / Query Row` | `331:255` | — | `Glyph#331:0` (INSTANCE_SWAP), `Label#331:1` |
| `Search / Scope Card` | `333:274` | `State ∈ {Default, Selected}` | `Glyph#333:8`, `Title#333:9`, `Count#333:10`, `Show count#333:11` — **parqué, zéro instance** |

`Search / Query Row` sert les **deux** listes du temps 2 : une recherche récente (glyphe `clock`, libellé nu) et une
suggestion inventaire.io (glyphe `book` / `feather` / `magnifyingglass`, requête en gras posée à la main sur
l'instance). C'est la même rangée, pas deux composants — 393 × 47, `spacing/medium` de retrait, `spacing/s-medium`
de gouttière.

`Search / Scope Card` : 156 × 124 à l'écran (dessiné à 168, les instances étaient réduites), `radius/rounded`,
bord `sizing/border/hairline`, `Show count` éteint quand le compte n'est pas connu. **Le carrousel a été retiré de
R2 le jour même** : la portée est un point d'entrée, pas un filtre, et le temps 1 se réduit aux récentes. Le
composant reste dans la bibliothèque sans aucune instance — sa description le dit, pour qu'il ne se lise pas comme
un oubli d'audit.

## Composants étendus

| Composant | Ce qui change | Pourquoi c'est sans risque |
|---|---|---|
| `Icon` (`21:60`) | **22 variantes** : `feather` (`330:258`, l'auteur·ice) et `xmark.circle` (`330:264`, effacer la saisie) | Ajout de variantes, les 20 autres intactes. La grille a été recalée sur 64 pt au passage — `magic` était à y=195 |
| `Chrome / Search Field` (`27:172`) | **6 variantes** : troisième état `State=Typed` en clair (`334:264`) et sombre (`334:277`) — texte en encre, `xmark.circle` dans le champ | `Idle` et `Active` ne bougent pas. Le placeholder des six variantes passe en **une ligne, troncature `ENDING`**, comme iOS |
| `Cell / Book` (`29:154`) | Propriété `Show tag#338:0`, **allumée par défaut** | Les 16 frames existants sont inchangés ; seuls les résultats de recherche l'éteignent |

Compteurs après la passe : **35 composants** sur `Screens · Components`, `Icon` à 22 variantes,
`Chrome / Search Field` à 6.

## Décisions de design, et leur revers

| Décision | Revers |
|---|---|
| Les récentes et les suggestions partagent **une** rangée | Le jour où une suggestion veut un chevron ou un compte, il faudra une variante — pas un second composant |
| **Pas de carrousel de portées** au temps 1 : le champ, les récentes, rien de plus | Le temps 1 ne dit plus où l'on cherche, et n'a plus rien à montrer quand aucune recherche n'a encore été faite (état non dessiné) |
| « Effacer » vit dans l'en-tête de section, pas sur chaque rangée | Pas de suppression unitaire : « Effacer » vide **tout** le stock et ramène à `R2b`. Assumé pour l'instant |
| Les libellés parlent à la **première personne** (« Mes livres », « Chez mes amis ») | Contourne la seule chaîne tutoyante du catalogue (`search.friends_inventory`) au lieu de la corriger — voir D-R4 |
| L'onglet Recherche est caché en **surcharge d'instance** | `Chrome / Tab Bar` garde sa variante `Active=Recherche`, désormais morte. Une version à 3 onglets reste à faire |

## Tranché le 2026-09-11

| Question | Réponse | Ce qui en découle |
|---|---|---|
| La portée : point d'entrée ou filtre persistant ? | **Point d'entrée** | Aucun rappel de portée sur R3/R4, pas de segmenté à la Mail. La maquette est complète telle quelle |
| « Sur inventaire.io » en carte double-t-elle les suggestions ? | **Sans objet** | Le carrousel sort de R2, la question tombe avec lui |
| Le seuil : 2 ou 3 caractères ? | **3**, comme le code | Rien à changer dans `SearchView.isRemoteSectionVisible`. La maquette s'aligne : R3 s'appelle désormais « Trois caractères ». **D-R2 close** |
| Où vivent les récentes ? | **Local seulement**, jamais remontées avec le compte | Écrites **à l'envoi** : touche « rechercher » du clavier, ou tap sur une suggestion. Une requête tapée puis abandonnée ne laisse aucune trace |
| Où va le scan ? | **Il reste où il est**, dans l'écran d'inventaire | Rien à déplacer, rien à maquetter |
| Combien de récentes sont stockées ? | **Toutes** | Trois sont affichées, le stock n'est pas plafonné. La suppression unitaire est remise à plus tard ; « Effacer » vide tout |
| Que fait « Annuler » ? | **Referme le mode recherche** | Retour à `R1`, requête perdue. Ce n'est pas le bouton qui vide le champ — c'est le `xmark.circle` dans le champ qui fait ça |
| Les récentes vides ? | **Un état vide**, à la manière d'Apple Music | `R2b` : `Empty State` (`204:263`) `Layout=Centered`, glyphe `magnifyingglass` 40, `Show action` éteint, bloc de 177 posé à `y=225` — centré entre le bas du champ (111) et le haut du clavier (516). Aucun composant nouveau |
| Où mène « Tout voir » ? | **Un écran poussé dédié** (tranché par le propriétaire, issue 0075) | « Dans mes livres et chez mes amis » : tous les résultats locaux de la requête, dans l'ordre de la section plafonnée. C'est l'option cohérente avec les résultats distants — un tap pour entrer, un pour revenir, le champ et ses suggestions toujours là. L'option « inventaire déjà filtré » perdait les suggestions et les livres des amis ; l'option « déplier sur place » repoussait la route vers inventaire.io sous le clavier, ce que le plafond de trois existe précisément pour éviter. Coût, anticipé : un cas de `NavigationDestination` (`localSearchResults(query:)`) et une passe Figma |

## Reste à trancher — recherche unifiée

Plus rien à trancher : le dernier point ouvert de la passe (« Tout voir ») l'a été le 2026-09-11, ci-dessus.

## Passes Figma dues — recherche unifiée (au 2026-09-11)

1. **La tab bar.** ~~La variante à trois onglets~~ — **dépassée le 2026-10-21** : l'onglet Recherche, supprimé à
   l'issue 0074, est revenu avec la feature 0037, sous le rôle système `.search`. Ce qui est dû maintenant est une
   barre Inventaire / Listes / Réseau / Réglages **plus une pastille loupe détachée** au bout, et sa forme repliée
   quand Recherche est actif (un bouton pour les autres onglets, le champ à côté). Voir D-R6.
2. **L'écran « Tout voir ».** La section `Recherche unifiée` (`334:8624`) n'a pas de frame pour lui. Il en faut une :
   barre de navigation avec retour et titre en ligne « Dans mes livres et chez mes amis », liste simple de rangées
   `Cell / Inventory` (l'exemplaire d'un ami nommant son propriétaire), plus la variante d'en-tête de section portant
   l'action « Tout voir » en fin de ligne — affichée seulement au-delà de trois résultats. Clair et sombre.

## Ce qui n'est pas maquetté — recherche unifiée

| Absent | Raison |
|---|---|
| Le clavier | Rien dans ce fichier ne le reproduit. Sur R2/R2b/R3/R4 il mange tout sous ~516 pt : le tiers bas n'est vide **que** sur la maquette |
| Chargement, **aucun résultat pour une requête**, erreur réseau | **Résolu dans le code le 2026-09-11 (issue 0076)** — trois états tenus à part par `RemoteSearchState.sign`, qui n'en rend jamais qu'un : chargement = `SyncingInlineRow` (`inventory.search.loading`), aucun résultat = `EmptyStateView` (proposition C), échec = `EmptyStateView` avec « Réessayer », la section locale restant affichée au-dessus. `R2b` ne traite toujours que les récentes **vides** : les deux copies sont distinctes et aucune ne sert pour l'autre. **Reste dû côté Figma** : des frames pour le chargement et pour l'échec, clair et sombre |
| La tab bar à 3 onglets | Surcharge d'instance ici, variante à créer quand ça se code |

## Divergences relevées dans le code — passe recherche unifiée

| # | Où | Constat | Statut |
|---|---|---|---|
| D-R6 | `Features/MainNavigation/MainTabView.swift` — `TabConfig.search` | Depuis la feature 0037 (2026-10-21), la recherche est un onglet à rôle `.search` qu'iOS 26 pose **à part**, en pastille, au bout de la barre ; actif, il replie les autres onglets en un bouton et met le champ en bas. `Chrome / Tab Bar` (`25:234`) a encore `Active ∈ {Inventaire, Listes, Réglages, Recherche}` : ni Réseau, ni pastille détachée, ni forme repliée. Le carrousel « Chez mes amis » (cellules `SortBookCardView`) et son invitation n'ont pas de frame non plus. Depuis la feature 0040, sous iOS 27, l'onglet reste dans la barre avec les autres et le champ est épinglé sous le titre (`.navigationBarDrawer(displayMode: .always)`, titre en ligne) ; aucune frame iOS 27 | ouverte — le code fait foi |
| D-R7 | `Features/MainNavigation/MainTabView.swift`, `Features/Profile/ProfileToolbarItem.swift` | Depuis la feature 0038 (2026-10-21), le Profil n'est plus un onglet : un bouton rond en haut à gauche d'Inventaire, Listes et Réseau (l'icône `person` dans le verre de la barre, ou la photo du compte en cercle de 44 pt) l'ouvre en sheet, avec « Fermer ». `Chrome / Tab Bar` a encore un onglet Profil / Réglages, et aucun écran ne porte l'avatar | ouverte — le code fait foi |
| D-R8 | `DesignSystem/Tokens/Color.swift`, `DesignSystem/List/View+applyBackground.swift` | Depuis la feature 0039 (2026-10-21), deux tokens existent dans le code et pas dans la collection `Color` : `background/grouped` (`gray/50` / `gray/1000`), sous la liste racine de Listes, Réseau et Recherche et, depuis la feature 0040, sous le détail d'une liste, et `background/grouped-elevated` (`gray/50` / `gray/900`), sous la liste du Profil en sheet. En sombre, les maquettes de ces écrans sont encore sur `background/secondary` (`gray/800`). Recherche est passée de liste *plain* à *inset grouped* dans toutes ses phases, et la carte « café » du Profil s'aligne sur les cellules (plus d'inset latéral de 8 pt) | ouverte — le code fait foi ; variables non créées, le plugin Figma n'étant pas authentifié dans la session |
| D-R9 | `Features/Components/SectionLoadingIndicator.swift`, `AuthorDetailView.swift`, `WorkEditionPicker.swift` | Depuis la feature 0059 (2026-10-29), « Œuvres de … » et « Éditions de … » portent, tant que l'écran redemande ses données à inventaire.io, un petit `ProgressView` (`controlSize(.small)`, teinte `foreground/secondary`) juste après le libellé. `Section Header` (`28:164`) n'a ni slot ni variante pour un indicateur de chargement | ouverte — le code fait foi |
| D-R1 | ~~`AppModels/Search/SearchModel.swift:20`~~ | `searchLocalInventory(query:modelContext:)` n'est **appelé par personne**. Le temps 2 de cette maquette est exactement son emploi | **résolue** le 2026-09-11 (issue 0074) — supprimée plutôt que ressuscitée : la section locale lit les `@Query` de l'inventaire via `InventorySearchRanking`, une seconde requête aurait cassé la réactivité qu'ADR 0001 demande |
| D-R2 | `Features/Search/SearchView.swift:34` | Le seuil distant est à **3** caractères ; la maquette proposait 2 | **close** le 2026-09-11 — le code fait foi, la maquette passe à 3 |
| D-R3 | ~~`Features/Search/SearchView.swift:67-72`~~ | Doublon de **D19** (chaîne non localisée + `HStack(spacing: 12)` littéral) | **résolue** le 2026-09-11 (issue 0074) — voir D19 |
| D-R4 | ~~`Localizable.xcstrings` — `search.friends_inventory`~~ | « Dans l'inventaire de **tes** amis » est le seul tutoiement du catalogue | **résolue** le 2026-09-11 (issue 0074) — voir D21 : la clé n'existe plus |
| D-R5 | ~~`Features/Search/SearchView.swift:101`~~ — mais aussi `EntityListDetail.swift:146,232`, `EntityAuthorsView.swift:22`, `AuthorDetailView.swift:71`, `WorkEditionPicker.swift:101`, `TransactionDetailView.swift:44`, `BookDetailView.swift:245,270` | Un `Button` qui enveloppe un `NavigationLink(value: UUID())` : le lien n'existe que pour le chevron, la navigation passe par `onNavigate` | **ouverte** — l'issue 0074 annonçait sa mort avec `SearchView`, à tort : le motif survit dans **huit** autres endroits. Deux d'entre eux (`AuthorDetailView`, `WorkEditionPicker`) sont exactement les rangées que `E2EScenarioTests.push(_:listIdentifier:driver:)` documente comme demandant deux points de visée, parce qu'un tap au centre tombe sur le lien mort. Re-cadrée sur ces fichiers le 2026-09-11 |

## Ce que la construction a appris

- **`componentPropertyReferences` s'écrase en entier.** Deux affectations successives (`{ characters }` puis
  `{ visible }`) laissent une seule référence : le texte de `Count` restait figé sur sa valeur par défaut sans
  qu'aucune erreur ne le dise. Toujours poser l'objet **complet** en une fois.
- **Une surcharge de visibilité survit à un changement de variante** — l'onglet Recherche caché est resté caché
  après le passage en `Theme=Dark` sur le clone — mais le `findOne` qui la repose, non : retrouver le nœud depuis
  l'instance de tab bar, jamais depuis la frame.
- **Éteindre `Show tag` ne raccourcit pas la cellule** : la rangée `meta` garde ses 24 pt. Il faut éteindre `meta`
  aussi, et alors la cellule hugge (118 → 90 avec sous-titre, 64 sans).
- **`resizeWithoutConstraints` sur une `SECTION`** est le seul moyen de la faire grandir : le panneau de spec fait
  1535 pt, soit plus haut que les deux rangées d'écrans réunies.
- **Cacher un nœud dans Figma ne le cache que là où on a cliqué.** Le carrousel avait été masqué sur
  `R2 · Focus · Light` (regroupé en `Group 2`, `visible = false`) et était resté visible sur le sombre. Une paire
  clair / sombre se modifie des deux côtés, ou l'un des deux ment. Les deux frames sont nettoyées — le groupe et
  les instances sont **supprimés**, pas masqués.
- **Les titres de section se répètent d'une passe à l'autre** (`## À trancher avant de coder`, `## Ce qui n'est pas
  maquetté`). Un script qui édite ce fichier par recherche de titre attrape la passe d'août, pas la sienne : les
  titres de cette passe portent leur suffixe, et toute édition se fait sur une chaîne unique.

---

# Œuvre & édition — passe du 2026-09-11

Réplication des deux écrans que l'[ADR 0002](../adr/0002-unified-book-detail.md) a laissés derrière lui : le détail
d'une **œuvre**, devenu une passerelle vers les éditions, et le détail d'une **édition**, qui a absorbé « mon
exemplaire ». Section `Œuvre & édition` (`351:9412`) sur la page `Screens`. **Clair seul** — tout est bâti sur les
tokens, le sombre suit sans redessin, comme à la passe `Astuces · TipKit`.

Ce que l'ADR a changé, et que le fichier ne montrait pas :

| Avant | Après |
|---|---|
| `WorkDetailView` — un écran d'œuvre | `WorkEditionGatewayView` — une **passerelle** : une seule édition → la fiche livre rendue en ligne, plusieurs → `WorkEditionPicker` |
| `EditionDetailView` + `InventoryItemDetailView` | `BookDetailView` seul, ancré sur une `Edition`, « Dans mon inventaire » plié dedans |

## Table des écrans

| Écran | Clair | Source Swift |
|---|---|---|
| **Œuvre · Choix de l'édition** | `351:9413` | `EntityBrowser/Work/WorkEditionPicker.swift` (via `WorkEditionGatewayView.swift`) |
| **Édition · Je ne possède pas** | `352:9493` | `Book/BookDetailView.swift` |
| **Édition · Je possède** (défilée) | `353:9571` | idem + `Book/BookMyCopySection.swift` |
| **Menu · Je ne possède pas** | `353:9828` | `BookDetailView.menuContent`, branche « pas à moi » |
| **Menu · Je possède** | `353:9964` | `BookDetailView.menuContent`, branche « à moi » |
| `Spec · Œuvre & édition` | `354:9973` | — |

**L'œuvre à une seule édition n'a pas de frame** : la passerelle rend `BookDetailView` en ligne, donc cet écran
n'existe pas dans ce cas. C'est le comportement, pas un oubli.

Les frames `Fiche livre` (`42:1125` / `42:1219`) du 2026-08-18 restent en place et gardent leur nom : elles
répliquent l'ancien `EditionDetailView`, d'avant les genres (issue 0035), « Autres éditions » et « Dans mon
inventaire ». Les lire comme un état antérieur, pas comme la fiche courante.

## Composants ajoutés — `Screens · Components`

| Composant | node id | Variantes | Propriétés | Source Swift |
|---|---|---|---|---|
| `Cell / Owner Item` | `348:278` | — | `Username`, `Since`, `Details`, `Show details` | `Inventory/InventoryItemDetail/UserItemCellView.swift` |
| `Row / Transaction Picker` | `348:292` | — | `Date`, `Value` | `Book/BookMyCopySection.swift` |
| `Chrome / Menu Row` | `349:303` | Theme ∈ {Light, Dark} | `Label`, `Glyph` (INSTANCE_SWAP), `Show chevron` | le `Menu { … }` de la barre |
| `Chrome / Menu Panel` | `350:363` | Theme ∈ {Light, Dark} | `Show row 2`, `Show row 3` | idem |
| `Chrome / Menu Scrim` | `350:366` | Theme ∈ {Light, Dark} | — | le voile posé par iOS derrière un menu ouvert |

`Cell / Owner Item` remplace l'usage que `Fiche livre` faisait de `Cell / User` : la vraie rangée de communauté porte
« Depuis le … » et la pastille de transaction, que `Cell / User` n'a pas.

## Composants étendus

`Row / Summary` (`38:201`) gagne `Label#347:0` (TEXT) et `Show meta#347:1` (BOOLEAN). Le libellé était figé sur
« Résumé » alors que c'est le même `withLabel(label:)` côté Swift : la même rangée sert donc « Ce que j'en pense »
dans « Dans mon inventaire ». `Show meta` éteint la ligne de pastilles, absente du picker d'édition.

`Icon` (`21:60`) passe à **25 variantes** : `trash` (`346:278`), `list.clipboard` (`346:285`) et
`chevron.up.chevron.down` (`346:292`) — vecteurs au trait 1,8 bindés à `foreground/default`, contraintes `SCALE`,
comme les 22 précédents.

## Recette de composition

- **Un écran défilé se fait avec un conteneur `scroll`, pas avec des `y` négatifs.** Le chrome de ce fichier est
  transparent (`Chrome / Status Bar` est « 393 × 59, sans fond ») : un contenu remonté par coordonnées se met à
  peindre par-dessus l'heure et la batterie. Un frame `scroll` à `y = 103`, haut de 666, `clipsContent = true`,
  écrête proprement — et reste un conteneur de mise en page, donc l'audit de factorisation le tolère.
- **Un menu contextuel** = `Chrome / Menu Scrim` plein écran + `Chrome / Menu Panel` à 12 du bord droit et 8 sous la
  barre. Ordre des enfants : contenu · tab bar · voile · **nav** · status bar · home indicator · panneau. La barre de
  navigation passe **au-dessus** du voile pour que le « … » qui a ouvert le menu reste net et l'ancre ; la tab bar,
  elle, se laisse assombrir.
- Le panneau applique le **patron des slots** : les rangs 2 et 3 sont enveloppés dans un groupe qui porte son filet
  **en tête**, si bien qu'un rang éteint emporte son séparateur.

## Ce qui n'est pas maquetté

| Absent | Pourquoi |
|---|---|
| `.loadingWork`, `.loadingEditions`, `.loading` | Des `ProgressView` — le fichier ne maquette pas les contrôles vivants |
| `.error`, `.noResult` (« Cette édition n'existe pas sur inventaire.io ») | Le code n'y met qu'un `Text` brut sans habillage : il n'y a rien à répliquer, seulement à proposer |
| La confirmation de suppression | `confirmationDialog` iOS, chrome système |
| Les sous-menus dépliés (`Étagère`, `Liste`, `Emprunter à`) | Le chevron dit qu'il y en a un ; les ouvrir demanderait une frame par sous-menu |
| La feuille `TransactionFormView` | Hors périmètre, comme les autres feuilles |
| Les glyphes de transaction | `lending`, `giving`, `selling`, `inventorying` sont des **SVG du dépôt**, pas des SF Symbols, et sont remplis noir/blanc là où tout `Icon` est au trait bindé. Les pastilles sont donc posées `Show glyph=false`, et le picker n'en porte pas |
| `books.vertical.fill` | Toujours absent du jeu, comme à la passe TipKit → `Icon/book` |
| Le placeholder « Écrire un commentaire » | La note est montrée remplie ; le champ vide demanderait `foreground/placeholder` en override d'instance |

## Divergences relevées dans le code — passe œuvre & édition

Suite des tables précédentes. **Statut « ouverte » = rien n'a été changé côté code.**

| # | Où | Constat | Statut |
|---|---|---|---|
| D64 | `Book/BookViewModel.swift` + `Book/BookDetailView.swift` | `ownedItemsPredicate` se présente comme « le prédicat du `@Query` de la vue », et l'ADR 0002 promet un `myItems: [InventoryItem]` sourcé réactivement. **La vue ne l'appelle jamais** : elle lit `edition.items` dans `iOwn(_:)`. Le prédicat n'est exercé que par les tests | ouverte — soit câbler le `@Query`, soit retirer le prédicat et le commentaire qui le vend |
| D65 | `Book/BookDetailView.swift`, `Book/BookViewModel.swift` | En-têtes périmés : la vue annonce un overlay « read-only here — folding in item editing (notes, transactions) is P3 » alors que P3 est livré ; le modèle dit calquer `EditionDetailView.loadEdition`, supprimé en P5 | ouverte — commentaires à réécrire |
| D66 | `EntityBrowser/EntityHeaderView.swift`, `EntityImageView.swift`, `EntityAuthorsView.swift` | Trois en-têtes ne portent pas le nom de leur fichier : `EntityHeaderView.swift` se déclare `WorkHeaderView.swift`, `EntityImageView.swift` se déclare `EntityHeaderView.swift`, `EntityAuthorsView.swift` se déclare `EditionAuthorsView.swift` | ouverte — trivial, mais c'est ce qui fait chercher un fichier qui n'existe pas |
| D67 | `EntityBrowser/Work/WorkEditionPicker.swift` | Chaque édition est empaquetée dans un `SearchResult` de `type: .works` — pour une **édition** — uniquement pour réutiliser `SearchResultCell` ; `score: 0` est inventé au passage | ouverte — extraire la cellule, ou lui donner un modèle propre |
| D68 | `WorkEditionPicker.swift`, `BookDetailView.swift` | Les deux listes enveloppent un `Button` autour d'un `NavigationLink(value: UUID())` : le lien ne sert qu'à **dessiner le chevron**, la navigation passant par `path.append`. La valeur de destination est un `UUID()` neuf à chaque rendu | ouverte — antérieure à cette passe, vue en la répliquant |

## Audit

Factorisation, sur les 5 frames : **0 dessin brut**, chaque `▢` de tête est un conteneur nommé et assumé (`scroll`,
`list group`), mode épinglé sur chacune, 22 à 41 instances par frame.

Design system : 0 variable en `ALL_SCOPES`, 0 nom de composant dupliqué, 0 texte sans style dans les composants de
cette passe. Les 5 peintures non bindées relevées sont **antérieures** — `Icon/magic` (×2), `Icon/undo`, et les
contours de sélection de deux `COMPONENT_SET` (`Livre`, `image 1`). Le fichier après la passe : 5 pages,
113 variables, 10 styles de texte, 7 styles d'effet, 46 composants.

## Ce que la construction a appris

- **Le chrome de ce fichier est transparent.** Tant que le contenu commence à `y = 103`, personne ne le voit ; dès
  qu'on simule un défilement, le texte remonte et peint sur l'heure et la batterie. Le conteneur `scroll` est la
  réponse, et il fallait le prévoir : le corriger après coup a coûté deux passes de reprise.
- **Un menu ouvert n'assombrit pas la barre qui l'a ouvert.** Poser le voile au-dessus de tout laisse le panneau
  flotter sans ancre. Remonter la seule barre de navigation au-dessus du voile suffit à rattacher le menu au « … ».
- **Une ligne de menu doit huguer en hauteur.** « Supprimer de mon inventaire » passe à deux lignes dans 250 de
  large ; figée à 44, la ligne la serrait. `counterAxisSizingMode = 'AUTO'` + padding 11 donne 45 sur une ligne et
  suit sur deux.
- `SearchResultCell.workCell` et `OtherEditionsCell` sont **la même vue écrite deux fois** — même `CellThumbnail`,
  même `content400Bold` + `content300`, mêmes écarts. Une seule instance de `Cell / Entity Type=Work` les sert
  toutes les deux ; c'est D67 vu depuis Figma.

---

# Édition · Actions mises en avant — propositions du 2026-09-11

**Exploration, pas une réplication.** Aucune de ces quatre dispositions n'existe dans le code : aujourd'hui les trois
actions vivent dans le menu « … » de `BookDetailView`. Section `Édition · Actions mises en avant` (`362:9924`) sur la
page `Screens`, clair seul.

Le besoin : les trois actions d'**entrée** — ajouter à l'inventaire, emprunter à un ami, ajouter à une liste — sont
enterrées derrière un « … » de 24 pt dans le coin haut droit, alors que ce sont elles qui font qu'on ouvre la fiche.
Le menu garde ce qui relève de la gestion : `Étagère` et « Supprimer de mon inventaire ».

Les quatre frames sont montées sur **« Je ne possède pas »** : les trois actions n'existent que de ce côté de la
ligne de possession (`BookDetailView.menuContent`).

## « Emprunter à un ami » est conditionnel

`BookDetailView.borrowableItems(_:)` ne retient que les exemplaires qui sont **d'autrui**, **encore en base**
(`isStillInTheStore`), dont le **propriétaire est connu** et dont le mode n'est **pas « Inventorié »** — cinq
propriétaires distincts au plus. Liste vide : le bouton **disparaît**, il n'est pas désactivé.

C'est porté par `Show borrow` sur `Action Bar / Attached`. Sur les trois autres pistes, c'est un élément en moins
dans la rangée — et B2 se replie alors sur une seule ligne, ce qui est un argument pour elle.

## Les quatre propositions

| Frame | id | Ce qu'elle propose |
|---|---|---|
| `A1 · Footer · Barre attachée` | `362:9925` | `Action Bar / Attached`, 393 × 80 contre la barre d'onglets : primaire pleine largeur entre deux ronds |
| `A2 · Footer · Barre flottante` | `362:10020` | `Bottom Action Bar` — le composant de l'écran de tri — 361 × 56 à 16 du bas, ombre `Shadow/Light` |
| `B1 · Sous la couverture · Ronds` | `363:10119` | Trois `Action / Circular` centrés à 16 sous le titre, façon fiche contact iOS |
| `B2 · Sous la couverture · Pilules` | `363:10218` | Rangée d'`Action / Pill` qui passe à la ligne, libellés entiers |
| `Spec · Actions mises en avant` | `364:10317` | L'arbitrage |

| Piste | Pour | Contre |
|---|---|---|
| **A1** attachée | Toujours atteignable, quel que soit le défilement. Le primaire a toute la largeur | **Deux barres empilées** en bas : 197 pt de chrome sur 852, et 80 pt de moins pour le contenu. Y échapper voudrait dire masquer la barre d'onglets sur cette destination — ce que l'app ne fait nulle part |
| **A2** flottante | Plus légère, laisse voir le contenu défiler dessous, et **réutilise un composant existant** (`114:231`) | Elle flotte sur la liste : son contraste dépend de ce qui passe dessous. Et elle sort `Bottom Action Bar` du seul écran où il vivait |
| **B1** ronds | Lisible d'un coup d'œil, zéro dessin nouveau (le cercle est `Button / Circular Icon`), c'est un motif qu'iOS a déjà appris aux gens | Chaque légende doit tenir en **un mot** : « Inventaire » n'est pas « Ajouter à l'inventaire ». Et la rangée **part au défilement** |
| **B2** pilules | Les libellés sont entiers, la hiérarchie est explicite (`Prominent` / `Tinted`), et la rangée se replie toute seule quand « Emprunter » disparaît | Deux lignes à trois actions, 126 pt poussés au contenu, et elle **part au défilement** elle aussi |

Le vrai partage est là : **A reste, B part**. Une action d'entrée qu'on ne retrouve plus une fois arrivé à « Dans la
communauté » — c'est-à-dire au moment précis où on voit qui pourrait nous le prêter — est une action qu'on ira
rechercher dans le « … ».

## Composants ajoutés — `Screens · Components`

| Composant | node id | Variantes | Propriétés | Note |
|---|---|---|---|---|
| `Action / Pill` | `358:357` | Style ∈ {Prominent, Tinted} | `Label`, `Glyph` (INSTANCE_SWAP), `Show glyph` | Glyphe 20 + `Action/action300`, `radius/full`. Mêmes couples de tokens que `Button / Large` Primary et que `Button / Circular Icon` |
| `Action / Circular` | `360:351` | — | `Label` | Une instance de `Button / Circular Icon` (56) + une légende `Caption/caption200`. Le cercle est une **instance exposée** : son glyphe se règle depuis la rangée |
| `Action Bar / Attached` | `361:354` | — | `Show borrow`, `Show list` | 393 × 80, `background/default` + filet haut `border/default`. Trois contrôles du design system, rien de redessiné |

`Bottom Action Bar` (`114:231`) est réutilisé tel quel pour A2 — c'est déjà « rond · bouton · rond ».

## Ce qu'il faut trancher avant de coder

- `Action / Pill` **n'est pas** `Button / Large` : celui-ci n'a pas de glyphe et impose 55 de haut. Retenir B2, c'est
  ajouter un glyphe à `LargeButtonStyle` ou écrire un style à part. Le choisir sans le dire ferait naître un
  deuxième bouton primaire dans le design system.
- Retenir B1, c'est écrire **trois libellés d'un mot** — et accepter qu'« Inventaire » soit ambigu avec l'onglet du
  même nom.
- Retenir A1, c'est accepter les deux barres empilées, ou masquer la barre d'onglets sur cette destination.
- Dans les quatre cas, le menu « … » reste, avec `Étagère` et « Supprimer de mon inventaire ». Il ne disparaît pas.

## Divergence Figma relevée en cours de passe

| # | Où | Constat | Statut |
|---|---|---|---|
| F1 | `Entity Header` (`32:179`) | Le nœud `cover` a gagné une **peinture d'image** depuis la passe du matin : toutes les instances affichent maintenant la même couverture (« Le chaos qui vient »), y compris sous un titre qui dit « Le Comte de Monte-Cristo ». C'est une divergence **interne à Figma**, pas code ↔ Figma | ouverte — à décider : remplissage de démonstration assumé, ou propriété d'échange pour que chaque frame montre son livre |

## Audit

Factorisation, sur les 4 frames : **0 dessin brut**, les `▢` de tête sont `list group` et `action row`, mode épinglé
sur chacune, 25 à 28 instances par frame. Les deux sections de la journée ne se chevauchent pas
(`Œuvre & édition` va jusqu'à `y = -1377`, `Édition · Actions mises en avant` commence à `-1177`).


---

# Réseau · Ajouter des amis lecteurs — proposition du 2026-09-12

**Proposition, pas une réplication.** Aucun de ces écrans n'existe dans le code. Section
`Réseau · Ajouter des amis lecteurs` (`407:10422`) sur la page `Screens`, **clair seul** — tout est bâti sur des
tokens, le mode sombre suit sans redessin.

Le besoin : la section `Réseau` du Profil liste des amis sans jamais permettre d'en ajouter un, et rien dans l'app
ne dit qu'une invitation est arrivée. La maquette part du bouton « Ajouter des amis lecteurs » de la frame
`Profil · Light` (`400:10441`) et va jusqu'au retrait d'un ami.

## Les onze frames

| Frame | id | Ce qu'elle montre |
|---|---|---|
| `N1 · Profil · Réseau (entrée)` | `407:10423` | Le Profil tel qu'il est maquetté, avec « Ajouter des amis lecteurs » sous les deux amis |
| `N2 · Rechercher des lecteurs · Repos` | `407:10451` | Le champ vide et ce que la recherche cherche (`Empty State` centré) |
| `N3 · Rechercher des lecteurs · Résultats` | `408:10585` | Trois résultats, un par état : à ajouter, demande envoyée, déjà ami |
| `N4 · Profil lecteur · Non-ami` | `408:10733` | `User Header`, « Ajouter au réseau » en primaire, inventaire fermé |
| `N5a · Demande d'ajout · Sans message` | `409:10740` | La feuille de confirmation — la seule implémentable telle quelle |
| `N5b · Demande d'ajout · Avec message` | `409:10770` | La même, avec un champ `Field` que le serveur n'accepte pas |
| `N6 · Profil lecteur · Demande envoyée` | `410:10880` | Bouton désactivé + « Annuler la demande » (`Row / Link` Destructive) |
| `N7 · Profil · Invitation reçue` | `410:11046` | Une section `Invitations` sous l'en-tête, deux `Cell / Invitation` |
| `N8 · Invitations · Écran dédié` | `410:11240` | L'autre piste : un écran qui porte les deux sens, reçues **et** envoyées |
| `N9 · Profil lecteur · Demande reçue` | `410:10971` | Accepter en primaire, Refuser en secondaire, jamais en destructif |
| `N10 · Profil lecteur · Ami (menu ouvert)` | `411:11215` | L'inventaire ouvert, et « Retirer du réseau » dans le « … » |
| `Spec · Réseau` | `412:11330` | Le parcours, le contrat serveur, les quatre états, les arbitrages |

## Ce que le serveur sait faire — vérifié le 2026-09-12

Contre `https://inventaire.io/public/api_specs.json`, la source de vérité (voir la note de mémoire sur les sources
d'API) :

| Besoin | Endpoint | Paramètres |
|---|---|---|
| Les quatre états, en un appel | `GET /api/relations` | — ; renvoie `friends`, `userRequested`, `otherRequested`, `network` |
| Demander | `POST /api/relations/request` | `user` — **et rien d'autre** |
| Accepter / Refuser | `POST /api/relations/accept` · `/discard` | `user` |
| Annuler / Retirer | `POST /api/relations/cancel` · `/unfriend` | `user` |
| Chercher un lecteur | `GET /search?types=users&search=…&limit=…` | public ; pas d'autre recherche floue de lecteurs |

Deux conséquences de fond :

- **Aucune demande ne porte de message.** `request` ne prend qu'un identifiant. `N5b` dessine donc un champ sans
  destination — c'est la première chose à trancher, pas un détail de copie.
- **Le serveur ne prévient personne.** Il n'y a pas de notification : une invitation ne se découvre qu'en ouvrant
  l'app. C'est ce qui rend le choix entre `N7` et `N8` structurel, et pas cosmétique.

## Les quatre états, et ce qu'ils donnent à voir

| État serveur | Dans une liste | Sur le profil du lecteur | Geste |
|---|---|---|---|
| Inconnu | `Cell / Relation State=Add` | « Ajouter au réseau » (primaire) | `request` |
| `userRequested` | `Cell / Relation State=Sent` | bouton désactivé + « Annuler la demande » | `cancel` |
| `otherRequested` | `Cell / Invitation` | « Accepter la demande » + « Refuser » | `accept` / `discard` |
| `friends` | `Cell / User` nu | l'inventaire s'ouvre, « Retirer du réseau » dans le « … » | `unfriend` |

## Composants ajoutés — `Screens · Components`

| Composant | node id | Variantes | Propriétés | Note |
|---|---|---|---|---|
| `Cell / Relation` | `403:10499` | State ∈ {Add, Sent} | `Username`, `Item count` | Clone de `Cell / User` (393 × 69) dont le bloc de textes passe en `FILL` ; `Add` porte un `Action / Pill` Tinted, `Sent` un `Tag` Secondary. **Pas de variante `Friend`** : un ami est un `Cell / User` nu |
| `Cell / Invitation` | `405:374` | — | `Username`, `Item count` | Le même clone retourné en vertical (393 × 120) : la rangée du lecteur, puis deux `Action / Pill` en `FILL`, glyphe éteint. Accepter est `Prominent`, Refuser `Tinted` — **jamais `Destructive`** : refuser ne détruit rien, et le rouge ferait de l'expéditeur une menace |

Consommés sans modification : les quatre `Chrome`, `Chrome / Search Field` (`Idle`, `Typed`), `Section Header`,
`Empty State`, `User Header`, `Button / Large` (Primary, Secondary, Secondary+Disabled), `Row / Link` Destructive,
`Note`, `Field`, `Action / Pill`, `Cell / Book`, `Chrome / Menu Scrim` + `Menu Panel`, `Separator`.

## Ce qu'il faut trancher avant de coder

- **Le message de la demande.** `N5a` (sans) est implémentable ; `N5b` (avec) demande de faire passer le texte
  ailleurs, ou de renoncer. Le dessiner sans le dire aurait promis une fonction que le serveur refuse.
- **Où vivent les invitations.** `N7` les pose dans le Profil, vues sans détour, mais elles poussent transactions et
  réseau vers le bas (+293 pt ici, pour deux invitations). `N8` leur donne un écran qui porte aussi les envoyées —
  plus propre, mais invisible tant que le Profil ne porte pas de compteur.
- **Le badge.** Sans notification serveur, un compteur sur l'onglet `Réglages` est le minimum. Il n'est pas
  maquetté.
- **Les confirmations.** « Refuser » et « Retirer du réseau » agissent directement dans ces frames. `unfriend`
  défait une relation qu'il faudra redemander.

## Écarts assumés

- **Clair seul**, et mode épinglé sur les onze frames.
- **Glyphes empruntés**, faute d'équivalents dans `Icon` : `plus` pour « ajouter » (il n'y a pas de
  `person.badge.plus`), `clock` pour l'attente, `person` et `exclamationmark.circle` dans le menu. Ajouter les vrais
  symboles voudrait dire dessiner trois vecteurs de plus, avec les contraintes `SCALE`.
- Aucun état de chargement ni d'erreur réseau n'est dessiné.

## Divergences code ↔ Figma

| # | Où | Constat |
|---|---|---|
| R1 | `UserModel.syncUserNetwork` | Lit `/api/relations` mais **ne garde que `network`** : `userRequested` et `otherRequested` sont jetés. Les deux listes dont vit toute cette maquette existent déjà dans la réponse |
| R2 | `UserDetailView` | Le « … » ne porte que `ReportButton`. Aucun geste de relation n'existe dans le code |
| R3 | `ProfileView` | La section `Réseau` liste `allUsers` moins moi — donc tout utilisateur tombé dans le store, pas les amis au sens du serveur. Sans les quatre listes, la distinction n'est pas faite |

## Audit

Factorisation, sur les 11 frames : **0 dessin brut** — chaque `▢` de tête est un conteneur nommé (`scroll` hérité du
gabarit, `list group`, `Invitations`, `sheet`, `body`, `actions`), mode épinglé sur chacune. Le panneau
`Spec · Réseau` est de la doc, donc hors audit de factorisation. La section (`4666`, `16200`, 4200 × 3400) ne
chevauche ni `Profil` (`400:10440`, qui finit à `y = 16027`) ni `Ranger mes livres`.


## Ce que le code a tranché, le 2026-09-12

La section a été implémentée le jour de sa passe. Deux arbitrages ont été rendus **dans la
maquette** avant le code, et font foi : les invitations vivent dans le Profil **et** dans un écran
dédié (`N7` a gagné une ligne « Toutes les invitations » qui pousse `N8`), et « Annuler la demande »
est monté du lien discret au bouton destructif plein (`N6`).

Cinq écarts restants, le code faisant foi :

| Point | Figma | Code |
|---|---|---|
| `N5b` · feuille avec message | dessinée | **non implémentée** — `POST /api/relations/request` ne prend qu'un identifiant |
| Confirmation du retrait (`N10`) | aucune | `confirmationDialog`, comme partout ailleurs pour un geste qui perd quelque chose |
| Dates (« Envoyée le 11 septembre ») | dessinées | absentes : `/api/relations` ne renvoie que des identifiants |
| Rangée « demande envoyée » (`N3`) | pilule | `Tag` secondaire — c'est un état, pas un geste |
| Glyphes empruntés | `plus`, `clock`, `person` | SF Symbols réels (`plus`, `clock`, `envelope`, `person.badge.minus`) : la contrainte était Figma, pas iOS |

`Action / Pill` a trouvé son équivalent Swift à cette occasion : `DesignSystem/ButtonStyles/PillButtonStyle.swift`,
mêmes couples de tokens que `Button / Large`, à la taille d'un contrôle de fin de rangée. `Cell / Relation` et
`Cell / Invitation` sont `ReaderRowView` et `InvitationRowView` dans `Features/Community/`.

---

# Nouveau livre — tel que livré (passe du 2026-10-25, `extract-screens`)

Le formulaire qui s'ouvre quand un scan ne trouve rien, **répliqué depuis le code** de la
[feature 0020](../features/0020-creating-a-book-that-inventaire-lacks.md) (`Features/CreateBook/`). La section
`Créer un livre absent` (`433:11445`), juste au-dessus, est la proposition d'avant le code et reste pour mémoire :
le code s'en est écarté. Clair seul, à la demande. Section `Nouveau livre · Tel que livré` (`704:20545`, page
`Screens`, `x = 4666`, `y = 22873`, 4464 × 1593), panneau `Spec · Nouveau livre (livré)` (`706:21066`).

## Table des écrans

| Frame | node id | Ce qu'il montre | Source Swift |
|---|---|---|---|
| `L1 · Nouveau livre · Vide` | `704:20546` | À l'ouverture : cadre photo en pointillés, invites, Publier désactivé, langue pas encore revenue | `CreateBook/CreateBookView.swift` |
| `L2 · Nouveau livre · Rempli` | `704:20672` | Photo prise, titre saisi, auteur existant choisi avec sa description, langue déduite | idem |
| `L3 · Échec · Réseau` | `705:20676` | `CreateBookFailure.network` : « Réessayer » + « Garder le brouillon et revenir » | idem + `Model/Creation/CreateBookFailure.swift` |
| `L4 · Échec · Refusé` | `705:20826` | `.refused` (4xx hors 401 / 403) : le bouton reste « Publier et ajouter à mes livres » | idem |
| `L5 · Échec · Compte requis` | `705:20969` | `.needsAccount` (401 / 403) | idem |
| `L6 · Auteur · Résultats` | `705:21112` | Écran poussé : « Déjà sur inventaire.io », puis « Créer « … » » | `CreateBook/AuthorPickerView.swift` |
| `L7 · Auteur · Aucun résultat` | `705:21226` | La seule ligne « Créer », et le pied « Aucun auteur de ce nom… » | idem |
| `L8 · Ce livre est connu` | `705:21302` | Écran poussé quand la passe à blanc reconnaît l'œuvre : deux choix, « Une édition de plus » coché | `CreateBook/WorkMatchView.swift` |

Livre de maquette : *Le Ministère des Rêves*, Momtchil Milanov, ISBN `9782494289857` — la couverture du composant
`Livre` (`51:1765`, page `Brouillon de Olivier`), qui est aussi la photo de `Form / Cover Slot` State=Photo.

## Composants ajoutés — `Screens · Components`

Rangés en colonne à partir de `x = 10800` (rangs) et `x = 11400` (carte et chrome).

| Composant | node id | Variantes | Propriétés | Rôle |
|---|---|---|---|---|
| `Form / Group` | `702:520` | — | `Row 1#702:0`, `Row 2#702:1`, `Row 3#702:3` (INSTANCE_SWAP), `Show row 2#702:2`, `Show row 3#702:4` | La carte d'une `Section` de `Form` encarté. Les slots portent les marges de rang (12 / 16), les rangs 2 et 3 leur `Separator` |
| `Form / Labeled Value` | `701:500` | State ∈ {Filled, Placeholder} | `Label#701:0`, `Value#701:3` | `.withLabel(label:)` sur un champ ou une valeur : l'ISBN, le titre |
| `Form / Cover Slot` | `701:510` | State ∈ {Empty, Photo} | — | `CreateBookCoverSlot`, 88 × 132 |
| `Form / Cover ISBN` | `701:511` | — | (instances imbriquées `Cover`, `ISBN`) | Le premier rang du formulaire |
| `Form / Author Row` | `701:536` | State ∈ {Placeholder, Chosen} | `Name#701:6`, `Description#701:9`, `Show description#701:12` | `CreateBookAuthorRow` et son chevron |
| `Form / Entity Row` | `701:537` | — | `Title#701:15`, `Detail#701:16`, `Show detail#701:17` | `AuthorPickerRow` et la ligne d'œuvre de `WorkMatchView` |
| `Form / Choice Row` | `701:555` | State ∈ {Selected, Unselected} | `Title#701:18`, `Explanation#701:21` | `WorkMatchChoice`, un bouton radio |
| `Form / Action Row` | `701:556` | — | `Label#701:24`, `Glyph#701:25` (INSTANCE_SWAP) | Un `Label` teinté dans un rang : « Créer « … » » |
| `Form / Failure Banner` | `701:561` | — | `Title#701:26`, `Body#701:27` | `CreateBookFailureBanner` |
| `Chrome / Sheet Nav Bar` | `702:540` | — | `Title#702:5` ; instance exposée `Leading` (`Chrome / Glass Button`) | La barre d'une `NavigationStack` dans une `.sheet` iOS 26 : `xmark` à la racine, `chevron.left` poussé |
| `Chrome / Sheet Backdrop` | `702:551` | — | — | Le scanner sombre reculé derrière la feuille. Couleurs **littérales**, comme tout le chrome |

`Icon` (`21:60`) passe à **31 variantes** : `xmark` (`700:494`), `camera` (`700:499`),
`exclamationmark.triangle` (`700:505`), `checkmark.circle.fill` (`700:512`), en ligne `y = 320`. Le dernier est le
seul glyphe plein du jeu : un disque `Disc` en remplissage (`foreground/default`, à surcharger) et une coche `Check`
en `background/default`.

Chaque composant porte sa description (type Swift, métriques, pièges).

## Recette de composition — une feuille

Frame 393 × 852, mode `Light` épinglé, puis dans l'ordre :

1. `Chrome / Sheet Backdrop` plein cadre, `Chrome / Status Bar` Theme=Dark par-dessus.
2. Un conteneur `feuille` : auto-layout vertical, `x = 0`, `y = 69`, 393 × 783 fixe, `background/secondary`, coins
   hauts `radius/rounded-large`, découpé. Dedans : `Chrome / Sheet Nav Bar` (FILL), éventuellement
   `Chrome / Search Field`, puis la colonne `formulaire` (padding 16 / 16 / 24 / 16, gap `spacing/medium`).
3. Une `section` par `Section` du code : `Section Header` facultatif, `Form / Group` (slots échangés, `Show row`
   réglés), puis un pied `Note` Footnote / Secondary. Une section dont le pied porte des boutons devient un conteneur
   `actions` (padding 12 / 16, gap `spacing/small`) de `Button / Large` en FILL.
4. `Chrome / Home Indicator` Theme=Light en dernier, à `y = 818`.

Pour régler un rang : `groupe.children[i].findOne(n => n.name === 'cell').children[0]` est l'instance du slot `i + 1`.

## Ce qui n'est pas maquetté, et les écarts assumés

- **Le mode sombre** — à la demande. Tout est bindé, sauf `Chrome / Sheet Backdrop`, qui est déjà sombre.
- **La publication en cours** — le spinner d'`AsyncButton` (`.showProgressView`) n'est pas dessiné.
- **L'appareil photo** (`CoverCaptureView`, `UIImagePickerController`) — c'est l'interface du système.
- **Le clavier** de L6 / L7, alors qu'on y tape.
- **Géométrie approchée, pas mesurée** : haut de feuille à 69, rayon de feuille 24, barre de 60, cartes au rayon
  `radius/medium` (iOS 26 arrondit davantage ; c'est la convention du fichier).
- **En-têtes de section** : police système dans le code, `Section Header` (Open Sans) ici.
- **Emplacement du champ de `.searchable`** dans un écran poussé d'une feuille sous iOS 26 : pas vérifié. Il est posé
  sous la barre.
- **L3 à L5 coupent** « Garder le brouillon et revenir » au pli, volontairement : le formulaire en échec dépasse la
  hauteur de la feuille, et c'est un constat (ci-dessous), pas un défaut de la maquette.

## Constats sur le parcours — ce que la maquette fait voir

Matière pour le travail sur les fonctionnalités. Aucun n'est corrigé.

1. **Après un échec, la seconde sortie est sous le pli** (L3–L5) : bannière + brouillon + deux boutons dépassent la
   feuille, donc « Garder le brouillon et revenir » ne se voit qu'en faisant défiler.
2. **Refusé et Compte requis laissent « Publier et ajouter à mes livres » actif** (L4, L5) : la même entrée peut être
   renvoyée telle quelle. La feature dit qu'une entrée refusée « n'offre pas de réessayer » — c'est vrai du libellé
   (`isWorthRetrying == false`), pas du geste.
3. **Compte requis demande de se reconnecter** sans aucun chemin pour le faire depuis la feuille (L5).
4. **Rien ne dit pourquoi Publier est désactivé** (L1).
5. **Une faute de frappe suffit pour qu'on propose de créer un auteur** (L7) : seul le pied de section met en garde.
6. **L'œuvre reconnue n'a ni couverture, ni date, ni nombre d'éditions** (L8) : peu de prise pour trancher entre
   « une édition de plus » et « un autre livre ». La proposition C4 en montrait davantage.

## Divergences relevées dans le code — passe Nouveau livre

| # | Où | Constat | Statut |
|---|---|---|---|
| D-NL1 | `Features/CreateBook/CreateBookView.swift:220-221` | Le commentaire de `create()` dit que l'issue 0096 donnera un visage à l'échec et « until then it is said on the shared snack bar » — périmé : l'échec est dit dans la feuille (`CreateBookFailureBanner`), et le `catch` juste en dessous le dit lui-même | ouverte |
| D-NL2 | `CreateBookView.swift:120` et `:279` | Deux styles pour un même rôle de libellé : `.withLabel` (titre, ISBN) est en `caption200` (Open Sans), le libellé « Auteur » de `CreateBookAuthorRow` en `footnote200` (Alegreya) | ouverte |
| D-NL3 | `CreateBookView.swift:115-120` | Le `TextField` du titre prend `create_book.title_field` comme invite **et** comme libellé : « Titre de cette édition » s'affiche deux fois quand il est vide | ouverte |
| D-NL4 | `WorkMatchView.swift:40` / `AuthorPickerView.swift:135` | La ligne d'œuvre espace titre et détail de `xSmall` (4), le rang d'auteur de `xxSmall` (2), pour la même forme — `Form / Entity Row` prend 2 | ouverte — écart de 2 pt assumé |
| D-NL5 | `docs/features/0020-creating-a-book-that-inventaire-lacks.md` | « Une entrée refusée le dit et n'offre pas de réessayer » : le bouton principal reste actif et republie (constat 2) | ouverte |
| D-NL6 | Figma — `Chrome / Search Field` (`27:172`) | La variante `State=Typed` n'est pas reliée à `Placeholder#27:4` : le texte tapé (« mont ») se surcharge à la main sur l'instance | ouverte — surchargé dans L6 / L7 |

## Ce que la construction a appris

- **Un slot porte la marge, pas le rang.** `Form / Group` met le padding de cellule dans ses slots : les rangs
  `Form / *` n'en ont pas, donc ils s'imbriquent aussi hors carte (l'ISBN de `Form / Cover ISBN` est un
  `Form / Labeled Value`).
- **Un composant créé par `createComponent()` + `resize()` refige l'axe principal** : `Form / Group` est sorti à
  50 pt de haut, deux rangs coupés, jusqu'à `primaryAxisSizingMode = 'AUTO'` après le `resize`.
- **Le jeu `Icon` se range à la main**, sur une grille de 64 ; un nouveau glyphe se fait en clonant `Glyph=plus`,
  en remplaçant ses vecteurs par ceux d'un `createNodeFromSvg`, et en leur redonnant le trait bindé et des
  contraintes `SCALE`.
- **Un pied de section sur deux paragraphes** (langue + avis public) tient dans une seule `Note`, avec
  `paragraphSpacing = 4` surchargé sur l'instance — deux `Note` empilées doubleraient leur padding.

## Audit

Factorisation, sur les 8 frames : **0 dessin brut**. Chaque frame : `◆ Chrome / Sheet Backdrop`,
`◆ Chrome / Status Bar`, `▢ feuille`, `◆ Chrome / Home Indicator` ; dans `feuille`, seuls des conteneurs nommés
(`formulaire`, `section · …`, `actions (pied de section)`). Composants nouveaux : 0 fill ou trait en dur sauf
`Chrome / Sheet Backdrop` (chrome, voulu), 0 texte sans style, une description chacun. Aucun nom de composant
dupliqué dans le fichier, aucune section qui en chevauche une autre. Compte : **69 composants** sur
`Screens · Components`, 4 sur `Components`, 113 variables locales.

---

# Nouveau livre v2 — l'œuvre d'abord (proposition du 2026-10-25)

Une proposition, pas une réplique du code : **rien n'est implémenté**. Quand un scan ne trouve pas l'édition, la
feuille ne demande plus d'emblée titre et auteur ; elle demande d'abord **de quel livre** il s'agit, en cherchant
l'œuvre sur inventaire.io. Une œuvre trouvée apporte ses auteur·ices et son titre, et il ne reste que l'édition à
décrire. Rien de trouvé : on crée l'œuvre, puis l'édition, dans le même formulaire. Clair seul. Section
`Nouveau livre v2` (`712:21292`, page `Screens`, `x = 4666`, `y = 24818`, 3991 × 2758), sous
`Nouveau livre · Tel que livré` ; panneau `Spec · Nouveau livre v2` (`713:21515`).

## Le parcours

Scan sans résultat → « + » de la rangée (inchangé) → `V1`. Un résultat de `V2` pousse `V3`. La dernière ligne de
`V2`, ou celle de `V4`, pousse `V5`. Au moment de publier `V5`, la passe à blanc peut encore reconnaître une
œuvre : `V6`, qui remplace `L8` sur cette branche. `V3` n'a pas besoin de passe à blanc, puisque l'œuvre y est déjà
nommée par son uri. Le choix d'auteur (`L6`, `L7`), les échecs (`L3`–`L5`) et les brouillons sont ceux de la v1.

## Table des écrans

| Frame | node id | Ce qu'il montre | Cloné de |
|---|---|---|---|
| `V1 · Quelle œuvre ? · À l'ouverture` | `712:21296` | Feuille « Nouveau livre », champ de recherche actif (« Titre ou auteur·ice »), `Empty State` Centered : « De quel livre s'agit-il ? » | `L6` |
| `V2 · Quelle œuvre ? · Résultats` | `712:21368` | « ministère des rêves » : trois `Form / Work Row`, puis « Aucune ne correspond : créer l'œuvre » en dernier | `L6` |
| `V3 · Nouvelle édition · Œuvre choisie` | `713:21206` | Poussé. « Édition de » rappelle l'œuvre (Trailing=None), puis couverture & ISBN, puis le titre de l'édition, pré-rempli avec celui de l'œuvre. Aucun champ auteur | `L2` |
| `V4 · Quelle œuvre ? · Aucun résultat` | `712:21479` | « étincelles écosocialistes » : la seule ligne « Créer l'œuvre « … » », et le pied qui demande de vérifier l'orthographe | `L7` |
| `V5 · Nouvelle œuvre` | `713:21319` | Poussé. « L'œuvre » (titre, auteur choisi, « Ajouter un·e autre auteur·ice »), puis « Cette édition » (couverture & ISBN, titre de l'édition) | `L2` |
| `V6 · Œuvre déjà connue` | `713:21424` | La passe à blanc de `V5` reconnaît une œuvre : la ligne d'œuvre de `V2`, et deux choix, « Une édition de cette œuvre » coché | `L8` |

### Seconde rangée — couverture d'une nouvelle œuvre

Une œuvre que personne n'a créée n'a pas de couverture, et `enrich` ne trouve rien pour un ISBN inconnu : `V5`
s'ouvre en réalité sans image. Rangée sous la première (titre `717:21398`, frames à `y = 1512` dans la section).

| Frame | node id | Ce qu'il montre | Cloné de |
|---|---|---|---|
| `V7 · Nouvelle œuvre · Sans couverture` | `717:21401` | `V5` avec `Form / Cover Slot` Empty, glyphe `photo`, légende « Ajouter une couverture » | `V5` |
| `V8 · Couverture · Choisir la source` | `717:21498` | `Chrome / Menu Scrim` + `Chrome / Menu Panel` sous le cadre : « Prendre une photo », « Choisir dans Photos », « Choisir un fichier », « Depuis une URL… » | `V7` |
| `V9 · Image depuis une URL · Vide` | `718:21591` | Écran poussé : « Chercher le titre et l'ISBN sur Google Images », puis l'URL (invite), « Coller le lien copié », l'aperçu vide ; « Utiliser cette image » désactivé | `L6` |
| `V10 · Image depuis une URL · Aperçu` | `718:21720` | Lien collé, image chargée et mesurée (600 × 900 px) ; le bouton s'active | `L6` |
| `V11 · Image depuis une URL · Pas une image` | `718:21842` | Une adresse `google.com/imgres?…` : la page répond, pas l'image ; aperçu en erreur, bouton désactivé | `L6` |
| `V12 · Couverture posée · Remplacer ou retirer` | `724:21922` | `V5` et son menu `Chrome / Menu Panel · Section`, ouvert au-dessus du cadre : « Retirer la couverture » (rouge, `trash`), puis « Remplacer par » et les quatre sources | `V5` |
| `V13 · Aide · Données bibliographiques` | `724:22141` | La feuille du « ? » : trois sections (« Ce que c'est », « D'où elles viennent », « Ce que vous publiez ») et trois liens (wiki, chat du projet, mes contributions) | `V1` |

« Choisir dans Photos » s'ajoute aux trois sources demandées (fichier, photo, URL) : c'est là que finit une image
enregistrée depuis Safari. Caméra, Photos et Fichiers sont des interfaces du système, non dessinées. Le même menu
sert `V3` et le formulaire livré. La recherche Google Images envoie `q=<titre de l'œuvre> <ISBN>`. Côté serveur,
l'URL passe par `POST /api/images/convert-url` (`{url, container: "entities"}`, authentifié, 100 requêtes et 500 ms
d'écart) : le serveur télécharge l'image lui-même et rend son chemin `/img/entities/…`. Les trois autres sources
passent par l'upload multipart existant. Le chemin rendu part dans `image` de la **graine d'édition** : sur
inventaire.io, la couverture appartient à l'édition, pas à l'œuvre.

### L'encart « Données bibliographiques », et le « ? »

En tête des écrans qui modifient des données bibliographiques (toute la section, pour l'instant), un encart
`Form / Notice` résume en trois lignes celui d'inventaire.io, « À propos des données bibliographiques ». Sa source est
`about_bibliographic_data.svelte` et `bibliographic_data_settings.svelte` dans inventaire-client, avec les textes
français de `src/client/fr.json` dans inventaire-i18n. La page d'édition du site demande une connexion : le texte a
été lu dans le code, pas sur la page.

- **Il s'affiche tant qu'il n'a pas été fermé.** Il est dessiné sur `V1`, `V3` et `V7` ; les autres frames
  montrent l'état fermé.
- **Sa croix le ferme partout et pour de bon** (`@AppStorage`), comme le `localStorage` d'inventaire.io.
- **Le « ? »** (`Chrome / Sheet Nav Bar`, `Show trailing`), présent sur chaque écran de la section, ouvre son contenu
  entier en feuille (`V13`). « En savoir plus » fait de même.
- **À l'ouverture, l'encart repousse « Publier » sous le pli** de `V3` et `V7`. C'est voulu : le bouton défile avec
  le formulaire, comme dans le code livré.

Livres de maquette : *Le Ministère des Rêves*, Momtchil Milanov (`V1`–`V3`, `Livre` Book=2, l'ISBN des frames `L`) ;
*Étincelles écosocialistes*, Michael Löwy (`V4`–`V6`, `Livre` Book=3, ISBN `9782493373052` **inventé**). Les autres
résultats de `V2` et toutes les années sont inventés.

## Composants ajoutés — `Screens · Components`

| Composant | node id | Variantes | Propriétés | Rôle |
|---|---|---|---|---|
| `Form / Work Row` | `711:21157` (`x = 10800`, `y = 1300`) | Cover ∈ {Photo, None} × Trailing ∈ {Chevron, None} — `711:21127`, `711:21137`, `711:21144`, `711:21152` | `Title#711:0`, `Detail#711:5` ; instance `Livre` exposée (Cover=Photo) | Une œuvre : couverture 36 × 54 (`radius/book`), titre `Content/content400Bold`, « auteur·ices · année » `Footnote/footnote200` secondaire, chevron de `Form / Author Row`. Sans marge propre : se pose dans un slot de `Form / Group` |
| `Form / Image Preview` | `716:615` (`x = 10800`, `y = 1700`) | State ∈ {Empty, Loaded, Failed} — `716:594`, `716:602`, `716:607` | `Caption#716:3` ; instance `Livre` exposée (Loaded) | L'aperçu d'une image par URL : 120 × 180, `radius/medium`, légende `Caption/caption200` centrée. Empty en pointillés comme `Form / Cover Slot`, Failed sur `background/error`. Un `AsyncImage` et ses trois phases |
| `Form / Notice` | `722:595` (`x = 11400`, `y = 1300`) | — | `Title`, `Body`, `Link` (TEXT) | L'encart des données bibliographiques : `background/tinted`, `radius/medium`, padding 12 / 12 / 12 / 16. Glyphe `questionmark.circle` à 20 teinté, titre `Content/content300`, corps `Footnote/footnote200`, lien `Footnote/footnote200Bold` teinté, `xmark` à 16 pour le fermer. 361 × 119 avec les textes par défaut |
| `Chrome / Menu Panel · Section` | `722:756` (`x = 11400`, `y = 1500`) | — (clair seul) | `Section` (TEXT) ; `row 1` → `row 5` exposées | Un menu en deux sections : une ligne, une bande de 8 (noir 6 %), un en-tête `Footnote/footnote200` secondaire, quatre lignes. Matériau de `Chrome / Menu Panel`. La ligne destructive se fait en surchargeant `row 1` en `foreground/error` |

Pourquoi pas `Cell / Entity` Type=Work : sa vignette est carrée, à 36, et sa marge est celle d'une liste plein
écran. Pour reconnaître le livre qu'on tient, il faut la couverture entière. Compte : **73 composants** sur
`Screens · Components`.

Étendus par la seconde rangée :
- **`Icon`** (`21:60`) passe à **35 variantes** : `photo` (`716:537`), `folder` (`716:544`), `link` (`716:550`) et
  `questionmark.circle` (`722:546`), en ligne `y = 384`. Le jeu fait maintenant 352 × 408.
- **`Chrome / Menu Panel`** (`350:363`) gagne `Show row 4`, éteinte par défaut.
- **`Chrome / Sheet Nav Bar`** (`702:540`) gagne `Show trailing#722:0`, éteint par défaut. Le cadre `trailing`
  porte un `Chrome / Glass Button` exposé, `Trailing`, au glyphe `questionmark.circle`. Éteint, le cadre de 44 garde
  le titre centré.
- Les deux interrupteurs sont éteints par défaut : les écrans existants n'en voient rien.

## Ce qui part sur le fil

- `V2` : `GET /api/search?types=works`, au fil de la frappe, comme le choix d'auteur.
- `V3` : `POST /api/entities/resolve` avec **une seule graine, l'édition** : `wdt:P629` (l'uri de l'œuvre choisie),
  `wdt:P212`, `wdt:P1476`, `wdt:P407`, `image`. Il n'y a ni graine d'œuvre ni graine d'auteur, parce que les
  auteur·ices sont portés par l'œuvre (`wdt:P50`) et pas par l'édition.
- `V5` : `resolve` comme dans la v1. L'œuvre est décrite par ses labels, les auteur·ices par uri ou par labels, et
  il peut y en avoir plusieurs. La passe à blanc (`create: false`) précède `V5`, et `V5` seulement.

## À trancher

1. **La recherche d'œuvres trouve-t-elle par nom d'auteur·ice ?** Si ce n'est pas le cas, chercher avec
   `types=works|humans` et faire pousser à un auteur la liste de ses œuvres (`author-works`).
2. **Le titre de l'édition pré-rempli avec celui de l'œuvre** (`V3`, `V5`) aide pour une réédition. Il piège pour
   une traduction dont le titre diffère.
3. **Une édition rattachée à la mauvaise œuvre** se corrige par `update-claim` sur `wdt:P629`, ce que l'app ne sait
   pas faire.
4. **La capitalisation du titre** : on tape en minuscules (`V4`), et `V5` montre le titre recapitalisé. Reste à
   décider si c'est l'app ou la personne qui le fait.
5. **`V1` ne rappelle le livre scanné que par l'ISBN, dans la phrase.** Faut-il y reprendre la rangée du scanner ?

## Tranché le 2026-10-25

1. **Google Images** cherche le titre de l'œuvre **et l'ISBN**.
2. **Droits** : rien de plus n'est dit à côté de « Utiliser cette image ».
3. **Une couverture déjà posée** rouvre le même menu, avec « Retirer la couverture » d'abord et les sources sous
   « Remplacer par » (`V12`).
4. **Le même menu** sert aussi `V3` et le formulaire livré.

## Ce que la construction a appris

- **`isExposedInstance` exige un parent composant** : poser l'instance `Livre` dans son cadre, puis le cadre dans le
  composant, **avant** de l'exposer. Sinon : « Instance must be contained within a component ».
- **Recomposer un écran livré par clonage** (`L2`, `L6`, `L7`, `L8`) garde le chrome, les marges et les noms de
  conteneurs. Atteindre un rang par le chemin de slot (`groupe.children[i]` → `cell` → `children[0]`) a marché
  là où un `findOne` sur `mainComponent.name` n'a rien trouvé dans un clone frais.

## Audit

Les 13 frames : **0 dessin brut**. Hors instances, seuls des conteneurs nommés, et aucun texte resté de la v1
(« Milanof », « Le Guin », « Garder… »). Pas de chevauchement de section. Le bouton principal finit au-dessus de
l'indicateur d'accueil (818) partout, sauf là où l'encart est ouvert : `y = 812` en `V5`, 791 en `V9` et `V10`, 807
en `V11`. Il passe sous le pli en `V3` (908) et en `V7` (947), à cause de l'encart.

---

# Modifier l'édition · Toutes les données (proposition du 2026-10-25)

**Implémentée le 2026-10-25** ([feature 0050](../features/0050-every-bibliographic-datum.md)) ; les écarts du code
sont en fin de section. Le formulaire livré par la [feature 0049](../features/0049-edit-an-edition.md) ne modifiait
que l'œuvre, la couverture, le titre et le sous-titre. Celui-ci montre et modifie **toutes les propriétés qu'inventaire.io accepte sur une édition**. C'est aussi l'écran de
l'ajout depuis le scanner : il remplacerait `V3` de « Nouveau livre v2 », et `V5` y devient l'écran d'une œuvre.
Section `Modifier l'édition · Toutes les données` (`750:2508`, page `Inventaire`, `x = 0`, `y = 13425`), sous
`Fiche livre · Données bibliographiques`. Panneau `Spec · Modifier l'édition · Toutes les données` (`754:3472`).

Affinée le même jour, à la demande : « Édition de » ajoute une **œuvre**, plus un·e auteur·ice ; les auteur·ices
s'ajoutent dans l'écran de l'œuvre ; une œuvre se détache d'un glissement ; « Enregistrer » est épinglé en bas.

## Table des écrans

| Frame | node id | Ce qu'il montre |
|---|---|---|
| `E1 · Modifier l'édition · Tout · Light` | `750:2509` | La feuille de la fiche livre, toute sa hauteur (393 × 2 744). Huit sections remplies en partie, la barre fixe « Enregistrer » au bout |
| `E1 · Modifier l'édition · Tout · Dark` | `752:2856` | Le même, mode `Dark` épinglé, indicateur d'accueil `Theme=Dark` |
| `E2 · Nouvelle édition · Depuis le scanner · Light` | `752:2917` | Après le choix de l'œuvre (`V2`) : cadre de couverture vide, ISBN du code-barres, titre repris de l'œuvre, langue déduite, le reste en invite ; « Publier et ajouter à mes livres » dans la barre fixe (393 × 2 680) |
| `E3 · Modifier l'édition · À l'ouverture · Light` | `758:3589` | `E1` tel qu'il s'ouvre (852) : la barre fixe par-dessus le contenu |
| `E4 · Détacher une œuvre · Light` | `758:3657` | Deux œuvres, la seconde glissée vers la gauche, « Détacher » révélé ; encart fermé |
| `E5 · Modifier l'œuvre · Light` | `758:3803` | Poussé depuis une œuvre de « Édition de » : la forme de `V5`, remplie — titre de l'œuvre, auteur, « Ajouter un·e autre auteur·ice ». Retour en `chevron.left` |

Les sections, dans l'ordre : l'encart « Données bibliographiques », « Édition de », « Couverture et ISBN », « Titre »,
« Publication », « Format », « Ont aussi fait cette édition », « Bases bibliographiques », « Autres données ».

## Les œuvres de l'édition

- « Édition de » liste les œuvres de l'édition (`wdt:P629` : un recueil en réunit plusieurs), puis « Ajouter une
  œuvre », qui pousse la recherche `V2`. Son « Créer l'œuvre » pousse `V5` vide, « Nouvelle œuvre ».
- **Toucher une œuvre** pousse `E5`, « Modifier l'œuvre » : la forme de `V5`, remplie de ce que la ligne montrait.
  C'est là, et seulement là, qu'on ajoute ou enlève un·e auteur·ice. Ses changements partent avec « Enregistrer » au
  retour : une seule sauvegarde pour toute la feuille. Une œuvre Wikidata s'y montre en lecture seule.
- **Glisser une œuvre vers la gauche** révèle « Détacher » (`E4`, `.swipeActions(edge: .trailing)`). L'édition
  cesse d'en être une édition ; l'œuvre reste sur inventaire.io.
- Une édition sans œuvre ne s'enregistre pas (`P629` obligatoire) : « Enregistrer » se désactive jusqu'à ce qu'on
  en ajoute une.

## La barre fixe

« Enregistrer » (« Publier et ajouter à mes livres » en création) est épinglé en bas de la feuille, par
`safeAreaInset(edge: .bottom)` : `Action Bar / Attached` (`361:354`), ses deux boutons ronds éteints, dans un cadre
`barre fixe (safeAreaInset)` sur `background/default` qui ajoute 34 de zone sûre (113 en tout). Dans les frames
toute hauteur, la barre est au bout ; dans `E3` et `E4`, elle est en position absolue, contrainte en bas, par-dessus
le contenu.

## Ce qu'inventaire.io permet sur une édition — vérifié le 2026-10-25

Source : `GET /api/data/properties` (les `subjectTypes` qui contiennent `edition`), et
`app/modules/entities/lib/editor/properties_per_type.ts` dans inventaire-client (priorités, libellés, propriétés
obligatoires, catégories repliées).

| Section | Propriétés |
|---|---|
| Édition de | `wdt:P629`, obligatoire, multivaluée (un recueil peut réunir plusieurs œuvres) |
| Couverture et ISBN | `invp:P2` · ISBN-13 `wdt:P212` · ISBN-10 `wdt:P957` |
| Titre | `wdt:P1476`, obligatoire · sous-titre `wdt:P1680` |
| Publication | maison d'édition `wdt:P123` · collection `wdt:P195` · date `wdt:P577` · langue `wdt:P407`, obligatoire |
| Format | format `wdt:P437` (six valeurs : broché, relié, poche, album BD, livre numérique, livre audio) · pages `wdt:P1104` · volumes `wdt:P2635` |
| Ont aussi fait cette édition | traduction `P655` · illustrations `P110` · illustration de couverture `P736` · préface `P2679` · postface `P2680` · direction éditoriale `P98` |
| Bases bibliographiques | 22 identifiants : VIAF `P214`, GND `P227`, OCLC `P243`, BnF `P268`, DOI `P356`, Open Library `P648`, Google Books `P675`, BNE `P950`, SUDOC `P1025`, SWB `P1044`, BN argentine `P1143`, LCCN `P1144`, LIBRIS `P1182`, ISFDB `P1234`, DNB `P1292`, HathiTrust `P1844`, Goodreads `P2969`, Runeberg `P3155`, CNB tchèque `P3184`, British Library `P5199`, NooSFere `P6901`, BookBrainz `P12351` |
| Autres données | liens : site officiel `P856`, blog `P1581`, X `P2002`, Instagram `P2003`, Facebook `P2013`, YouTube `P2397`, Mastodon `P4033`, TikTok `P7085`, Threads `P11892`, Bluesky `P12361` · différente de `P1889` |

Ne sont pas montrés, comme sur le site : `wdt:P31`, qui n'a qu'une valeur permise pour une édition, ainsi que
`invp:P1` et `invp:P3`, cachés par inventaire-client. Sur le site, « Bases bibliographiques » et « Présence sur le
web » sont repliées. Ici, une section vide se réduit à son bouton « Ajouter … ».

## Composants

| Composant | node id | Ajout | Rôle |
|---|---|---|---|
| `Form / Swipe Row` | `757:607` (`x = 10800`, `y = 2526`) | **Nouveau.** `Row#757:0` (INSTANCE_SWAP, `Form / Work Row` par défaut), `Action#757:1` (TEXT, « Détacher ») | Un rang glissé vers la gauche, son action de fin révélée. 361 de large, découpé, aligné à droite : le `contenu` (fond `background/default`, padding 12 / 16) déborde à gauche de la largeur de l'action, l'`action` (96, pleine hauteur) apparaît à droite, aux couleurs de `Button / Large` Destructive (`background/error`, `foreground/error`). Se pose dans un slot de `Form / Group` dont la cellule a ses paddings surchargés à 0 |
| `Action Bar / Attached` | `361:354` | Réutilisée, `Show borrow` et `Show list` éteints | La barre fixe |
| `Form / Labeled Value` | `701:500` | Axe `Trailing` ∈ {None, Chevron, Menu} ; variantes `748:14`, `748:21`, `748:28`, `748:35` | Chevron : un choix poussé (maison d'édition, collection, langue, personne). Menu : un `Picker` en menu (date, format). Les variantes d'origine sont renommées `…, Trailing=None` |
| `Form / Group` | `702:520` | `Row 4..6` (`748:9`, `748:11`, `748:13`), `Show row 4..6` (`748:8`, `748:10`, `748:12`) | Six rangs pour « Ont aussi fait cette édition » |
| `Form / Cover ISBN` | `701:511` | `Show ISBN-10#748:14` ; les ISBN rangés dans `identifiants` (`748:24453`) | L'ISBN-10 sous l'ISBN-13 |

Les extensions sont éteintes par défaut : les écrans existants n'en voient rien. Compte : **74 composants** sur
`Screens · Components`.

## Comportement proposé

- **Un seul écran**, pour modifier (`E1`, « Enregistrer ») comme pour créer (`E2`, « Publier et ajouter à mes
  livres »). Ne changent que le titre, le bouton et ce qui est pré-rempli : l'ISBN du code-barres, l'œuvre choisie,
  son titre, la langue déduite de l'ISBN.
- **Obligatoires** : l'œuvre, le titre et la langue (`requiredPropertiesPerType` d'inventaire-client). Sans eux, le
  bouton reste désactivé.
- **Chevron** : pousse une recherche sur inventaire.io, avec « Créer « … » » en dernier, comme le choix
  d'auteur·ice. Un rôle peut nommer plusieurs personnes : l'écran poussé les liste.
- **Menu** : la date (jour, mois ou année seule) et le format.
- **Bases et liens** : « Ajouter … » pousse la liste, puis un champ validé par le format de la base. Une valeur
  s'efface d'un glissement.
- **Sur le fil** : un `update-claim` par valeur qui change. Ajouter une œuvre envoie `P629` sans ancienne valeur, la
  détacher sans nouvelle valeur. Le titre d'une œuvre est un label (`update-label`), ses auteur·ices des `P50` sur
  l'œuvre. Une maison d'édition, une collection ou une personne inconnue est d'abord créée par
  `POST /api/entities`. En création, `resolve` porte toutes les valeurs dans la graine d'édition.

## Tranché à l'implémentation (2026-10-25)

1. **Le glissement** va vers la gauche, l'action à droite (`.swipeActions(edge: .trailing)`).
2. **L'ISBN reste en lecture seule** : le serveur réserve `wdt:P212` aux admins (`updateAccessLevel: 'admin'`) et
   déduit `wdt:P957`. Le site ne le permet pas à un compte ordinaire non plus.
3. **Les liens vers des réseaux sociaux sont montrés**, puisque inventaire.io les accepte.

## Ce qui n'est pas maquetté

- Les écrans poussés : maison d'édition, collection, personne, langue, liste des bases, saisie d'un identifiant,
  « Différente de ».
- Les menus de date et de format, l'état d'échec, le clavier.
- `E5` pour une œuvre Wikidata (en lecture seule), et l'état sans œuvre après un « Détacher ».
- Le mode sombre, sauf pour `E1`.
- **Données de maquette inventées** : maison d'édition, traductrice, date, nombre de pages, identifiants, et la
  seconde œuvre « Le Bureau des oublis ». Le livre est celui des frames `L` et `V` (*Le Ministère des Rêves*, ISBN
  `9782494289857`), et son ISBN-10 est calculé.

## Divergences relevées dans le code

| # | Où | Constat | Statut |
|---|---|---|---|
| D-ME1 | `Features/CreateBook/CreateBookCoverRow.swift`, via `EditEditionView` | Quand l'édition n'a pas d'ISBN, le libellé « ISBN » s'affiche quand même, sans valeur. C'est le cas de *Dans la forêt* sur la capture du 2026-10-25. `E1` montre l'ISBN en champ, avec une invite quand il manque | corrigée (feature 0050) : rien ne s'affiche sans ISBN |
| D-ME2 | `BookBibliographicDataSection.swift` | La maquette `744:2383`, retouchée à la main le 2026-10-25, n'a plus qu'une rangée teintée « Données bibliographiques », sans en-tête, et une note « Enrichir les données bibliographiques… ». Le code montrait encore l'en-tête « Données bibliographiques » et une rangée « Modifier » | corrigée (feature 0050) |
| D-ME3 | `EditEditionView.swift` | Le code livré ajoute des auteur·ices depuis l'écran de l'édition, n'y montre qu'une œuvre et pose « Enregistrer » au pied du formulaire. La maquette met les auteur·ices dans l'écran de l'œuvre (`E5`), liste les œuvres et épingle la barre | corrigée (feature 0050) |

## Écarts du code livré (feature 0050)

- « Autres données » devient « Sur le web », sans « Différente de » (`wdt:P1889`) : `/api/search` ne cherche pas
  les éditions.
- L'ISBN-13 et l'ISBN-10 sont des textes, pas des champs (voir « Tranché »).
- Les actions de glissement suivent le système — fond rouge (`.tint(.foregroundError)`), libellé blanc — et non
  `Form / Swipe Row` (`background/error`, libellé `foreground/error`).
- La date est un écran poussé (précision année / mois / jour), pas un menu.
- `E5` n'a pas de barre fixe : ses changements partent avec l'« Enregistrer » de l'édition, au retour.

## Ce que la construction a appris

- **Ajouter un axe de variantes à un jeu existant** : renommer les variantes d'origine avec la nouvelle valeur
  (`State=Filled, Trailing=None`), puis cloner. Les textes déplacés dans un nouveau cadre perdent leur
  `componentPropertyReferences`, qu'il faut rebrancher à la main.
- **Un slot échangé garde la hauteur fixe de l'ancien rang** : `Form / Swipe Row` posé à la place d'un
  `Form / Entity Row` sortait à 44 de haut, coupé, jusqu'à `layoutSizingVertical = 'HUG'` sur l'instance.
- **Un débordement à gauche** s'obtient par un auto-layout horizontal de largeur fixe, découpé, aligné à droite
  (`primaryAxisAlignItems = 'MAX'`) : c'est ce qui fait le rang glissé.
- **`sips` ignore `--cropOffset`** : pour lire une capture haute par morceaux, découper avec CoreGraphics.

## Audit

Les 6 frames : **0 dessin brut**. Hors instances, seuls les conteneurs `feuille`, `formulaire`, `section · …` et
`barre fixe (safeAreaInset)`. Pas de chevauchement de section sur `Inventaire`.

---

# Modifier l'édition, l'œuvre et l'auteur·ice · V2 (proposition du 2026-10-28)

**Implémentée le 2026-10-28** ([feature 0057](../features/0057-edit-works-and-authors.md)) ; ses écarts avec le
code y sont listés — le code fait foi. Section `Modifier l'édition, l'œuvre et l'auteur·ice · V2` (`814:5090`, page `Inventaire`,
`x = 0`, `y = 21859`), un double de `750:2508` (V1, ci-dessus, laissée telle quelle). Panneau
`Spec · Modifier l'édition, l'œuvre et l'auteur·ice · V2` (`814:5215`). `E5` n'y est plus : `W1` le remplace.

## Table des écrans

| Frame | node id | Ce qu'il montre |
|---|---|---|
| `V2 · E1 · Modifier l'édition · Tout · Light` / `Dark` | `814:5091` / `814:5132` | `E1` de la V1 ; la note de « Ont aussi fait cette édition » ajoute « Touchez une personne pour modifier sa fiche » |
| `V2 · E2` → `V2 · E4` | `814:5173`, `814:5238`, `814:5279` | Inchangés |
| `V2 · W1 · Modifier l'œuvre · Tout · Light` / `Dark` | `815:6686` / `815:7640` | Toute la hauteur (393 × 2 847), « Enregistrer » au bout. Neuf sections : L'œuvre, Auteur·ices, Ont aussi fait cette œuvre, Bande dessinée, Série, Genre et sujet, Liens avec d'autres œuvres, Bases bibliographiques, Autres données |
| `V2 · A1 · Modifier l'auteur·ice · Tout · Light` / `Dark` | `815:7335` / `815:8028` | Toute la hauteur (393 × 1 405), « Enregistrer » au bout. Quatre sections : L'auteur·ice, Courant et influences, Bases bibliographiques, Autres données |

`W1` et `A1` sont poussés dans la feuille de `E1` (chevron.left, « ? »). **Un écran, une entité, un
« Enregistrer »** (décidé le 2026-10-28) : chacun a la barre fixe de `E1` (`Action Bar / Attached` dans
`barre fixe (safeAreaInset)`, 113 avec la zone sûre). `W1` enregistre l'œuvre, `A1` l'auteur·ice, `E1` l'édition —
y compris les œuvres ajoutées ou détachées, qui sont des `P629` de l'édition. Enregistrer `W1` ou `A1` envoie (non
optimiste, comme la feature 0049) puis revient d'un cran ; ce qui avait changé dans `E1` y est toujours. Le bouton est
éteint tant que rien n'a changé ; chevron.left sur des changements demande « Quitter sans enregistrer ? »
(feature 0032). Une entité Wikidata s'ouvre sans barre.

## Le parcours (prototype)

Flow `V2 · Modifier l'édition, l'œuvre, l'auteur·ice`, départ sur `E1 Light`. Toucher une œuvre de `E1` ou `E3` →
`W1` ; toucher l'auteur·ice de `W1` ou « Traduction » de `E1` → `A1` ; chevron.left → retour. Câblé en clair et en
sombre. Une entité Wikidata s'ouvrirait en lecture seule (pas maquetté).

## Ce qu'inventaire.io permet — vérifié le 2026-10-28

Source : `GET /api/data/properties` (les `subjectTypes` `work` et `human`), `GET /api/data/property-values` (valeurs
permises de `P31` et `P7937`), et `properties_per_type.ts` d'inventaire-client (priorités, libellés, catégories).

| Œuvre (`W1`) | Propriétés |
|---|---|
| L'œuvre | titre : un label par langue · type `P31`, une valeur parmi six (œuvre littéraire, œuvre écrite, bande dessinée, roman graphique, manga, manhwa) · forme `P7937`, une valeur parmi 31 · langue originale `P407` · date de première publication `P577` |
| Auteur·ices | `P50` |
| Ont aussi fait cette œuvre | scénario `P58` · illustrations `P110` · direction éditoriale `P98` |
| Bande dessinée | dessin `P10837` · encrage `P10836` · couleurs `P6338` · lettrage `P9191` |
| Série | `P179` · rang `P1545` |
| Genre et sujet | genre `P136` · sujet principal `P921` |
| Liens avec d'autres œuvres | basée sur `P144` · inspirée de `P941` · publiée dans `P1433` · en réponse à `P2675` |
| Bases bibliographiques (20) | `P214` `P227` `P243` `P244` `P268` `P269` `P648` `P950` `P1085` `P1274` `P1984` `P3631` `P4087` `P5331` `P5571` `P6221` `P7823` `P8383` `P10100` `P11308` |
| Autres données | liens `P856` `P1581` `P2002` `P2003` `P2013` `P2397` `P4033` `P7085` `P11892` `P12361` · à ne pas confondre avec `P1889` |

| Auteur·ice (`A1`) | Propriétés |
|---|---|
| L'auteur·ice | nom : un label par langue · pseudonymes `P742` (texte) · langues d'écriture `P1412` · naissance `P569` · mort `P570` |
| Courant et influences | mouvement `P135` · influencé·e par `P737` |
| Bases bibliographiques (29) | `P213` `P214` `P227` `P243` `P244` `P268` `P269` `P349` `P496` `P648` `P906` `P950` `P1006` `P1233` `P1960` `P1982` `P2607` `P2963` `P3630` `P4084` `P4285` `P4369` `P5361` `P5491` `P5570` `P7400` `P9707` `P12430` `P14412` |
| Autres données | les dix liens d'une œuvre et LinkedIn `P6634` · à ne pas confondre avec `P1889` |

Absents : `invp:P1`, `invp:P3` (cachés par inventaire-client), `P31` d'une personne (une seule valeur). Ni couverture
ni portrait : `invp:P2` ne vaut que pour une édition.

## Composants

Ceux de la V1, aucun nouveau : `Section Header`, `Form / Group` (un par section), `Form / Labeled Value`,
`Form / Author Row`, `Form / Action Row`, `Note`, le chrome de feuille. `Form / Group` plafonne à six rangs, d'où
les rôles d'une œuvre en deux sections. Les glyphes des `Form / Action Row` sont teints en `VariableID:6:6` par
surcharge, comme dans `E1` (le composant les livre en noir).

## Tranché le 2026-10-28

- Tous les rôles d'une œuvre restent montrés, bande dessinée comprise, comme sur le site — pour le moment.
- Modifier une œuvre ou un·e auteur·ice touche toutes ses éditions ou œuvres : la note sous la première section le
  dit, sans avertissement de plus.
- Chaque écran a son « Enregistrer », plutôt qu'une seule sauvegarde au retour dans `E1` (ce que faisait `E5`).

---

# Le fond des formulaires — passe du 2026-10-27

En sombre, un formulaire était un fond `background/secondary` (`gray/800`) sous des cartes `background/default`
(noir) : des trous noirs dans une feuille grise. Il prend désormais le fond par défaut, noir, et ses cartes passent
en `gray/800` — la disposition des listes groupées d'iOS en sombre. Le clair ne change pas.

## Les deux variables

| Variable | id | Light | Dark | Code syntax iOS |
|---|---|---|---|---|
| `background/form` | `VariableID:779:10270` | alias `background/secondary` | alias `background/default` | `DesignSystem.Color.backgroundForm` |
| `background/form-cell` | `VariableID:779:10271` | alias `background/default` | alias `background/secondary` | `DesignSystem.Color.backgroundFormCell` |

Portées `FRAME_FILL`, `SHAPE_FILL`. **Exception à la convention des alias** : ce sont des alias vers deux
*sémantiques*, pas vers des primitives. Le rôle est « le fond secondaire en clair, le fond par défaut en sombre » ;
si l'un des deux bouge, le formulaire doit suivre. `background/form-cell` est nécessaire à `background/form` : sans
elle, les cartes restent `background/default` et disparaissent sur le fond noir.

## Ce qui est lié

- **Composants** (`Screens · Components`) : le fond de `Form / Group` (`702:520`) et le `contenu` de
  `Form / Swipe Row` (`757:608`) sont sur `background/form-cell`.
- **Écrans** : la frame `feuille` des écrans suivants est sur `background/form`, et chaque instance de
  `Form / Group` qui y surchargeait le fond est rebranchée sur `background/form-cell` (106 fonds de carte,
  contenus de `Form / Swipe Row` compris).
  - page `Scan et ajout` : `Nouveau livre · Tel que livré` (`L1` → `L8`), `Nouveau livre v2` (`V1` → `V13`) et
    `Nouveau livre v2 dark` (ses 13 frames, `777:*`) ;
  - page `Inventaire` : `Modifier l'édition · Toutes les données` (`E1` clair et sombre, `E2` → `E5`).
- Les 12 frames de `Nouveau livre v2 dark` qui héritaient le mode Dark de leur section l'épinglent désormais sur
  elles-mêmes, comme `V1` (`777:13442`) et `E1 · Dark` le faisaient déjà.

## Ce qui ne l'est pas

- **La `barre fixe (safeAreaInset)` et `Action Bar / Attached`** restent sur `background/default` : en sombre, la
  barre d'« Enregistrer » se fond dans le fond noir, comme dans l'app.
- **Les feuilles de `Doublons · ISBN et signalement`** (`A3`, `B2`, `B3`) : des feuilles, pas des formulaires, sans
  `Form / Group`.
- **« Modifier la liste »** (`ListFormView`) n'a pas de maquette ; c'est pourtant le premier formulaire où le fond
  sombre se voit.
- Les pages `Archive` et `Screens iPad`.

## Divergence

| # | Où | Constat | Statut |
|---|---|---|---|
| D-FF1 | `DesignSystem/Tokens/Color.swift` | `background/form` et `background/form-cell` sont nés dans Figma : le code peignait les formulaires avec `.applyListBackground()` (`background/secondary`) et des cellules au fond système | **résolue** le 2026-10-27 — `.backgroundForm` et `.backgroundFormCell` dans `Color.swift`, posés par `DesignSystem.Form` (`DesignSystem/List/DesignSystem+Form.swift`) sur les 13 `Form` de l'app et par `DesignSystem.FormList` sur les 6 `List` poussées depuis un formulaire (`WorkSearchView`, `AuthorPickerView`, `BibliographicDataHelpView`, `EntityPickerView`, `EditionEntityValuesView`, `IdentifierCatalogView`). Un rang qui pose son propre `listRowBackground` le garde (l'encart des données). Vu sur le simulateur, clair et sombre, sur « Create new list » et « Edit edition ». Dans le code, les deux couleurs nomment leurs colorsets au lieu d'aliaser les sémantiques |
| D-FF2 | `DesignSystem/Tokens/Color.swift` | Le 2026-10-27, en sombre, le code passe les formulaires à l'allure de la fiche livre — cartes un cran **sous** un fond `gray/800`, au lieu de cartes `gray/800` sur du noir — pendant que Figma aliasait encore `background/default` et `background/secondary`. Figma suit le même jour : `background/form` → `background/secondary` dans les deux modes, `background/form-cell` → `background/shade` en sombre, variable nouvelle (`784:14830`) : transparente en clair, `color/black-04` en sombre | **résolue** le 2026-10-27 — `.backgroundShade` dans `Color.swift` (`.black.opacity(0)` / `.black.opacity(0.4)`) ; `.backgroundFormCell` en sombre vaut le même voile, écrit en toutes lettres parce qu'une couleur dynamique imbriquée ne se résout pas. La fiche livre (`BookDetailView`, `BookResolvingView`) passe par `.backgroundForm` / `.backgroundFormCell` au lieu de `background/secondary` et du gris de cellule système. Vu sur le simulateur, clair et sombre, sur « Create new list » et la fiche livre |
| D-FF3 | Figma — `background/shade`, `background/form`, `background/form-cell` | `background/shade` a les scopes `ALL_SCOPES` (les autres `background/*` sont en `FRAME_FILL`, `SHAPE_FILL`) et pas de description. Les descriptions de `background/form` et `background/form-cell` disent encore « Dark: background/default » / « background/secondary » et « not yet in Color.swift » | ouverte — à corriger dans Figma |
| D-FF4 | `Features/Components/FormActionBar.swift` | Depuis le 2026-10-27, la barre fixe d'un formulaire (« Enregistrer » de « Modifier l'édition », « Nouvelle édition », la revue des doublons) n'a plus de fond : à partir d'iOS 26, une `safeAreaBar` au-dessus de l'effet de bord de défilement `.soft` du système, qui estompe le formulaire sous le bouton ; avant iOS 26, le `.thinMaterial` sous un filet, jusqu'au bord bas de l'écran. Plus de `background/default` : en sombre, le noir de la barre et de la zone sûre tranchait sur le fond `gray/800` du formulaire. `Action Bar / Attached` et les `barre fixe (safeAreaInset)` des maquettes sont encore sur `background/default` | ouverte — le code fait foi ; Figma n'a pas de variable pour un matériau, un flou d'arrière-plan sur la barre l'imiterait |

## Ce que la construction a appris

- **Une surcharge de fill sur une instance s'affiche avec sa couleur de base, résolue dans le mode du composant
  maître.** Lier `background/form-cell` sur les cartes d'un écran sombre les a laissées **blanches** : la base
  stockée était la valeur claire. La feuille, simple frame, s'est résolue en noir. Épingler le mode sur la frame
  n'a rien changé ; seule la base résolue en Dark (le `paint(token, MODES.Dark)` du préambule) corrige. Les écrans
  clairs et `E1 · Dark` sont sortis justes, ce dernier sans qu'on sache pourquoi : capturer chaque mode.

# Éditions · Filtre par langue — proposition du 2026-10-29

Une œuvre peut avoir des milliers d'éditions : *L'Appel de la forêt* en a 7 742 sur inventaire.io, et l'écran
« Éditions » les listait toutes. La proposition filtre la liste par langue, depuis l'en-tête de section. Section
`Éditions · Filtre par langue` (`831:7654`) sur la page `Inventaire`, sous `Modifier l'édition, l'œuvre et
l'auteur·ice · V2`. **Clair seul.** **Implémentée le même jour** ([feature
0058](../features/0058-editions-language-filter.md)).

| Frame | node id | Ce qu'elle montre |
|---|---|---|
| `L1 · Éditions · En français · Light` | `831:7657` | Clone de `C1 · Éditions · Doublons probables` (`770:4774`) : *L'Appel de la forêt*, cinq éditions françaises réelles (Nathan 1967 → Librairie générale française 1986), le libellé « Français » à droite de l'en-tête. Le bandeau des doublons est retiré, ses paires étant celles de Monte-Cristo |
| `L2 · Éditions · Choix de la langue · Light` | `831:7849` | Défilée (conteneur `scroll`, en-tête à y = 140), `Chrome / Menu Scrim` puis le menu `menu · langues` ancré sous le libellé : « Toutes les langues » (7 742), sept langues par nombre d'éditions, « Langue non renseignée » (5 613) |
| `Spec · Éditions · Filtre par langue` | `831:9045` | Le libellé, le menu, la valeur par défaut, ce que le filtre touche, les données, quatre points à trancher |

Le menu `menu · langues` est un frame brut qui reprend le fond, le rayon 13 et l'ombre de `Chrome / Menu Panel`
Light (valeurs brutes, comme le composant) : le panneau n'a que quatre rangs à slots, il en faut neuf et deux
séparateurs de section.

## Composants

| Composant | node id | Changement |
|---|---|---|
| `Chrome / Menu Row · Choice` | `830:23605` | **Nouveau.** Une entrée de Picker dans un Menu : place de coche de 20 gardée même éteinte (libellés alignés), `Label`, `Detail` (le compte, style et couleur du titre de `Chrome / Menu Panel · Section`), `Show detail`, `Selected`. Un seul composant, sans variante `Theme` : textes bindés aux variables |
| `Section Header` | `28:164` | **Étendu, éteint par défaut.** Un `Trailing glyph` après le libellé de l'action (16 pt, trait `foreground/tinted`), avec `Show trailing glyph` (false), `Trailing glyph` (INSTANCE_SWAP, `chevron.up.chevron.down`) et `Show leading glyph` (true). Le `Label` se tronque en fin de ligne, sur une ligne. Les instances existantes ne bougent pas |
| `Icon` | `21:60` | **36 variantes** : `checkmark` (`830:651`), la coche de `checkmark.circle` sans le cercle, agrandie à 14 × 10 |

## Ce que la construction a appris

- **Un glyphe de 12 pt au trait 1,8 ne lit plus `chevron.up.chevron.down`** : les deux chevrons (4 × 2) se fondent
  en un point. Le glyphe de queue est à 16.
- **`resize()` repasse un composant en hauteur fixe** : la rangée `Choice` faisait 45 et ses textes débordaient ;
  `counterAxisSizingMode = "AUTO"` après le redimensionnement.

## Écarts du code — 2026-10-29

| # | Où | Constat | Statut |
|---|---|---|---|
| D-LF1 | `Features/EntityBrowser/Work/EditionLanguageMenu.swift` | Le menu est celui d'iOS (matière, police système, coche, comptes en sous-titre) : `Chrome / Menu Row · Choice` et `menu · langues` n'en sont qu'une figure | ouverte — le code fait foi |
| D-LF2 | idem | Le glyphe du libellé est `chevron.up.chevron.down` en `.imageScale(.small)`, pas le `Trailing glyph` de 16 pt | ouverte |

