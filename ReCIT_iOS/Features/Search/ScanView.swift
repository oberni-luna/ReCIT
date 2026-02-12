//
//  AddInventoryItemScanView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import SwiftUI
import CodeScanner
import AVFoundation

struct ScanView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onResult: (String) -> Void

    var body: some View {
        CodeScannerView(
            codeTypes: [.ean13],
            simulatedData: "9782367935836",
            completion: handleScan
        )
        .ignoresSafeArea(.all)
    }

    func handleScan(result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let result):
            let details = result.string
            guard details.count == 13 else { return }
            onResult(details)
            dismiss()

        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
}
