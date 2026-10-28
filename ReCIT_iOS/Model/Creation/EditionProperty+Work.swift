//
//  EditionProperty+Work.swift
//  ReCIT_iOS
//
//  What inventaire.io accepts on a work, read on 2026-10-28 from `GET /api/data/properties` (the
//  `subjectTypes` that hold `work`), `GET /api/data/property-values` (the values allowed for its
//  type and its form) and `properties_values_constraints.ts` (the identifiers' patterns, a work's
//  own where they differ from an edition's). « Modifier l'œuvre », Figma `W1` (`815:6686`).
//
//  Left out, as the website leaves them out: `invp:P1` and `invp:P3`. A work's title is not a
//  claim but a label per language, and its picture is its editions'.
//

import Foundation

extension EditionProperty {

    // MARK: - L'œuvre

    static let workType: EditionProperty = .init(
        uri: "wdt:P31",
        kind: .choice([
            .init(uri: "wd:Q7725634", label: "work_type.literary_work"),
            .init(uri: "wd:Q47461344", label: "work_type.written_work"),
            .init(uri: "wd:Q1004", label: "work_type.comic"),
            .init(uri: "wd:Q725377", label: "work_type.graphic_novel"),
            .init(uri: "wd:Q8274", label: "work_type.manga"),
            .init(uri: "wd:Q562214", label: "work_type.manhwa")
        ]),
        group: .general,
        isMultivalued: false,
        label: "entity_property.work_type"
    )

    static let workForm: EditionProperty = .init(
        uri: "wdt:P7937",
        kind: .choice([
            .init(uri: "wd:Q8261", label: "work_form.novel"),
            .init(uri: "wd:Q149537", label: "work_form.novella"),
            .init(uri: "wd:Q49084", label: "work_form.short_story"),
            .init(uri: "wd:Q472808", label: "work_form.novelette"),
            .init(uri: "wd:Q25379", label: "work_form.play"),
            .init(uri: "wd:Q5185279", label: "work_form.poem"),
            .init(uri: "wd:Q35760", label: "work_form.essay"),
            .init(uri: "wd:Q384515", label: "work_form.treatise"),
            .init(uri: "wd:Q193495", label: "work_form.monograph"),
            .init(uri: "wd:Q1266946", label: "work_form.thesis"),
            .init(uri: "wd:Q49850", label: "work_form.journal"),
            .init(uri: "wd:Q185598", label: "work_form.diary"),
            .init(uri: "wd:Q1279564", label: "work_form.short_story_collection"),
            .init(uri: "wd:Q12106333", label: "work_form.poetry_collection"),
            .init(uri: "wd:Q27560760", label: "work_form.fairy_tale_collection"),
            .init(uri: "wd:Q65085460", label: "work_form.letter_collection"),
            .init(uri: "wd:Q133500522", label: "work_form.novel_collection"),
            .init(uri: "wd:Q20024995", label: "work_form.novella_collection"),
            .init(uri: "wd:Q111180384", label: "work_form.novelette_collection"),
            .init(uri: "wd:Q105420", label: "work_form.anthology"),
            .init(uri: "wd:Q125544547", label: "work_form.short_story_anthology"),
            .init(uri: "wd:Q19357149", label: "work_form.poetry_anthology"),
            .init(uri: "wd:Q5456296", label: "work_form.fix_up"),
            .init(uri: "wd:Q725377", label: "work_form.graphic_novel"),
            .init(uri: "wd:Q642946", label: "work_form.gamebook"),
            .init(uri: "wd:Q23622", label: "work_form.dictionary"),
            .init(uri: "wd:Q5292", label: "work_form.encyclopedia"),
            .init(uri: "wd:Q83790", label: "work_form.textbook"),
            .init(uri: "wd:Q2352616", label: "work_form.catalog"),
            .init(uri: "wd:Q780605", label: "work_form.exhibition_catalogue"),
            .init(uri: "wd:Q1143604", label: "work_form.conference_proceedings")
        ]),
        group: .general,
        isMultivalued: false,
        label: "entity_property.work_form"
    )

    static let originalLanguage: EditionProperty = .init(uri: "wdt:P407", kind: .entity(.languages), group: .general, isMultivalued: true, label: "entity_property.original_language")
    static let firstPublicationDate: EditionProperty = .init(uri: "wdt:P577", kind: .date, group: .general, isMultivalued: false, label: "entity_property.first_publication_date")

    // MARK: - Who made it

    static let author: EditionProperty = person("wdt:P50", "entity_property.author", group: .authors)

    static let workRoles: [EditionProperty] = [
        person("wdt:P58", "entity_property.scenarist", group: .roles),
        person("wdt:P110", "edition_property.illustrator", group: .roles),
        person("wdt:P98", "edition_property.editor", group: .roles)
    ]

