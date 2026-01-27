//
//  WpExtract.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import Foundation
import SwiftData

@Model
public class WpExtract: Identifiable {
    @Attribute(.unique) var uri: String
    var content: String
    var url: String

    init(uri: String, content: String, url: String) {
        self.uri = uri
        self.content = content
        self.url = url
    }
}
