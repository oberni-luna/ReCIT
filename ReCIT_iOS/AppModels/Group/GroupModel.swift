//
//  GroupModel.swift
//  ReCIT_iOS
//
//  Groups of readers on inventaire.io — the ones I belong to, the ones inviting me, the ones I
//  asked to join, and whichever one is open on screen. See PRD 0016.
//
//  **In memory, not in SwiftData.** A group is a `ReaderGroup` value held here for the launch:
//  a new `@Model` would be a store migration, which this project does not do without asking.
//  The screens stay reactive all the same — this is `@Observable`, and they read the
//  dictionary — and the people in a group are `User`s of the store, looked up by id.
//
//  **Writes are optimistic** (ADR 0001): a gesture is applied to the local value first,
//  through the same transition the server runs (`ReaderGroup.applying`), then sent in a task
//  this model owns; a refusal puts the previous value back and speaks through the snack bar.
//  Creating a group is the exception — see `createGroup`.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class GroupModel: OptimisticMutating {

    private let apiService: APIServicing
    private let ledger: GroupRequestLedger

    /// Shared channel used to surface a background optimistic failure to the UI.
    var errorReporter: AppErrorReporter?

    /// Every group this launch knows, by id: mine, and the ones opened from a search.
    private(set) var groupsByID: [String: ReaderGroup] = [:]

    /// Whether `syncMyGroups` has answered once this launch. Until then the Groupes segment
    /// says it is loading, rather than that there is no group — the groups are not kept across
    /// launches, so an empty dictionary means nothing before the first answer.
    private(set) var hasLoaded: Bool = false

    /// Whether the last sync failed before any had answered — the segment says so instead of
    /// spinning for ever.
    private(set) var syncFailed: Bool = false

    /// The signed-in reader, as of the last sync. Every gesture is made in their name.
    private(set) var myUserId: String?

    /// The most recent background task spawned by an optimistic write. Exposed so tests can
    /// await completion; not observed by the UI.
    @ObservationIgnored private(set) var inFlightTask: Task<Void, Never>?

    init(
        apiService: APIServicing,
        errorReporter: AppErrorReporter? = nil,
        ledger: GroupRequestLedger = .init()
    ) {
        self.apiService = apiService
        self.errorReporter = errorReporter
        self.ledger = ledger
    }

    // MARK: - Reading

    func group(id: String) -> ReaderGroup? {
        groupsByID[id]
    }

    /// The groups where I hold `roles`, by name.
    func groups(where roles: Set<GroupRole>) -> [ReaderGroup] {
        groupsByID.values
            .filter { group in group.role(of: myUserId).map(roles.contains) ?? false }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var myGroups: [ReaderGroup] {
        groups(where: [.admin, .member])
    }

    var invitations: [ReaderGroup] {
        groups(where: [.invited])
    }

    var sentRequests: [ReaderGroup] {
        groups(where: [.requested])
    }

    /// Requests waiting on me, in the groups I administer.
    var requestsToReview: Int {
        groups(where: [.admin]).reduce(0) { $0 + $1.requested.count }
    }

    /// Everything in the Groupes segment that waits on an answer from me — what the Réseau
    /// tab's badge adds to the friends' invitations.
    var pendingCount: Int {
        invitations.count + requestsToReview
    }

    // MARK: - Syncing

    /// Reads `GET /api/groups`, then the groups this device asked to join, and puts a name on
    /// everyone they mention.
    ///
    /// The answer replaces what was known: a group I left on the website, or that removed me,
    /// is gone from the segment at the next sync rather than lingering.
    func syncMyGroups(myUserId: String, modelContext: ModelContext) async throws {
        self.myUserId = myUserId
        syncFailed = false

        let answer: GroupsDTO?
        do {
            answer = try await apiService.fetchData(fromEndpoint: "/api/groups")
        } catch {
            syncFailed = true
            throw error
        }
        var fresh: [String: ReaderGroup] = [:]
        for dto in answer?.groups ?? [] {
            fresh[dto._id] = makeGroup(dto)
        }

        // The requests are the one role `/api/groups` leaves out. Each is read back: still
        // waiting, it stays; accepted or refused, the ledger forgets it. A failed read keeps
        // what was known, so a bad connection does not erase a request.
        for id in ledger.ids(for: myUserId) where fresh[id] == nil {
            do {
                let group: ReaderGroup = try await readGroup(id: id, modelContext: modelContext)
                if group.role(of: myUserId) == .requested {
                    fresh[id] = group
                } else {
                    ledger.remove(id, for: myUserId)
                }
            } catch NetworkError.badStatus(code: 404, _) {
                ledger.remove(id, for: myUserId)
            } catch {
                if let known = groupsByID[id] {
                    fresh[id] = known
                }
            }
        }

        groupsByID = fresh
        hasLoaded = true

        try await fetchMissingUsers(Set(fresh.values.flatMap(\.everyoneIds)), modelContext: modelContext)
    }

    /// Reads one group afresh — the screen of a group, mine or not — and stores the people it
    /// names, which `by-id` sends along already shaped as users.
    @discardableResult
    func fetchGroup(id: String, modelContext: ModelContext) async throws -> ReaderGroup {
        let group: ReaderGroup = try await readGroup(id: id, modelContext: modelContext)
        groupsByID[id] = group
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
    /// - Parameter target: The other person, for the gestures about someone else.
    func perform(
        _ action: GroupAction,
        on groupId: String,
        target: String? = nil,
        modelContext: ModelContext
    ) {
        guard let myUserId, let current = groupsByID[groupId] else { return }

        let next: ReaderGroup
        do {
            next = try current.applying(action, by: myUserId, on: target)
        } catch {
            errorReporter?.report(error)
            return
        }

        let ledger: GroupRequestLedger = ledger
        inFlightTask = optimistic(
            modelContext,
            apply: { [weak self] in self?.groupsByID[groupId] = next },
            revert: { [weak self] in self?.groupsByID[groupId] = current },
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
        open: Bool
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
        let group: ReaderGroup = makeGroup(dto)
        groupsByID[group.id] = group
        return group
    }

    /// Writes one setting, optimistically. `update-settings` takes one attribute per call, so a
    /// form that changed two sends two.
    func update(_ setting: GroupSetting, on groupId: String, modelContext: ModelContext) {
        guard let current = groupsByID[groupId] else { return }
        let next: ReaderGroup = setting.applied(to: current)
        guard next != current else { return }

        inFlightTask = optimistic(
            modelContext,
            apply: { [weak self] in self?.groupsByID[groupId] = next },
            revert: { [weak self] in self?.groupsByID[groupId] = current },
            request: { [weak self] in
                try await self?.putSetting(setting, groupId: groupId)
            }
        )
    }

    // MARK: - Signing out

    /// Leaves nothing of the last account's groups in memory. The ledger is keyed by account,
    /// and stays for when they come back.
    func reset() {
        groupsByID = [:]
        hasLoaded = false
        syncFailed = false
        myUserId = nil
    }

    // MARK: - Private

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

    private func readGroup(id: String, modelContext: ModelContext) async throws -> ReaderGroup {
        guard let answer: GroupByIdDTO = try await apiService.fetchData(
            fromEndpoint: "/api/groups/by-id?id=\(id)"
        ) else {
            throw NetworkError.badResponse
        }
        try User.upsert(answer.users, baseUrl: apiService.baseUrl(), in: modelContext)
        return makeGroup(answer.group)
    }

    private func makeGroup(_ dto: GroupDTO) -> ReaderGroup {
        .init(dto: dto, pictureURL: apiService.absoluteImageUrl(dto.picture))
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
