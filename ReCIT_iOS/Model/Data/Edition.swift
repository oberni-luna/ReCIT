//
//  Entity.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation
import SwiftData

@Model
public class Edition: Identifiable {
    @Attribute(.unique) var uri: String

    var title: String
    var subtitle: String?
    var lang: String?
    var authors: [String]
    var image: String?
    var series: String?

    init(uri: String, title: String, subtitle: String? = nil, lang: String?, authors: [String], image: String? = nil, series: String? = nil) {
        self.uri = uri
        self.title = title
        self.subtitle = subtitle
        self.lang = lang
        self.authors = authors
        self.image = image
        self.series = series
    }

    convenience init(uri: String, entitySnapshotDTO: EntitySnapshotDTO, baseUrl: String) {
        self.init(
            uri: uri,
            title: entitySnapshotDTO.`entity:title`,
            subtitle: entitySnapshotDTO.`entity:subtitle`,
            lang: entitySnapshotDTO.`entity:lang`,
            authors: entitySnapshotDTO.`entity:authors`?.components(separatedBy: ",") ?? [],
            image: entitySnapshotDTO.`entity:image` != nil ? "\(baseUrl)\(entitySnapshotDTO.`entity:image` ?? "")" : nil,
            series: entitySnapshotDTO.`entity:series`
        )
    }
}
