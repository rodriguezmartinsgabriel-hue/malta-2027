import SwiftUI
import MaltaKit

/// Aba Orcamento: acerto automatico em bloco solido, resumo, registro de
/// gastos e lista em vidro.
struct BudgetView: View {
    @Environment(MaltaStore.self) private var store
    @State private var descTx = ""
    @State private var eurTx = ""
    @State private var payer: Expense.Payer = .nana
    @FocusState private var eurFocused: Bool

    var body: some View {
        NavigationStack {
            MaltaScreen(title: "Orcamento") {
                settleCard
                summaryCard
                addCard
                expenseContent
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var settleCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    switch store.settlement.statement {
                    case .none:
                        Text("Quitado")
                            .font(Fonts.display(30))
                            .foregroundStyle(Theme.cream)
                    case .some(let s):
                        Text(s.debtor + " deve")
                            .font(.subheadline)
                            .foregroundStyle(Theme.cream.opacity(0.85))
                            .padding(.top, 2)
                        Text("EUR " + Money.brNumber(s.amount.rounded2()))
                            .font(Fonts.display(34))
                            .foregroundStyle(Theme.cream)
                    }
                }
                Spacer()
                Image(systemName: store.settlement.statement == nil ? "checkmark.circle.fill" : "banknote.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Theme.cream.opacity(0.85))
                    .padding(.top, 4)
            }
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(Theme.cream.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Theme.wineFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: Theme.wine.opacity(0.6), radius: 26, y: 14)
        }
    }

    private var subtitle: String {
        switch store.settlement.statement {
        case .none: return "ninguem deve nada"
        case .some(let s):
            return "para equilibrar com a " + (s.debtor == "Dani" ? "Nana" : "Dani")
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 10) {
            summaryRow(label: "Total gasto", value: Money.eur(store.settlement.total.rounded2()))
            summaryRow(label: "Cada uma consumiu",
                       value: Money.eur(store.settlement.eachConsumed.rounded2()))
        }
        .padding(16)
        .glass()
    }

    private var addCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScreenLabel(text: "Novo gasto").padding(.top, 0)
            TextField("Descricao - jantar, ferry, hospedagem...", text: $descTx)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.sentences)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.07))
                }
            RowField("Valor (EUR)", text: $eurTx)
            Picker("Pagou", selection: $payer) {
                Text("Nana").tag(Expense.Payer.nana)
                Text("Dani").tag(Expense.Payer.dani)
                Text("50/50").tag(Expense.Payer.ambas)
            }
            .pickerStyle(.segmented)
            joinButton
        }
        .padding(16)
        .glass()
    }

    /// Capsule filled action button.
    private var joinButton: some View {
        Button {
            addExpense()
        } label: {
            Text("Adicionar gasto")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Capsule().fill(Theme.wineFill))
                .shadow(color: Theme.wine.opacity(0.45), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var expenseContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenLabel(text: "Gastos")
            if store.expenses.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nenhum gasto ainda.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Comecem pelo aporte: transferencias, reservas e compras. Ative o sync (icone no topo do Inicio) para ficar igual nos dois aparelhos.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .glass()
            } else {
                VStack(spacing: 0) {
                    ForEach(store.expenses.reversed()) { e in
                        ExpenseRow(expense: e) {
                            store.removeExpense(id: e.id)
                        }
                        if e.id != store.expenses.first?.id {
                            Rectangle().fill(.white.opacity(0.08)).frame(height: 0.5)
                                .padding(.vertical, 6)
                        }
                    }
                }
                .padding(16)
                .glass()
            }
        }
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

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.muted)
            Spacer()
            Text(value)
                .font(Fonts.mono(14))
                .foregroundStyle(Theme.ink)
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    let onRemove: () -> Void

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
                .font(Fonts.mono(14))
                .foregroundStyle(Theme.ink)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .padding(6)
                    .background(Circle().fill(.white.opacity(0.09)))
            }
            .buttonStyle(.plain)
        }
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
