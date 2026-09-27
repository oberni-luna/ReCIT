//
//  GroupSettingPayload.swift
//  ReCIT_iOS
//
//  The body of `PUT /api/groups/update-settings`: one attribute and its new value per call.
//

import Foundation

struct GroupSettingPayload: Codable {
    let group: String
    let attribute: String
    let value: GroupSetting.Value
}
