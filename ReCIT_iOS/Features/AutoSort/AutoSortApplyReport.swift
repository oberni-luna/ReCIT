//
//  AutoSortApplyReport.swift
//  ReCIT_iOS
//
//  What the run did, said in words at the foot of the list.
//
//  The marks up the list already show it shelf by shelf, but a partial failure is the
//  one outcome a user has to be able to read without counting rows: nothing is rolled
//  back, so the étagères that landed are theirs now and the ones that did not were
//  never created. Both halves are named rather than counted, because "6 sur 8" does
//  not tell anyone which two are missing.
//
//  It also says what recovery is: another run, which is safe because the next plan is
//  built from the books that are still on no étagère. See PRD 0006.
//

import SwiftUI

struct AutoSortApplyReport: View {
    let progress: AutoSortApplyProgress

    var body: some View {
        switch progress.result {
        case .running:
            EmptyView()
        case .allLanded:
            Text("\(progress.landedCount) étagère\(progress.landedCount > 1 ? "s ont" : " a") été créée\(progress.landedCount > 1 ? "s" : "") et remplie\(progress.landedCount > 1 ? "s" : "").")
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
        case .stopped(let landed, let failed, let notAttempted):
            VStack(alignment: .leading, spacing: .sMedium) {
                Text("Le rangement s'est arrêté en cours de route. Ce qui a été créé est conservé.")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)

                if landed.isEmpty {
                    Text("Aucune étagère n'a été créée et remplie.")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                } else {
                    Text("Créée\(landed.count > 1 ? "s" : "") et remplie\(landed.count > 1 ? "s" : "") : \(landed.joined(separator: ", ")).")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }

                // Said separately from "non créée" on purpose: nothing is rolled back, so
                // the étagère the run broke on may be sitting in the carousel empty. A
                // user told it was not created would go looking for it and find it.
                if failed.isEmpty == false {
                    Text("Échec sur \(failed.joined(separator: ", ")) : l'étagère a pu être créée sans ses livres. Vous pouvez la supprimer si elle est vide.")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }

                if notAttempted.isEmpty == false {
                    Text("Non créée\(notAttempted.count > 1 ? "s" : "") : \(notAttempted.joined(separator: ", ")).")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }

                Text("Relancez le rangement pour reprendre : seuls les livres encore sans étagère seront proposés, donc rien ne sera créé en double.")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
    }
}
