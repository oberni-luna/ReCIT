//
//  TransactionType.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 28/11/2025.
//


enum TransactionType: String, Codable {
    case lending = "lending"
    case inventorying = "inventorying"
    case selling = "selling"
    case giving = "giving"
}
