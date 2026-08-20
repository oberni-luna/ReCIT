//
//  AutoSortPrompts.swift
//  ReCIT_iOS
//
//  Every word the model is shown, in one place, because prompt tuning is expected
//  to take several rounds and hunting it through an orchestrator would make that
//  miserable.
//
//  Written in French so the étagère names come out French — the shelves have to sit
//  alongside ones the user named themselves. Nothing here contains a book: the
//  taxonomy prompt shows genres and counts, the mapping prompt shows genres and
//  étagère names, and that is the whole reason a library of any size fits in a few
//  thousand tokens.
//
//  Pure string building, so what the model reads can be inspected without running
//  it. See PRD 0006.
//

import Foundation

enum AutoSortPrompts {

    /// The librarian framing, set once per session rather than repeated in each
    /// prompt so the two phases share it.
    static let instructions: String = """
    Tu es bibliothécaire et tu conçois les rayonnages d'une bibliothèque personnelle.
    Tu réponds toujours en français, sans commentaire ni explication.
    """

    /// How many étagères to ask for, given how many distinct genres there are.
    ///
    /// A single figure rather than a range, and stated as an order rather than a
    /// suggestion. Asked for a range the model reliably takes the loosest possible
    /// reading and returns one étagère per genre — measured on a synthetic French
    /// library, three runs out of three — which is the outcome this whole design
    /// exists to prevent. Roughly half the genre count, so merging is not optional:
    /// the arithmetic itself forces genres to share a shelf.
    ///
    /// Floored at three so a two-genre library still gets a taxonomy rather than a
    /// tautology, and capped at eight because past that the bookshelf screen stops
    /// reading as a bookshelf.
    static func shelfCount(genreCount: Int) -> Int {
        min(8, max(3, (genreCount + 1) / 2))
    }

    /// Phase 1. The counts are the working part: they are what lets the model fold a
    /// three-book genre into a broader étagère instead of proposing a three-book one.
    ///
    /// The shelf budget leads rather than trailing a list of rules, and the fact that
    /// there are more genres than shelves is said out loud — a small model asked
    /// politely to merge simply does not, but told that merging is arithmetically
    /// unavoidable it does.
    ///
    /// The naming rule is phrased positively, with examples, and that phrasing was
    /// arrived at the hard way. Forbidden only from *copying the genre list*, the
    /// model produced a taxonomy of vague near-synonyms — "Livres de rêve", "Livres
    /// pour tous" — and in one run a single "Diverses" étagère holding a hundred and
    /// fifty books, which is a taxonomy of one. Naming the vague words to ban them
    /// made it worse still: told not to say "Divers" it said "Divers" on three
    /// shelves out of five. A small model does not reliably invert a negation, so the
    /// rule now says what a good name *is* and shows three, and the cap on any one
    /// shelf holding half the collection carries the rest of the weight.
    static func taxonomyPrompt(histogram: GenreHistogram) -> String {
        let lines: String = histogram.entries
            .map { "- \($0.genre) : \($0.count) livre\($0.count > 1 ? "s" : "")" }
            .joined(separator: "\n")
        let genreCount: Int = histogram.entries.count
        let target: Int = shelfCount(genreCount: genreCount)

        return """
        Voici les \(genreCount) genres présents dans les livres non rangés de cette bibliothèque, avec le nombre de livres pour chacun :
        \(lines)

        Propose exactement \(target) étagères pour ranger tous ces livres, pas une de plus.
        Il y a \(genreCount) genres pour \(target) étagères : plusieurs genres devront donc partager la même étagère.

        Règles :
        - Regroupe sous un même nom, plus large, les genres qui se ressemblent.
        - Un genre qui compte beaucoup de livres peut garder une étagère pour lui seul, et lui donner son nom.
        - Un genre qui ne compte que quelques livres ne doit jamais avoir son étagère : il rejoint une étagère plus large.
        - Aucune étagère ne doit contenir plus de la moitié des livres.
        - Chaque étagère rassemble des genres qui ont quelque chose en commun, et son nom dit lequel.
        - Chaque genre de la liste doit pouvoir aller dans une des étagères proposées.
        - Les noms sont en français, de deux à quatre mots, et sonnent comme les panneaux d'un rayon de librairie.
        """
    }

    /// Phase 2, one batch of genres at a time. The étagère list is repeated in every
    /// batch so each call is answerable on its own — the closed list is the whole
    /// point, and a batch that could not see it would invent its own names, which is
    /// precisely the failure chunking the *books* would have caused.
    static func mappingPrompt(genres: [String], shelfNames: [String]) -> String {
        let shelves: String = shelfNames.map { "- \($0)" }.joined(separator: "\n")
        let list: String = genres.map { "- \($0)" }.joined(separator: "\n")

        return """
        Voici les étagères disponibles :
        \(shelves)

        Range chacun des genres suivants dans exactement une de ces étagères :
        \(list)

        Règles :
        - Recopie le nom de l'étagère à l'identique depuis la liste ci-dessus. N'invente aucun nom d'étagère.
        - Recopie le genre à l'identique.
        - Une entrée par genre, sans en oublier et sans en ajouter.
        """
    }
}
