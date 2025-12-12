//
//  UserNetworkDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/12/2025.
//

import Foundation

struct UserNetworkDTO: Codable {
    let friends: [String]
    let userRequested: [String]
    let otherRequested: [String]
    let network: [String]
}
