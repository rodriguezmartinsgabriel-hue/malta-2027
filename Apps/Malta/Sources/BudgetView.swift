import SwiftUI
import MaltaKit

/// Aba Orcamento: quem pagou o que, consumo 50/50 e acerto automatico.
struct BudgetView: View {
    @Environment(MaltaStore.self) private var store
    @State private var descTx = ""
    @State private var eurTx = ""
    @State private var payer: Expense.Payer = .nana
    @FocusState private var eurFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                settleSection
                summarySection
                addSection
                expenseSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Orcamento")
        }
    }

    /// The one solid-brand block: the automatic settlement.
    private var settleSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                switch store.settlement.statement {
                case .none:
                    Text("Quitado")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.creamOnInk)
                    Text("ninguem deve nada")
                        .font(.callout)
                        .foregroundStyle(Theme.mutedOnInk)
                case .some(let s):
                    Text(s.debtor + " deve " + Money.eur(s.amount.rounded2()))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.creamOnInk)
                    Text("para equilibrar com a " +
                         (s.debtor == "Dani" ? "Nana" : "Dani"))
                        .font(.callout)
                        .foregroundStyle(Theme.mutedOnInk)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
        }
        .listRowBackground(Theme.wine)
    }

    private var summarySection: some View {
        Section("Resumo") {
            LabeledRow(label: "Total gasto",
                       value: Money.eur(store.settlement.total.rounded2()))
            LabeledRow(label: "Cada uma consumiu",
                       value: Money.eur(store.settlement.eachConsumed.rounded2()))
        }
        .listRowBackground(Theme.paper)
    }

    private var addSection: some View {
        Section("Novo gasto") {
            TextField("Descricao - jantar, ferry, hospedagem...", text: $descTx)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.sentences)
            RowField("Valor (EUR)", text: $eurTx)
            Picker("Pagou", selection: $payer) {
                Text("Nana").tag(Expense.Payer.nana)
                Text("Dani").tag(Expense.Payer.dani)
                Text("50/50").tag(Expense.Payer.ambas)
            }
            .pickerStyle(.segmented)
            Button("Adicionar gasto") {
                addExpense()
            }
        }
        .listRowBackground(Theme.paper)
    }

    private var expenseSection: some View {
        Section("Gastos") {
            if store.expenses.isEmpty {
                Note("Nenhum gasto ainda. Comecem pelo aporte: transferencias, reservas e compras. " +
                     "Ative o sync (icone no topo do Inicio) para ficar igual nos dois aparelhos.")
                    .listRowSeparator(.hidden)
            } else {
                ForEach(store.expenses.reversed()) { e in
                    ExpenseRow(expense: e)
                }
                .onDelete { offsets in
                    let ids = offsets.map { store.expenses.reversed()[$0].id }
                    for id in ids { store.removeExpense(id: id) }
                }
            }
        }
        .listRowBackground(Theme.paper)
    }

    private func addExpense() {
        let value = Money.parse(eurTx) ?? 0
        let desc = descTx.trimmingCharacters(in: .whitespaces)
        guard !desc.isEmpty, value > 0 else { return }
        store.addExpense(desc: desc, eur: value, payer: payer)
        descTx = ""
        eurTx = ""
        eurFocused = false
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

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.desc)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text(who + " - " + dateLabel)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            Text(Money.eur(expense.eur.rounded2()))
                .font(.callout.monospacedDigit())
                .foregroundStyle(Theme.ink)
        }
        .padding(.vertical, 4)
    }

    private var who: String {
        switch expense.payer {
        case .nana: return "Nana pagou"
        case .dani: return "Dani pagou"
        case .ambas: return "Dividido 50/50"
        }
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM"
        return f.string(from: expense.at)
    }
}
