//
//  AuthorWorksDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 20/01/2026.
//

import Foundation

struct AuthorWorkDTO: Codable {
    let uri: String
    let score: Int?
}

struct AuthorWorksDTO: Codable {
    let works: [AuthorWorkDTO]
}

//        {
//            "series": [
//                {
//                    "uri": "wd:Q93132238",
//                    "score": 110
//                }
//            ],
//            "works": [
//                {
//                    "uri": "wd:Q93132243",
//                    "date": "2017-03-01",
//                    "serie": "wd:Q93132238",
//                    "score": 46
//                },
//                {
//                    "uri": "wd:Q93132249",
//                    "score": 31
//                },
//                {
//                    "uri": "wd:Q93132245",
//                    "date": "2020",
//                    "serie": "wd:Q93132238",
//                    "score": 30
//                },
//                {
//                    "uri": "wd:Q93132244",
//                    "date": "2018",
//                    "serie": "wd:Q93132238",
//                    "score": 29
//                },
//                {
//                    "uri": "inv:07290adaec17bf3f57847accdb196f67",
//                    "score": 25
//                },
//                {
//                    "uri": "inv:ca64a84ce0844d9109d0c11fc20e4efc",
//                    "score": 13
//                },
//                {
//                    "uri": "inv:108f2010fdf8994bdc604ba198376e0a",
//                    "score": 11
//                },
//                {
//                    "uri": "inv:399a754013f1f364e6c06eb766797c05",
//                    "score": 1
//                }
//            ],
//            "articles": []
//        }
