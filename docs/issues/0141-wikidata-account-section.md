# 0141 — Relier son compte Wikidata depuis Compte et connexion

Parent: docs/prd/0141-wikidata-account-and-editing.md
Blocked by: —
Type: AFK

Section « Wikidata » (W1 / W3), feuille de connexion (W2), `enabledOAuth` lu.

## Acceptance

- [ ] `AccountSettings.linksWikidata` vient d'`enabledOAuth`
- [ ] W1 non relié, W3 relié
- [ ] la feuille porte la session, se ferme au retour, l'app relit `GET /api/user`
- [ ] tests de `WikidataOAuthFlow` et de la lecture
