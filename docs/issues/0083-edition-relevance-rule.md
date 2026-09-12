Title: `EditionRelevance` — la règle qui choisit une édition, en type pur
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-search-results-are-editions.md` — [ADR 0002, Move 3](../adr/0002-unified-book-detail.md)

## What to build

La règle de pertinence, seule, sans réseau et sans SwiftData. C'est la première issue parce que
c'est la seule décision de cette feature qui mérite d'être prouvée : tout le reste est du câblage.

`ReCIT_iOS/Model/Books/EditionRelevance.swift`, sur le patron d'`InventorySearchRanking` — un
`Candidate` réduit à ce dont le classement a besoin, et une fonction qui rend le gagnant :

```swift
enum EditionRelevance {
    struct Candidate: Equatable, Identifiable, Sendable {
        let id: String          // l'uri de l'édition
        let lang: String?       // "fr", "en", … résolu depuis wdt:P407
        let hasTitle: Bool      // wdt:P1476 présent et non vide
        let hasCover: Bool      // invp:P2 / image présente
        let isHeld: Bool        // un InventoryItem local, à moi ou à un ami
        let isSingleWork: Bool  // wdt:P629 ne nomme qu'une œuvre — un roman, pas un coffret
    }

    static func best(
        among candidates: [Candidate],
        preferredLang: String,
        originalLang: String?
    ) -> Candidate?
}
```

L'échelle, le premier palier non vide gagnant :

1. `lang == preferredLang` && `hasTitle` && `hasCover`
2. `lang == preferredLang` && `hasTitle`
3. `lang == originalLang` && `hasTitle` && `hasCover`
4. `hasTitle`

**Pas de cinquième palier.** Sous le titre il n'y a plus rien : un candidat sans nom n'est jamais
une cible de redirection, puisqu'il s'afficherait `Unknown`. `best` rend `nil`, et l'appelant
dessine une absence.

**Deux départages à l'intérieur du palier retenu, dans cet ordre.** D'abord `isSingleWork`
(`wdt:P629` ne nomme qu'une œuvre) : un livre seul avant un coffret, parce que « Harry Potter et la
Chambre des Secrets » ouvrait *Harry Potter, coffret 4 volumes*. Il restreint sans exclure — si tout
le palier est fait de coffrets, un coffret gagne. Ensuite `isHeld`.

**`isHeld` ne trie qu'à l'intérieur du palier retenu.** Il ne fait jamais monter un candidat d'un
palier au suivant — c'est l'arbitrage explicite du PRD, et c'est la propriété la plus facile à
casser par accident. À départage égal, l'ordre d'entrée décide, pour que la fonction soit
déterministe.

`hasTitle` est volontairement un booléen et **pas** une comparaison avec le titre de l'œuvre : cette
comparaison rejette `Dune, Tome 1` et toutes les traductions légitimes. Voir le PRD, section
Solution.

Il se calcule par `EditionTitle.resolve(labels:claims:)`, **la même résolution que `Edition` utilise
pour se nommer** — `labels.fromclaims`, puis `labels.mul`, puis la revendication `wdt:P1476`. Lire
la revendication seule fait diverger le classement de l'affichage pour 13 % des éditions (66 sur
513 sondées, toutes des entités `wd:`) : classées titrées, dessinées `Unknown`.

## Acceptance criteria

- [ ] `EditionRelevance` ne dépend ni de `Foundation` au-delà du strict nécessaire, ni de SwiftData,
      ni d'`APIServicing`
- [ ] `EditionRelevanceTests` a un cas nommé par palier, dans l'ordre
- [ ] Un cas prouve qu'un livre seul gagne contre un coffret du même palier
- [ ] Un cas prouve qu'un coffret gagne quand le palier n'a que des coffrets
- [ ] Un cas prouve que `isSingleWork` est consulté **avant** `isHeld`
- [ ] Un cas prouve qu'un candidat `isHeld` gagne **dans** son palier
- [ ] Un cas prouve qu'un candidat `isHeld` d'un palier inférieur **ne gagne pas** contre un palier
      supérieur — l'exemplaire espagnol d'un ami contre vingt éditions françaises
- [ ] Un cas couvre `candidates.isEmpty` → `nil`
- [ ] Un cas couvre « aucun candidat avec titre » → `nil`, et pas un candidat sans nom
- [ ] Un cas couvre « un seul candidat nommé parmi des anonymes » → c'est lui qui gagne
- [ ] `EditionTitle` a sa propre suite : `fromclaims`, `mul`, `wdt:P1476`, et l'absence des trois
- [ ] Un cas couvre `originalLang == nil`
- [ ] La fonction est déterministe : même entrée, même sortie, deux appels de suite
- [ ] `xcodebuild -scheme ReCIT_iOSTests` passe

## Blocked by

None - can start immediately
