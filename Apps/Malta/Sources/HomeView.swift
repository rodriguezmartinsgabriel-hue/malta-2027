import SwiftUI
import MaltaKit

/// Aba Inicio: hero da data, numeros principais, poupanca e marcos.
struct HomeView: View {
    @Environment(MaltaStore.self) private var store
    @State private var showingSync = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    hero
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    countdown
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                statsSection
                CofrinhoSection()
                milestonesSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingSync) {
                SyncSheetView()
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button {
                    showingSync = true
                } label: {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.wine)
                }
            }
            Text("Malta")
                .font(Fonts.display(56))
                .foregroundStyle(Theme.ink)
                .padding(.top, 4)
            Text(store.settings.start == Trip.defaultStart ? "2027." : "A caminho.")
                .font(Fonts.display(56).italic())
                .foregroundStyle(Theme.ink)
                .padding(.top, -14)
            Text("21 dias entre o fim de agosto e o inicio de setembro de 2027.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
        }
    }

    private var countdown: some View {
        let days = Trip.countdown(toISO: store.settings.start)
        return VStack(alignment: .leading, spacing: 0) {
            Text("\(days)")
                .font(Fonts.display(64))
                .foregroundStyle(Theme.wine)
            Text(days == 1 ? "dia ate o embarque" : "dias ate o embarque")
                .font(.callout)
                .foregroundStyle(Theme.muted)
            Note("Embarque " + Trip.longDateLabel(for: Trip.date(fromISO: store.settings.start)))
                .padding(.top, 10)
        }
    }

    private var statsSection: some View {
        Section {
            Grid(alignment: .leading, verticalSpacing: 12) {
                GridRow {
                    StatCell(label: "Meta total", value: Money.brl(store.settings.meta))
                    StatCell(label: "Orcamento", value: Money.eur(store.budgetEur))
                }
                GridRow {
                    StatCell(label: "Cada uma", value: Money.eur(store.budgetEur / 2))
                    StatCell(label: "Cotacao", value: "EUR 1 = R$ " + Money.brNumber(store.fx))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var milestonesSection: some View {
        Section("Marcos ate o embarque") {
            ForEach(Milestones.all) { m in
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d", m.id))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.olive)
                        .padding(.top, 3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                        Text(m.body)
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(Fonts.display(24))
                .foregroundStyle(Theme.ink)
        }
    }
}

/// Poupanca: aporte, meta, cotacao e progresso em linhas nativas de lista.
struct CofrinhoSection: View {
    @Environment(MaltaStore.self) private var store
    @State private var monthlyTx = ""
    @State private var fxTx = ""
    @State private var metaTx = ""
    @State private var seeded = false

    var body: some View {
        Section("Poupanca") {
            RowField("Aporte por mes", text: $monthlyTx)
            RowField("Meta total", text: $metaTx)
            RowField("Cotacao EUR/BRL", text: $fxTx)
            Toggle(isOn: Binding(
                get: { store.useLiveFX },
                set: { on in
                    store.setUseLiveFX(on)
                    Task { await store.refreshLiveFX() }
                })) {
                Text("Cotacao ao vivo")
            }
            progressRow
                .listRowSeparator(.hidden)
        }
        .listRowBackground(Theme.paper)
        .onAppear {
            guard !seeded else { return }
            seeded = true
            monthlyTx = Money.brNumber(store.settings.monthly)
            fxTx = String(format: "%.2f", store.settings.manualFx).replacingOccurrences(of: ".", with: ",")
            metaTx = Money.brNumber(store.settings.meta)
        }
        .onChange(of: monthlyTx) { _, v in
            store.settings.monthly = Money.parse(v) ?? 0
        }
        .onChange(of: fxTx) { _, v in
            let manual = Money.parse(v) ?? 0
            store.settings.manualFx = manual > 1 ? manual : TripSettings.defaultFx
        }
        .onChange(of: metaTx) { _, v in
            store.settings.meta = Money.parse(v) ?? 0
        }
    }

    private var progressRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressLine(ratio: store.cofrinho.ratio)
            Note(store.cofrinho.text)
            Note(fxNote)
        }
        .padding(.vertical, 4)
    }

    private var fxNote: String {
        guard store.useLiveFX else { return "Cotacao manual.\n* cambio usado nos calculos em EUR." }
        if let q = store.liveQuote, Date().timeIntervalSince(q.fetchedAt) < 60 * 60 * 36 {
            return "Cotacao ao vivo: open.er-api.com, atualizada " + stamp(q) + "."
        }
        return "Sem cotacao ao vivo agora - usando a ultima conhecida."
    }

    private func stamp(_ q: FXQuote) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM HH'h'"
        return f.string(from: q.fetchedAt)
    }
}
