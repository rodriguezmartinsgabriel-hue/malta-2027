import SwiftUI
import MaltaKit

/// Aba Roteiro: cartao de embarque + 21 dias agrupados em semanas de vidro.
struct ItineraryView: View {
    @Environment(MaltaStore.self) private var store

    var body: some View {
        NavigationStack {
            MaltaScreen(title: "Roteiro") {
                departureCard
                ForEach(weekStarts, id: \.self) { start in
                    weekCard(start: start)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var departureCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenLabel(text: "Embarque").padding(.top, 0)
            HStack {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.wineBright)
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
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "pt_BR"))
            }
            Text("Datas calculadas a partir do embarque. Toque na data de um dia para marca-lo como pronto.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .glass()
    }

    private var weekStarts: [Int] {
        stride(from: 0, to: max(store.itinerary.count, 1), by: 7).map { $0 }
    }

    private func weekCard(start: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenLabel(text: "Semana \(start / 7 + 1)")
            let days = Array(store.itinerary.enumerated())
                .dropFirst(start)
                .prefix(7)
            VStack(spacing: 2) {
                ForEach(Array(days), id: \.element.id) { idx, day in
                    DayRow(index: idx,
                           date: Trip.itineraryDate(startISO: store.settings.start, dayIndex: idx),
                           day: day,
                           onTitle: { store.itinerary[idx].title = $0 },
                           onNote: { store.itinerary[idx].note = $0 },
                           onDone: { store.itinerary[idx].done = $0 })
                    if idx != (start + days.count - 1) {
                        Rectangle().fill(Theme.hairline).frame(height: 0.5)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(16)
        .glass()
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
            // Tap the date to mark the day ready (success feedback on done).
            Button {
                onDone(!day.done)
            } label: {
                VStack(spacing: 1) {
                    Text(Trip.dayMonthLabel(for: date))
                        .font(Fonts.display(19))
                        .foregroundStyle(day.done ? Theme.oliveBright : Theme.ink)
                        .strikethrough(day.done, color: Theme.oliveBright)
                    Text(Trip.weekdayLabel(for: date))
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
                .frame(width: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text("DIA \(index + 1)")
                    .font(.caption2)
                    .foregroundStyle(day.done ? Theme.oliveBright : Theme.muted)
                    .tracking(0.8)
                TextField("Sugestao do dia...", text: Binding(
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
        .padding(.vertical, 2)
        .sensoryFeedback(.success, trigger: day.done) { _, _ in
            day.done
        }
    }
}
