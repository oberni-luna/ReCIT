//
//  AutoSortMappingDraft.swift
//  ReCIT_iOS
//
//  Phase 2's output as the model produces it: one line per genre saying which
//  étagère it belongs on. Unchecked — the étagère name is free text here, and the
//  validator is what turns it into something a plan may use.
//
//  The schema deliberately does *not* constrain the étagère to an enumeration of
//  phase 1's names, which a dynamic schema could do. Constraining it would hide a
//  hallucinating model rather than catch one, and the guarantee this feature rests
//  on is the validator's, not the decoder's — so the failure has to stay visible.
//  See PRD 0006.
//

import FoundationModels

@Generable(description: "Le rangement de chaque genre dans une étagère.")
struct AutoSortMappingDraft {

    @Generable(description: "Un genre et l'étagère où il est rangé.")
    struct Entry {
        @Guide(description: "Le genre, recopié exactement tel qu'il a été fourni.")
        var genre: String

        @Guide(description: "Le nom de l'étagère choisie, recopié exactement depuis la liste fournie.")
        var etagere: String
    }

    @Guide(description: "Une entrée par genre fourni, sans en oublier aucun et sans en ajouter.")
    var affectations: [Entry]
}
