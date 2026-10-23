//
//  EnvironmentValues+SyncUserData.swift
//  ReCIT_iOS
//
//  Where `SyncUserDataAction` is found: set by `RootView`, read by « Tout »'s status pill.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var syncUserData: SyncUserDataAction = .init {}
}
