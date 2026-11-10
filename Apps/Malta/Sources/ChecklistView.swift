import SwiftUI
import MaltaKit

/// Aba Checklist: chips de grupo, anel de progresso e itens em vidro.
struct ChecklistView: View {
    @Environment(MaltaStore.self) private var store
    @State private var selectedGroup = 0
    @State private var newItemTx = ""

    var body: some View {
        NavigationStack {
            MaltaScreen(title: "Checklist") {
                ringCard
                chipsRow
                itemsCard
                addRow
            }
            .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - Cards

    private var ringCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Theme.hairline, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progressRatio)
                    .stroke(Theme.glowFill, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.wineBright.opacity(0.4), radius: 6)
                    .opacity(progressRatio > 0 ? 1 : 0)
                Text("\(Int((progressRatio * 100).rounded()))%")
                    .font(Fonts.display(19))
                    .foregroundStyle(Theme.ink)
            }
            .frame(width: 66, height: 66)
            VStack(alignment: .leading, spacing: 3) {
                Text("No geral")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                let c = store.checklistCounts
                Text("\(c.done) de \(c.total) concluidos")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(items.filter(\.done).count > 0
                        ? "Neste grupo: \(items.filter(\.done).count)/\(items.count)."
                        : "Nada marcado neste grupo ainda.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
        }
        .padding(16)
        .glass()
    }

    private var chipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(Seeds.checklistGroups.enumerated()), id: \.element.index) { idx, g in
                    chip(idx: idx, label: g.label)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func chip(idx: Int, label: String) -> some View {
        let active = selectedGroup == idx
        return Button {
            withAnimation(.snappy(duration: 0.25)) { selectedGroup = idx }
        } label: {
            Text(label)
                .font(.subheadline.weight(active ? .semibold : .regular))
                .foregroundStyle(active ? Theme.cream : Theme.muted)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if active {
                        Capsule().fill(Theme.wineFill)
                            .shadow(color: Theme.wine.opacity(0.5), radius: 8, y: 3)
                    } else {
                        Capsule().fill(Theme.soft)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var itemsCard: some View {
        VStack(spacing: 4) {
            ForEach(items) { item in
                ChecklistRow(item: item,
                             onToggle: { store.toggleChecklistItem(item, group: group) },
                             onRemove: { store.removeChecklistItem(item, group: group) })
                if item.id != items.last?.id {
                    Rectangle().fill(Theme.hairline).frame(height: 0.5)
                        .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .glass()
    }

    private var addRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.wineBright)
            TextField("Adicionar item...", text: $newItemTx)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.sentences)
                .onSubmit(addItem)
                .submitLabel(.done)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glass(corner: 20)
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
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(item.done ? Theme.oliveBright : Theme.muted)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            Text(item.text)
                .font(.subheadline)
                .foregroundStyle(item.done ? Theme.muted : Theme.ink)
                .strikethrough(item.done, color: Theme.olive)
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted.opacity(0.7))
                    .padding(6)
                    .background(Circle().fill(Theme.softStrong))
            }
            .buttonStyle(.plain)
            .opacity(item.done ? 1 : 0)
        }
        .sensoryFeedback(.success, trigger: item.done) { _, _ in
            item.done
        }
    }
}
