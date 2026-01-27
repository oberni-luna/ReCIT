//
//  Entity.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import Foundation

protocol Entity {
    var uri: String {get set}
    var extract: WpExtract? {get set}
}
