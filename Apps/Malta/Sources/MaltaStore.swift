import SwiftUI
import MaltaKit

/// Observable state holder. Local persistence = UserDefaults (same key names as the
/// PWA). When a Supabase project is configured, every mutation pushes and every
/// launch merges the shared data, so both phones stay equal.

struct ChecklistArchive: Codable {
    var groups: [Int: [ChecklistItem]]
}

@Observable
final class MaltaStore {
    var settings: TripSettings {
        didSet { encode(settings, key: "settings") }
    }
    var expenses: [Expense] {
        didSet { encode(expenses, key: "expenses") }
    }
    var itinerary: [ItineraryDay] {
        didSet { encode(itinerary, key: "itinerary") }
    }
    var checklist: [ChecklistItem.Group: [ChecklistItem]] {
        didSet { encode(ChecklistArchive(groups: keyedGroups()), key: "checklist") }
    }
    var liveQuote: FXQuote?
    var useLiveFX: Bool
    var tripID: String
    var remoteURL: String
    var remoteKey: String
    var syncStatus: SyncStatus = .offline

    enum SyncStatus: Equatable {
        case offline            // sem configuracao
        case syncing
        case synced(Date)
        case failed(String)

        var label: String {
            switch self {
            case .offline: return "Modo local - sem sync"
            case .syncing: return "Sincronizando..."
            case .synced: return "Sincronizado"
            case .failed(let msg): return "Falha: \(msg)"
            }
        }
    }

    private let defaults: UserDefaults
    private let iso: ISO8601DateFormatter

    // MARK: init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        iso = f

        if var s = MaltaStore.dec(TripSettings.self, "settings", defaults) {
            if s.start.isEmpty { s.start = Trip.defaultStart }
            // migracao: sessoes antigas gravaram meta com parse quebrado (ex.: 10)
            if s.meta < 100 { s.meta = TripSettings.defaultMeta }
            if s.monthly < 0 { s.monthly = TripSettings.defaultMonthly }
            if s.manualFx <= 1 { s.manualFx = TripSettings.defaultFx }
            settings = s
        } else {
            settings = TripSettings()
        }
        expenses = MaltaStore.dec([Expense].self, "expenses", defaults) ?? []
        itinerary = MaltaStore.dec([ItineraryDay].self, "itinerary", defaults) ?? Seeds.itinerary

