//
//  RecentPublicItemsDTO.swift
//  ReCIT_iOS
//
//  What `GET /api/items/recent-public` answers, read down to the one field the wall needs: the
//  cover path of each item.
//
//  Deliberately **not** `ItemsDTO`. That one is the inventory's item, with its revision, its
//  owner, its transaction and a required title — everything the app needs to own a book. The
//  wall needs a jacket, from a feed it does not control, on the screen shown before anyone has
//  signed in: a missing `_rev` or an item whose snapshot has no title would fail the whole
//  decode and empty the screen. Every field here is optional for that reason.
//
//  See PRD 0011.
//

import Foundation

struct RecentPublicItemsDTO: Codable {
    let items: [RecentPublicItemDTO]?
}

struct RecentPublicItemDTO: Codable {
    let snapshot: RecentPublicSnapshotDTO?
}

struct RecentPublicSnapshotDTO: Codable {
    let `entity:image`: String?
}
