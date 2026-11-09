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
                    StatCell(label: "Cada uma", value: Money.eur(store.budgetEur / 2))
                    StatCell(label: "Projecao", value: Money.brl(store.cofrinho.saved))
                }
                GridRow {
                    StatCell(label: "Aportes restantes",
                             value: "\(store.cofrinho.months + 1)")
                    StatCell(label: "Meta em euros", value: Money.eur(store.budgetEur))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var milestonesSection: some View {
        Section("Marcos ate o embarque") {
            ForEach(Milestones.all.prefix(3)) { m in
                MilestoneRow(milestone: m)
            }
            DisclosureGroup("Os outros \(max(0, Milestones.all.count - 3)) marcos") {
                ForEach(Milestones.all.dropFirst(3)) { m in
                    MilestoneRow(milestone: m)
                }
            }
        }
    }
}

private struct MilestoneRow: View {
    let milestone: Milestone

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(String(format: "%02d", milestone.id))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.olive)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(milestone.body)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
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
    @State private var metaTx = ""
    @State private var seeded = false

    var body: some View {
        Section("Poupanca") {
            RowField("Aporte por mes", text: $monthlyTx)
            RowField("Meta total", text: $metaTx)
            progressRow
                .listRowSeparator(.hidden)
        }
        .onAppear {
            guard !seeded else { return }
            seeded = true
            monthlyTx = Money.brNumber(store.settings.monthly)
            metaTx = Money.brNumber(store.settings.meta)
        }
        .onChange(of: monthlyTx) { _, v in
            store.settings.monthly = Money.parse(v) ?? 0
        }
        .onChange(of: metaTx) { _, v in
            store.settings.meta = Money.parse(v) ?? 0
        }
    }

    private var progressRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressLine(ratio: store.cofrinho.ratio)
            Note(progressText)
        }
        .padding(.vertical, 4)
    }

    private var progressText: String {
        let c = store.cofrinho
        let remaining = max(0, store.settings.meta - c.saved)
        if remaining < 0.5 {
            return "Meta atingida com " + "\(c.months + 1)" + " aportes de " +
                Money.brl(store.settings.monthly) + "."
        }
        return "Faltam " + Money.brl(remaining) + " para a meta de " +
            Money.brl(store.settings.meta) + ". A cotacao fica na aba Dinheiro."
    }
}
