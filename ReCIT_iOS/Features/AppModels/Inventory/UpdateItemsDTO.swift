//
//  UpdateItemsDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/02/2026.
//

import Foundation

struct UpdateItemsDTO: Codable {
    let ids: [String]
    let attribute: String
    let value: String
}

struct UpdateItemsResponseDTO: Codable {
    let ok: Bool
}

//        {
//            "ids": [
//                "5b4b50dc0bb40609458d0e1ebbe65bcd"
//            ],
//            "attribute": "transaction",
//            "value": "lending"
//        }

