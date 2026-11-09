import SwiftUI
import MaltaKit

/// Aba Inicio: hero em vidro, contagem de dias viva, numeros-chave,
/// poupanca e marcos.
struct HomeView: View {
    @Environment(MaltaStore.self) private var store
    @State private var showingSync = false

    var body: some View {
        NavigationStack {
            MaltaScreen(title: "Malta 2027", subtitle: "21 dias entre o fim de agosto e o inicio de setembro.") {
                countdownCard
                statsCard
                CofrinhoCard()
                marcosContent
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingSync) {
                SyncSheetView()
            }
        }
    }

    private var syncButton: some View {
        Button {
            showingSync = true
        } label: {
            Image(systemName: "person.2.circle")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(width: 38, height: 38)
                .glass(corner: 19)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .accessibilityLabel("Sync")
    }

    private var countdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(days)")
                    .font(Fonts.display(76))
                    .foregroundStyle(Theme.wineBright)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy(duration: 0.5), value: days)
                    .shadow(color: Theme.wineBright.opacity(0.5), radius: 22, y: 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("dias")
                        .font(Fonts.display(26))
                        .foregroundStyle(Theme.ink)
                    Text("ate o embarque")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 22)
                Spacer()
                syncButton
            }
            let date = Trip.date(fromISO: store.settings.start)
            Text("Embarque 28 de agosto - " + Trip.weekdayLabel(for: date))
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .padding(.leading, 4)
        }
        .padding(18)
        .glass(glow: Theme.wine)
    }

    private var days: Int {
        Trip.countdown(toISO: store.settings.start)
    }

    private var statsCard: some View {
        VStack(spacing: 0) {
            ScreenLabel(text: "Nesta altura")
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    GlassStat(label: "Cada uma", value: Money.eur(store.budgetEur / 2))
                    GlassStat(label: "Meta em euros", value: Money.eur(store.budgetEur))
                }
                GridRow {
                    GlassStat(label: "Projecao", value: Money.brl(store.cofrinho.saved))
                    GlassStat(label: "Aportes restantes",
                              value: "\(store.cofrinho.months + 1)")
                }
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glass()
    }

    private var marcosContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenLabel(text: "Marcos ate o embarque")
            VStack(spacing: 12) {
                ForEach(Milestones.all.prefix(3)) { m in
                    MilestoneRow(milestone: m)
                }
                DisclosureGroup {
                    ForEach(Milestones.all.dropFirst(3)) { m in
                        MilestoneRow(milestone: m)
                    }
                } label: {
                    Text("Os outros \(max(0, Milestones.all.count - 3)) marcos")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
                .tint(Theme.muted)
            }
            .padding(16)
            .glass()
        }
    }
}

private struct MilestoneRow: View {
    let milestone: Milestone

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(String(format: "%02d", milestone.id))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Theme.oliveBright)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 3) {
                Text(milestone.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(milestone.body)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
    }
}

/// Poupanca: aporte + meta + progresso, em vidro.
struct CofrinhoCard: View {
    @Environment(MaltaStore.self) private var store
    @State private var monthlyTx = ""
    @State private var metaTx = ""
    @State private var seeded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ScreenLabel(text: "Poupanca")
                    .padding(.top, 0)
                Spacer()
                Text(Money.brNumber(store.settings.meta))
                    .font(Fonts.mono(13))
                    .foregroundStyle(Theme.muted)
            }
            RowField("Aporte por mes", text: $monthlyTx)
            RowField("Meta total", text: $metaTx)
            ProgressLine(ratio: store.cofrinho.ratio)
                .padding(.top, 2)
            Text(progressText)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glass()
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

    private var progressText: String {
        let c = store.cofrinho
        let remaining = max(0, store.settings.meta - c.saved)
        if remaining < 0.5 {
            return "Meta atingida. A cotacao fica na aba Dinheiro."
        }
        return "Faltam " + Money.brl(remaining) + " para a meta. A cotacao fica na aba Dinheiro."
    }
}
