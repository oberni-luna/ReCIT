//
//  Entity.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation
import SwiftData

@Model
public class Work: Identifiable {
    @Attribute(.unique) var uri: String

    var title: String
    var subtitle: String?
    var lang: String?
    var authors: [String]
    var image: String?
    var series: String?
    var editions: [Edition]

    init(uri: String, title: String, subtitle: String? = nil, lang: String?, authors: [String], image: String? = nil, series: String? = nil) {
        self.uri = uri
        self.title = title
        self.subtitle = subtitle
        self.lang = lang
        self.authors = authors
        self.image = image
        self.series = series
        self.editions = []
    }
}

/*

 wdt:P31 : instance of
 wdt:P136 : genre
 wdt:P577 : publication date
 wdt:P648 : Open Library ID
 wdt:P50 : Author
 wdt:P212 : ISBN-13
 wdt:P957 : ISBN-10
 wdt:P407 : language of work or name // useless
 wdt:P1476 : title
 wdt:P629 : edition or translation of
 wdt:P123 : publisher
 wdt:P195 : collection
 wdt:P1104 : number of pages
 wdt:P2969 : Goodreads version/edition ID
 wdt:P179 : series

 wdt:P213 : International Standard Name Identifier for an identity.
 wdt:P214 : Virtual International Authority File database
 wdt:P227 : identifier from an international authority file of names, subjects, and organizations

 wdt:P569 : date of birth
 wdt:P570 : date of death
 wdt:P856 : official website
 wdt:P106 : occupation
 wdt:P166 : award received

 wdt:P18 : image
 wdt:P69 : educated at
 wdt:P106 : occupation
 wdt:P109 : signature

 https://inventaire.io/api/items?action=by-ids&ids=1bfebff48fdd52cb6f6f24a15e1b89a8|ceec13136b4ac90974fc0e0ddb27bf10|1e581c0c77d9cd3989a5af39054243a0|1e581c0c77d9cd3989a5af39054236fe|1e581c0c77d9cd3989a5af3905422223|049a5d616589c7d82d7e3ca3e0be5b5a|049a5d616589c7d82d7e3ca3e0be350c|049a5d616589c7d82d7e3ca3e0ad2ac6|049a5d616589c7d82d7e3ca3e0ac987f|049a5d616589c7d82d7e3ca3e0ac53b3|049a5d616589c7d82d7e3ca3e0a1f7a9|049a5d616589c7d82d7e3ca3e0a1e9ec|049a5d616589c7d82d7e3ca3e0a1e52f|049a5d616589c7d82d7e3ca3e0a1daed|049a5d616589c7d82d7e3ca3e092eeea|049a5d616589c7d82d7e3ca3e092e642|049a5d616589c7d82d7e3ca3e092d71f|049a5d616589c7d82d7e3ca3e08d2d0b|049a5d616589c7d82d7e3ca3e0404b6b|049a5d616589c7d82d7e3ca3e04048c2&include-users=true

 */



