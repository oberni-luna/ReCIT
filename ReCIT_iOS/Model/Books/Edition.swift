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
    var authorNames: [String]
    var image: String?
    var series: String?
    var works: [Work] = []

    @Relationship(deleteRule: .nullify, inverse: \InventoryItem.edition) var items: [InventoryItem] = []
    
    init(uri: String, title: String, subtitle: String? = nil, lang: String?, authorNames: [String], image: String? = nil, series: String? = nil, items: [InventoryItem] = []) {
        self.uri = uri
        self.title = title
        self.subtitle = subtitle
        self.lang = lang
        self.authorNames = authorNames
        self.image = image
        self.series = series
    }

    convenience init(uri: String, entitySnapshotDTO: EntitySnapshotDTO, baseUrl: String, works: [Work] = [], items: [InventoryItem] = []) {
        self.init(
            uri: uri,
            title: entitySnapshotDTO.`entity:title`,
            subtitle: entitySnapshotDTO.`entity:subtitle`,
            lang: entitySnapshotDTO.`entity:lang`,
            authorNames: entitySnapshotDTO.`entity:authors`?.components(separatedBy: ",") ?? [],
            image: entitySnapshotDTO.`entity:image` != nil ? "\(baseUrl)\(entitySnapshotDTO.`entity:image` ?? "")" : nil,
            series: entitySnapshotDTO.`entity:series`
        )
    }
}
