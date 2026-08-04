//
//  TransactionStateMachineTests.swift
//  ReCIT_iOSTests
//
//  Pure, dependency-free coverage of the transaction lifecycle rules: which
//  events each role can trigger from each state, which are the default (forward)
//  actions, and where a message is mandatory. No SwiftData, no network.
//

import Testing
@testable import ReCIT_iOS

@Suite("TransactionStateMachine")
struct TransactionStateMachineTests {

    typealias State = UserTransaction.TransactionState

    private func events(from state: State, role: TransactionRole) -> Set<TransactionEvent> {
        Set(TransactionStateMachine.available(from: state, role: role).map(\.event))
    }

    // MARK: - Requested

    @Test("From requested, the owner can accept or reject")
    func requestedOwner() {
        #expect(events(from: .requested, role: .owner) == [.accept, .reject])
    }

    @Test("From requested, the requester can only cancel")
    func requestedRequester() {
        #expect(events(from: .requested, role: .requester) == [.cancel])
    }

    // MARK: - Accepted

    @Test("From accepted, the requester can confirm or cancel")
    func acceptedRequester() {
        #expect(events(from: .accepted, role: .requester) == [.confirm, .cancel])
    }

    @Test("From accepted, the owner can only cancel")
    func acceptedOwner() {
        #expect(events(from: .accepted, role: .owner) == [.cancel])
    }

    // MARK: - Confirmed

    @Test("From confirmed, the owner can close and the requester can do nothing")
    func confirmed() {
        #expect(events(from: .confirmed, role: .owner) == [.close])
        #expect(events(from: .confirmed, role: .requester).isEmpty)
    }

    // MARK: - Finished states

    @Test("Finished states offer no transition to anyone", arguments: [State.returned, .declined, .cancelled])
    func finishedStatesAreTerminal(state: State) {
        #expect(state.isFinished)
        #expect(events(from: state, role: .owner).isEmpty)
        #expect(events(from: state, role: .requester).isEmpty)
    }

    @Test("Non-finished states are not terminal", arguments: [State.requested, .accepted, .confirmed])
    func openStatesAreNotFinished(state: State) {
        #expect(!state.isFinished)
    }

    // MARK: - Resulting states

    @Test("Each event maps to the expected resulting state")
    func eventsProduceExpectedStates() {
        let map: [(State, TransactionRole, TransactionEvent, State)] = [
            (.requested, .owner,     .accept,  .accepted),
            (.requested, .owner,     .reject,  .declined),
            (.requested, .requester, .cancel,  .cancelled),
            (.accepted,  .requester, .confirm, .confirmed),
            (.accepted,  .requester, .cancel,  .cancelled),
            (.accepted,  .owner,     .cancel,  .cancelled),
            (.confirmed, .owner,     .close,   .returned)
        ]
        for (from, role, event, expected) in map {
            let transition = TransactionStateMachine.available(from: from, role: role).first { $0.event == event }
            #expect(transition?.to == expected, "\(event) from \(from) as \(role)")
        }
    }

    // MARK: - Default vs secondary actions

    @Test("Only accept, confirm and close are default (forward) actions")
    func defaultEvents() {
        for event in TransactionEvent.allCases {
            let isDefault: Bool = [.accept, .confirm, .close].contains(event)
            #expect(event.isDefault == isDefault, "\(event)")
        }
    }

    @Test("At most one default transition is available per state and role")
    func atMostOneDefault() {
        let states: [State] = [.requested, .accepted, .confirmed, .returned, .declined, .cancelled]
        for state in states {
            for role in [TransactionRole.owner, .requester] {
                let defaults = TransactionStateMachine.available(from: state, role: role).filter(\.event.isDefault)
                #expect(defaults.count <= 1, "\(state)/\(role)")
            }
        }
    }

    // MARK: - Message rule

    @Test("Only the initial request requires a message")
    func onlyRequestRequiresMessage() {
        for transition in TransactionStateMachine.transitions {
            #expect(transition.requiresMessage == (transition.event == .request), "\(transition.event)")
        }
    }

    @Test("The request transition creates the transaction and lands in requested")
    func requestTransition() {
        let request: TransactionTransition = TransactionStateMachine.requestTransition
        #expect(request.from == nil)
        #expect(request.to == .requested)
        #expect(request.actor == .requester)
        #expect(request.requiresMessage)
    }
}
