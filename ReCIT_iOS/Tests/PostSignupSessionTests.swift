//
//  PostSignupSessionTests.swift
//  ReCIT_iOSTests
//
//  The branch production never takes on demand.
//
//  `POST /auth/signup` opens the session itself today, so `chainSignIn` is unreachable by hand:
//  no fixture, no test account and no amount of clicking will produce it, and the day the server
//  stops setting those cookies it breaks for every new user at once — with the only symptom
//  being an account that was created and a screen that still asks you to sign in. A rule nobody
//  can exercise is a rule nobody will notice rotting, which is the whole reason it is a type.
//
//  Pure and network-free, like `OnboardingGateTests`.
//
//  See PRD 0010 and issue 0057.
//

import Testing
@testable import ReCIT_iOS

@Suite("PostSignupSession")
struct PostSignupSessionTests {

    @Test("Cookies came back: the user is already in")
    func cookiesPresentNeedNothing() {
        #expect(PostSignupSession.next(hasSessionCookies: true) == .established)
    }

    @Test("No cookies came back: sign in with what was just typed")
    func cookiesAbsentChainASignIn() {
        #expect(PostSignupSession.next(hasSessionCookies: false) == .chainSignIn)
    }

    @Test("The two answers are different answers")
    func theRuleActuallyBranches() {
        // Guards against the shape of failure a one-line rule invites: a version that always
        // says `established`, which reads as correct every day production sets its cookies and
        // strands every new user the day it stops.
        #expect(
            PostSignupSession.next(hasSessionCookies: true)
                != PostSignupSession.next(hasSessionCookies: false)
        )
    }
}
