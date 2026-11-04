# Remplissage automatique des mots de passe — fichier à héberger sur inventaire.io

Pour qu'iOS propose dans l'app le mot de passe qu'un utilisateur a enregistré depuis le site
`inventaire.io`, Apple exige que **le domaine déclare l'app**. C'est une association à sens unique :
l'app dit à quel domaine elle se rattache (entitlement, côté app), et le domaine dit quelle app il
autorise (ce fichier, côté serveur). Sans les deux moitiés, rien ne se passe — et l'échec est
silencieux.

Ce fichier est la moitié serveur. Il est à déposer par l'équipe inventaire.io.

## L'URL

Le fichier doit être lisible à **exactement** cette adresse :

```
https://inventaire.io/.well-known/apple-app-site-association
```

Contraintes d'Apple, toutes obligatoires :

| Contrainte | Détail |
|---|---|
| **HTTPS** | Certificat valide. Pas de HTTP. |
| **Aucune redirection** | L'URL doit répondre `200` directement. Une redirection, même vers la bonne ressource, invalide l'association. |
| **Pas d'extension** | Le fichier s'appelle `apple-app-site-association`, **sans** `.json`. |
| **`Content-Type: application/json`** | Servi comme du JSON, même sans extension. |
| **Pas d'authentification** | La ressource doit être publique. |
| **Chemin exact** | `/.well-known/apple-app-site-association`. La variante à la racine (`/apple-app-site-association`) est dépréciée. |

Vérification une fois en place :

```bash
curl -sSI https://inventaire.io/.well-known/apple-app-site-association
```

Attendu : `HTTP/2 200`, `content-type: application/json`, et **aucun** `location:`.

## Le contenu

Le fichier `apple-app-site-association` de ce dossier, à copier tel quel :

```json
{
  "webcredentials": {
    "apps": [
      "VH79XGK7M2.studio.lunabee.nouveau-recit"
    ]
  }
}
```

La chaîne est un **App ID** : `<Team ID>.<Bundle ID>`.

- Team ID `VH79XGK7M2` — l'équipe Apple Developer de la cible applicative.
- Bundle ID `studio.lunabee.nouveau-recit`.

⚠️ **Si l'app est un jour publiée depuis une autre équipe Apple, ou si son bundle id change, cette
chaîne doit changer avec.** Le projet contient d'ailleurs un second Team ID (`WP5UTYKSQ4`) sur les
cibles de test : ce n'est **pas** celui à utiliser ici.

Si le domaine sert déjà un `apple-app-site-association` (pour des liens universels, par exemple), il
ne faut pas l'écraser : ajouter la clé `webcredentials` à côté des clés existantes.

```json
{
  "applinks": { "…": "… ce qui existe déjà, inchangé …" },
  "webcredentials": {
    "apps": ["VH79XGK7M2.studio.lunabee.nouveau-recit"]
  }
}
```

## Côté app

À faire de notre côté, une fois le fichier en ligne : ajouter la capacité **Associated Domains** à la
cible et y déclarer

```
webcredentials:inventaire.io
```

Apple met le fichier en cache via son CDN. Compter un délai avant que l'association prenne effet, et
tester sur un appareil réel — le simulateur ne valide pas toujours les domaines associés.

## Ce que ça change, et ce que ça ne change pas

**Ça change** : le mot de passe enregistré sur le site est proposé au-dessus du clavier dans l'app,
et le mot de passe créé dans l'app est proposé sur le site.

**Ça ne change pas** : rien dans l'authentification elle-même. Sans ce fichier, l'app fonctionne à
l'identique — les indices de champ `textContentType` font déjà que le trousseau propose les
identifiants **enregistrés depuis l'app**. Le fichier ne sert qu'à faire le pont avec ceux du site.
