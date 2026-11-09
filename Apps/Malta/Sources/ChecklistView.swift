import SwiftUI
import MaltaKit

/// Aba Checklist: documentos, mala e dinheiro com progresso unico.
struct ChecklistView: View {
    @Environment(MaltaStore.self) private var store
    @State private var selectedGroup = 0
    @State private var newItemTx = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Grupo", selection: $selectedGroup) {
                        ForEach(Array(Seeds.checklistGroups.enumerated()), id: \.element.index) { idx, g in
                            Text(g.label).tag(idx)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Theme.paper)
                } footer: {
                    Note(progressText)
                }

                itemsSection

                Section {
                    TextField("Adicionar item...", text: $newItemTx)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.sentences)
                        .onSubmit(addItem)
                        .submitLabel(.done)
                }
                .listRowBackground(Theme.paper)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Checklist")
        }
    }

    private var group: ChecklistItem.Group {
        ChecklistItem.Group.allCases[selectedGroup]
    }

    private var items: [ChecklistItem] {
        store.checklist[group] ?? []
    }

    private var progressRatio: Double {
        let c = store.checklistCounts
        return c.total > 0 ? Double(c.done) / Double(c.total) : 0
    }

    private var progressText: String {
        let c = store.checklistCounts
        return "\(c.done) de \(c.total) concluidos no geral. Nesta lista: " +
            "\(items.filter(\.done).count)/\(items.count)."
    }

    private var itemsSection: some View {
        Section {
            ForEach(items) { item in
                ChecklistRow(item: item,
                             onToggle: { store.toggleChecklistItem(item, group: group) })
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.removeChecklistItem(item, group: group)
                        } label: {
                            Label("Remover", systemImage: "trash")
                        }
                    }
            }
        } header: {
            Text(Seeds.checklistGroups[selectedGroup].label)
        } footer: {
            ProgressLine(ratio: progressRatio)
                .padding(.top, 4)
        }
        .listRowBackground(Theme.paper)
    }

    private func addItem() {
        let t = newItemTx.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        store.addChecklistItem(t, group: group)
        newItemTx = ""
    }
}

private struct ChecklistRow: View {
    let item: ChecklistItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(item.done ? Theme.olive : Theme.muted)
                Text(item.text)
                    .font(.subheadline)
                    .foregroundStyle(item.done ? Theme.muted : Theme.ink)
                    .strikethrough(item.done, color: Theme.olive)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
