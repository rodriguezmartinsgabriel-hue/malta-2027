import SwiftUI
import MaltaKit

/// Aba Dinheiro: cotacao (manual + ao vivo), conversor, contas e taxas.
struct MoneyView: View {
    @Environment(MaltaStore.self) private var store
    @State private var brlTx = "10.000"
    @State private var presetIdx = 0
    @State private var fxTx = ""
    @State private var fxSeeded = false

    var body: some View {
        NavigationStack {
            MaltaScreen(title: "Dinheiro") {
                rateCard
                converterCard
                accountsContent
                taxContent
            }
            .toolbar(.hidden, for: .navigationBar)
        }
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

    // MARK: - Cards

    private var rateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                ScreenLabel(text: "Cotacao").padding(.top, 0)
                Spacer()
                Text("EUR 1 = R$ " + Money.brNumber(store.fx))
                    .font(Fonts.mono(13))
                    .foregroundStyle(store.fxSourceIsLive ? Theme.oliveBright : Theme.muted)
            }
            RowField("Cotacao manual", text: $fxTx)
            Toggle(isOn: Binding(
                get: { store.useLiveFX },
                set: { on in
                    store.setUseLiveFX(on)
                    Task { await store.refreshLiveFX() }
                })) {
                Text("Cotacao ao vivo")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
            }
            .tint(Theme.wineBright)
            Text(rateNote)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glass()
        .onAppear {
            guard !fxSeeded else { return }
            fxSeeded = true
            fxTx = String(format: "%.2f", store.settings.manualFx)
                .replacingOccurrences(of: ".", with: ",")
        }
        .onChange(of: fxTx) { _, v in
            let manual = Money.parse(v) ?? 0
            store.settings.manualFx = manual > 1 ? manual : TripSettings.defaultFx
        }
    }

    private var rateNote: String {
        guard store.useLiveFX else {
            return "Manual em uso. Ligue ao vivo para buscar de open.er-api.com."
        }
        if let q = store.liveQuote,
           Date().timeIntervalSince(q.fetchedAt) < 60 * 60 * 36 {
            return "Ao vivo: open.er-api.com, atualizada " + stamp(q) + "."
        }
        return "Sem cotacao ao vivo agora - usando a ultima conocida ou a manual."
    }

    private var converterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScreenLabel(text: "Converter")
            RowField("Reais (R$)", text: $brlTx)
            Menu {
                ForEach(Array(Seeds.presets.enumerated()), id: \.offset) { idx, p in
                    Button(p.name) { presetIdx = idx }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(Seeds.presets[presetIdx].name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.soft))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text("Voce recebe")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                Text(convEur)
                    .font(Fonts.display(40))
                    .foregroundStyle(Theme.oliveBright)
                    .shadow(color: Theme.oliveBright.opacity(0.35), radius: 14, y: 1)
            }
            .padding(.top, 2)
            Text(convCost)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .glass()
    }

    private var accountsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenLabel(text: "Onde abrir")
            VStack(spacing: 12) {
                ForEach(accountRows) { row in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Text(row.eur)
                                .font(.caption2)
                                .foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Text(row.cost)
                            .font(Fonts.mono(13))
                            .foregroundStyle(Theme.wineBright)
                    }
                    .padding(.vertical, 3)
                    if row.id != accountRows.last?.id {
                        Rectangle().fill(Theme.hairline).frame(height: 0.5)
                    }
                }
            }
            .padding(16)
            .glass()
        }
    }

    private var taxContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenLabel(text: "Taxas de cambio")
            VStack(spacing: 10) {
                taxRow(label: "IOF no cambio", value: "3,5%")
                taxRow(label: "Via investimento", value: "1,1%")
                taxRow(label: "FGC em EUR/USD", value: "Nao existe")
            }
            .padding(16)
            .glass()
        }
    }

    private func taxRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.muted)
            Spacer()
            Text(value)
                .font(Fonts.mono(14))
                .foregroundStyle(Theme.ink)
        }
    }

    private func stamp(_ q: FXQuote) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM HH'h'"
        return f.string(from: q.fetchedAt)
    }
}
