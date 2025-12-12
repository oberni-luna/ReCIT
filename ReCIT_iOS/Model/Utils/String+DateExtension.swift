//
//  String+DateExtension.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/12/2025.
//

import Foundation

extension String {
    func parseToDate(dateFormat: String = "yyyy-MM-dd") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat

        return dateFormatter.date(from: self)
    }
}