    static let comicRoles: [EditionProperty] = [
        person("wdt:P10837", "entity_property.penciller", group: .comics),
        person("wdt:P10836", "entity_property.inker", group: .comics),
        person("wdt:P6338", "entity_property.colorist", group: .comics),
        person("wdt:P9191", "entity_property.letterer", group: .comics)
    ]

    // MARK: - Series, genre, relations

    static let series: EditionProperty = .init(uri: "wdt:P179", kind: .entity(.series), group: .series, isMultivalued: true, label: "entity_property.series")
    static let seriesOrdinal: EditionProperty = .init(uri: "wdt:P1545", kind: .ordinal, group: .series, isMultivalued: false, label: "entity_property.series_ordinal")

    static let genre: EditionProperty = .init(uri: "wdt:P136", kind: .entity(.genres), group: .subjects, isMultivalued: true, label: "entity_property.genre")
    /// Any entity on the server; `/api/search` has no type for a subject, so the search looks
    /// among those a subject usually is.
    static let mainSubject: EditionProperty = .init(uri: "wdt:P921", kind: .anyEntity([.genres, .movements, .humans, .works]), group: .subjects, isMultivalued: true, label: "entity_property.main_subject")

    static let workRelations: [EditionProperty] = [
        .init(uri: "wdt:P144", kind: .anyEntity([.works, .series]), group: .relations, isMultivalued: true, label: "entity_property.based_on"),
        .init(uri: "wdt:P941", kind: .anyEntity([.works, .series]), group: .relations, isMultivalued: true, label: "entity_property.inspired_by"),
        .init(uri: "wdt:P1433", kind: .entity(.works), group: .relations, isMultivalued: true, label: "entity_property.published_in"),
        .init(uri: "wdt:P2675", kind: .anyEntity([.works, .series]), group: .relations, isMultivalued: true, label: "entity_property.reply_to")
    ]

    // MARK: - Databases, links, misc

    static let workDatabases: [EditionProperty] = [
        database("wdt:P268", "edition_property.bnf", #"^\d{8}[0-9bcdfghjkmnpqrstvwxz]$"#, "123735831"),
        database("wdt:P269", "entity_property.idref", #"^\d{8}[\dX]$"#, "026927608"),
        database("wdt:P3631", "entity_property.babelio", #"^\d+$"#, "3874"),
        database("wdt:P648", "edition_property.open_library", #"^OL[1-9]\d{0,7}W$"#, "OL36858W"),
        database("wdt:P8383", "edition_property.goodreads", #"^[1-9]\d*$"#, "556821"),
        database("wdt:P10100", "entity_property.senscritique", #"^[1-9]\d*$"#, "26922520"),
        database("wdt:P214", "edition_property.viaf", #"^[1-9]\d(\d{0,7}|\d{17,20})$"#, "120062731"),
        database("wdt:P227", "edition_property.gnd", #"^1[01]?\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]$"#, "4079154-3"),
        database("wdt:P243", "edition_property.oclc", #"^0*[1-9]\d*$"#, "57722711"),
        database("wdt:P5331", "entity_property.oclc_work", #"^[1-9]\d*$"#, "203314739"),
        database("wdt:P244", "entity_property.library_of_congress", #"^(gf|n|nb|nr|no|ns|sh|sj)([4-9][0-9]|00|20[0-2][0-9])[0-9]{6}$"#, "n79022935"),
        database("wdt:P950", "edition_property.bne", #"^XX\d{4,7}$"#, "XX1718747"),
        database("wdt:P1085", "entity_property.librarything", #"^\d{1,8}$"#, "337646"),
        database("wdt:P1274", "edition_property.isfdb", #"^[1-9]\d{0,6}$"#, "68494"),
        database("wdt:P5571", "edition_property.noosfere", #"^[1-9]\d*$"#, "4638"),
        database("wdt:P6221", "entity_property.noosfere_story", #"^[1-9]\d*$"#, "3640"),
        database("wdt:P7823", "edition_property.bookbrainz", #"[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}"#, "9e631014-cc9a-4ae9-8abb-90b49424db11"),
        database("wdt:P1984", "entity_property.anime_news_network", #"^[1-9]\d*$"#, "2440"),
        database("wdt:P4087", "entity_property.myanimelist", #"^\d+$"#, "46024"),
        database("wdt:P11308", "entity_property.grand_comics_database", #"^[1-9]\d*$"#, "52303")
    ]

    static let workDifferentFrom: EditionProperty = .init(uri: "wdt:P1889", kind: .anyEntity([.works, .series]), group: .misc, isMultivalued: true, label: "entity_property.different_from")

    /// Every property of a work, in the order « Modifier l'œuvre » shows them. A work's links
    /// are an edition's ten.
    static let workProperties: [EditionProperty] = [workType, workForm, originalLanguage, firstPublicationDate, author]
        + workRoles + comicRoles + [series, seriesOrdinal, genre, mainSubject] + workRelations
        + workDatabases + links + [workDifferentFrom]
}
