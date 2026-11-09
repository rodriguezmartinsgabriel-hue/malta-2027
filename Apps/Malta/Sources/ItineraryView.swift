import SwiftUI
import MaltaKit

/// Aba Roteiro: data do embarque + 21 dias datados, titulo/nota editaveis.
struct ItineraryView: View {
    @Environment(MaltaStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Data", selection: Binding(
                        get: { Trip.date(fromISO: store.settings.start) },
                        set: { d in
                            let cal = Calendar.current
                            let comp = cal.dateComponents([.year, .month, .day], from: d)
                            store.settings.start = String(
                                format: "%04d-%02d-%02d",
                                comp.year ?? 2027, comp.month ?? 8, comp.day ?? 28)
                        }),
                        displayedComponents: [.date])
                } header: {
                    Text("Embarque")
                } footer: {
                    Note("Datas calculadas a partir do embarque. Titulos e notas sao sugestao inicial - editam quando quiser.")
                }
                daysSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Roteiro")
        }
    }

    private var daysSection: some View {
        ForEach(weekStarts, id: \.self) { start in
            Section("Semana \(start / 7 + 1)") {
                ForEach(Array(store.itinerary.enumerated())
                    .dropFirst(start)
                    .prefix(7), id: \.element.id) { idx, day in
                    DayRow(index: idx,
                           date: Trip.itineraryDate(startISO: store.settings.start, dayIndex: idx),
                           day: day,
                           onTitle: { store.itinerary[idx].title = $0 },
                           onNote: { store.itinerary[idx].note = $0 },
                           onDone: { store.itinerary[idx].done = $0 })
                }
            }
            .listRowBackground(Theme.paper)
        }
    }

    private var weekStarts: [Int] {
        stride(from: 0, to: max(store.itinerary.count, 1), by: 7).map { $0 }
    }
}

private struct DayRow: View {
    let index: Int
    let date: Date
    @State var day: ItineraryDay
    let onTitle: (String) -> Void
    let onNote: (String) -> Void
    let onDone: (Bool) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Toque na data marca o dia como pronto (fila de viagem feita).
            Button {
                onDone(!day.done)
            } label: {
                VStack(spacing: 1) {
                    Text(Trip.dayMonthLabel(for: date))
                        .font(Fonts.display(20))
                        .foregroundStyle(day.done ? Theme.olive : Theme.wine)
                    Text(Trip.weekdayLabel(for: date))
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                    if day.done {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundStyle(Theme.olive)
                    }
                }
                .frame(width: 54)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("DIA \(index + 1)")
                    .font(.caption2)
                    .foregroundStyle(Theme.olive)
                TextField("", text: Binding(
                    get: { day.title },
                    set: { onTitle($0) }
                ))
                .font(.subheadline)
                .foregroundStyle(day.done ? Theme.muted : Theme.ink)
                .autocorrectionDisabled()
                .strikethrough(day.done, color: Theme.olive)
                .textFieldStyle(.plain)
                TextField("Anotacoes...", text: Binding(
                    get: { day.note },
                    set: { onNote($0) }
                ))
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .autocorrectionDisabled()
                .textFieldStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
