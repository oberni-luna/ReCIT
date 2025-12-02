//
//  Entityimage.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2025.
//

import SwiftUI

struct EditionImage: View {
    let imageUrl: String?
    let contentMode: ContentMode
    
    var body: some View {
        if let url = URL(string: imageUrl ?? "") {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } placeholder: {
                ProgressView()
            }
        } else {
            Image(.eventPlaceholder)
                .resizable()
        }
    }
}

#Preview {
    EditionImage(imageUrl: "https://inventaire.io/img/entities/1000x1000/bc2052c59270ba1bc041fadf790648b2290ae6c0", contentMode: .fill)
}
