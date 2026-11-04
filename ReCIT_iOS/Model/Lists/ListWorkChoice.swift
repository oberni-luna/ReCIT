//
//  ListWorkChoice.swift
//  ReCIT_iOS
//
//  A pending « which of its works? » — what presents the confirmation dialog when the book the
//  reader wants to add holds more than one work. See PRD 0029.
//

import Foundation

struct ListWorkChoice: Identifiable {
    let id: UUID = .init()
    let works: [ListWorkOption]
}