        if let archive = MaltaStore.dec(ChecklistArchive.self, "checklist", defaults) {
            var groups: [ChecklistItem.Group: [ChecklistItem]] = [:]
            for g in ChecklistItem.Group.allCases {
                let idx = ChecklistItem.Group.allCases.firstIndex(of: g) ?? 0
                groups[g] = archive.groups[idx] ?? []
            }
            checklist = groups
        } else {
            let seed = Seeds.checklist()
            checklist = seed
        }
        liveQuote = MaltaStore.dec(FXQuote.self, "fxQuote", defaults)
        useLiveFX = defaults.bool(forKey: "useLiveFX") || defaults.object(forKey: "useLiveFX") == nil
        tripID = defaults.string(forKey: "tripID") ?? ""
        remoteURL = defaults.string(forKey: "remoteURL") ?? ""
        remoteKey = defaults.string(forKey: "remoteKey") ?? ""
    }

    private func keyedGroups() -> [Int: [ChecklistItem]] {
        var out: [Int: [ChecklistItem]] = [:]
        for g in ChecklistItem.Group.allCases {
            out[ChecklistItem.Group.allCases.firstIndex(of: g) ?? 0] = checklist[g] ?? []
        }
        return out
    }

    // MARK: fx

    /// Live quando valido e ativado; senao manual (36h de validade).
    var fx: Double {
        if useLiveFX, let q = liveQuote, q.rate > 1,
           Date().timeIntervalSince(q.fetchedAt) < 60 * 60 * 36 {
            return q.rate
        }
        return settings.manualFx
    }

    var fxSourceIsLive: Bool {
        fx != settings.manualFx || (useLiveFX && liveQuote != nil && Date().timeIntervalSince(liveQuote!.fetchedAt) < 60 * 60 * 36)
    }

    func refreshLiveFX() async {
        guard useLiveFX else { return }
        if let q = try? await LiveFX.fetch() {
            liveQuote = q
            encode(q, key: "fxQuote")
        }
        // offline: mantem a ultima cotacao, senao manual
    }

    func setUseLiveFX(_ on: Bool) {
        useLiveFX = on
        defaults.set(on, forKey: "useLiveFX")
    }

    // MARK: derived

    var settlement: Settlement {
        SettlementEngine.settle(expenses)
    }

    var cofrinho: (saved: Double, months: Int, ratio: Double, text: String) {
        let months = monthsUntil(start: Trip.date(fromISO: settings.start), from: Date())
        let saved = projected(monthly: settings.monthly, months: months)
        let ratio = settings.meta > 0 ? min(1, saved / settings.meta) : 0
        let pct = Int((ratio * 100).rounded())
        let text = Money.brl(saved) + " projetados ate o embarque (" + "\(months + 1)" +
            " aportes de " + Money.brl(settings.monthly) + "), " + "\(pct)" +
            "% da meta de " + Money.brl(settings.meta) + "."
        return (saved, months, ratio, text)
    }

    var budgetEur: Double {
        settings.meta / max(1, fx)
    }

    var checklistCounts: (done: Int, total: Int) {
        let all = ChecklistItem.Group.allCases.flatMap { checklist[$0] ?? [] }
        return (all.filter(\.done).count, all.count)
    }

    // MARK: mutations (persistem localmente e, configurado, sobem pro Supabase)

    func addExpense(desc: String, eur: Double, payer: Expense.Payer) {
        guard !desc.isEmpty, eur > 0 else { return }
        expenses.append(Expense(desc: desc, eur: eur, payer: payer))
        Task { await pushExpenses() }
    }

    func removeExpense(id: UUID) {
        // nota: sem tombstone - remocao local; sync re-add so se outra pessoa mantiver.
        expenses.removeAll { $0.id == id }
    }

    func addChecklistItem(_ text: String, group: ChecklistItem.Group) {
        guard !text.isEmpty else { return }
        checklist[group, default: []].append(ChecklistItem(text: text, done: false))
        Task { await pushChecklist() }
    }

    func toggleChecklistItem(_ item: ChecklistItem, group: ChecklistItem.Group) {
        guard let idx = checklist[group]?.firstIndex(where: { $0.id == item.id }) else { return }
        checklist[group]?[idx].done.toggle()
        Task { await pushChecklist() }
    }

    func removeChecklistItem(_ item: ChecklistItem, group: ChecklistItem.Group) {
        checklist[group]?.removeAll { $0.id == item.id }
        Task { await pushChecklist() }
    }

    func fixItineraryForStart() {
        // seeds sao 21 dias fixos; so garante que cada dia existe
        if itinerary.count < Trip.days {
            for d in Seeds.itinerary.dropFirst(itinerary.count) { itinerary.append(d) }
        }
    }

    // MARK: sync

    private func configuredConfig() -> SupabaseConfig? {
        let url = urlOrDefault(remoteURL)
        let key = keyOrDefault(remoteKey)
        guard SupabaseConfig.valid(url, key), !tripID.isEmpty else { return nil }
        return SupabaseConfig(url: url, anonKey: key)
    }

    func bakedConfig() -> SupabaseConfig? {
        SupabaseConfig.fromBundle()
    }

    var isSyncConfigured: Bool {
        configuredConfig() != nil
    }

    var client: SupabaseClient? {
        guard let cfg = configuredConfig() else { return nil }
        return try? SupabaseClient(baseURL: cfg.url, anonKey: cfg.anonKey)
    }

    private func urlOrDefault(_ override: String) -> String {
        if !override.isEmpty { return override }
        return (Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String) ?? ""
    }

    private func keyOrDefault(_ override: String) -> String {
        if !override.isEmpty { return override }
        return (Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String) ?? ""
    }

    /// Called on launch and on foreground when configured.
    func syncNow() async {
        guard let cl = client else { return }
        syncStatus = .syncing
        do {
            let remoteExp = SyncMap.decodeExpenses(try await cl.select(table: "expenses", tripID: tripID))
            let remoteIti = SyncMap.decodeItinerary(try await cl.select(table: "itinerary", tripID: tripID))
            let remoteCk = SyncMap.decodeChecklist(try await cl.select(table: "checklists", tripID: tripID))

            // gastos: union por id (remote wins nothing - gastos sao imutaveis)
            var seenExp = Set<UUID>()
            var mergedExp: [Expense] = []
            for e in (expenses + remoteExp) where !seenExp.contains(e.id) {
                mergedExp.append(e)
                seenExp.insert(e.id)
            }
            expenses = mergedExp

            // roteiro: 3 casos praticos das duas usuarias
            // 1) aparelho novo + roteiro vindo do supabase: adota o remoto inteiro
            // 2) ids equalizados: remoto vence no dia que existiu la (LWW)
            // 3) fallback: union sem duplicar titulo
            let localSeedTitles = Set(itinerary.map(\.title))
            if remoteIti.count == Trip.days,
               localSeedTitles.allSatisfy({ Seeds.itinerary.map(\.title).contains($0) }) {
                itinerary = remoteIti
            } else {
                var out: [ItineraryDay] = []
                var seen = Set<UUID>()
                for local in itinerary {
                    guard !seen.contains(local.id) else { continue }
                    seen.insert(local.id)
                    if let m = remoteIti.first(where: { $0.id == local.id }) ??
                               remoteIti.first(where: { $0.title == local.title }) {
                        out.append(m)          // remoto vence no mesmo dia
                    } else {
                        out.append(local)      // local vence
                    }
                }
                for r in remoteIti where !seen.contains(r.id) && !Set(out.map(\.title)).contains(r.title) {
                    out.append(r)
                    seen.insert(r.id)
                }
                itinerary = out
            }

            // checklist: union por id, dedupe por texto
            for g in ChecklistItem.Group.allCases {
                var seen = Set<UUID>()
                var seenText = Set<String>()
                var merged: [ChecklistItem] = []
                for item in ((checklist[g] ?? []) + (remoteCk[g] ?? []))
                where !seen.contains(item.id) && !seenText.contains(item.text) {
                    merged.append(item)
                    seen.insert(item.id)
                    seenText.insert(item.text)
                }
                checklist[g] = merged
            }

            syncStatus = .synced(Date())
        } catch {
            syncStatus = .failed(describe(error))
        }
    }

    private func describe(_ error: Error) -> String {
        if let se = error as? SyncError {
            switch se {
            case .http(let code): return "HTTP \(code)"
            case .malformedURL: return "URL invalida"
            case .network(let m): return m
            case .notConfigured: return "sem sync"
            }
        }
        return error.localizedDescription
    }

    func pushAll() async {
        guard let cl = client else { return }
        do {
            try await cl.upsert(table: "settings",
                                rows: [SyncRow.tripSettings(settings, tripID: tripID)])
            try await cl.upsert(table: "expenses",
                                rows: SyncMap.expenseRows(expenses, tripID: tripID))
            try await cl.upsert(table: "itinerary",
                                rows: SyncMap.itineraryRows(itinerary, tripID: tripID))
            try await cl.upsert(table: "checklists",
                                rows: SyncMap.checklistRows(checklist, tripID: tripID))
            syncStatus = .synced(Date())
        } catch {
            syncStatus = .failed(describe(error))
        }
    }

    private func pushExpenses() async {
        guard let cl = client else { return }
        do {
            try await cl.upsert(table: "expenses",
                                rows: SyncMap.expenseRows(expenses, tripID: tripID))
        } catch {
            syncStatus = .failed(describe(error))
        }
    }

    func pushItinerary() async {
        guard let cl = client else { return }
        do {
            try await cl.upsert(table: "itinerary",
                                rows: SyncMap.itineraryRows(itinerary, tripID: tripID))
        } catch {
            syncStatus = .failed(describe(error))
        }
    }

    private func pushChecklist() async {
        guard let cl = client else { return }
        do {
            try await cl.upsert(table: "checklists",
                                rows: SyncMap.checklistRows(checklist, tripID: tripID))
        } catch {
            syncStatus = .failed(describe(error))
        }
    }

    func saveSyncConfig(url: String, key: String, trip: String) {
        remoteURL = url
        remoteKey = key
        tripID = trip
        defaults.set(url, forKey: "remoteURL")
        defaults.set(key, forKey: "remoteKey")
        defaults.set(trip, forKey: "tripID")
    }

    // MARK: persistence

    private func encode<T: Codable>(_ value: T?, key: String) {
        guard let v = value, let data = try? JSONEncoder().encode(v) else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(data, forKey: key)
    }

    private func dec<T: Codable>(_ t: T.Type, _ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func dec<T: Codable>(_ t: T.Type, _ key: String, _ defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

/// Server row format for settings (other tables use PK id; settings uses trip_id).
public enum SyncRow {
    public static func tripSettings(_ s: TripSettings, tripID: String) -> [String: Any] {
        ["trip_id": tripID, "start": s.start, "meta": s.meta, "monthly": s.monthly]
    }
}

extension Array where Element == Expense {
    mutating func mergedWith(_ incoming: [Element]) {
        for e in incoming where !contains(where: { $0.id == e.id }) {
            append(e)
        }
    }
}
