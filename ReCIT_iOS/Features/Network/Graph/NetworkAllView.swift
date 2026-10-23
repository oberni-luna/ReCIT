//
//  NetworkAllView.swift
//  ReCIT_iOS
//
//  Réseau › Tout — the segment that draws my network as a graph (PRD 0019), on
//  `backgroundDefault`, nav bar included, where the lists keep their grey (Q14).
//
//  The constellation (issue 0106): « Vous » at the centre, my groups in a ring, my friends near
//  the groups they share with me, the readers tied to me alone close by — or the empty state E1
//  when there is nobody and nothing to draw around me (Q39).
//
//  Touching a node opens its sheet; « Ouvrir le groupe » and « Voir le profil » push the group's
//  page or the reader's profile onto the Réseau tab's own path, so going back returns to the
//  graph (issue 0107). An invitation to a group or a friend request is answered from its sheet,
//  with the optimistic gestures of the Amis and Groupes rows (issue 0108, ADR 0001): the store
//  moves at once, a failure is put back and reported through `AppErrorReporter`.
//
//  Everything is read from the store through `@Query` (ADR 0001), the groups included since issue
//  0103, so the segment is the same offline and from the moment the app opens.
//
//  **The status pill** (issue 0109), at the bottom left: « N amis · N groupes », « Synchronisation… »
//  until my relations and my groups have answered once, or « Réessayer » on a first launch whose
//  sync failed, which runs it again (Q10, Q40, Q41). The empty state does without the counter and
//  the zoom controls (Q39) — but not without the other two: on a first launch the store is empty
//  because nothing has arrived yet, and that is where « Réessayer » is needed.
//

import LBSnackBar
import SwiftUI
import SwiftData

struct NetworkAllView: View {
    @Binding var path: NavigationPath

    @Environment(UserModel.self) private var userModel
    @Environment(GroupModel.self) private var groupModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar
    @Environment(SyncStatusStore.self) private var syncStatus
    @Environment(\.syncUserData) private var syncUserData

    @Query private var allUsers: [User]
    @Query private var storedGroups: [StoredGroup]

    /// Me, as of the last sync — or, before the launch's first one and offline, my row in the
    /// store, found by the id `GroupModel` keeps across launches.
    private var signedInUser: User? {
        userModel.myUser ?? allUsers.first { $0._id == groupModel.myUserId }
    }

    var body: some View {
        let me: User? = signedInUser
        let groups: MyGroups = groupModel.myGroups(from: storedGroups)
        let content: NetworkAllContent = .init(
            relations: allUsers.lazy.filter { $0._id != me?._id }.map(\.relation),
            groups: groups
        )

        let graph: NetworkGraph = .init(
            .init(
                me: me,
                myUserId: groupModel.myUserId,
                users: allUsers,
                groups: groups
            )
        )
        let status: NetworkGraphStatus = .init(
            counter: graph.counter,
            community: syncStatus.phase(.community),
            groups: syncStatus.phase(.groups)
        )

        Group {
            switch content {
            case .empty:
                NetworkEmptyView(
                    username: me?.username ?? "",
                    imageUrl: me?.avatarURLValue
                )
            case .graph:
                NetworkGraphView(graph: graph) { node in
                    open(node)
                } onAnswer: { node, answer in
                    self.answer(answer, to: node)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomLeading) {
            if content == .graph || status.isCounter == false {
                NetworkGraphStatusPill(status: status) {
                    syncUserData()
                }
                .padding(.all, .medium)
            }
        }
        // Through every safe area, so the band and the nav bar are white too. Not
        // `toolbarBackground`: it swaps the bar's appearance for one of SwiftUI's, which drops the
        // design system's title fonts — « Réseau » turned to the system font on this one segment.
        .background {
            DesignSystem.Color.backgroundDefault.color
                .ignoresSafeArea()
        }
    }

    /// Pushes the page of `node`: the group's, or the reader's profile — the reader looked up in
    /// the store, which `UserDetailView` is built from.
    private func open(_ node: NetworkNodeID) {
        switch node {
        case .group(let id):
            path.append(NavigationDestination.group(id: id))
        case .reader(let id):
            guard let user = allUsers.first(where: { $0._id == id }) else { return }

            path.append(NavigationDestination.user(user: user))
        case .me:
            break
        }
    }

    /// Answers what `node` stands for: an invitation to a group, or a reader asking to be my
    /// friend — the latter as the Invitations list does, SnackBar included.
    private func answer(_ answer: NetworkSheetAnswer, to node: NetworkNodeID) {
        switch node {
        case .group(let id):
            groupModel.perform(answer.groupAction, on: id, modelContext: modelContext)
        case .reader(let id):
            guard let user = allUsers.first(where: { $0._id == id }) else { return }

            let invitation: InvitationAnswer = .init(
                userModel: userModel,
                modelContext: modelContext,
                snackBar: snackBar
            )
            switch answer {
            case .accept:
                invitation.accept(user)
            case .refuse:
                invitation.refuse(user)
            }
        case .me:
            break
        }
    }
}
