//
//  Entity.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import Foundation

protocol Entity: Identifiable {
    var uri: String {get}
    var extract: WpExtract? {get set}
    var image: String? {get}
    var title: String {get}
    var subtitle: String? {get}
}
