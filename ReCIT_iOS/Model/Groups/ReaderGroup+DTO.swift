//
//  ReaderGroup+DTO.swift
//  ReCIT_iOS
//

import Foundation

extension ReaderGroup {
    /// - Parameter pictureURL: The document's `picture`, already made absolute — it is served as
    ///   `/img/groups/<hash>` on inventaire.io.
    init(dto: GroupDTO, pictureURL: String?) {
        self.init(
            id: dto._id,
            name: dto.name,
            slug: dto.slug,
            description: dto.description ?? "",
            pictureURL: pictureURL,
            searchable: dto.searchable ?? true,
            open: dto.open ?? false,
            admins: dto.admins,
            members: dto.members,
            invited: dto.invited ?? [],
            declined: dto.declined ?? [],
            requested: dto.requested ?? []
        )
    }
}
