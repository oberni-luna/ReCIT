//
//  AddInventoryItemScanView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import SwiftUI
import CodeScanner
internal import AVFoundation

struct AddInventoryItemScanView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isShowingScanner:Bool = false
    @State private var path: NavigationPath = .init()
    
    var body: some View {
        NavigationStack(path: $path) {
            CodeScannerView(
                codeTypes: [.ean13],
                simulatedData: "9782367935836",
                completion: handleScan
            )
            .ignoresSafeArea(.all)
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
        }
    }

    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false

        switch result {
        case .success(let result):
            let details = result.string
            guard details.count == 13 else { return }

            let editionUri = "isbn:\(details)"
            path.append(NavigationDestination.edition(uri: editionUri))

        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }

    }
}

#Preview {
    AddInventoryItemScanView()
}
