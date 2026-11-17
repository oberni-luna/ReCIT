//
//  NetworkSegment+ScreenSignpost.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/11/2026.
//

extension NetworkSegment {
    var screenSignpost: ScreenSignpost {
        switch self {
        case .friends:
            .networkFriends
        case .groups:
            .networkGroups
        }
    }
}
