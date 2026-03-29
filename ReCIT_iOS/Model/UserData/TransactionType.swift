//
//  TransactionType.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 28/11/2025.
//


enum TransactionType: String, Codable, CaseIterable, Identifiable {
    var id: Self {self}
    
    case lending = "lending"
    case inventorying = "inventorying"
    case selling = "selling"
    case giving = "giving"

    var isOpenToTransaction: Bool {
        switch self {
        case .lending, .giving, .selling:
            return true
        case .inventorying:
            return false
        }
    }

}
