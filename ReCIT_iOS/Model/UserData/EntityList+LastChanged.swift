//
//  EntityList+LastChanged.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/11/2026.
//

import Foundation

extension EntityList {
    /// When the list last changed: its update, else its creation. What lists made by my friends
    /// are ordered by, the most recent first.
    var lastChanged: Date {
        updated ?? created
    }
}
