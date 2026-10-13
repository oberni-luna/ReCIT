//
//  AbsoluteImageURLTests.swift
//  ReCIT_iOSTests
//
//  The three shapes of image path inventaire.io answers with, and a reader's avatar resolved by
//  the same rule as a group's (PRD 0019, issue 0104). The avatar used to be the base url and the
//  `picture` glued together, so an absolute `picture` came out as two urls end to end.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Absolute image url")
struct AbsoluteImageURLTests {

    private let baseUrl: String = "https://inventaire.io"

    private func user(picture: String?) throws -> User {
        let pictureField: String = picture.map { #","picture":"\#($0)""# } ?? ""
        let json: String = #"{"_id":"u1","username":"olivier_berni"\#(pictureField)}"#
        let dto: UserDTO = try JSONDecoder().decode(UserDTO.self, from: Data(json.utf8))
        return .init(userDTO: dto, baseUrl: baseUrl)
    }

    // MARK: - The rule

    @Test("An /img path is put after the base url")
    func imgPath() {
        #expect(AbsoluteImageURL.resolve("/img/users/abc", baseUrl: baseUrl) == "https://inventaire.io/img/users/abc")
    }

    @Test("An absolute url is kept as it is")
    func absoluteUrl() {
        let url: String = "https://example.org/avatar.jpg"
        #expect(AbsoluteImageURL.resolve(url, baseUrl: baseUrl) == url)
    }

    @Test("A bare file name is asked of Wikimedia Commons at 512 wide")
    func wikimediaFileName() {
        #expect(
            AbsoluteImageURL.resolve("Victor Hugo.jpg", baseUrl: baseUrl)
                == "https://commons.wikimedia.org/wiki/Special:FilePath/Victor Hugo.jpg?width=512"
        )
    }

    @Test("No path, no url")
    func noPath() {
        #expect(AbsoluteImageURL.resolve(nil, baseUrl: baseUrl) == nil)
    }

    @Test(
        "APIService.absoluteImageUrl is the same rule, after the environment's base url",
        arguments: ["/img/groups/xyz", "https://example.org/a.png", "Cover.jpg"]
    )
    func apiServiceDelegates(path: String) {
        let service: APIService = .init(env: .production, session: MockURLProtocol.makeSession())

        #expect(service.absoluteImageUrl(path) == AbsoluteImageURL.resolve(path, baseUrl: service.baseUrl()))
        #expect(service.absoluteImageUrl(nil) == nil)
    }

    // MARK: - A reader's avatar

    @Test("A reader's /img picture is put after the base url")
    func userImgPicture() throws {
        #expect(try user(picture: "/img/users/abc").avatarURLValue == "https://inventaire.io/img/users/abc")
    }

    @Test("A reader's absolute picture is kept, not glued after the base url")
    func userAbsolutePicture() throws {
        let url: String = "https://example.org/avatar.jpg"
        #expect(try user(picture: url).avatarURLValue == url)
    }

    @Test("A reader without a picture, or with an empty one, has no avatar url")
    func userWithoutPicture() throws {
        #expect(try user(picture: nil).avatarURLValue == nil)
        #expect(try user(picture: "").avatarURLValue == nil)
    }
}
