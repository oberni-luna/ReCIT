//
//  EditionEdit.swift
//  ReCIT_iOS
//
//  What the reader has changed in « Modifier l'édition », and what that comes to on the wire. A
//  value type with no opinion about the network: the form fills it, `EntityCreationModel` sends
//  the updates it lists, and tells it which ones landed.
//
//  **A change half sent is finished, not redone.** Each claim is its own request, so a title can
//  land and a cover fail. `landed(_:)` moves `original` to what the server now holds, and the
//  retry lists only what is left — sending the title again would name, as the value it
//  replaces, a title the edition no longer has.
//

import Foundation

struct EditionEdit: Equatable, Sendable {

    /// What became of the cover since the form opened.
    enum Cover: Equatable, Sendable {
        case unchanged
        /// A new picture, as JPEG bytes, not yet hung on the edition.
        case replaced(Data)
        /// The edition's picture taken away.
        case removed
    }

    /// The edition as the server holds it — when the form opened, then after each change that
    /// landed.
    private(set) var original: EditionClaims

    var title: String
    var subtitle: String
    private(set) var cover: Cover = .unchanged

    /// The picture the edition had when the form opened, downloaded to fill the cover frame.
    /// `nil` when it has none, and when the download failed — the frame then offers to add one,
    /// which replaces it.
    var originalCoverData: Data?

    /// The hash a replacing picture was filed under, once uploaded: a retry hangs it on the
    /// edition without sending the same picture twice.
    var uploadedCoverHash: String?

    init(
        original: EditionClaims,
        originalCoverData: Data? = nil
    ) {
        self.original = original
        self.originalCoverData = originalCoverData
        title = original.title
        subtitle = original.subtitle ?? ""
    }

    /// The picture the cover frame shows, and the binding it writes through: a picture set
    /// replaces the edition's, none removes it.
    var coverData: Data? {
        get {
            switch cover {
            case .unchanged: originalCoverData
            case .replaced(let data): data
            case .removed: nil
            }
        }
        set {
            uploadedCoverHash = nil
            if let newValue {
                cover = .replaced(newValue)
            } else {
                // Taking away a picture the edition never had changes nothing.
                cover = original.coverHash == nil ? .unchanged : .removed
            }
        }
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSubtitle: String {
        subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var originalTitle: String {
        original.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var originalSubtitle: String {
        (original.subtitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasChanges: Bool {
        trimmedTitle != originalTitle || trimmedSubtitle != originalSubtitle || cover != .unchanged
    }

    /// Whether there is something to send, and it can be sent. An edition without a title is
    /// unreadable in every list it appears in, so the title cannot be emptied.
    var isSaveable: Bool {
        trimmedTitle.isEmpty == false && hasChanges
    }

    /// The picture to upload before the cover's claim can be sent: a replacing one whose hash
    /// is not known yet.
    var coverToUpload: Data? {
        guard case .replaced(let data) = cover, uploadedCoverHash == nil else { return nil }
        return data
    }

    /// The claims to send, in order: title, subtitle, cover. A replacing cover is listed once its
    /// hash is known, which takes the upload first.
    var claimUpdates: [EditionClaimUpdate] {
        var updates: [EditionClaimUpdate] = []

        if trimmedTitle != originalTitle {
            updates.append(update(.title, from: original.title, to: trimmedTitle))
        }

        if trimmedSubtitle != originalSubtitle {
            updates.append(update(.subtitle, from: original.subtitle, to: trimmedSubtitle))
        }

        switch cover {
        case .replaced:
            if let uploadedCoverHash {
                updates.append(update(.cover, from: original.coverHash, to: uploadedCoverHash))
            }
        case .removed:
            updates.append(update(.cover, from: original.coverHash, to: nil))
        case .unchanged:
            break
        }

        return updates
    }

    /// Records that `update` landed: `original` now holds its new value, so it drops out of
    /// `claimUpdates`.
    mutating func landed(_ update: EditionClaimUpdate) {
        switch update.property {
        case .title:
            original.title = update.newValue ?? ""
        case .subtitle:
            original.subtitle = update.newValue
        case .cover:
            original.coverHash = update.newValue
            originalCoverData = coverData
            cover = .unchanged
            uploadedCoverHash = nil
        }
    }

    /// An update naming the value it replaces. An empty value on either side is no value: no
    /// old one adds the claim, no new one removes it.
    private func update(
        _ property: EditableEditionProperty,
        from oldValue: String?,
        to newValue: String?
    ) -> EditionClaimUpdate {
        .init(
            uri: original.uri,
            property: property,
            oldValue: oldValue?.isEmpty == true ? nil : oldValue,
            newValue: newValue?.isEmpty == true ? nil : newValue
        )
    }
}
