import SwiftUI
import MaltaKit

/// Aba Dinheiro: conversor R$ -> EUR por caminho, comparacao de contas e taxas.
struct MoneyView: View {
    @Environment(MaltaStore.self) private var store
    @State private var brlTx = "10.000"
    @State private var presetIdx = 0

    var body: some View {
        NavigationStack {
            List {
                converterSection
                accountSection
                recommendationSection
                taxSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Dinheiro")
        }
    }

    private var converterSection: some View {
        Section {
            RowField("Reais (R$)", text: $brlTx)
            presetRow
            HStack(alignment: .firstTextBaseline) {
                Text("Voce recebe")
                Spacer(minLength: 12)
                Text(convEur)
                    .font(Fonts.display(30))
                    .foregroundStyle(Theme.wine)
            }
        } header: {
            Text("Converter")
        } footer: {
            Note(convCost)
        }
        .listRowBackground(Theme.paper)
    }

    private var presetRow: some View {
        Menu {
            ForEach(Array(Seeds.presets.enumerated()), id: \.offset) { idx, p in
                Button(p.name) { presetIdx = idx }
            }
        } label: {
            HStack {
                Text("Caminho")
                Spacer(minLength: 12)
                Text(Seeds.presets[presetIdx].name)
                    .foregroundStyle(Theme.muted)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var accountSection: some View {
        Section("Onde abrir") {
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    Text("CONTA").gridCellColumns(1)
                    Text("EUR")
                    Text("CUSTO*")
                    Text("ABERTURA")
                }
                .font(.caption2.monospaced())
                .foregroundStyle(Theme.muted)
                ForEach(accountRows) { row in
                    GridRow {
                        Text(row.name).gridCellColumns(1)
                        Text(row.eur)
                        Text(row.cost)
                        Text(row.opening)
                    }
                    .font(.footnote)
                }
            }
            Note("* custo medio por operacao. O FGC brasileiro nao cobre contas em EUR/USD.")
                .listRowSeparator(.hidden)
        }
        .listRowBackground(Theme.paper)
    }

    private var recommendationSection: some View {
        Section("Recomendado para as duas") {
            Text(moneyRecommendation)
                .font(.footnote)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .listRowBackground(Theme.paper)
    }

    private var taxSection: some View {
        Section("Taxas de cambio") {
            LabeledRow(label: "IOF no cambio", value: "3,5%")
            LabeledRow(label: "Via investimento", value: "1,1%")
            LabeledRow(label: "FGC em EUR/USD", value: "Nao existe")
        }
        .listRowBackground(Theme.paper)
    }

    private var amount: Double {
        Money.parse(brlTx) ?? 0
    }

    private var convEur: String {
        let got = Seeds.brlToEur(amount, rate: store.fx, preset: Seeds.presets[presetIdx])
        return Money.eur(got.rounded2())
    }

    private var convCost: String {
        let p = Seeds.presets[presetIdx]
        let got = Seeds.brlToEur(amount, rate: store.fx, preset: p)
        return "No caminho " + p.name + ": " + Money.brl((amount - got * store.fx).rounded2()) +
            " em impostos e spread."
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(Theme.muted)
        }
    }
}

/// Inline footer with the conversion cost, shared with the converter section.
/// Reference from Content.swift (global in MaltaKit).
private let accountRows = MaltaKit.accountRows

extension Double {
    func rounded2() -> Double {
        (self * 100).rounded() / 100
    }
}
