//
//  CreateAccountPlaceholderView.swift
//  ReCIT_iOS
//
//  What "Créer un compte" reaches until issue 0057 builds the form: one sentence saying so.
//
//  It exists because the welcome screen offers two doors and a door that opens onto nothing is
//  worse than a door that says "not yet". Everything else in this slice is finished; this is the
//  only placeholder, and it is deliberately too small to be mistaken for a start on 0057's work.
//
//  See PRD 0010 and issues 0056 and 0057.
//

import SwiftUI

struct CreateAccountPlaceholderView: View {
    var body: some View {
        VStack(spacing: .medium) {
            Text("signup.placeholder.body")
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.all, .large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundDefault)
        .navigationTitle(Text("login.button.create_account"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CreateAccountPlaceholderView()
    }
}
