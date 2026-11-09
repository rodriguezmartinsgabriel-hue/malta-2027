import Foundation

/// Supabase REST layer - plain URLSession, no SDK dependency.
///
/// Schema (also in research/supabase/schema.sql):
///   expenses  (id uuid pk, trip_id text, description text, amount numeric, payer text, created_at timestamptz)
///   itinerary (id uuid pk, trip_id text, idx int, title text, note text, done bool, updated_at timestamptz)
///   checklists(id uuid pk, trip_id text, group_idx int, text text, done bool, updated_at timestamptz)
///   settings  (trip_id text pk, start date, meta numeric, monthly numeric, updated_at timestamptz)
///
/// For two trusted users (Nana e Dani) the anon key + trip_id is the practical gate
/// while RLS keeps the tables closed to everyone else.

public struct SupabaseConfig: Codable, Equatable {
    public var url: String      // https://xxxx.supabase.co
    public var anonKey: String

    public init(url: String, anonKey: String) {
        self.url = url
        self.anonKey = anonKey
    }

    /// From Info.plist defaults (injected by Config/Local.xcconfig).
    public static func fromBundle(_ bundle: Bundle = .main) -> SupabaseConfig? {
        let base = (bundle.object(forInfoDictionaryKey: "SupabaseURL") as? String)
            .flatMap { $0.hasPrefix("https://") && !$0.contains("YOURPROJECT") ? $0 : nil }
        let key = (bundle.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String)
            .flatMap { ($0.count >= 20 && !$0.contains("YOURANON")) ? $0 : nil }
        guard let b = base, let k = key else { return nil }
        return SupabaseConfig(url: b, anonKey: k)
    }

    public static func valid(_ url: String, _ key: String) -> Bool {
        url.hasPrefix("https://") && key.count >= 20
    }
}

public enum SyncError: Error, Equatable {
    case notConfigured
    case malformedURL
    case http(Int)
    case network(String)
}

public struct SupabaseClient {
    let base: URL
    let anonKey: String

    public init(baseURL: String, anonKey: String) throws {
        guard SupabaseConfig.valid(baseURL, anonKey), let u = URL(string: baseURL) else {
            throw SyncError.malformedURL
        }
        base = u
        self.anonKey = anonKey
    }

    func table(_ name: String) -> URL? {
        URL(string: base.absoluteString + "/rest/v1/" + name)
    }

    func request(url: URL, method: String, body: Data? = nil, prefer: String? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer " + anonKey, forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let p = prefer { req.setValue(p, forHTTPHeaderField: "Prefer") }
        req.httpBody = body
        return req
    }

    /// GET /rest/v1/{table}?trip_id=eq.X&limit=500
    public func select(table name: String, tripID: String) async throws -> [[String: Any]] {
        guard let t = table(name) else { throw SyncError.malformedURL }
        guard let comps = URLComponents(url: t, resolvingAgainstBaseURL: false) else {
            throw SyncError.malformedURL
        }
        var c = comps
        c.queryItems = [
            URLQueryItem(name: "trip_id", value: "eq." + tripID),
            URLQueryItem(name: "limit", value: "500")
        ]
        guard let u = c.url else { throw SyncError.malformedURL }
        let req = request(url: u, method: "GET")
        return try await run(req)
    }

    /// POST /rest/v1/{table}?on_conflict=id - merge duplicates.
    public func upsert(table name: String, rows: [[String: Any]]) async throws {
        guard let t = table(name) else { throw SyncError.malformedURL }
        var comps = URLComponents(url: t, resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "on_conflict", value: "id")]
        let json = try JSONSerialization.data(withJSONObject: rows)
        let req = request(url: comps.url!, method: "POST", body: json,
                          prefer: "resolution=merge-duplicates")
        _ = try await run(req)
    }

    private func run(_ req: URLRequest) async throws -> [[String: Any]] {
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw SyncError.network("sem resposta") }
        guard (200..<300).contains(http.statusCode) else { throw SyncError.http(http.statusCode) }
        guard !data.isEmpty else { return [] }
        return (try JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }
}

// MARK: - row coders (schema <-> MaltaKit models)

public enum SyncMap {
    public static func expenseRows(_ expenses: [Expense], tripID: String) -> [[String: Any]] {
        expenses.map { e in
            [
                "id": e.id.uuidString,
                "trip_id": tripID,
                "description": e.desc,
                "amount": e.eur,
                "payer": e.payer.rawValue,
                "created_at": ISO8601DateFormatter().string(from: e.at)
            ]
        }
    }

    public static func decodeExpenses(_ rows: [[String: Any]]) -> [Expense] {
        rows.compactMap { row in
            guard let idStr = row["id"] as? String, let id = UUID(uuidString: idStr),
                  let desc = row["description"] as? String,
                  let amount = row["amount"] as? Double,
                  let payerRow = row["payer"] as? String,
                  let payer = Expense.Payer(rawValue: payerRow)
            else { return nil }
            var at = Date()
            if let atStr = row["created_at"] as? String {
                at = ISO8601DateFormatter().date(from: atStr) ?? at
            }
            return Expense(id: id, desc: desc, eur: amount, payer: payer, at: at)
        }
    }

    public static func itineraryRows(_ days: [ItineraryDay], tripID: String) -> [[String: Any]] {
        days.enumerated().map { (idx, d) in
            [
                "id": d.id.uuidString,
                "trip_id": tripID,
                "idx": idx,
                "title": d.title,
                "note": d.note,
                "done": d.done
            ]
        }
    }

    public static func decodeItinerary(_ rows: [[String: Any]]) -> [ItineraryDay] {
        rows.compactMap { row -> (idx: Int, day: ItineraryDay)? in
            guard let idStr = row["id"] as? String, let id = UUID(uuidString: idStr),
                  let title = row["title"] as? String
            else { return nil }
            let note = row["note"] as? String ?? ""
            let done = row["done"] as? Bool ?? false
            let idx = row["idx"] as? Int ?? 0
            return (idx, ItineraryDay(id: id, title: title, note: note, done: done))
        }
        .sorted { $0.idx < $1.idx }
        .map(\.day)
    }

    public static func checklistRows(_ groups: [ChecklistItem.Group: [ChecklistItem]], tripID: String) -> [[String: Any]] {
        var rows: [[String: Any]] = []
        for group in ChecklistItem.Group.allCases {
            for item in groups[group] ?? [] {
                rows.append([
                    "id": item.id.uuidString,
                    "trip_id": tripID,
                    "group_idx": ChecklistItem.Group.allCases.firstIndex(of: group) ?? 0,
                    "text": item.text,
                    "done": item.done
                ])
            }
        }
        return rows
    }

    public static func decodeChecklist(_ rows: [[String: Any]]) -> [ChecklistItem.Group: [ChecklistItem]] {
        var out: [ChecklistItem.Group: [ChecklistItem]] = [:]
        for group in ChecklistItem.Group.allCases { out[group] = [] }
        for row in rows {
            guard let idStr = row["id"] as? String, let id = UUID(uuidString: idStr),
                  let text = row["text"] as? String,
                  let gIdx = row["group_idx"] as? Int,
                  gIdx >= 0, gIdx < ChecklistItem.Group.allCases.count
            else { continue }
            let done = row["done"] as? Bool ?? false
            let group = ChecklistItem.Group.allCases[gIdx]
            out[group]?.append(ChecklistItem(id: id, text: text, done: done))
        }
        return out
    }
}

public struct ItineraryRow {
    let day: ItineraryDay
    let idx: Int
}
