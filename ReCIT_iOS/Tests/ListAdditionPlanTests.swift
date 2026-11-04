//
//  ListAdditionPlanTests.swift
//  ReCIT_iOSTests
//

import Testing
@testable import ReCIT_iOS

@Suite("ListAdditionPlan")
struct ListAdditionPlanTests {

    @Test("A work the list does not hold is added")
    func newWorkIsAdded() {
        #expect(ListAdditionPlan.plan(chosen: ["wd:Q1"], existing: ["wd:Q2"]) == .add(["wd:Q1"]))
    }

    @Test("A work the list already holds is shown, never added twice")
    func existingWorkIsShown() {
        #expect(ListAdditionPlan.plan(chosen: ["wd:Q1"], existing: ["wd:Q1"]) == .alreadyInList("wd:Q1"))
    }

    @Test("« Toutes les œuvres » adds only the works the list is missing, in their order")
    func allWorksAddsTheMissingOnes() {
        let plan: ListAdditionPlan = .plan(
            chosen: ["wd:Q1", "wd:Q2", "wd:Q3"],
            existing: ["wd:Q2"]
        )

        #expect(plan == .add(["wd:Q1", "wd:Q3"]))
    }

    @Test("Every work of a collection already there shows the first one")
    func allWorksAlreadyThere() {
        let plan: ListAdditionPlan = .plan(
            chosen: ["wd:Q3", "wd:Q1"],
            existing: ["wd:Q1", "wd:Q3"]
        )

        #expect(plan == .alreadyInList("wd:Q3"))
    }

    @Test("A uri chosen twice is sent once")
    func duplicatesAreSentOnce() {
        #expect(ListAdditionPlan.plan(chosen: ["wd:Q1", "wd:Q1"], existing: []) == .add(["wd:Q1"]))
    }

    @Test("Nothing chosen, nothing to do")
    func nothingChosen() {
        #expect(ListAdditionPlan.plan(chosen: [], existing: ["wd:Q1"]) == .nothing)
    }
}
