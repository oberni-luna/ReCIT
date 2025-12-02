//
//  SettingsView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @ObservedObject var authModel: AuthModel
    @State private var isOn: Bool = false
    @Query var users: [User]

    var body: some View {
        Group {
            if authModel.isAuthenticated {
                connectedView
            } else {
                anonymousView
            }
        }
        .navigationTitle("Profile")
    }

    @ViewBuilder
    var connectedView: some View {
        VStack {
            if authModel.isAuthenticated, let user = users.first {
                Text("Utilisateur: \(user.username)")
                
                AsyncButton(action: {
                    Task {
                        await authModel.logout()
                    }
                }, label: {
                    Text("Se déconnecter")
                })
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()

    }

    @ViewBuilder
    var anonymousView: some View {
        Text("Vous n'êtes pas connecté.")
    }
}
