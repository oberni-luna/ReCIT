//
//  GroupModel.swift
//  ReCIT_iOS
//
//  Groups of readers on inventaire.io — the ones I belong to, the ones inviting me, the ones I
//  asked to join, and whichever one is open on screen. See PRD 0016, and PRD 0019 for the move
//  to the store.
//
//  **Mine in the store, the others in memory.** A group I hold a role in — admin, member,
//  invited, or asked to join from this device — is a `StoredGroup`, there from the moment the app
//  opens and offline, read by the screens through `@Query` (ADR 0001). A group opened from a
//  search is a `ReaderGroup` kept here for the launch, as every group was until issue 0103. The
//  people in a group are `User`s of the store, looked up by id.
//
//  **Writes are optimistic** (ADR 0001): a gesture is applied to the group first, through the
//  same transition the server runs (`ReaderGroup.applying`), then sent in a task this model owns;
//  a refusal puts the previous value back and speaks through the snack bar. Creating and
//  deleting a group are the exceptions — see `createGroup` and `deleteGroup`.
//
//  **The sync is an upsert with a deletion scope** (feature 0019): every stored group is in its
//  charge, except one whose read failed. A group I left, or whose invitation was withdrawn, is
//  gone from the store at the next sync; a group from a search was never in it.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class GroupModel: OptimisticMutating {

    private let apiService: APIServicing
    private let ledger: GroupRequestLedger
    private let defaults: UserDefaults
    private static let signedInReaderKey: String = "groups.signedInReader"

    /// The roles that make a group one of mine, and so a group the store keeps. A declined
    /// invitation is not one: `GET /api/groups` stops naming the group, and so does the device.
    private static let storedRoles: Set<GroupRole> = [.admin, .member, .invited, .requested]

    /// Shared channel used to surface a background optimistic failure to the UI.
    var errorReporter: AppErrorReporter?

    /// The groups this launch has read that the store does not hold: opened from a search, or
    /// dropped by a sync while a screen may still be open on them. Never shown in the Groupes
    /// segment, which lists the store alone.
    private(set) var visitedGroups: [String: ReaderGroup] = [:]

    /// The signed-in reader, as of the last sync. Every gesture is made in their name, and every
    /// role a screen shows is theirs.
    ///
    /// **Kept across launches**, unlike the rest of this model: the stored groups are only
    /// readable with it, and the first answer that would bring it back — `GET /api/user` — is a
    /// network call. Without it the Groupes segment could not tell an invitation from a group of
    /// mine before the sync, nor at all offline. Forgotten with the groups at sign-out.
    private(set) var myUserId: String?

    /// The most recent background task spawned by an optimistic write. Exposed so tests can
    /// await completion; not observed by the UI.
    @ObservationIgnored private(set) var inFlightTask: Task<Void, Never>?

    init(
        apiService: APIServicing,
        errorReporter: AppErrorReporter? = nil,
        ledger: GroupRequestLedger = .init(),
        defaults: UserDefaults = .standard
    ) {
        self.apiService = apiService
        self.errorReporter = errorReporter
        self.ledger = ledger
        self.defaults = defaults
        self.myUserId = defaults.string(forKey: Self.signedInReaderKey)
    }

    // MARK: - Reading

    /// A group as a screen shows it: the stored copy when it is one of mine, the one read for
    /// this launch otherwise.
    ///
    /// - Parameter stored: What the screen's `@Query` holds. Passed in rather than fetched, so
    ///   the screen redraws when the store changes.
    func group(id: String, among stored: [StoredGroup]) -> ReaderGroup? {
        stored.first { $0.isStillInTheStore && $0._id == id }?.readerGroup ?? visitedGroups[id]
    }

    /// The same lookup, straight from the store — for the gestures, and for the tests.
    func group(id: String, in modelContext: ModelContext) -> ReaderGroup? {
        storedGroup(id: id, in: modelContext)?.readerGroup ?? visitedGroups[id]
    }

    /// My groups by section, from what a screen's `@Query` holds.
    func myGroups(from stored: [StoredGroup]) -> MyGroups {
        .init(stored.filter(\.isStillInTheStore).map(\.readerGroup), me: myUserId)
    }

    // MARK: - Syncing

    /// Reads `GET /api/groups`, then the groups this device asked to join, writes them into the
    /// store, and puts a name on everyone they mention.
    ///
    /// The answer is upserted in place — an open screen keeps its object — and every stored
    /// group it does not name is deleted: a group I left on the website, or that removed me, is
    /// gone from the segment at the next sync rather than lingering. The only exception is a
    /// request whose read failed: a bad connection does not erase a request.
    func syncMyGroups(myUserId: String, modelContext: ModelContext) async throws {
        remember(myUserId)

        let answer: GroupsDTO? = try await apiService.fetchData(fromEndpoint: "/api/groups")
        var fresh: [String: GroupDTO] = [:]
        for dto in answer?.groups ?? [] {
            fresh[dto._id] = dto
        }

        // The requests are the one role `/api/groups` leaves out. Each is read back: still
        // waiting, it stays; accepted or refused, the ledger forgets it.
        var unread: Set<String> = []
        for id in ledger.ids(for: myUserId).sorted() where fresh[id] == nil {
            do {
                let dto: GroupDTO = try await readGroup(id: id, modelContext: modelContext)
                if ReaderGroup(dto: dto, pictureURL: nil).role(of: myUserId) == .requested {
                    fresh[id] = dto
                } else {
                    ledger.remove(id, for: myUserId)
                }
            } catch NetworkError.badStatus(code: 404, _) {
                ledger.remove(id, for: myUserId)
            } catch {
                unread.insert(id)
            }
        }

        // Signed out while the answers were on their way: the store is the next account's now,
        // and a sync that wrote nothing must not be counted as one that succeeded.
        guard self.myUserId == myUserId else { throw CancellationError() }

        try store(Array(fresh.values), keeping: unread, in: modelContext)

        let named: [String] = try modelContext.fetch(FetchDescriptor<StoredGroup>())
            .flatMap { $0.readerGroup.everyoneIds }
        try await fetchMissingUsers(Set(named), modelContext: modelContext)
    }

    /// Reads one group afresh — the screen of a group, mine or not — and stores the people it
    /// names, which `by-id` sends along already shaped as users.
    @discardableResult
    func fetchGroup(id: String, modelContext: ModelContext) async throws -> ReaderGroup {
        let dto: GroupDTO = try await readGroup(id: id, modelContext: modelContext)
        let group: ReaderGroup = absorb(dto, in: modelContext)
        try modelContext.save()
        return group
    }

    /// Groups whose name or description matches, best match first. Only the searchable ones:
    /// the server leaves the others out.
    func searchGroups(query: String, limit: Int = 20) async throws -> [GroupSearchResult] {
        let trimmedQuery: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return [] }

        // An ampersand or a plus would end the query parameter and truncate the search.
        let search: String = trimmedQuery.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed.subtracting(.init(charactersIn: "&+=?#"))
        ) ?? trimmedQuery

        let answer: GroupSearchResultsDTO? = try await apiService.fetchData(
            fromEndpoint: "/api/search?types=groups&search=\(search)&limit=\(limit)"
        )
        return (answer?.results ?? [])
            .sorted { ($0.score ?? 0) > ($1.score ?? 0) }
            .map { result in
                .init(
                    id: result.id,
                    name: result.label,
                    description: result.description,
                    pictureURL: apiService.absoluteImageUrl(result.image)
                )
            }
    }

    // MARK: - Membership writes

    /// Makes one membership gesture, in my name, optimistically.
    ///
    /// The gesture is checked against the group as it stands before anything moves: one the
    /// server would refuse — inviting someone who declined, leaving as the last admin — is
    /// reported and goes no further, instead of flashing a state that will be taken back.
    ///
    /// A gesture that makes a group from a search mine — a request, or joining an open group —
    /// moves it into the store; a refusal moves it back out.
    ///
    /// - Parameter target: The other person, for the gestures about someone else.
    func perform(
        _ action: GroupAction,
        on groupId: String,
        target: String? = nil,
        modelContext: ModelContext
    ) {
        guard let myUserId, let current = group(id: groupId, in: modelContext) else { return }

        let next: ReaderGroup
        do {
            next = try current.applying(action, by: myUserId, on: target)
        } catch {
            errorReporter?.report(error)
            return
        }

        let wasStored: Bool = storedGroup(id: groupId, in: modelContext) != nil
        let ledger: GroupRequestLedger = ledger
        inFlightTask = optimistic(
            modelContext,
            apply: { [weak self] in self?.place(next, in: modelContext) },
            revert: { [weak self] in
                self?.putBack(current, wasStored: wasStored, actor: myUserId, in: modelContext)
            },
            request: { [weak self] in
                try await self?.put(action, groupId: groupId, target: target)
            },
            reconcile: {
                // Only a request that is still waiting needs remembering: a request to an open
                // group let me straight in, and `/api/groups` will name it from now on.
                if action == .request && next.role(of: myUserId) == .requested {
                    ledger.add(groupId, for: myUserId)
                } else if action == .cancelRequest {
                    ledger.remove(groupId, for: myUserId)
                }
            }
        )
    }

    // MARK: - Creating and settings

    /// Starts a group, with me as its only admin, and answers it once the server has.
    ///
    /// **Not optimistic**, unlike every other write here. The server limits creations (five in a
    /// row, two seconds apart), runs a spam check on the name and the description, and makes up
    /// the slug; a placeholder shown at once would too often have to be taken back, and the
    /// screen the form leads to needs the id the server gives.
    func createGroup(
        name: String,
        description: String,
        searchable: Bool,
        open: Bool,
        modelContext: ModelContext
    ) async throws -> ReaderGroup {
        guard let dto: GroupDTO = try await apiService.send(
            toEndpoint: "/api/groups",
            payload: GroupCreationPayload(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                searchable: searchable,
                open: open
            )
        ) else {
            throw NetworkError.badResponse
        }
        let group: ReaderGroup = absorb(dto, in: modelContext)
        try modelContext.save()
        return group
    }

    /// Writes one setting, optimistically. `update-settings` takes one attribute per call, so a
    /// form that changed two sends two.
    func update(_ setting: GroupSetting, on groupId: String, modelContext: ModelContext) {
        guard let current = group(id: groupId, in: modelContext) else { return }
        let next: ReaderGroup = setting.applied(to: current)
        guard next != current else { return }

        let wasStored: Bool = storedGroup(id: groupId, in: modelContext) != nil
        let actor: String? = myUserId
        inFlightTask = optimistic(
            modelContext,
            apply: { [weak self] in self?.place(next, in: modelContext) },
            revert: { [weak self] in
                self?.putBack(current, wasStored: wasStored, actor: actor, in: modelContext)
            },
            request: { [weak self] in
                try await self?.putSetting(setting, groupId: groupId)
            }
        )
    }

    // MARK: - Deleting

    /// Deletes a group I am the only admin of, then forgets it.
    ///
    /// **inventaire.io has no deletion.** It drops a group once its last admin leaves, and that
    /// admin may only leave an empty group (`ReaderGroup.canDelete`). So the group is read
    /// afresh — someone may have joined since the screen opened —, each member is removed by a
    /// `kick`, and I leave last.
    ///
    /// **Not optimistic**, like `createGroup`: it cannot be taken back, and it takes one call per
    /// member. A refusal halfway stops there. The members already removed stay removed, and the
    /// group is read again so that the screen shows who is left.
    func deleteGroup(id groupId: String, modelContext: ModelContext) async throws {
        guard let myUserId else { throw CancellationError() }

        let group: ReaderGroup = try await fetchGroup(id: groupId, modelContext: modelContext)
        guard group.canDelete(myUserId) else { throw GroupTransitionError.otherAdmins }

        do {
            for member in group.members {
                try await put(.kick, groupId: groupId, target: member.user)
            }
            try await put(.leave, groupId: groupId, target: nil)
        } catch {
            _ = try? await fetchGroup(id: groupId, modelContext: modelContext)
            throw error
        }

        if let stored = storedGroup(id: groupId, in: modelContext) {
            modelContext.delete(stored)
        }
        visitedGroups[groupId] = nil
        try modelContext.save()
    }

    // MARK: - Signing out

    /// Leaves nothing of the last account's groups in memory, and forgets who they were for.
    /// The stored groups go with the rest of the account's rows (`UserModel.wipeUserData`); the
    /// ledger is keyed by account, and stays for when they come back.
    func reset() {
        visitedGroups = [:]
        myUserId = nil
        defaults.removeObject(forKey: Self.signedInReaderKey)
    }

    // MARK: - Private · the store

    private func remember(_ userId: String) {
        myUserId = userId
        defaults.set(userId, forKey: Self.signedInReaderKey)
    }

    private func storedGroup(id: String, in modelContext: ModelContext) -> StoredGroup? {
        let descriptor: FetchDescriptor<StoredGroup> = .init(predicate: #Predicate { $0._id == id })
        return try? modelContext.fetch(descriptor).first
    }

    /// Whether `group` is one the store should keep: one I hold a role in.
    private func isMine(_ group: ReaderGroup) -> Bool {
        group.role(of: myUserId).map(Self.storedRoles.contains) ?? false
    }

    /// Takes a document the server sent: merged into the stored copy when there is one, stored
    /// when it makes the group one of mine, kept for the launch otherwise. Not saved.
    private func absorb(_ dto: GroupDTO, in modelContext: ModelContext) -> ReaderGroup {
        let pictureURL: String? = apiService.absoluteImageUrl(dto.picture)
        if let stored = storedGroup(id: dto._id, in: modelContext) {
            stored.update(from: dto, pictureURL: pictureURL)
            return stored.readerGroup
        }
        let group: ReaderGroup = .init(dto: dto, pictureURL: pictureURL)
        if isMine(group) {
            modelContext.insert(StoredGroup(dto: dto, pictureURL: pictureURL))
            visitedGroups[group.id] = nil
        } else {
            visitedGroups[group.id] = group
        }
        return group
    }

    /// Writes a value the app computed — a gesture's outcome, a setting — where the group
    /// lives. A stored group stays stored whatever the gesture did to my role: the next sync is
    /// what takes it out, so a screen open on it does not lose it mid-gesture. Not saved.
    private func place(_ group: ReaderGroup, in modelContext: ModelContext) {
        if let stored = storedGroup(id: group.id, in: modelContext) {
            stored.overwrite(with: group)
        } else if isMine(group) {
            modelContext.insert(StoredGroup(group: group))
            visitedGroups[group.id] = nil
        } else {
            visitedGroups[group.id] = group
        }
    }

    /// Undoes `place` after a refusal. A group that was stored gets its previous value back —
    /// unless it has left the store meanwhile, synced away or signed out, and there is nothing
    /// to put back. A group that was not goes back to memory, out of the store it was moved
    /// into. Nothing at all when the account changed during the round trip.
    private func putBack(
        _ previous: ReaderGroup,
        wasStored: Bool,
        actor: String?,
        in modelContext: ModelContext
    ) {
        guard actor == myUserId else { return }
        let stored: StoredGroup? = storedGroup(id: previous.id, in: modelContext)
        if wasStored {
            stored?.overwrite(with: previous)
        } else {
            if let stored {
                modelContext.delete(stored)
            }
            visitedGroups[previous.id] = previous
        }
    }

    /// Upserts what a sync read, in place, and deletes every stored group it did not name —
    /// except `unread`, the requests that could not be read this time. Saves.
    private func store(
        _ dtos: [GroupDTO],
        keeping unread: Set<String>,
        in modelContext: ModelContext
    ) throws {
        // What the sync drops stays readable for this launch, for a screen still open on it — as
        // the server now has it, without me: a group I left on the website must not go on
        // offering « Quitter », nor show me as a member in the search, until it is read again.
        let named: Set<String> = Set(dtos.map(\._id))
        for stored in try modelContext.fetch(FetchDescriptor<StoredGroup>())
        where named.contains(stored._id) == false && unread.contains(stored._id) == false {
            visitedGroups[stored._id] = Self.dropping(myUserId, from: stored.readerGroup)
        }

        try modelContext.upsert(
            dtos,
            dtoID: { dto in dto._id },
            modelID: { (stored: StoredGroup) in stored._id },
            make: { dto in StoredGroup(dto: dto, pictureURL: apiService.absoluteImageUrl(dto.picture)) },
            update: { stored, dto in stored.update(from: dto, pictureURL: apiService.absoluteImageUrl(dto.picture)) },
            deleteMissing: true,
            scope: { stored in unread.contains(stored._id) == false }
        )
        for id in named {
            visitedGroups[id] = nil
        }
        try modelContext.save()
    }

    /// `group` once a sync has stopped naming it among mine: I hold none of the roles that keep
    /// a group in the store any more. A refusal, which the sync does not read, is left as it was.
    private static func dropping(_ userId: String?, from group: ReaderGroup) -> ReaderGroup {
        guard let userId else { return group }
        var group: ReaderGroup = group
        group.admins.removeAll { $0.user == userId }
        group.members.removeAll { $0.user == userId }
        group.invited.removeAll { $0.user == userId }
        group.requested.removeAll { $0.user == userId }
        return group
    }

    // MARK: - Private · the server

    private func put(_ action: GroupAction, groupId: String, target: String?) async throws {
        let _: OkStatusDTO? = try await apiService.send(
            toEndpoint: "/api/groups/\(action.rawValue)",
            method: "PUT",
            payload: GroupActionPayload(group: groupId, user: action.targetsAnotherUser ? target : nil)
        )
    }

    private func putSetting(_ setting: GroupSetting, groupId: String) async throws {
        let _: OkStatusDTO? = try await apiService.send(
            toEndpoint: "/api/groups/update-settings",
            method: "PUT",
            payload: GroupSettingPayload(group: groupId, attribute: setting.attribute, value: setting.value)
        )
    }

    /// `GET /api/groups/by-id`, with the people it names stored on the way.
    private func readGroup(id: String, modelContext: ModelContext) async throws -> GroupDTO {
        guard let answer: GroupByIdDTO = try await apiService.fetchData(
            fromEndpoint: "/api/groups/by-id?id=\(id)"
        ) else {
            throw NetworkError.badResponse
        }
        try User.upsert(answer.users, baseUrl: apiService.baseUrl(), in: modelContext)
        return answer.group
    }

    /// The people a group names who are not in the store yet, fetched by fifty so the url
    /// stays short. A group of strangers is a list of blank lines without them.
    private func fetchMissingUsers(_ ids: Set<String>, modelContext: ModelContext) async throws {
        let stored: Set<String> = Set(try modelContext.fetch(FetchDescriptor<User>()).map(\._id))
        let missing: [String] = ids.subtracting(stored).sorted()
        for start in stride(from: 0, to: missing.count, by: 50) {
            let chunk: [String] = Array(missing[start..<min(start + 50, missing.count)])
            let answer: UsersDTO? = try await apiService.fetchData(
                fromEndpoint: "/api/users/by-ids?ids=\(chunk.joined(separator: "|"))"
            )
            if let users = answer?.users.values {
                try User.upsert(Array(users), baseUrl: apiService.baseUrl(), in: modelContext)
            }
        }
    }
}
