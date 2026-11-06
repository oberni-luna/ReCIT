//
//  GroupPictureTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 06/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite
struct GroupPictureTests {
    private static let oldPath: String = "/img/groups/old"
    private static let newPath: String = "/img/groups/0123456789012345678901234567890123456789"

    private static func body(of setting: GroupSetting) throws -> [String: Any] {
        let payload: GroupSettingPayload = .init(group: "g", attribute: setting.attribute, value: setting.value)
        let object: Any = try JSONSerialization.jsonObject(with: try JSONEncoder().encode(payload))
        return try #require(object as? [String: Any])
    }

    private static func lastValue(_ mock: MockAPIService) throws -> Any? {
        let payload: Data = try #require(mock.sentPayloads.last)
        let object: [String: Any] = try #require(try JSONSerialization.jsonObject(with: payload) as? [String: Any])
        return object["value"]
    }

    private static func group(picture: String) throws -> ReaderGroup {
        let json: String = GroupFixture.groupJSON(id: "g", admins: ["me"], extra: #""picture":"\#(picture)","#)
        let dto: GroupDTO = try JSONDecoder().decode(GroupDTO.self, from: Data(json.utf8))
        return .init(dto: dto, pictureURL: "https://test.local\(picture)")
    }

    private static func syncedModel(
        _ mock: MockAPIService,
        reporter: AppErrorReporter? = nil
    ) async throws -> (GroupModel, ModelContext) {
        let context: ModelContext = try TestStore.makeContext()
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub(
            "/api/groups",
            json: GroupFixture.groupsJSON([
                GroupFixture.groupJSON(id: "g", admins: ["me"], extra: #""picture":"\#(oldPath)","#)
            ])
        )
        let model: GroupModel = GroupFixture.makeModel(mock, reporter: reporter)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)
        return (model, context)
    }

    @Test
    func `a picture travels as its path`() throws {
        let body: [String: Any] = try Self.body(of: .picture(Self.newPath))

        #expect(body["group"] as? String == "g")
        #expect(body["attribute"] as? String == "picture")
        #expect(body["value"] as? String == Self.newPath)
    }

    @Test
    func `a removed picture travels as null`() throws {
        let body: [String: Any] = try Self.body(of: .picture(nil))

        #expect(body["attribute"] as? String == "picture")
        #expect(body["value"] is NSNull)
    }

    @Test
    func `a null value decodes back as null`() throws {
        let value: GroupSetting.Value = try JSONDecoder().decode(GroupSetting.Value.self, from: Data("null".utf8))

        #expect(value == .null)
    }

    @Test
    func `a written picture is kept as the address it is fetched at`() throws {
        let group: ReaderGroup = try Self.group(picture: Self.oldPath)

        let replaced: ReaderGroup = GroupSetting.picture(Self.newPath).applied(to: group, baseUrl: "https://test.local")
        let removed: ReaderGroup = GroupSetting.picture(nil).applied(to: group, baseUrl: "https://test.local")

        #expect(replaced.pictureURL == "https://test.local\(Self.newPath)")
        #expect(removed.pictureURL == nil)
    }

    @Test
    func `a picked picture is uploaded into groups, then named, then shown`() async throws {
        let mock: MockAPIService = .init()
        mock.uploadedImageUrl = Self.newPath
        mock.stub("/api/groups/update-settings", json: #"{"ok":true}"#)
        let reporter: AppErrorReporter = .init()
        let (model, context): (GroupModel, ModelContext) = try await Self.syncedModel(mock, reporter: reporter)

        model.updatePicture(Data([1, 2, 3]), on: "g", modelContext: context)
        #expect(try GroupFixture.stored(context).first?.pictureURL == "https://test.local\(Self.oldPath)")

        await model.inFlightTask?.value
        let writes: [String] = mock.recordedRequests.filter { $0.method != "GET" }.map(\.endpoint)
        #expect(writes == ["/api/images/upload?container=groups", "/api/groups/update-settings"])
        #expect(try Self.lastValue(mock) as? String == Self.newPath)
        #expect(try GroupFixture.stored(context).first?.pictureURL == "https://test.local\(Self.newPath)")
        #expect(reporter.lastFailure == nil)
    }

    @Test
    func `a refused picture leaves the old one, and says so`() async throws {
        let mock: MockAPIService = .init()
        mock.uploadedImageUrl = Self.newPath
        mock.stub("/api/groups/update-settings", error: NetworkError.badStatus(code: 400, message: "invalid picture"))
        let reporter: AppErrorReporter = .init()
        let (model, context): (GroupModel, ModelContext) = try await Self.syncedModel(mock, reporter: reporter)

        model.updatePicture(Data([1, 2, 3]), on: "g", modelContext: context)
        await model.inFlightTask?.value

        #expect(try GroupFixture.stored(context).first?.pictureURL == "https://test.local\(Self.oldPath)")
        #expect(reporter.lastFailure != nil)
    }

    @Test
    func `a failed upload names nothing, and leaves the old picture`() async throws {
        let mock: MockAPIService = .init()
        mock.uploadFailure = NetworkError.badStatus(code: 500, message: "upload")
        let reporter: AppErrorReporter = .init()
        let (model, context): (GroupModel, ModelContext) = try await Self.syncedModel(mock, reporter: reporter)

        model.updatePicture(Data([1, 2, 3]), on: "g", modelContext: context)
        await model.inFlightTask?.value

        #expect(mock.recordedRequests.contains { $0.endpoint == "/api/groups/update-settings" } == false)
        #expect(try GroupFixture.stored(context).first?.pictureURL == "https://test.local\(Self.oldPath)")
        #expect(reporter.lastFailure != nil)
    }

    @Test
    func `a refused name gives back the name alone, and keeps the picture that landed first`() async throws {
        let mock: MockAPIService = .init()
        mock.uploadedImageUrl = Self.newPath
        mock.stub("/api/groups/update-settings", json: #"{"ok":true}"#)
        let reporter: AppErrorReporter = .init()
        let (model, context): (GroupModel, ModelContext) = try await Self.syncedModel(mock, reporter: reporter)
        var pictureLandedFirst: Bool = false
        mock.onSend = { [unowned mock] index in
            let payload: GroupSettingPayload = try JSONDecoder().decode(
                GroupSettingPayload.self,
                from: mock.sentPayloads[index]
            )
            guard payload.attribute == "name" else { return }
            pictureLandedFirst = try GroupFixture.stored(context).first?.pictureURL == "https://test.local\(Self.newPath)"
            throw NetworkError.badStatus(code: 400, message: "name")
        }

        model.updatePicture(Data([1, 2, 3]), on: "g", modelContext: context)
        let pictureWrite: Task<Void, Never>? = model.inFlightTask
        model.update(.name("Polars"), on: "g", modelContext: context)
        let rename: Task<Void, Never>? = model.inFlightTask
        await pictureWrite?.value
        await rename?.value

        let stored: StoredGroup = try #require(try GroupFixture.stored(context).first)
        #expect(pictureLandedFirst)
        #expect(stored.name == "Club")
        #expect(stored.pictureURL == "https://test.local\(Self.newPath)")
        #expect(reporter.lastFailure != nil)
    }

    @Test
    func `a removed picture sends null without uploading`() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/update-settings", json: #"{"ok":true}"#)
        let (model, context): (GroupModel, ModelContext) = try await Self.syncedModel(mock)

        model.updatePicture(nil, on: "g", modelContext: context)
        await model.inFlightTask?.value

        #expect(mock.recordedRequests.contains { $0.endpoint.contains("upload") } == false)
        #expect(try Self.lastValue(mock) is NSNull)
        #expect(try GroupFixture.stored(context).first?.pictureURL == nil)
    }

    @Test
    func `only a picked photo, or a saved one taken away, is a change`() {
        let bytes: Data = .init([1])

        #expect(GroupPictureEdit.unchanged.isChange(from: Self.oldPath) == false)
        #expect(GroupPictureEdit.replaced(bytes).isChange(from: nil))
        #expect(GroupPictureEdit.removed.isChange(from: Self.oldPath))
        #expect(GroupPictureEdit.removed.isChange(from: nil) == false)
    }

    @Test
    func `the slot shows the saved photo until it is replaced or taken away`() {
        let bytes: Data = .init([1])

        #expect(GroupPictureEdit.unchanged.showsPicture(savedPictureURL: Self.oldPath))
        #expect(GroupPictureEdit.unchanged.showsPicture(savedPictureURL: nil) == false)
        #expect(GroupPictureEdit.replaced(bytes).showsPicture(savedPictureURL: nil))
        #expect(GroupPictureEdit.removed.showsPicture(savedPictureURL: Self.oldPath) == false)
        #expect(GroupPictureEdit.replaced(bytes).imageData == bytes)
        #expect(GroupPictureEdit.removed.imageData == nil)
    }
}
