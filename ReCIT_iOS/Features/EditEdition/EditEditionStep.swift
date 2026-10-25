//
//  EditEditionStep.swift
//  ReCIT_iOS
//
//  What « Modifier l'édition » can push over its form: the search for the edition's work, the
//  search for an author to add to it, and the cover from an address on the web.
//

import Foundation

enum EditEditionStep: Hashable {
    case work
    case author
    case coverFromURL
}
